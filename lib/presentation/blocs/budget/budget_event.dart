part of 'budget_bloc.dart';

abstract class BudgetEvent extends Equatable {
  const BudgetEvent();
  @override
  List<Object?> get props => [];
}

class LoadBudgetSummary extends BudgetEvent {
  final DateTime month;
  const LoadBudgetSummary({required this.month});

  @override
  List<Object> get props => [month];
}

class RefreshBudget extends BudgetEvent {
  const RefreshBudget();
}
