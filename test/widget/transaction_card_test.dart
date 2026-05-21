import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/domain/entities/transaction.dart';
import 'package:finance_tracker/presentation/widgets/transaction_card.dart';

void main() {
  final now = DateTime(2024, 6, 15);

  final tTransaction = Transaction(
    id: 'tx-widget-1',
    title: 'Netflix',
    amount: 15.99,
    category: TransactionCategory.entertainment,
    type: TransactionType.expense,
    date: now,
    isSynced: true,
    createdAt: now,
    updatedAt: now,
  );

  Widget buildCard({
    required Transaction transaction,
    VoidCallback? onDelete,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TransactionCard(
            transaction: transaction,
            onDelete: onDelete ?? () {},
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );
  }

  group('TransactionCard widget', () {
    testWidgets('Widget 1: renders title and amount correctly',
        (tester) async {
      await tester.pumpWidget(buildCard(transaction: tTransaction));
      await tester.pumpAndSettle();

      expect(find.text('Netflix'), findsOneWidget);
      // Amount with minus sign for expense
      expect(find.textContaining('15.99'), findsOneWidget);
    });

    testWidgets('Widget 2: calls onDelete callback on swipe', (tester) async {
      bool deleted = false;

      await tester.pumpWidget(buildCard(
        transaction: tTransaction,
        onDelete: () => deleted = true,
      ));
      await tester.pumpAndSettle();

      // Swipe left past threshold
      await tester.drag(
        find.byType(TransactionCard),
        const Offset(-400, 0),
      );
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });
  });
}
