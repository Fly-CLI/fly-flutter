import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Utility class for building Semantics widgets from configuration
class SemanticsBuilder {
  /// Build a Semantics widget for feedback content
  ///
  /// [child] - The widget to wrap with Semantics
  /// [event] - The feedback event
  /// [config] - Optional semantics configuration
  /// [context] - Optional build context for dynamic builders
  static Widget buildSemantics({
    required Widget child,
    required FeedbackEvent event,
    FeedbackSemanticsConfig? config,
    BuildContext? context,
  }) {
    // If no config provided, use defaults
    final semanticsConfig = config ?? FeedbackSemanticsConfig.defaults();

    // Get properties with priority:
    // 1. Custom label/hint builders
    // 2. Feedback type specific
    // 3. Default semantics
    // 4. System defaults

    String? label;
    String? hint;

    // Try custom label builder first
    if (semanticsConfig.labelBuilder != null) {
      label = semanticsConfig.labelBuilder!(event, event.type, context);
    } else {
      // Get from feedback type semantics
      final typeSemantics = semanticsConfig.feedbackTypeSemantics[event.type];
      label = typeSemantics?.label ?? semanticsConfig.defaultSemantics?.label;
    }

    // Try custom hint builder first
    if (semanticsConfig.hintBuilder != null) {
      hint = semanticsConfig.hintBuilder!(event, event.type, context);
    } else {
      // Get from feedback type semantics
      final typeSemantics = semanticsConfig.feedbackTypeSemantics[event.type];
      hint = typeSemantics?.hint ?? semanticsConfig.defaultSemantics?.hint;
    }

    // Build custom hint for actions if applicable
    if (hint == null) {
      hint = _buildActionHint(event);
    }

    // Get other properties from type-specific or default
    final typeSemantics = semanticsConfig.feedbackTypeSemantics[event.type];
    final properties = typeSemantics ?? semanticsConfig.defaultSemantics;

    // If no properties at all, use minimal defaults
    if (label == null && hint == null && properties == null) {
      return child;
    }

    return Semantics(
      label: label,
      hint: hint,
      value: properties?.value,
      increasedValue: properties?.increasedValue,
      decreasedValue: properties?.decreasedValue,
      tooltip: properties?.tooltip,
      excludeSemantics: properties?.excludeSemantics ?? false,
      container: properties?.container ?? false,
      explicitChildNodes: properties?.explicitChildNodes ?? false,
      scopesRoute: properties?.scopesRoute ?? false,
      namesRoute: properties?.namesRoute ?? false,
      hidden: properties?.hidden ?? false,
      image: properties?.image ?? false,
      liveRegion: properties?.liveRegion ?? false,
      button: properties?.button ?? false,
      link: properties?.link ?? false,
      header: properties?.header ?? false,
      textField: properties?.textField ?? false,
      readOnly: properties?.readOnly ?? false,
      focusable: properties?.focusable ?? false,
      focused: properties?.focused ?? false,
      inMutuallyExclusiveGroup: properties?.inMutuallyExclusiveGroup ?? false,
      obscured: properties?.obscured ?? false,
      multiline: properties?.multiline ?? false,
      selected: properties?.selected ?? false,
      toggled: properties?.toggled ?? false,
      slider: properties?.slider ?? false,
      checked: properties?.checked ?? false,
      mixed: properties?.mixed ?? false,
      maxValueLength: properties?.maxValueLength,
      currentValueLength: properties?.currentValueLength,
      headingLevel: properties?.headingLevel,
      onTap: properties?.onTap == true ? () {} : null,
      onLongPress: properties?.onLongPress == true ? () {} : null,
      onScrollLeft: properties?.onScrollLeft == true ? () {} : null,
      onScrollRight: properties?.onScrollRight == true ? () {} : null,
      onScrollUp: properties?.onScrollUp == true ? () {} : null,
      onScrollDown: properties?.onScrollDown == true ? () {} : null,
      onIncrease: properties?.onIncrease == true ? () {} : null,
      onDecrease: properties?.onDecrease == true ? () {} : null,
      onCopy: properties?.onCopy == true ? () {} : null,
      onCut: properties?.onCut == true ? () {} : null,
      onPaste: properties?.onPaste == true ? () {} : null,
      onMoveCursorForwardByCharacter:
          properties?.onMoveCursorForwardByCharacter == true
              ? (bool extendSelection) {}
              : null,
      onMoveCursorBackwardByCharacter:
          properties?.onMoveCursorBackwardByCharacter == true
              ? (bool extendSelection) {}
              : null,
      onSetSelection: properties?.onSetSelection == true
          ? (TextSelection selection) {}
          : null,
      onDidGainAccessibilityFocus:
          properties?.onDidGainAccessibilityFocus == true ? () {} : null,
      onDidLoseAccessibilityFocus:
          properties?.onDidLoseAccessibilityFocus == true ? () {} : null,
      onDismiss: properties?.onDismiss == true ? () {} : null,
      child: child,
    );
  }

