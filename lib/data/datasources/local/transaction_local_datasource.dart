import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../../core/error/exceptions.dart';
import '../../models/transaction_model.dart';
import '../../../domain/entities/transaction.dart';

abstract class TransactionLocalDatasource {
  Future<List<TransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
  });

  Future<TransactionModel> insertTransaction(TransactionModel model);
  Future<TransactionModel> updateTransaction(TransactionModel model);
  Future<String> deleteTransaction(String id);
  Future<List<TransactionModel>> getUnsyncedTransactions();
  Future<void> markAsSynced(List<String> ids);
  Stream<List<TransactionModel>> watchTransactions();
}

class TransactionLocalDatasourceImpl implements TransactionLocalDatasource {
  final Database _db;
  final _streamController =
      StreamController<List<TransactionModel>>.broadcast();

  TransactionLocalDatasourceImpl(this._db);

  @override
  Future<List<TransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
  }) async {
    try {
      String where = '';
      final args = <dynamic>[];

      if (startDate != null) {
        where += (where.isEmpty ? '' : ' AND ') + 'date >= ?';
        args.add(startDate.toIso8601String());
      }
      if (endDate != null) {
        where += (where.isEmpty ? '' : ' AND ') + 'date <= ?';
        args.add(endDate.toIso8601String());
      }
      if (category != null) {
        where += (where.isEmpty ? '' : ' AND ') + 'category = ?';
        args.add(category.name);
      }

      final maps = await _db.query(
        'transactions',
        where: where.isEmpty ? null : where,
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'date DESC',
      );
      return maps.map(TransactionModel.fromMap).toList();
    } catch (e) {
      throw CacheException('Failed to load transactions: $e');
    }
  }

  @override
  Future<TransactionModel> insertTransaction(TransactionModel model) async {
    try {
      await _db.insert(
        'transactions',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _notifyListeners();
      return model;
    } catch (e) {
      throw CacheException('Failed to insert transaction: $e');
    }
  }

  @override
  Future<TransactionModel> updateTransaction(TransactionModel model) async {
    try {
      await _db.update(
        'transactions',
        model.toMap(),
        where: 'id = ?',
        whereArgs: [model.id],
      );
      _notifyListeners();
      return model;
    } catch (e) {
      throw CacheException('Failed to update transaction: $e');
    }
  }

  @override
  Future<String> deleteTransaction(String id) async {
    try {
      await _db.delete('transactions', where: 'id = ?', whereArgs: [id]);
      _notifyListeners();
      return id;
    } catch (e) {
      throw CacheException('Failed to delete transaction: $e');
    }
  }

  @override
  Future<List<TransactionModel>> getUnsyncedTransactions() async {
    final maps = await _db.query(
      'transactions',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return maps.map(TransactionModel.fromMap).toList();
  }

  @override
  Future<void> markAsSynced(List<String> ids) async {
    final batch = _db.batch();
    for (final id in ids) {
      batch.update(
        'transactions',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Stream<List<TransactionModel>> watchTransactions() {
    // Emit initial data
    getTransactions().then((data) {
      if (!_streamController.isClosed) {
        _streamController.add(data);
      }
    });
    return _streamController.stream;
  }

  Future<void> _notifyListeners() async {
    if (!_streamController.isClosed) {
      final data = await getTransactions();
      _streamController.add(data);
    }
  }

  void dispose() {
    _streamController.close();
  }
}
