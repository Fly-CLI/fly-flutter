import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Builder function for generating semantic labels dynamically
typedef SemanticsLabelBuilder = String Function(
  FeedbackEvent event,
  FeedbackType type,
  BuildContext? context,
);

/// Builder function for generating semantic hints dynamically
typedef SemanticsHintBuilder = String? Function(
  FeedbackEvent event,
  FeedbackType type,
  BuildContext? context,
);

/// Action types for semantics configuration
enum SemanticsActionType {
  /// Retry action (typically for error feedback)
  retry,

  /// Dismiss action
  dismiss,

  /// Confirm action (typically for confirmation dialogs)
  confirm,

  /// Cancel action
  cancel,

  /// Close action
  close,

  /// Generic action (typically for success feedback)
  action,

  /// OK action
  ok,
}

/// Properties for Semantics widget configuration
class SemanticsProperties {
  /// Semantic label
  final String? label;

  /// Semantic hint
  final String? hint;

  /// Semantic value
  final String? value;

  /// Increased value for sliders
  final String? increasedValue;

  /// Decreased value for sliders
  final String? decreasedValue;

  /// Tooltip text
  final String? tooltip;

  /// Whether to exclude semantics
  final bool? excludeSemantics;

  /// Whether this is a container
  final bool? container;

  /// Whether to explicitly include child nodes
  final bool? explicitChildNodes;

  /// Whether this scopes a route
  final bool? scopesRoute;

  /// Whether this names a route
  final bool? namesRoute;

  /// Whether this is hidden
  final bool? hidden;

  /// Whether this is an image
  final bool? image;

  /// Whether this is a live region
  final bool? liveRegion;

  /// Whether this is a button
  final bool? button;

  /// Whether this is a link
  final bool? link;

  /// Whether this is a header
  final bool? header;

  /// Whether this is a text field
  final bool? textField;

  /// Whether this is read-only
  final bool? readOnly;

  /// Whether this is focusable
  final bool? focusable;

  /// Whether this is focused
  final bool? focused;

  /// Whether this is in a mutually exclusive group
  final bool? inMutuallyExclusiveGroup;

  /// Whether text is obscured
  final bool? obscured;

  /// Whether text is multiline
  final bool? multiline;

  /// Whether this is selected
  final bool? selected;

  /// Whether this is toggled
  final bool? toggled;

  /// Whether this is a slider
  final bool? slider;

  /// Whether this is checked
  final bool? checked;

  /// Whether this is mixed
  final bool? mixed;

  /// Maximum value length
  final int? maxValueLength;

  /// Current value length
  final int? currentValueLength;

  /// Heading level
  final int? headingLevel;

  /// Whether onTap is supported
  final bool? onTap;

  /// Whether onLongPress is supported
  final bool? onLongPress;

  /// Whether onScrollLeft is supported
  final bool? onScrollLeft;

  /// Whether onScrollRight is supported
  final bool? onScrollRight;

  /// Whether onScrollUp is supported
  final bool? onScrollUp;

  /// Whether onScrollDown is supported
  final bool? onScrollDown;

  /// Whether onIncrease is supported
  final bool? onIncrease;

  /// Whether onDecrease is supported
  final bool? onDecrease;

  /// Whether onCopy is supported
  final bool? onCopy;

  /// Whether onCut is supported
  final bool? onCut;

  /// Whether onPaste is supported
  final bool? onPaste;

  /// Whether onMoveCursorForwardByCharacter is supported
  final bool? onMoveCursorForwardByCharacter;

  /// Whether onMoveCursorBackwardByCharacter is supported
  final bool? onMoveCursorBackwardByCharacter;

  /// Whether onSetSelection is supported
  final bool? onSetSelection;

  /// Whether onDidGainAccessibilityFocus is supported
  final bool? onDidGainAccessibilityFocus;

  /// Whether onDidLoseAccessibilityFocus is supported
  final bool? onDidLoseAccessibilityFocus;

  /// Whether onDismiss is supported
  final bool? onDismiss;

