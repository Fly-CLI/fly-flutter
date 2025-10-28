import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/core/command_foundation/infrastructure/interactive_prompt.dart';
import 'package:fly_cli/src/core/diagnostics/system_checker.dart';
import 'package:mason_logger/mason_logger.dart';

import 'mock_logger.dart';

/// Mock TemplateManager for testing
class MockTemplateManager extends TemplateManager {
  bool _shouldFail = false;
  
  MockTemplateManager() : super(
    templatesDirectory: '/test/templates',
    logger: Logger(),
  );
  
  void setFailure(bool shouldFail) {
    _shouldFail = shouldFail;
  }
  
  // Add mock methods as needed
}

/// Mock SystemChecker for testing
class MockSystemChecker extends SystemChecker {
  bool _isHealthy = true;
  
  MockSystemChecker() : super(logger: Logger());
  
  void setHealthStatus(bool isHealthy) {
    _isHealthy = isHealthy;
  }
  
  // Add mock methods as needed
}

/// Mock InteractivePrompt for testing
class MockInteractivePrompt extends InteractivePrompt {
  List<String> _stringResponses = [];
  List<String> _choiceResponses = [];
  List<bool> _confirmResponses = [];
  List<List<String>> _multiChoiceResponses = [];
  
  MockInteractivePrompt() : super(Logger());
  
  void setStringResponses(List<String> responses) {
    _stringResponses = responses;
  }
  
  void setChoiceResponses(List<String> responses) {
    _choiceResponses = responses;
  }
  
  void setConfirmResponses(List<bool> responses) {
    _confirmResponses = responses;
  }
  
  void setMultiChoiceResponses(List<List<String>> responses) {
    _multiChoiceResponses = responses;
  }
  
  // Add mock methods as needed
}
