import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/sync/sync_bloc.dart';

class SyncStatusBar extends StatelessWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        if (state is SyncIdle && state.isOnline) return const SizedBox.shrink();

        Color bgColor;
        String message;
        Widget? leading;

        if (state is SyncOffline) {
          bgColor = AppColors.warning.withOpacity(0.15);
          message = 'Offline — changes saved locally';
          leading = const Icon(Icons.wifi_off_rounded,
              color: AppColors.warning, size: 16);
        } else if (state is SyncInProgress) {
          bgColor = AppColors.primary.withOpacity(0.15);
          message = 'Syncing…';
          leading = const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          );
        } else if (state is SyncSuccess) {
          bgColor = AppColors.income.withOpacity(0.15);
          message = state.syncedCount > 0
              ? '${state.syncedCount} item(s) synced'
              : 'All up to date';
          leading = const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.income, size: 16);
        } else if (state is SyncFailure) {
          bgColor = AppColors.expense.withOpacity(0.15);
          message = 'Sync failed — will retry';
          leading = const Icon(Icons.error_outline_rounded,
              color: AppColors.expense, size: 16);
        } else {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: bgColor,
          child: Row(
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 8)],
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
