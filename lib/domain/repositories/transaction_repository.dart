import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/transaction.dart';
import '../entities/budget_summary.dart';
import '../entities/chart_data.dart';

abstract class TransactionRepository {
  /// Returns immediately from cache, then syncs in background
  Stream<Either<Failure, List<Transaction>>> watchTransactions();

  Future<Either<Failure, List<Transaction>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
  });

  Future<Either<Failure, Transaction>> addTransaction(Transaction transaction);

  Future<Either<Failure, Transaction>> updateTransaction(
      Transaction transaction);

  Future<Either<Failure, String>> deleteTransaction(String id);

  Future<Either<Failure, BudgetSummary>> getBudgetSummary({
    required DateTime month,
  });

  Future<Either<Failure, SpendingChartData>> getSpendingChartData({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Flush pending write queue to remote
  Future<Either<Failure, int>> syncPendingOperations();
}
