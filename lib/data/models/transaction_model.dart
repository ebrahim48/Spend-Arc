import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.category,
    required super.type,
    required super.date,
    super.note,
    super.isSynced,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TransactionModel.fromEntity(Transaction t) => TransactionModel(
        id: t.id,
        title: t.title,
        amount: t.amount,
        category: t.category,
        type: t.type,
        date: t.date,
        note: t.note,
        isSynced: t.isSynced,
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
      );

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
        id: map['id'] as String,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        category: TransactionCategory.values.firstWhere(
          (e) => e.name == map['category'],
        ),
        type: TransactionType.values.firstWhere(
          (e) => e.name == map['type'],
        ),
        date: DateTime.parse(map['date'] as String),
        note: map['note'] as String?,
        isSynced: (map['is_synced'] as int) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: TransactionCategory.values.firstWhere(
          (e) => e.name == json['category'],
        ),
        type: TransactionType.values.firstWhere(
          (e) => e.name == json['type'],
        ),
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
        isSynced: json['is_synced'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category.name,
        'type': type.name,
        'date': date.toIso8601String(),
        'note': note,
        'is_synced': isSynced ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category.name,
        'type': type.name,
        'date': date.toIso8601String(),
        'note': note,
        'is_synced': isSynced,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
