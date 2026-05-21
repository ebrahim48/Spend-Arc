import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/network/network_info.dart';
import '../../../domain/repositories/transaction_repository.dart';

part 'sync_event.dart';
part 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final TransactionRepository repository;
  final NetworkInfo networkInfo;
  StreamSubscription<bool>? _connectivitySub;

  SyncBloc({required this.repository, required this.networkInfo})
      : super(const SyncIdle()) {
    on<StartSyncMonitoring>(_onStartMonitoring);
    on<TriggerSync>(_onTriggerSync);
    on<ConnectivityChanged>(_onConnectivityChanged);
  }

  Future<void> _onStartMonitoring(
    StartSyncMonitoring event,
    Emitter<SyncState> emit,
  ) async {
    await _connectivitySub?.cancel();
    _connectivitySub = networkInfo.onConnectivityChanged.listen((isConnected) {
      add(ConnectivityChanged(isConnected));
    });

    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      add(TriggerSync());
    } else {
      emit(SyncOffline());
    }
  }

  Future<void> _onTriggerSync(
    TriggerSync event,
    Emitter<SyncState> emit,
  ) async {
    emit(SyncInProgress());
    final result = await repository.syncPendingOperations();
    result.fold(
      (failure) => emit(SyncFailure(failure.message)),
      (count) => emit(SyncSuccess(count)),
    );
    // Return to idle after brief success display
    await Future.delayed(const Duration(seconds: 2));
    if (!isClosed) emit(const SyncIdle(isOnline: true));
  }

  Future<void> _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<SyncState> emit,
  ) async {
    if (event.isConnected) {
      add(TriggerSync());
    } else {
      emit(SyncOffline());
    }
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }
}
