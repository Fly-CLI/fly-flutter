import 'package:flutter/material.dart';
import 'package:foundation_project/l10n/app_localizations.dart';

/// Status information for display
class StatusInfo {
  final String text;
  final Color color;
  final IconData icon;
  final bool showAction;
  final String? actionLabel;

  const StatusInfo({
    required this.text,
    required this.color,
    required this.icon,
    this.showAction = false,
    this.actionLabel,
  });
}

/// Sync status enum - unified for both entity-level and system-level sync states
enum SyncStatus {
  idle,
  pending,
  syncing,
  synced,
  failed,
  conflicted,
  offline;

  /// Convert SyncStatus to JSON string representation
  String toJson() {
    return name;
  }

  /// Parse JSON string to SyncStatus
  static SyncStatus fromJson(String? value) {
    if (value == null || value.isEmpty) return SyncStatus.pending;
    try {
      return SyncStatus.values.byName(value);
    } catch (_) {
      return SyncStatus.pending;
    }
  }

  bool get needsSync => this == SyncStatus.pending;
  bool get isConflicted => this == SyncStatus.conflicted;
  bool get syncFailed => this == SyncStatus.failed;
  bool get isSynced => this == SyncStatus.synced;
}

/// Extension for SyncStatus
extension SyncStatusExtension on SyncStatus {
  String displayName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case SyncStatus.idle:
        return l10n.syncStatusIdle;
      case SyncStatus.pending:
        return l10n.syncStatusPending;
      case SyncStatus.syncing:
        return l10n.syncing;
      case SyncStatus.synced:
        return l10n.syncStatusSynced;
      case SyncStatus.failed:
        return l10n.syncStatusFailed;
      case SyncStatus.conflicted:
        return l10n.syncStatusConflicted;
      case SyncStatus.offline:
        return l10n.syncStatusOffline;
    }
  }

  StatusInfo getLocalizedStatusInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case SyncStatus.idle:
        return StatusInfo(
          text: l10n.syncStatusIdle,
          color: Colors.grey,
          icon: Icons.cloud_queue,
        );
      case SyncStatus.pending:
        return StatusInfo(
          text: l10n.syncStatusPending,
          color: Colors.orange,
          icon: Icons.schedule,
        );
      case SyncStatus.syncing:
        return StatusInfo(
          text: l10n.syncing,
          color: Colors.blue,
          icon: Icons.sync,
        );
      case SyncStatus.synced:
        return StatusInfo(
          text: l10n.syncStatusSynced,
          color: Colors.green,
          icon: Icons.check_circle,
        );
      case SyncStatus.failed:
        return StatusInfo(
          text: l10n.syncStatusFailed,
          color: Colors.red,
          icon: Icons.error_outline,
          showAction: true,
          actionLabel: l10n.retry,
        );
      case SyncStatus.conflicted:
        return StatusInfo(
          text: l10n.syncStatusConflicted,
          color: Colors.red,
          icon: Icons.error,
          showAction: true,
          actionLabel: l10n.retry,
        );
      case SyncStatus.offline:
        return StatusInfo(
          text: l10n.syncStatusOffline,
          color: Colors.grey,
          icon: Icons.cloud_off,
        );
    }
  }
}
