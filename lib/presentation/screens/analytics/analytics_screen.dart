import 'package:flutter/material.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/chart_data.dart';
import '../../../domain/usecases/analytics/get_spending_chart_data.dart';
import '../../widgets/animations/line_chart_painter.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  SpendingChartData? _chartData;
  bool _loading = true;
  String? _error;
  bool _showIncome = true;
  bool _showExpense = true;

  // 30-day range by default
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 29));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final useCase = sl<GetSpendingChartData>();
    final result = await useCase(ChartDataParams(
      startDate: _startDate,
      endDate: _endDate,
    ));

    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _loading = false;
      }),
      (data) => setState(() {
        _chartData = data;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.expense)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final data = _chartData;
    if (data == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Range selector
        _RangeSelector(
          startDate: _startDate,
          endDate: _endDate,
          onRangeChanged: (start, end) {
            setState(() {
              _startDate = start;
              _endDate = end;
            });
            _loadData();
          },
        ),
        const SizedBox(height: 20),

        // Chart card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.cardGradientStart, AppColors.cardGradientEnd],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Income vs Expense',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      _LegendToggle(
                        label: 'Income',
                        color: AppColors.income,
                        isActive: _showIncome,
                        onTap: () =>
                            setState(() => _showIncome = !_showIncome),
                      ),
                      const SizedBox(width: 12),
                      _LegendToggle(
                        label: 'Expense',
                        color: AppColors.expense,
                        isActive: _showExpense,
                        onTap: () =>
                            setState(() => _showExpense = !_showExpense),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AnimatedLineChart(
                points: data.points,
                maxValue: data.maxValue,
                height: 220,
                showIncome: _showIncome,
                showExpense: _showExpense,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Summary stats
        _buildSummaryStats(data),
      ],
    );
  }

  Widget _buildSummaryStats(SpendingChartData data) {
    double totalIncome = 0, totalExpense = 0;
    for (final p in data.points) {
      totalIncome += p.income;
      totalExpense += p.expense;
    }
    final net = totalIncome - totalExpense;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Income',
            value: '\$${totalIncome.toStringAsFixed(0)}',
            color: AppColors.income,
            icon: Icons.trending_up_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Total Expense',
            value: '\$${totalExpense.toStringAsFixed(0)}',
            color: AppColors.expense,
            icon: Icons.trending_down_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Net',
            value: '\$${net.abs().toStringAsFixed(0)}',
            color: net >= 0 ? AppColors.income : AppColors.expense,
            icon: net >= 0
                ? Icons.savings_rounded
                : Icons.warning_amber_rounded,
          ),
        ),
      ],
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime, DateTime) onRangeChanged;

  const _RangeSelector({
    required this.startDate,
    required this.endDate,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ranges = [
      ('7D', now.subtract(const Duration(days: 6)), now),
      ('30D', now.subtract(const Duration(days: 29)), now),
      ('90D', now.subtract(const Duration(days: 89)), now),
    ];

    return Row(
      children: ranges.map((r) {
        final isSelected = startDate.day == r.$2.day &&
            startDate.month == r.$2.month;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onRangeChanged(r.$2, r.$3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(
                r.$1,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LegendToggle extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _LegendToggle({
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive ? color : AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? color : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
