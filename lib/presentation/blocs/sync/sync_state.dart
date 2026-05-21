part of 'sync_bloc.dart';

abstract class SyncState extends Equatable {
  const SyncState();
  @override
  List<Object?> get props => [];
}

class SyncIdle extends SyncState {
  final bool isOnline;
  const SyncIdle({this.isOnline = true});

  @override
  List<Object> get props => [isOnline];
}

class SyncInProgress extends SyncState {}

class SyncSuccess extends SyncState {
  final int syncedCount;
  const SyncSuccess(this.syncedCount);

  @override
  List<Object> get props => [syncedCount];
}

class SyncFailure extends SyncState {
  final String message;
  const SyncFailure(this.message);

  @override
  List<Object> get props => [message];
}

class SyncOffline extends SyncState {}
