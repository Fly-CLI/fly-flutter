import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Haptic Feedback Example
///
/// This screen demonstrates haptic feedback configuration and usage:
/// - Configuring haptic feedback globally and per feedback type
/// - Different haptic types (light, medium, heavy, selection, vibrate)
/// - Metadata overrides for per-event haptic control
/// - Enabling/disabling haptic feedback
///
/// **Key Concepts:**
/// - HapticConfig for global and per-type configuration
/// - HapticType enum for different haptic intensities
/// - Metadata overrides for fine-grained control
/// - Integration with DefaultFeedbackService
class HapticFeedbackScreen extends StatefulWidget {
  const HapticFeedbackScreen({super.key});

  @override
  State<HapticFeedbackScreen> createState() => _HapticFeedbackScreenState();
}

class _HapticFeedbackScreenState extends State<HapticFeedbackScreen> {
  late DefaultFeedbackService feedbackService;
  late HapticConfig hapticConfig;
  bool hapticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _updateHapticConfig();
  }

  void _updateHapticConfig() {
    hapticConfig = HapticConfig(
      enabled: hapticsEnabled,
      defaultType: HapticType.lightImpact,
      typeMapping: {
        FeedbackType.success: HapticType.lightImpact,
        FeedbackType.error: HapticType.mediumImpact,
        FeedbackType.warning: HapticType.lightImpact,
        FeedbackType.info: HapticType.selectionClick,
      },
    );

    feedbackService = DefaultFeedbackService(
      handler: CompositeFeedbackHandler([
        SnackbarFeedbackHandler(),
        DialogFeedbackHandler(),
        BottomSheetFeedbackHandler(),
        ToastFeedbackHandler(),
        BannerFeedbackHandler(),
      ]),
      hapticConfig: hapticConfig,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('8. Haptic Feedback'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader(
              title: 'Haptic Feedback',
              description:
                  'Enhance user experience with tactile feedback. Configure haptic feedback globally or per feedback type.',
            ),
            const SizedBox(height: 24),
            _HapticToggleCard(
              enabled: hapticsEnabled,
              onChanged: (value) {
                setState(() {
                  hapticsEnabled = value;
                  _updateHapticConfig();
                });
              },
            ),
            const SizedBox(height: 24),
            const _SectionHeader(
              title: 'Default Haptic Types',
              description:
                  'Each feedback type has a default haptic type configured. Try them out!',
            ),
            const SizedBox(height: 16),
            _HapticTypeCard(
              title: 'Success Feedback',
              description: 'Light haptic impact',
              icon: Icons.check_circle,
              color: colorScheme.primary,
              hapticType: HapticType.lightImpact,
              onTap: () {
                feedbackService.showSuccess(
                  context,
                  'Success! Light haptic feedback triggered.',
                );
              },
            ),
            _HapticTypeCard(
              title: 'Error Feedback',
              description: 'Medium haptic impact',
              icon: Icons.error,
              color: colorScheme.error,
              hapticType: HapticType.mediumImpact,
              onTap: () {
                feedbackService.showError(
                  context,
                  'Error! Medium haptic feedback triggered.',
                );
              },
            ),
            _HapticTypeCard(
              title: 'Warning Feedback',
              description: 'Light haptic impact',
              icon: Icons.warning,
              color: colorScheme.tertiary,
              hapticType: HapticType.lightImpact,
              onTap: () {
                feedbackService.showWarning(
                  context,
                  'Warning! Light haptic feedback triggered.',
                );
              },
            ),
            _HapticTypeCard(
              title: 'Info Feedback',
              description: 'Selection click haptic',
              icon: Icons.info,
              color: colorScheme.secondary,
              hapticType: HapticType.selectionClick,
              onTap: () {
                feedbackService.showInfo(
                  context,
                  'Info! Selection click haptic feedback triggered.',
                );
              },
            ),
            const SizedBox(height: 24),
            const _SectionHeader(
              title: 'All Haptic Types',
              description:
                  'Try all available haptic types using metadata overrides.',
            ),
            const SizedBox(height: 16),
            _HapticTypeCard(
              title: 'Light Impact',
              description: 'Subtle tactile feedback',
              icon: Icons.touch_app,
              color: colorScheme.primary,
              hapticType: HapticType.lightImpact,
              onTap: () {
                feedbackService.showSuccess(
                  context,
                  'Light impact haptic',
                  metadata: {'haptic_type': 'lightImpact'},
                );
              },
            ),
            _HapticTypeCard(
              title: 'Medium Impact',
              description: 'Moderate tactile feedback',
              icon: Icons.touch_app,
              color: colorScheme.secondary,
              hapticType: HapticType.mediumImpact,
              onTap: () {
                feedbackService.showSuccess(
                  context,
                  'Medium impact haptic',
                  metadata: {'haptic_type': 'mediumImpact'},
                );
              },
            ),
            _HapticTypeCard(
              title: 'Heavy Impact',
              description: 'Strong tactile feedback',
              icon: Icons.touch_app,
              color: colorScheme.error,
              hapticType: HapticType.heavyImpact,
              onTap: () {
                feedbackService.showSuccess(
                  context,
                  'Heavy impact haptic',
                  metadata: {'haptic_type': 'heavyImpact'},
                );
              },
            ),
            _HapticTypeCard(
              title: 'Selection Click',
              description: 'Minimal tactile feedback',
              icon: Icons.touch_app,
              color: colorScheme.tertiary,
              hapticType: HapticType.selectionClick,
              onTap: () {
                feedbackService.showSuccess(
                  context,
                  'Selection click haptic',
                  metadata: {'haptic_type': 'selectionClick'},
                );
              },
            ),
            _HapticTypeCard(
              title: 'Vibrate',
              description: 'Platform vibration (Android)',
              icon: Icons.vibration,
              color: colorScheme.inversePrimary,
              hapticType: HapticType.vibrate,
              onTap: () {
                feedbackService.showSuccess(
                  context,
                  'Vibrate haptic (Android only)',
                  metadata: {'haptic_type': 'vibrate'},
                );
              },
            ),
            const SizedBox(height: 24),
            const _SectionHeader(
              title: 'Disable Haptic for Event',
              description:
                  'You can disable haptic feedback for specific events using metadata.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                feedbackService.showSuccess(
                  context,
                  'This success message has haptic feedback disabled.',
                  metadata: {'haptic_enabled': false},
                );
              },
              icon: const Icon(Icons.block),
              label: const Text('Show Success (No Haptic)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),
            const _CodeExample(
              title: 'Haptic feedback configuration:',
              code: '''
// Create haptic configuration
final hapticConfig = HapticConfig(
  enabled: true,
  defaultType: HapticType.lightImpact,
  typeMapping: {
    FeedbackType.success: HapticType.lightImpact,
    FeedbackType.error: HapticType.mediumImpact,
    FeedbackType.warning: HapticType.lightImpact,
    FeedbackType.info: HapticType.selectionClick,
  },
);

// Use with service
final service = DefaultFeedbackService(
  handler: handler,
  hapticConfig: hapticConfig,
);

// Override haptic type per event
service.showSuccess(
  context,
  'Message',
  metadata: {
    'haptic_type': 'heavyImpact',
  },
);

// Disable haptic for specific event
service.showSuccess(
  context,
  'Message',
  metadata: {
    'haptic_enabled': false,
  },
);
''',
            ),
          ],
        ),
      ),
    );
  }
}

/// Card widget for haptic toggle
class _HapticToggleCard extends StatelessWidget {
  const _HapticToggleCard({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              enabled ? Icons.vibration : Icons.block,
              color: enabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Haptic Feedback',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    enabled
                        ? 'Haptic feedback is enabled'
                        : 'Haptic feedback is disabled',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card widget for haptic type demonstration
class _HapticTypeCard extends StatelessWidget {
  const _HapticTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.hapticType,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final HapticType hapticType;
  final VoidCallback onTap;

  String _getHapticTypeName() {
    switch (hapticType) {
      case HapticType.none:
        return 'None';
      case HapticType.lightImpact:
        return 'Light Impact';
      case HapticType.mediumImpact:
        return 'Medium Impact';
      case HapticType.heavyImpact:
        return 'Heavy Impact';
      case HapticType.selectionClick:
        return 'Selection Click';
      case HapticType.vibrate:
        return 'Vibrate';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type: ${_getHapticTypeName()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Code example widget
class _CodeExample extends StatelessWidget {
  const _CodeExample({
    required this.title,
    required this.code,
  });

  final String title;
  final String code;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

