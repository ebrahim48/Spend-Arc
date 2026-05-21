import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/transaction.dart';

class TransactionDetailSheet extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required Transaction transaction,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TransactionDetailSheet(
        transaction: transaction,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  Color get _categoryColor {
    switch (transaction.category) {
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
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome ? AppColors.income : AppColors.expense;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Category icon + amount
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _categoryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _categoryColor.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                transaction.category.emoji,
                style: const TextStyle(fontSize: 34),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            transaction.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: amountColor,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),

          // Details rows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.category_rounded,
                    label: 'Category',
                    value: transaction.category.displayName,
                    valueColor: _categoryColor,
                  ),
                  _Divider(),
                  _DetailRow(
                    icon: isIncome
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    label: 'Type',
                    value: isIncome ? 'Income' : 'Expense',
                    valueColor: amountColor,
                  ),
                  _Divider(),
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: DateFormatter.formatDate(transaction.date),
                  ),
                  if (transaction.note != null &&
                      transaction.note!.isNotEmpty) ...[
                    _Divider(),
                    _DetailRow(
                      icon: Icons.notes_rounded,
                      label: 'Note',
                      value: transaction.note!,
                    ),
                  ],
                  _Divider(),
                  _DetailRow(
                    icon: transaction.isSynced
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    label: 'Sync Status',
                    value: transaction.isSynced ? 'Synced' : 'Pending',
                    valueColor: transaction.isSynced
                        ? AppColors.income
                        : AppColors.warning,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Edit button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onEdit();
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Delete button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      _confirmDelete(context);
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.expense.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.expense.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.expense,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: AppColors.expense,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete Transaction?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '"${transaction.title}" permanently delete হয়ে যাবে।',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete();
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.divider,
      indent: 16,
      endIndent: 16,
    );
  }
}
