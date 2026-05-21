part of 'transactions_bloc.dart';

abstract class TransactionsState extends Equatable {
  const TransactionsState();
  @override
  List<Object?> get props => [];
}

class TransactionsInitial extends TransactionsState {}

class TransactionsLoading extends TransactionsState {}

class TransactionsLoaded extends TransactionsState {
  final List<Transaction> transactions;
  final List<Transaction> filtered;
  final TransactionCategory? activeCategory;
  final TransactionType? activeType;
  final bool isSyncing;

  const TransactionsLoaded({
    required this.transactions,
    required this.filtered,
    this.activeCategory,
    this.activeType,
    this.isSyncing = false,
  });

  TransactionsLoaded copyWith({
    List<Transaction>? transactions,
    List<Transaction>? filtered,
    TransactionCategory? activeCategory,
    bool clearCategory = false,
    TransactionType? activeType,
    bool clearType = false,
    bool? isSyncing,
  }) {
    return TransactionsLoaded(
      transactions: transactions ?? this.transactions,
      filtered: filtered ?? this.filtered,
      activeCategory:
          clearCategory ? null : (activeCategory ?? this.activeCategory),
      activeType: clearType ? null : (activeType ?? this.activeType),
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object?> get props =>
      [transactions, filtered, activeCategory, activeType, isSyncing];
}

class TransactionsError extends TransactionsState {
  final String message;
  final List<Transaction> cachedTransactions;

  const TransactionsError({
    required this.message,
    this.cachedTransactions = const [],
  });

  @override
  List<Object> get props => [message, cachedTransactions];
}

class TransactionOperationSuccess extends TransactionsState {
  final String message;
  final List<Transaction> transactions;

  const TransactionOperationSuccess({
    required this.message,
    required this.transactions,
  });

  @override
  List<Object> get props => [message, transactions];
}
