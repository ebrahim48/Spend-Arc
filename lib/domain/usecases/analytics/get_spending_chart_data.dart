import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/chart_data.dart';
import '../../repositories/transaction_repository.dart';

class GetSpendingChartData
    implements UseCase<SpendingChartData, ChartDataParams> {
  final TransactionRepository repository;
  GetSpendingChartData(this.repository);

  @override
  Future<Either<Failure, SpendingChartData>> call(ChartDataParams params) {
    return repository.getSpendingChartData(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class ChartDataParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  const ChartDataParams({required this.startDate, required this.endDate});

  @override
  List<Object> get props => [startDate, endDate];
}
