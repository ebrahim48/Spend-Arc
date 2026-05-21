import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/transaction.dart';
import '../../blocs/transactions/transactions_bloc.dart';
import '../../blocs/budget/budget_bloc.dart';
import '../../blocs/sync/sync_bloc.dart';
import '../../widgets/transaction_card.dart';
import '../../widgets/transaction_detail_sheet.dart';
import '../../widgets/sync_status_bar.dart';
import '../add_transaction/add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionsBloc>().add(const LoadTransactions());
    context.read<SyncBloc>().add(StartSyncMonitoring());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const SyncStatusBar(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                _buildSummaryCard(),
                _buildFilterChips(),
                _buildTransactionList(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTransaction(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      snap: true,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SpendArc',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              DateFormatter.formatMonth(DateTime.now()),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded,
              color: AppColors.textPrimary),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return SliverToBoxAdapter(
      child: BlocBuilder<TransactionsBloc, TransactionsState>(
        builder: (context, state) {
          double income = 0, expense = 0;
          if (state is TransactionsLoaded) {
            for (final t in state.transactions) {
              if (t.type == TransactionType.income) {
                income += t.amount;
              } else {
                expense += t.amount;
              }
            }
          }
          final balance = income - expense;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3D35CC), Color(0xFF6C63FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          label: 'Income',
                          amount: income,
                          icon: Icons.arrow_downward_rounded,
                          color: AppColors.income,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white24,
                      ),
                      Expanded(
                        child: _SummaryTile(
                          label: 'Expense',
                          amount: expense,
                          icon: Icons.arrow_upward_rounded,
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return SliverToBoxAdapter(
      child: BlocBuilder<TransactionsBloc, TransactionsState>(
        builder: (context, state) {
          final activeCategory =
              state is TransactionsLoaded ? state.activeCategory : null;

          return SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: activeCategory == null,
                  onTap: () => context
                      .read<TransactionsBloc>()
                      .add(const FilterTransactions()),
                ),
                ...TransactionCategory.values.map((cat) => _FilterChip(
                      label: '${cat.emoji} ${cat.displayName}',
                      isSelected: activeCategory == cat,
                      onTap: () => context
                          .read<TransactionsBloc>()
                          .add(FilterTransactions(category: cat)),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionList() {
    return BlocConsumer<TransactionsBloc, TransactionsState>(
      listener: (context, state) {
        if (state is TransactionsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.expense,
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is TransactionsLoading) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        List<Transaction> transactions = [];
        if (state is TransactionsLoaded) {
          transactions = state.filtered;
        } else if (state is TransactionsError) {
          transactions = state.cachedTransactions;
        }

        if (transactions.isEmpty) {
          return const SliverFillRemaining(
            child: _EmptyState(),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final t = transactions[index];
                return TransactionCard(
                  key: ValueKey(t.id),
                  transaction: t,
                  onDelete: () => _deleteTransaction(context, t),
                  onTap: () => _openDetailSheet(context, t),
                );
              },
              childCount: transactions.length,
            ),
          ),
        );
      },
    );
  }

  void _openDetailSheet(BuildContext context, Transaction t) {
    final transBloc = context.read<TransactionsBloc>();
    final budgetBloc = context.read<BudgetBloc>();
    TransactionDetailSheet.show(
      context,
      transaction: t,
      onEdit: () => _openEditTransaction(context, t, transBloc, budgetBloc),
      onDelete: () => _deleteTransaction(context, t),
    );
  }

  void _deleteTransaction(BuildContext context, Transaction t) {
    final bloc = context.read<TransactionsBloc>();
    bloc.add(DeleteTransactionEvent(t.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${t.title}" deleted'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primary,
          onPressed: () => bloc.add(UndoDeleteTransaction(t)),
        ),
      ),
    );
  }

  void _openAddTransaction(BuildContext context) {
    final transBloc = context.read<TransactionsBloc>();
    final budgetBloc = context.read<BudgetBloc>();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: transBloc),
            BlocProvider.value(value: budgetBloc),
          ],
          child: const AddTransactionScreen(),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }

  void _openEditTransaction(
    BuildContext context,
    Transaction t, [
    TransactionsBloc? transBloc,
    BudgetBloc? budgetBloc,
  ]) {
    final tb = transBloc ?? context.read<TransactionsBloc>();
    final bb = budgetBloc ?? context.read<BudgetBloc>();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: tb),
            BlocProvider.value(value: bb),
          ],
          child: AddTransactionScreen(existing: t),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              Text(
                CurrencyFormatter.formatCompact(amount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💸', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text(
            'No transactions yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to add your first transaction',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
