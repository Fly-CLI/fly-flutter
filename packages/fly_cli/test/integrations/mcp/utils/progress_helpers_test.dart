import 'package:fly_cli/src/integrations/mcp/infrastructure/utils/progress_helpers.dart';
import 'package:fly_mcp/fly_mcp.dart';
import 'package:test/test.dart';

void main() {
  group('ProgressHelpers', () {
    group('notifyStage', () {
      test('should send progress notification', () async {
        var receivedMessage = '';
        var receivedPercent = 0;

        // Create a mock progress notifier that captures calls
        final mockNotifier = MockProgressNotifier(
          onNotify: (message, percent) {
            receivedMessage = message;
            receivedPercent = percent ?? 0;
          },
        );

        final stage = ProgressStage(percent: 50, message: 'Testing');

        await ProgressHelpers.notifyStage(mockNotifier, stage);

        expect(receivedMessage, 'Testing');
        expect(receivedPercent, 50);
      });
    });

    group('notifyStages', () {
      test('should send multiple progress notifications', () async {
        final notifications = <String, int>{};

        final mockNotifier = MockProgressNotifier(
          onNotify: (message, percent) {
            notifications[message] = percent ?? 0;
          },
        );

        final stages = [
          ProgressStage(percent: 10, message: 'Step 1'),
          ProgressStage(percent: 50, message: 'Step 2'),
          ProgressStage(percent: 100, message: 'Complete'),
        ];

        await ProgressHelpers.notifyStages(mockNotifier, stages);

        expect(notifications.length, 3);
        expect(notifications['Step 1'], 10);
        expect(notifications['Step 2'], 50);
        expect(notifications['Complete'], 100);
      });
    });

    group('TemplateProgressStage', () {
      test('should have all expected stages', () {
        expect(TemplateProgressStage.loading.percent, 10);
        expect(TemplateProgressStage.loaded.percent, 20);
        expect(TemplateProgressStage.validating.percent, 30);
        expect(TemplateProgressStage.validated.percent, 40);
        expect(TemplateProgressStage.generating.percent, 50);
        expect(TemplateProgressStage.generatingFiles.percent, 60);
        expect(TemplateProgressStage.applying.percent, 70);
        expect(TemplateProgressStage.processing.percent, 80);
        expect(TemplateProgressStage.finalizing.percent, 90);
        expect(TemplateProgressStage.complete.percent, 100);
      });

      test('should convert to ProgressStage', () {
        final stage = TemplateProgressStage.loading.toProgressStage();
        expect(stage.percent, 10);
        expect(stage.message, 'Loading template...');
      });
    });
  });
}

/// Mock progress notifier for testing
class MockProgressNotifier extends ProgressNotifier {
  MockProgressNotifier({required this.onNotify}) : super(enabled: true);

  final void Function(String message, int? percent) onNotify;

  @override
  Future<void> notify({required String message, int? percent}) async {
    onNotify(message, percent);
  }
}
