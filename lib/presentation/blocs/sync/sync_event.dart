part of 'sync_bloc.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

class StartSyncMonitoring extends SyncEvent {}

class TriggerSync extends SyncEvent {}

class ConnectivityChanged extends SyncEvent {
  final bool isConnected;
  const ConnectivityChanged(this.isConnected);

  @override
  List<Object> get props => [isConnected];
}
