import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../data/datasources/local/transaction_local_datasource.dart';
import '../../data/datasources/local/write_queue_datasource.dart';
import '../../data/datasources/remote/transaction_remote_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/transactions/get_transactions.dart';
import '../../domain/usecases/transactions/add_transaction.dart';
import '../../domain/usecases/transactions/delete_transaction.dart';
import '../../domain/usecases/transactions/update_transaction.dart';
import '../../domain/usecases/budget/get_budget_summary.dart';
import '../../domain/usecases/analytics/get_spending_chart_data.dart';
import '../../presentation/blocs/transactions/transactions_bloc.dart';
import '../../presentation/blocs/budget/budget_bloc.dart';
import '../../presentation/blocs/sync/sync_bloc.dart';
import '../network/network_info.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {

  final db = await _initDatabase();
  sl.registerSingleton<Database>(db);

  // Dio
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.financetracker.dev/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  sl.registerSingleton<Dio>(dio);


  sl.registerSingleton<Connectivity>(Connectivity());


  sl.registerSingleton<NetworkInfo>(NetworkInfoImpl(sl()));


  sl.registerSingleton<TransactionLocalDatasource>(
    TransactionLocalDatasourceImpl(sl()),
  );
  sl.registerSingleton<WriteQueueDatasource>(
    WriteQueueDatasourceImpl(sl()),
  );
  sl.registerLazySingleton<TransactionRemoteDatasource>(
    () => TransactionRemoteDatasourceImpl(sl()),
  );


  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      localDatasource: sl(),
      remoteDatasource: sl(),
      writeQueue: sl(),
      networkInfo: sl(),
    ),
  );


  sl.registerLazySingleton(() => GetTransactions(sl()));
  sl.registerLazySingleton(() => AddTransaction(sl()));
  sl.registerLazySingleton(() => DeleteTransaction(sl()));
  sl.registerLazySingleton(() => UpdateTransaction(sl()));
  sl.registerLazySingleton(() => GetBudgetSummary(sl()));
  sl.registerLazySingleton(() => GetSpendingChartData(sl()));


  sl.registerFactory(
    () => TransactionsBloc(
      getTransactions: sl(),
      addTransaction: sl(),
      deleteTransaction: sl(),
      updateTransaction: sl(),
    ),
  );
  sl.registerFactory(
    () => BudgetBloc(getBudgetSummary: sl()),
  );
  sl.registerFactory(
    () => SyncBloc(repository: sl(), networkInfo: sl()),
  );
}

Future<Database> _initDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = p.join(dbPath, 'finance_tracker.db');

  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE transactions (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          type TEXT NOT NULL,
          date TEXT NOT NULL,
          note TEXT,
          is_synced INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE write_queue (
          id TEXT PRIMARY KEY,
          operation TEXT NOT NULL,
          payload TEXT NOT NULL,
          created_at TEXT NOT NULL,
          retry_count INTEGER NOT NULL DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE budget_limits (
          category TEXT PRIMARY KEY,
          monthly_limit REAL NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    },
  );
}
