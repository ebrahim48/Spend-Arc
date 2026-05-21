import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/data/models/transaction_model.dart';
import 'package:finance_tracker/domain/entities/transaction.dart';

void main() {
  final now = DateTime(2024, 6, 15, 10, 30);

  final tMap = {
    'id': 'test-id-1',
    'title': 'Coffee',
    'amount': 4.5,
    'category': 'food',
    'type': 'expense',
    'date': now.toIso8601String(),
    'note': 'Morning coffee',
    'is_synced': 0,
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  final tModel = TransactionModel(
    id: 'test-id-1',
    title: 'Coffee',
    amount: 4.5,
    category: TransactionCategory.food,
    type: TransactionType.expense,
    date: now,
    note: 'Morning coffee',
    isSynced: false,
    createdAt: now,
    updatedAt: now,
  );

  group('TransactionModel', () {
    test('1. fromMap creates correct model', () {
      final result = TransactionModel.fromMap(tMap);
      expect(result.id, 'test-id-1');
      expect(result.title, 'Coffee');
      expect(result.amount, 4.5);
      expect(result.category, TransactionCategory.food);
      expect(result.type, TransactionType.expense);
      expect(result.isSynced, false);
    });

    test('2. toMap produces correct map', () {
      final map = tModel.toMap();
      expect(map['id'], 'test-id-1');
      expect(map['amount'], 4.5);
      expect(map['category'], 'food');
      expect(map['type'], 'expense');
      expect(map['is_synced'], 0);
    });

    test('3. fromMap → toMap round-trip is lossless', () {
      final model = TransactionModel.fromMap(tMap);
      final backToMap = model.toMap();
      expect(backToMap['id'], tMap['id']);
      expect(backToMap['title'], tMap['title']);
      expect(backToMap['amount'], tMap['amount']);
      expect(backToMap['category'], tMap['category']);
      expect(backToMap['is_synced'], tMap['is_synced']);
    });

    test('4. fromEntity preserves all fields', () {
      final entity = Transaction(
        id: 'ent-1',
        title: 'Salary',
        amount: 3000.0,
        category: TransactionCategory.salary,
        type: TransactionType.income,
        date: now,
        isSynced: true,
        createdAt: now,
        updatedAt: now,
      );
      final model = TransactionModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.amount, entity.amount);
      expect(model.type, TransactionType.income);
      expect(model.isSynced, true);
    });

    test('5. copyWith updates only specified fields', () {
      final updated = tModel.copyWith(title: 'Latte', amount: 5.0);
      expect(updated.title, 'Latte');
      expect(updated.amount, 5.0);
      // Unchanged fields
      expect(updated.id, tModel.id);
      expect(updated.category, tModel.category);
      expect(updated.type, tModel.type);
    });
  });
}
