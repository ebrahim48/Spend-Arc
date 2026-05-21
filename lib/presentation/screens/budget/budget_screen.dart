import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../blocs/budget/budget_bloc.dart';
import '../../widgets/budget_arc_card.dart';
import '../../widgets/animations/arc_meter_painter.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<BudgetBloc>()
        .add(LoadBudgetSummary(month: DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<BudgetBloc>().add(const RefreshBudget()),
          ),
        ],
      ),
      body: BlocBuilder<BudgetBloc, BudgetState>(
        builder: (context, state) {
          if (state is BudgetLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is BudgetError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppColors.expense),
              ),
            );
          }

          if (state is BudgetLoaded) {
            final summary = state.summary;
            return CustomScrollView(
              slivers: [
                // Savings rate arc
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _SavingsRateCard(
                      savingsRate: summary.savingsRate,
                      totalIncome: summary.totalIncome,
                      totalExpense: summary.totalExpense,
                      balance: summary.totalBalance,
                    ),
                  ),
                ),

                // Category budgets grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => BudgetArcCard(
                        budget: summary.categoryBudgets[index],
                      ),
                      childCount: summary.categoryBudgets.length,
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SavingsRateCard extends StatelessWidget {
  final double savingsRate;
  final double totalIncome;
  final double totalExpense;
  final double balance;

  const _SavingsRateCard({
    required this.savingsRate,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.cardGradientStart, AppColors.cardGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          AnimatedArcMeter(
            progress: savingsRate,
            size: 130,
            fillColor: AppColors.secondary,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💰', style: TextStyle(fontSize: 22)),
                const SizedBox(height: 2),
                Text(
                  '${(savingsRate * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'saved',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This Month',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                _StatRow(
                  label: 'Income',
                  value: CurrencyFormatter.format(totalIncome),
                  color: AppColors.income,
                ),
                const SizedBox(height: 8),
                _StatRow(
                  label: 'Spent',
                  value: CurrencyFormatter.format(totalExpense),
                  color: AppColors.expense,
                ),
                const Divider(height: 20, color: AppColors.divider),
                _StatRow(
                  label: 'Balance',
                  value: CurrencyFormatter.format(balance),
                  color: balance >= 0 ? AppColors.income : AppColors.expense,
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: bold ? 13 : 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
