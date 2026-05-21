part of 'transactions_bloc.dart';

abstract class TransactionsEvent extends Equatable {
  const TransactionsEvent();
  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionsEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionCategory? category;

  const LoadTransactions({this.startDate, this.endDate, this.category});

  @override
  List<Object?> get props => [startDate, endDate, category];
}

class AddTransactionEvent extends TransactionsEvent {
  final Transaction transaction;
  const AddTransactionEvent(this.transaction);

  @override
  List<Object> get props => [transaction];
}

class UpdateTransactionEvent extends TransactionsEvent {
  final Transaction transaction;
  const UpdateTransactionEvent(this.transaction);

  @override
  List<Object> get props => [transaction];
}

class DeleteTransactionEvent extends TransactionsEvent {
  final String id;
  const DeleteTransactionEvent(this.id);

  @override
  List<Object> get props => [id];
}

class UndoDeleteTransaction extends TransactionsEvent {
  final Transaction transaction;
  const UndoDeleteTransaction(this.transaction);

  @override
  List<Object> get props => [transaction];
}

class FilterTransactions extends TransactionsEvent {
  final TransactionCategory? category;
  final TransactionType? type;
  const FilterTransactions({this.category, this.type});

  @override
  List<Object?> get props => [category, type];
}
