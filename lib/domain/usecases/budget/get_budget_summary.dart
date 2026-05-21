import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/budget_summary.dart';
import '../../repositories/transaction_repository.dart';

class GetBudgetSummary
    implements UseCase<BudgetSummary, GetBudgetSummaryParams> {
  final TransactionRepository repository;
  GetBudgetSummary(this.repository);

  @override
  Future<Either<Failure, BudgetSummary>> call(GetBudgetSummaryParams params) {
    return repository.getBudgetSummary(month: params.month);
  }
}

class GetBudgetSummaryParams extends Equatable {
  final DateTime month;
  const GetBudgetSummaryParams({required this.month});

  @override
  List<Object> get props => [month];
}
