import 'package:flutter/material.dart';
import 'package:foundation_project/core/models/base/sync_status.dart' as core_sync;
import 'package:foundation_project/features/home/data/models/sync_status.dart';
import 'package:foundation_project/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Sync status widget
class SyncStatusWidget extends StatelessWidget {
  final SyncStatus syncStatus;
  final VoidCallback? onSyncPressed;

  const SyncStatusWidget({
    super.key,
    required this.syncStatus,
    this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final statusInfo = syncStatus.status.getLocalizedStatusInfo(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusInfo.icon, color: statusInfo.color),
                    const SizedBox(width: 8),
                    Text(
                      l10n.networkStatus,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (onSyncPressed != null)
                  TextButton.icon(
                    onPressed: syncStatus.isSyncing ? null : onSyncPressed,
                    icon: syncStatus.isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: Text(l10n.syncNow),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              statusInfo.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: statusInfo.color,
              ),
            ),
            if (syncStatus.lastSync != null) ...[
              const SizedBox(height: 4),
              Text(
                '${l10n.lastSync}: ${DateFormat('MMM dd, yyyy HH:mm').format(syncStatus.lastSync!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
            if (syncStatus.pendingOperations > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${l10n.pendingOperations}: ${syncStatus.pendingOperations}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

