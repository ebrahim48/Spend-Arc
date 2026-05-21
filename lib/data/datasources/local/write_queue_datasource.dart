import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../core/error/exceptions.dart';

enum QueueOperation { create, update, delete }

class WriteQueueEntry {
  final String id;
  final QueueOperation operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  const WriteQueueEntry({
    required this.id,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  factory WriteQueueEntry.fromMap(Map<String, dynamic> map) => WriteQueueEntry(
        id: map['id'] as String,
        operation: QueueOperation.values.firstWhere(
          (e) => e.name == map['operation'],
        ),
        payload:
            jsonDecode(map['payload'] as String) as Map<String, dynamic>,
        createdAt: DateTime.parse(map['created_at'] as String),
        retryCount: map['retry_count'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'operation': operation.name,
        'payload': jsonEncode(payload),
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
      };
}

abstract class WriteQueueDatasource {
  Future<void> enqueue(WriteQueueEntry entry);
  Future<List<WriteQueueEntry>> getPending();
  Future<void> remove(String id);
  Future<void> incrementRetry(String id);
}

class WriteQueueDatasourceImpl implements WriteQueueDatasource {
  final Database _db;
  WriteQueueDatasourceImpl(this._db);

  @override
  Future<void> enqueue(WriteQueueEntry entry) async {
    try {
      await _db.insert(
        'write_queue',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to enqueue write: $e');
    }
  }

  @override
  Future<List<WriteQueueEntry>> getPending() async {
    final maps = await _db.query(
      'write_queue',
      orderBy: 'created_at ASC',
      where: 'retry_count < ?',
      whereArgs: [5], // max 5 retries
    );
    return maps.map(WriteQueueEntry.fromMap).toList();
  }

  @override
  Future<void> remove(String id) async {
    await _db.delete('write_queue', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> incrementRetry(String id) async {
    await _db.rawUpdate(
      'UPDATE write_queue SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }
}
