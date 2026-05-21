part of 'budget_bloc.dart';

abstract class BudgetState extends Equatable {
  const BudgetState();
  @override
  List<Object?> get props => [];
}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetLoaded extends BudgetState {
  final BudgetSummary summary;
  final DateTime month;

  const BudgetLoaded({required this.summary, required this.month});

  @override
  List<Object> get props => [summary, month];
}

class BudgetError extends BudgetState {
  final String message;
  const BudgetError(this.message);

  @override
  List<Object> get props => [message];
}
