import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/transaction.dart';
import '../../repositories/transaction_repository.dart';

class GetTransactions
    implements UseCase<List<Transaction>, GetTransactionsParams> {
  final TransactionRepository repository;
  GetTransactions(this.repository);

  @override
  Future<Either<Failure, List<Transaction>>> call(
      GetTransactionsParams params) {
    return repository.getTransactions(
      startDate: params.startDate,
      endDate: params.endDate,
      category: params.category,
    );
  }
}

class GetTransactionsParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionCategory? category;

  const GetTransactionsParams({this.startDate, this.endDate, this.category});

  @override
  List<Object?> get props => [startDate, endDate, category];
}
