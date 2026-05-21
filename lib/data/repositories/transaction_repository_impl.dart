import 'dart:isolate';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/budget_summary.dart';
import '../../domain/entities/chart_data.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/local/transaction_local_datasource.dart';
import '../datasources/local/write_queue_datasource.dart';
import '../datasources/remote/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDatasource localDatasource;
  final TransactionRemoteDatasource remoteDatasource;
  final WriteQueueDatasource writeQueue;
  final NetworkInfo networkInfo;

  TransactionRepositoryImpl({
    required this.localDatasource,
    required this.remoteDatasource,
    required this.writeQueue,
    required this.networkInfo,
  });

  @override
  Stream<Either<Failure, List<Transaction>>> watchTransactions() {
    return localDatasource.watchTransactions().map(
          (models) => Right<Failure, List<Transaction>>(models),
        );
  }

  @override
  Future<Either<Failure, List<Transaction>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
  }) async {
    try {
      // Always load from local first (offline-first)
      final local = await localDatasource.getTransactions(
        startDate: startDate,
        endDate: endDate,
        category: category,
      );

      // Background sync if online
      if (await networkInfo.isConnected) {
        _syncInBackground();
      }

      return Right(local);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Transaction>> addTransaction(
      Transaction transaction) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      // Write locally immediately
      final saved = await localDatasource.insertTransaction(model);

      // Enqueue for remote sync
      await writeQueue.enqueue(WriteQueueEntry(
        id: const Uuid().v4(),
        operation: QueueOperation.create,
        payload: model.toJson(),
        createdAt: DateTime.now(),
      ));

      // Try immediate sync if online
      if (await networkInfo.isConnected) {
        _syncInBackground();
      }

      return Right(saved);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Transaction>> updateTransaction(
      Transaction transaction) async {
    try {
      final model = TransactionModel.fromEntity(
        transaction.copyWith(
          isSynced: false,
          updatedAt: DateTime.now(),
        ),
      );
      final updated = await localDatasource.updateTransaction(model);

      await writeQueue.enqueue(WriteQueueEntry(
        id: const Uuid().v4(),
        operation: QueueOperation.update,
        payload: model.toJson(),
        createdAt: DateTime.now(),
      ));

      if (await networkInfo.isConnected) {
        _syncInBackground();
      }

      return Right(updated);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> deleteTransaction(String id) async {
    try {
      final deleted = await localDatasource.deleteTransaction(id);

      await writeQueue.enqueue(WriteQueueEntry(
        id: const Uuid().v4(),
        operation: QueueOperation.delete,
        payload: {'id': id},
        createdAt: DateTime.now(),
      ));

      if (await networkInfo.isConnected) {
        _syncInBackground();
      }

      return Right(deleted);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, BudgetSummary>> getBudgetSummary({
    required DateTime month,
  }) async {
    try {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final transactions = await localDatasource.getTransactions(
        startDate: start,
        endDate: end,
      );

      // Run heavy computation in isolate
      final summary = await Isolate.run(() => _computeBudgetSummary(transactions));
      return Right(summary);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, SpendingChartData>> getSpendingChartData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final transactions = await localDatasource.getTransactions(
        startDate: startDate,
        endDate: endDate,
      );

      final chartData = await Isolate.run(
        () => _computeChartData(transactions, startDate, endDate),
      );
      return Right(chartData);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, int>> syncPendingOperations() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final pending = await writeQueue.getPending();
      int synced = 0;

      for (final entry in pending) {
        try {
          switch (entry.operation) {
            case QueueOperation.create:
              final model = TransactionModel.fromJson(entry.payload);
              await remoteDatasource.createTransaction(model);
              await localDatasource.markAsSynced([model.id]);
              break;
            case QueueOperation.update:
              final model = TransactionModel.fromJson(entry.payload);
              await remoteDatasource.updateTransaction(model);
              await localDatasource.markAsSynced([model.id]);
              break;
            case QueueOperation.delete:
              await remoteDatasource.deleteTransaction(
                  entry.payload['id'] as String);
              break;
          }
          await writeQueue.remove(entry.id);
          synced++;
        } catch (_) {
          await writeQueue.incrementRetry(entry.id);
        }
      }

      return Right(synced);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  void _syncInBackground() {
    syncPendingOperations();
  }
}

// Pure functions for isolate computation
BudgetSummary _computeBudgetSummary(List<TransactionModel> transactions) {
  double totalIncome = 0;
  double totalExpense = 0;
  final categorySpend = <TransactionCategory, double>{};

  for (final t in transactions) {
    if (t.type == TransactionType.income) {
      totalIncome += t.amount;
    } else {
      totalExpense += t.amount;
      categorySpend[t.category] =
          (categorySpend[t.category] ?? 0) + t.amount;
    }
  }

  // Default budget limits
  const defaultLimits = {
    TransactionCategory.food: 500.0,
    TransactionCategory.transport: 200.0,
    TransactionCategory.entertainment: 150.0,
    TransactionCategory.health: 300.0,
    TransactionCategory.shopping: 400.0,
    TransactionCategory.utilities: 250.0,
  };

  final categoryBudgets = categorySpend.entries.map((e) {
    return CategoryBudget(
      category: e.key,
      spent: e.value,
      limit: defaultLimits[e.key] ?? 500.0,
    );
  }).toList();

  final balance = totalIncome - totalExpense;
  final savingsRate =
      totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) : 0.0;

  return BudgetSummary(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    totalBalance: balance,
    categoryBudgets: categoryBudgets,
    savingsRate: savingsRate.clamp(0.0, 1.0),
  );
}

SpendingChartData _computeChartData(
  List<TransactionModel> transactions,
  DateTime startDate,
  DateTime endDate,
) {
  final dayMap = <DateTime, ChartPoint>{};

  // Build day buckets
  var current = DateTime(startDate.year, startDate.month, startDate.day);
  final end = DateTime(endDate.year, endDate.month, endDate.day);
  while (!current.isAfter(end)) {
    dayMap[current] = ChartPoint(date: current, income: 0, expense: 0);
    current = current.add(const Duration(days: 1));
  }

  for (final t in transactions) {
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    final existing = dayMap[day];
    if (existing != null) {
      if (t.type == TransactionType.income) {
        dayMap[day] = ChartPoint(
          date: day,
          income: existing.income + t.amount,
          expense: existing.expense,
        );
      } else {
        dayMap[day] = ChartPoint(
          date: day,
          income: existing.income,
          expense: existing.expense + t.amount,
        );
      }
    }
  }

  final points = dayMap.values.toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  double maxVal = 0;
  double minVal = double.infinity;
  for (final p in points) {
    final max = p.income > p.expense ? p.income : p.expense;
    final min = p.income < p.expense ? p.income : p.expense;
    if (max > maxVal) maxVal = max;
    if (min < minVal) minVal = min;
  }

  return SpendingChartData(
    points: points,
    maxValue: maxVal,
    minValue: minVal == double.infinity ? 0 : minVal,
  );
}