  /// Build a Semantics widget for action buttons
  ///
  /// [child] - The widget to wrap with Semantics
  /// [actionType] - The type of action
  /// [config] - Optional semantics configuration
  /// [event] - Optional feedback event for dynamic hints
  static Widget buildActionSemantics({
    required Widget child,
    required SemanticsActionType actionType,
    FeedbackSemanticsConfig? config,
    FeedbackEvent? event,
  }) {
    // If no config provided, use defaults
    final semanticsConfig = config ?? FeedbackSemanticsConfig.defaults();

    // Get action-specific semantics
    final actionSemantics = semanticsConfig.actionSemantics[actionType];

    // If no action semantics, return child as-is
    if (actionSemantics == null) {
      return child;
    }

    // Build custom hint if event provided
    String? hint = actionSemantics.hint;
    if (hint == null && event != null) {
      hint = _buildActionHintForType(event, actionType);
    }

    return Semantics(
      label: actionSemantics.label,
      hint: hint ?? actionSemantics.hint,
      value: actionSemantics.value,
      tooltip: actionSemantics.tooltip,
      excludeSemantics: actionSemantics.excludeSemantics ?? false,
      container: actionSemantics.container ?? false,
      explicitChildNodes: actionSemantics.explicitChildNodes ?? false,
      button: actionSemantics.button ?? true,
      // Actions are typically buttons
      focusable: actionSemantics.focusable ?? true,
      onTap: actionSemantics.onTap == true ? () {} : null,
      child: child,
    );
  }

  /// Build a custom hint for action based on event
  static String? _buildActionHint(FeedbackEvent event) {
    if (event is SuccessFeedback && event.action != null) {
      return 'Double tap to ${event.actionLabel?.toLowerCase() ?? 'perform action'}';
    }
    if (event is ErrorFeedback && event.retryAction != null) {
      return 'Double tap to ${event.retryLabel?.toLowerCase() ?? 'retry'}';
    }
    return null;
  }

  /// Build a custom hint for specific action type
  static String? _buildActionHintForType(
    FeedbackEvent event,
    SemanticsActionType actionType,
  ) {
    switch (actionType) {
      case SemanticsActionType.retry:
        if (event is ErrorFeedback && event.retryLabel != null) {
          return 'Double tap to ${event.retryLabel!.toLowerCase()}';
        }
        return 'Double tap to retry';
      case SemanticsActionType.action:
        if (event is SuccessFeedback && event.actionLabel != null) {
          return 'Double tap to ${event.actionLabel!.toLowerCase()}';
        }
        return 'Double tap to perform action';
      case SemanticsActionType.dismiss:
      case SemanticsActionType.close:
      case SemanticsActionType.ok:
        return 'Double tap to dismiss';
      case SemanticsActionType.confirm:
        if (event is ConfirmationFeedback && event.isDangerous) {
          return 'Double tap to confirm dangerous action';
        }
        return 'Double tap to confirm';
      case SemanticsActionType.cancel:
        return 'Double tap to cancel';
    }
  }
}