  /// Create SemanticsProperties
  const SemanticsProperties({
    this.label,
    this.hint,
    this.value,
    this.increasedValue,
    this.decreasedValue,
    this.tooltip,
    this.excludeSemantics,
    this.container,
    this.explicitChildNodes,
    this.scopesRoute,
    this.namesRoute,
    this.hidden,
    this.image,
    this.liveRegion,
    this.button,
    this.link,
    this.header,
    this.textField,
    this.readOnly,
    this.focusable,
    this.focused,
    this.inMutuallyExclusiveGroup,
    this.obscured,
    this.multiline,
    this.selected,
    this.toggled,
    this.slider,
    this.checked,
    this.mixed,
    this.maxValueLength,
    this.currentValueLength,
    this.headingLevel,
    this.onTap,
    this.onLongPress,
    this.onScrollLeft,
    this.onScrollRight,
    this.onScrollUp,
    this.onScrollDown,
    this.onIncrease,
    this.onDecrease,
    this.onCopy,
    this.onCut,
    this.onPaste,
    this.onMoveCursorForwardByCharacter,
    this.onMoveCursorBackwardByCharacter,
    this.onSetSelection,
    this.onDidGainAccessibilityFocus,
    this.onDidLoseAccessibilityFocus,
    this.onDismiss,
  });

  /// Create a copy with updated values
  SemanticsProperties copyWith({
    String? label,
    String? hint,
    String? value,
    String? increasedValue,
    String? decreasedValue,
    String? tooltip,
    bool? excludeSemantics,
    bool? container,
    bool? explicitChildNodes,
    bool? scopesRoute,
    bool? namesRoute,
    bool? hidden,
    bool? image,
    bool? liveRegion,
    bool? button,
    bool? link,
    bool? header,
    bool? textField,
    bool? readOnly,
    bool? focusable,
    bool? focused,
    bool? inMutuallyExclusiveGroup,
    bool? obscured,
    bool? multiline,
    bool? selected,
    bool? toggled,
    bool? slider,
    bool? checked,
    bool? mixed,
    int? maxValueLength,
    int? currentValueLength,
    int? headingLevel,
    bool? onTap,
    bool? onLongPress,
    bool? onScrollLeft,
    bool? onScrollRight,
    bool? onScrollUp,
    bool? onScrollDown,
    bool? onIncrease,
    bool? onDecrease,
    bool? onCopy,
    bool? onCut,
    bool? onPaste,
    bool? onMoveCursorForwardByCharacter,
    bool? onMoveCursorBackwardByCharacter,
    bool? onSetSelection,
    bool? onDidGainAccessibilityFocus,
    bool? onDidLoseAccessibilityFocus,
    bool? onDismiss,
  }) {
    return SemanticsProperties(
      label: label ?? this.label,
      hint: hint ?? this.hint,
      value: value ?? this.value,
      increasedValue: increasedValue ?? this.increasedValue,
      decreasedValue: decreasedValue ?? this.decreasedValue,
      tooltip: tooltip ?? this.tooltip,
      excludeSemantics: excludeSemantics ?? this.excludeSemantics,
      container: container ?? this.container,
      explicitChildNodes: explicitChildNodes ?? this.explicitChildNodes,
      scopesRoute: scopesRoute ?? this.scopesRoute,
      namesRoute: namesRoute ?? this.namesRoute,
      hidden: hidden ?? this.hidden,
      image: image ?? this.image,
      liveRegion: liveRegion ?? this.liveRegion,
      button: button ?? this.button,
      link: link ?? this.link,
      header: header ?? this.header,
      textField: textField ?? this.textField,
      readOnly: readOnly ?? this.readOnly,
      focusable: focusable ?? this.focusable,
      focused: focused ?? this.focused,
      inMutuallyExclusiveGroup:
          inMutuallyExclusiveGroup ?? this.inMutuallyExclusiveGroup,
      obscured: obscured ?? this.obscured,
      multiline: multiline ?? this.multiline,
      selected: selected ?? this.selected,
      toggled: toggled ?? this.toggled,
      slider: slider ?? this.slider,
      checked: checked ?? this.checked,
      mixed: mixed ?? this.mixed,
      maxValueLength: maxValueLength ?? this.maxValueLength,
      currentValueLength: currentValueLength ?? this.currentValueLength,
      headingLevel: headingLevel ?? this.headingLevel,
      onTap: onTap ?? this.onTap,
      onLongPress: onLongPress ?? this.onLongPress,
      onScrollLeft: onScrollLeft ?? this.onScrollLeft,
      onScrollRight: onScrollRight ?? this.onScrollRight,
      onScrollUp: onScrollUp ?? this.onScrollUp,
      onScrollDown: onScrollDown ?? this.onScrollDown,
      onIncrease: onIncrease ?? this.onIncrease,
      onDecrease: onDecrease ?? this.onDecrease,
      onCopy: onCopy ?? this.onCopy,
      onCut: onCut ?? this.onCut,
      onPaste: onPaste ?? this.onPaste,
      onMoveCursorForwardByCharacter:
          onMoveCursorForwardByCharacter ?? this.onMoveCursorForwardByCharacter,
      onMoveCursorBackwardByCharacter: onMoveCursorBackwardByCharacter ??
          this.onMoveCursorBackwardByCharacter,
      onSetSelection: onSetSelection ?? this.onSetSelection,
      onDidGainAccessibilityFocus:
          onDidGainAccessibilityFocus ?? this.onDidGainAccessibilityFocus,
      onDidLoseAccessibilityFocus:
          onDidLoseAccessibilityFocus ?? this.onDidLoseAccessibilityFocus,
      onDismiss: onDismiss ?? this.onDismiss,
    );
  }
}

