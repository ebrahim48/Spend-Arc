import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/transaction_repository.dart';

class DeleteTransaction implements UseCase<String, DeleteTransactionParams> {
  final TransactionRepository repository;
  DeleteTransaction(this.repository);

  @override
  Future<Either<Failure, String>> call(DeleteTransactionParams params) {
    return repository.deleteTransaction(params.id);
  }
}

class DeleteTransactionParams extends Equatable {
  final String id;
  const DeleteTransactionParams({required this.id});

  @override
  List<Object> get props => [id];
}
