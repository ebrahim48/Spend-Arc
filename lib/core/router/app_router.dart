import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/transaction.dart';
import '../../presentation/screens/main_shell.dart';
import '../../presentation/screens/add_transaction/add_transaction_screen.dart';

/// GoRouter configuration with deep link support.
/// Deep links:
///   spendarc://home                → Home tab
///   spendarc://add                 → Add transaction
///   spendarc://edit/:id            → Edit transaction (pass via extra)
///   spendarc://budget              → Budget tab
///   spendarc://analytics           → Analytics tab
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/add',
        name: 'add-transaction',
        builder: (context, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: '/edit/:id',
        name: 'edit-transaction',
        builder: (context, state) {
          final transaction = state.extra as Transaction?;
          return AddTransactionScreen(existing: transaction);
        },
      ),
      GoRoute(
        path: '/budget',
        name: 'budget',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const MainShell(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page not found: ${state.uri}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
}