/// Configuration for feedback semantics
class FeedbackSemanticsConfig {
  /// Per feedback type semantics
  final Map<FeedbackType, SemanticsProperties> feedbackTypeSemantics;

  /// Action-specific semantics
  final Map<SemanticsActionType, SemanticsProperties> actionSemantics;

  /// Global default semantics
  final SemanticsProperties? defaultSemantics;

  /// Custom label builder
  final SemanticsLabelBuilder? labelBuilder;

  /// Custom hint builder
  final SemanticsHintBuilder? hintBuilder;

  /// Create FeedbackSemanticsConfig
  const FeedbackSemanticsConfig({
    this.feedbackTypeSemantics = const {},
    this.actionSemantics = const {},
    this.defaultSemantics,
    this.labelBuilder,
    this.hintBuilder,
  });

  /// Create with default values matching current hardcoded behavior
  factory FeedbackSemanticsConfig.defaults() {
    return FeedbackSemanticsConfig(
      feedbackTypeSemantics: {
        FeedbackType.success: const SemanticsProperties(
          label: 'Success message',
        ),
        FeedbackType.error: const SemanticsProperties(
          label: 'Error message',
        ),
        FeedbackType.warning: const SemanticsProperties(
          label: 'Warning message',
        ),
        FeedbackType.info: const SemanticsProperties(
          label: 'Information message',
        ),
      },
      actionSemantics: {
        SemanticsActionType.retry: const SemanticsProperties(
          label: 'Retry button',
          hint: 'Double tap to retry',
          button: true,
        ),
        SemanticsActionType.dismiss: const SemanticsProperties(
          label: 'Dismiss button',
          hint: 'Double tap to dismiss',
          button: true,
        ),
        SemanticsActionType.confirm: const SemanticsProperties(
          label: 'Confirm button',
          hint: 'Double tap to confirm',
          button: true,
        ),
        SemanticsActionType.cancel: const SemanticsProperties(
          label: 'Cancel button',
          hint: 'Double tap to cancel',
          button: true,
        ),
        SemanticsActionType.close: const SemanticsProperties(
          label: 'Close button',
          hint: 'Double tap to dismiss',
          button: true,
        ),
        SemanticsActionType.action: const SemanticsProperties(
          label: 'Action button',
          hint: 'Double tap to perform action',
          button: true,
        ),
        SemanticsActionType.ok: const SemanticsProperties(
          label: 'OK button',
          hint: 'Double tap to dismiss',
          button: true,
        ),
      },
    );
  }

  /// Create a copy with updated values
  FeedbackSemanticsConfig copyWith({
    Map<FeedbackType, SemanticsProperties>? feedbackTypeSemantics,
    Map<SemanticsActionType, SemanticsProperties>? actionSemantics,
    SemanticsProperties? defaultSemantics,
    SemanticsLabelBuilder? labelBuilder,
    SemanticsHintBuilder? hintBuilder,
  }) {
    return FeedbackSemanticsConfig(
      feedbackTypeSemantics:
          feedbackTypeSemantics ?? this.feedbackTypeSemantics,
      actionSemantics: actionSemantics ?? this.actionSemantics,
      defaultSemantics: defaultSemantics ?? this.defaultSemantics,
      labelBuilder: labelBuilder ?? this.labelBuilder,
      hintBuilder: hintBuilder ?? this.hintBuilder,
    );
  }

  /// Merge this configuration with another
  ///
  /// Values from [other] take precedence over this configuration's values.
  FeedbackSemanticsConfig merge(FeedbackSemanticsConfig? other) {
    if (other == null) return this;

    return FeedbackSemanticsConfig(
      feedbackTypeSemantics: {
        ...feedbackTypeSemantics,
        ...other.feedbackTypeSemantics,
      },
      actionSemantics: {
        ...actionSemantics,
        ...other.actionSemantics,
      },
      defaultSemantics: other.defaultSemantics ?? defaultSemantics,
      labelBuilder: other.labelBuilder ?? labelBuilder,
      hintBuilder: other.hintBuilder ?? hintBuilder,
    );
  }
}
