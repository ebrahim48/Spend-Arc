import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/budget_summary.dart';
import '../../domain/entities/transaction.dart';
import 'animations/arc_meter_painter.dart';

class BudgetArcCard extends StatelessWidget {
  final CategoryBudget budget;

  const BudgetArcCard({super.key, required this.budget});

  Color get _categoryColor {
    switch (budget.category) {
      case TransactionCategory.food:
        return const Color(0xFFFF7043);
      case TransactionCategory.transport:
        return const Color(0xFF42A5F5);
      case TransactionCategory.entertainment:
        return const Color(0xFFAB47BC);
      case TransactionCategory.health:
        return const Color(0xFF26A69A);
      case TransactionCategory.shopping:
        return const Color(0xFFEC407A);
      case TransactionCategory.utilities:
        return const Color(0xFFFFCA28);
      case TransactionCategory.salary:
        return const Color(0xFF66BB6A);
      case TransactionCategory.investment:
        return const Color(0xFF29B6F6);
      case TransactionCategory.other:
        return const Color(0xFF78909C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = budget.isOverBudget ? AppColors.expense : _categoryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.cardGradientStart, AppColors.cardGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: budget.isOverBudget
              ? AppColors.expense.withOpacity(0.3)
              : AppColors.divider,
        ),
      ),
      child: Column(
        children: [
          AnimatedArcMeter(
            progress: budget.percentage,
            size: 120,
            fillColor: color,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  budget.category.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(budget.percentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            budget.category.displayName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(budget.spent),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'of ${CurrencyFormatter.format(budget.limit)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          if (budget.isOverBudget) ...[
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.expense.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Over budget',
                style: TextStyle(
                  color: AppColors.expense,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
