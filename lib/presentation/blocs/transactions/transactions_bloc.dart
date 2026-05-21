import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/usecases/transactions/get_transactions.dart';
import '../../../domain/usecases/transactions/add_transaction.dart';
import '../../../domain/usecases/transactions/delete_transaction.dart';
import '../../../domain/usecases/transactions/update_transaction.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final GetTransactions getTransactions;
  final AddTransaction addTransaction;
  final DeleteTransaction deleteTransaction;
  final UpdateTransaction updateTransaction;

  // For optimistic rollback
  List<Transaction> _lastKnownGoodState = [];

  TransactionsBloc({
    required this.getTransactions,
    required this.addTransaction,
    required this.deleteTransaction,
    required this.updateTransaction,
  }) : super(TransactionsInitial()) {
    on<LoadTransactions>(_onLoad);
    on<AddTransactionEvent>(_onAdd);
    on<UpdateTransactionEvent>(_onUpdate);
    on<DeleteTransactionEvent>(_onDelete);
    on<UndoDeleteTransaction>(_onUndoDelete);
    on<FilterTransactions>(_onFilter);
  }

  Future<void> _onLoad(
    LoadTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(TransactionsLoading());
    final result = await getTransactions(GetTransactionsParams(
      startDate: event.startDate,
      endDate: event.endDate,
      category: event.category,
    ));
    result.fold(
      (failure) => emit(TransactionsError(message: failure.message)),
      (transactions) {
        _lastKnownGoodState = transactions;
        emit(TransactionsLoaded(
          transactions: transactions,
          filtered: transactions,
        ));
      },
    );
  }

  Future<void> _onAdd(
    AddTransactionEvent event,
    Emitter<TransactionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TransactionsLoaded) return;

    // Optimistic update
    final optimisticList = [event.transaction, ...currentState.transactions];
    emit(currentState.copyWith(
      transactions: optimisticList,
      filtered: _applyFilter(
        optimisticList,
        currentState.activeCategory,
        currentState.activeType,
      ),
    ));

    final result = await addTransaction(
      AddTransactionParams(transaction: event.transaction),
    );

    result.fold(
      (failure) {
        // Rollback
        emit(currentState.copyWith(
          transactions: _lastKnownGoodState,
          filtered: _applyFilter(
            _lastKnownGoodState,
            currentState.activeCategory,
            currentState.activeType,
          ),
        ));
        emit(TransactionsError(
          message: failure.message,
          cachedTransactions: _lastKnownGoodState,
        ));
      },
      (saved) {
        _lastKnownGoodState = optimisticList;
      },
    );
  }

  Future<void> _onUpdate(
    UpdateTransactionEvent event,
    Emitter<TransactionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TransactionsLoaded) return;

    final previousList = List<Transaction>.from(currentState.transactions);

    // Optimistic update
    final optimisticList = currentState.transactions.map((t) {
      return t.id == event.transaction.id ? event.transaction : t;
    }).toList();

    emit(currentState.copyWith(
      transactions: optimisticList,
      filtered: _applyFilter(
        optimisticList,
        currentState.activeCategory,
        currentState.activeType,
      ),
    ));

    final result = await updateTransaction(
      UpdateTransactionParams(transaction: event.transaction),
    );

    result.fold(
      (failure) {
        // Rollback
        emit(currentState.copyWith(
          transactions: previousList,
          filtered: _applyFilter(
            previousList,
            currentState.activeCategory,
            currentState.activeType,
          ),
        ));
        emit(TransactionsError(
          message: failure.message,
          cachedTransactions: previousList,
        ));
      },
      (updated) {
        _lastKnownGoodState = optimisticList;
      },
    );
  }

  Future<void> _onDelete(
    DeleteTransactionEvent event,
    Emitter<TransactionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TransactionsLoaded) return;

    final previousList = List<Transaction>.from(currentState.transactions);

    // Optimistic delete
    final optimisticList =
        currentState.transactions.where((t) => t.id != event.id).toList();

    emit(currentState.copyWith(
      transactions: optimisticList,
      filtered: _applyFilter(
        optimisticList,
        currentState.activeCategory,
        currentState.activeType,
      ),
    ));

    final result =
        await deleteTransaction(DeleteTransactionParams(id: event.id));

    result.fold(
      (failure) {
        // Rollback
        emit(currentState.copyWith(
          transactions: previousList,
          filtered: _applyFilter(
            previousList,
            currentState.activeCategory,
            currentState.activeType,
          ),
        ));
        emit(TransactionsError(
          message: failure.message,
          cachedTransactions: previousList,
        ));
      },
      (_) {
        _lastKnownGoodState = optimisticList;
      },
    );
  }

  Future<void> _onUndoDelete(
    UndoDeleteTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    add(AddTransactionEvent(event.transaction));
  }

  void _onFilter(
    FilterTransactions event,
    Emitter<TransactionsState> emit,
  ) {
    final currentState = state;
    if (currentState is! TransactionsLoaded) return;

    final filtered = _applyFilter(
      currentState.transactions,
      event.category,
      event.type,
    );

    emit(currentState.copyWith(
      filtered: filtered,
      activeCategory: event.category,
      clearCategory: event.category == null,
      activeType: event.type,
      clearType: event.type == null,
    ));
  }

  List<Transaction> _applyFilter(
    List<Transaction> transactions,
    TransactionCategory? category,
    TransactionType? type,
  ) {
    return transactions.where((t) {
      final categoryMatch = category == null || t.category == category;
      final typeMatch = type == null || t.type == type;
      return categoryMatch && typeMatch;
    }).toList();
  }
}
