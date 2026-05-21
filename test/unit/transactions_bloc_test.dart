import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:finance_tracker/core/error/failures.dart';
import 'package:finance_tracker/domain/entities/transaction.dart';
import 'package:finance_tracker/domain/usecases/transactions/get_transactions.dart';
import 'package:finance_tracker/domain/usecases/transactions/add_transaction.dart';
import 'package:finance_tracker/domain/usecases/transactions/delete_transaction.dart';
import 'package:finance_tracker/domain/usecases/transactions/update_transaction.dart';
import 'package:finance_tracker/presentation/blocs/transactions/transactions_bloc.dart';

// Mocks
class MockGetTransactions extends Mock implements GetTransactions {}
class MockAddTransaction extends Mock implements AddTransaction {}
class MockDeleteTransaction extends Mock implements DeleteTransaction {}
class MockUpdateTransaction extends Mock implements UpdateTransaction {}

// Fake params for mocktail
class FakeGetTransactionsParams extends Fake implements GetTransactionsParams {}
class FakeAddTransactionParams extends Fake implements AddTransactionParams {}
class FakeDeleteTransactionParams extends Fake implements DeleteTransactionParams {}
class FakeUpdateTransactionParams extends Fake implements UpdateTransactionParams {}

void main() {
  late MockGetTransactions mockGet;
  late MockAddTransaction mockAdd;
  late MockDeleteTransaction mockDelete;
  late MockUpdateTransaction mockUpdate;

  final now = DateTime(2024, 6, 15);

  final tTransaction = Transaction(
    id: 'tx-1',
    title: 'Groceries',
    amount: 50.0,
    category: TransactionCategory.food,
    type: TransactionType.expense,
    date: now,
    isSynced: false,
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(FakeGetTransactionsParams());
    registerFallbackValue(FakeAddTransactionParams());
    registerFallbackValue(FakeDeleteTransactionParams());
    registerFallbackValue(FakeUpdateTransactionParams());
  });

  setUp(() {
    mockGet = MockGetTransactions();
    mockAdd = MockAddTransaction();
    mockDelete = MockDeleteTransaction();
    mockUpdate = MockUpdateTransaction();
  });

  TransactionsBloc buildBloc() => TransactionsBloc(
        getTransactions: mockGet,
        addTransaction: mockAdd,
        deleteTransaction: mockDelete,
        updateTransaction: mockUpdate,
      );

  group('TransactionsBloc', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'emits [Loading, Loaded] on successful LoadTransactions',
      build: buildBloc,
      setUp: () {
        when(() => mockGet(any()))
            .thenAnswer((_) async => Right([tTransaction]));
      },
      act: (bloc) => bloc.add(const LoadTransactions()),
      expect: () => [
        isA<TransactionsLoading>(),
        isA<TransactionsLoaded>().having(
          (s) => s.transactions.length,
          'transactions count',
          1,
        ),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'emits [Loading, Error] on failed LoadTransactions',
      build: buildBloc,
      setUp: () {
        when(() => mockGet(any()))
            .thenAnswer((_) async => const Left(CacheFailure('DB error')));
      },
      act: (bloc) => bloc.add(const LoadTransactions()),
      expect: () => [
        isA<TransactionsLoading>(),
        isA<TransactionsError>().having(
          (s) => s.message,
          'error message',
          'DB error',
        ),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'optimistically adds transaction before server confirms',
      build: buildBloc,
      seed: () => TransactionsLoaded(
        transactions: [tTransaction],
        filtered: [tTransaction],
      ),
      setUp: () {
        when(() => mockAdd(any()))
            .thenAnswer((_) async => Right(tTransaction));
      },
      act: (bloc) => bloc.add(AddTransactionEvent(tTransaction.copyWith(
        id: 'tx-2',
        title: 'New item',
      ))),
      expect: () => [
        isA<TransactionsLoaded>().having(
          (s) => s.transactions.length,
          'optimistic count',
          2,
        ),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'rolls back on add failure',
      build: buildBloc,
      seed: () => TransactionsLoaded(
        transactions: [tTransaction],
        filtered: [tTransaction],
      ),
      setUp: () {
        when(() => mockAdd(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Network error')),
        );
      },
      act: (bloc) => bloc.add(AddTransactionEvent(tTransaction.copyWith(
        id: 'tx-fail',
        title: 'Will fail',
      ))),
      expect: () => [
        // Optimistic state (2 items)
        isA<TransactionsLoaded>().having(
          (s) => s.transactions.length,
          'optimistic',
          2,
        ),
        // Rollback state (1 item)
        isA<TransactionsLoaded>().having(
          (s) => s.transactions.length,
          'rolled back',
          1,
        ),
        // Error state
        isA<TransactionsError>(),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'FilterTransactions filters by category',
      build: buildBloc,
      seed: () {
        final transport = tTransaction.copyWith(
          id: 'tx-3',
          category: TransactionCategory.transport,
        );
        return TransactionsLoaded(
          transactions: [tTransaction, transport],
          filtered: [tTransaction, transport],
        );
      },
      act: (bloc) => bloc.add(
        const FilterTransactions(category: TransactionCategory.food),
      ),
      expect: () => [
        isA<TransactionsLoaded>().having(
          (s) => s.filtered.length,
          'filtered count',
          1,
        ),
      ],
    );
  });
}
