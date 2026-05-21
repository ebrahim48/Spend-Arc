import 'package:equatable/equatable.dart';
import 'transaction.dart';

class CategoryBudget extends Equatable {
  final TransactionCategory category;
  final double spent;
  final double limit;

  const CategoryBudget({
    required this.category,
    required this.spent,
    required this.limit,
  });

  double get percentage => limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
  bool get isOverBudget => spent > limit;
  double get remaining => (limit - spent).clamp(0, double.infinity);

  @override
  List<Object> get props => [category, spent, limit];
}

class BudgetSummary extends Equatable {
  final double totalIncome;
  final double totalExpense;
  final double totalBalance;
  final List<CategoryBudget> categoryBudgets;
  final double savingsRate;

  const BudgetSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBalance,
    required this.categoryBudgets,
    required this.savingsRate,
  });

  @override
  List<Object> get props =>
      [totalIncome, totalExpense, totalBalance, categoryBudgets, savingsRate];
}
