import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/transaction.dart';
import '../../repositories/transaction_repository.dart';

class UpdateTransaction implements UseCase<Transaction, UpdateTransactionParams> {
  final TransactionRepository repository;
  UpdateTransaction(this.repository);

  @override
  Future<Either<Failure, Transaction>> call(UpdateTransactionParams params) {
    return repository.updateTransaction(params.transaction);
  }
}

class UpdateTransactionParams extends Equatable {
  final Transaction transaction;
  const UpdateTransactionParams({required this.transaction});

  @override
  List<Object> get props => [transaction];
}
