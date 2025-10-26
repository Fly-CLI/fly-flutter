import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Extension methods for String
extension StringExtension on String {
  /// Convert string to snake_case
  String get toSnakeCase {
    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp(r'^_'), '');
  }
  
  /// Convert string to camelCase
  String get toCamelCase {
    final words = split('_');
    if (words.isEmpty) return this;
    
    final firstWord = words.first.toLowerCase();
    final otherWords = words.skip(1).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });
    
    return '$firstWord${otherWords.join()}';
  }
  
  /// Convert string to PascalCase
  String get toPascalCase {
    return split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join();
  }
  
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
  
  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(this);
  }
  
  /// Check if string is a valid URL
  bool get isValidUrl {
    try {
      Uri.parse(this);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if string is a valid phone number
  bool get isValidPhone {
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(replaceAll(RegExp(r'[\s\-\(\)]'), ''));
  }
  
  /// Truncate string to specified length
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }
  
  /// Remove all whitespace
  String get removeWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }
  
  /// Check if string is null or empty
  bool get isNullOrEmpty => isEmpty;
  
  /// Check if string is not null and not empty
  bool get isNotNullOrEmpty => isNotEmpty;
}

/// Extension methods for List
extension ListExtension<T> on List<T> {
  /// Get the first element or null if empty
  T? get firstOrNull => isEmpty ? null : first;
  
  /// Get the last element or null if empty
  T? get lastOrNull => isEmpty ? null : last;
  
  /// Get element at index or null if out of bounds
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
  
  /// Add element if it's not already in the list
  void addIfNotContains(T element) {
    if (!contains(element)) add(element);
  }
  
  /// Remove element if it exists in the list
  void removeIfContains(T element) {
    if (contains(element)) remove(element);
  }
  
  /// Toggle element in the list (add if not present, remove if present)
  void toggle(T element) {
    if (contains(element)) {
      remove(element);
    } else {
      add(element);
    }
  }
  
  /// Split list into chunks of specified size
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      chunks.add(sublist(i, (i + size).clamp(0, length)));
    }
    return chunks;
  }
  
  /// Remove duplicates while preserving order
  List<T> get unique {
    final seen = <T>{};
    return where((element) => seen.add(element)).toList();
  }
}

/// Extension methods for Map
extension MapExtension<K, V> on Map<K, V> {
  /// Get value or return default if key doesn't exist
  V getOrDefault(K key, V defaultValue) {
    return this[key] ?? defaultValue;
  }
  
  /// Get value or return null if key doesn't exist
  V? getOrNull(K key) {
    return this[key];
  }
  
  /// Remove entries where the value is null
  Map<K, V> get removeNullValues {
    return Map.fromEntries(
      entries.where((entry) => entry.value != null),
    );
  }
  
  /// Merge with another map
  Map<K, V> merge(Map<K, V> other) {
    return {...this, ...other};
  }
}

/// Extension methods for DateTime
extension DateTimeExtension on DateTime {
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
  
  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }
  
  /// Get start of day
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }
  
  /// Get end of day
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }
  
  /// Get start of week (Monday)
  DateTime get startOfWeek {
    final daysFromMonday = weekday - 1;
    return subtract(Duration(days: daysFromMonday)).startOfDay;
  }
  
  /// Get end of week (Sunday)
  DateTime get endOfWeek {
    final daysToSunday = 7 - weekday;
    return add(Duration(days: daysToSunday)).endOfDay;
  }
  
  /// Get start of month
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }
  
  /// Get end of month
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0, 23, 59, 59, 999);
  }
  
  /// Format date as relative time (e.g., "2 hours ago")
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

/// Extension methods for BuildContext
extension BuildContextExtension on BuildContext {
  /// Get the current theme
  ThemeData get theme => Theme.of(this);
  
  /// Get the current color scheme
  ColorScheme get colorScheme => theme.colorScheme;
  
  /// Get the current text theme
  TextTheme get textTheme => theme.textTheme;
  
  /// Get the current media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  
  /// Get the current screen size
  Size get screenSize => mediaQuery.size;
  
  /// Get the current screen width
  double get screenWidth => screenSize.width;
  
  /// Get the current screen height
  double get screenHeight => screenSize.height;
  
  /// Check if the screen is mobile
  bool get isMobile => screenWidth < 600;
  
  /// Check if the screen is tablet
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  
  /// Check if the screen is desktop
  bool get isDesktop => screenWidth >= 1200;
  
  /// Get the current locale
  Locale get locale => Localizations.localeOf(this);
  
  /// Check if the current platform is Android
  bool get isAndroid => Platform.isAndroid;
  
  /// Check if the current platform is iOS
  bool get isIOS => Platform.isIOS;
  
  /// Check if the current platform is Web
  bool get isWeb => kIsWeb;
  
  /// Check if the current platform is Windows
  bool get isWindows => Platform.isWindows;
  
  /// Check if the current platform is macOS
  bool get isMacOS => Platform.isMacOS;
  
  /// Check if the current platform is Linux
  bool get isLinux => Platform.isLinux;
  
  /// Show a snackbar
  void showSnackBar(String message, {Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }
  
  /// Show an error snackbar
  void showErrorSnackBar(String message, {Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        duration: duration,
      ),
    );
  }
  
  /// Show a success snackbar
  void showSuccessSnackBar(String message, {Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.primary,
        duration: duration,
      ),
    );
  }
  
  /// Navigate to a new screen
  Future<T?> navigateTo<T>(Widget screen) {
    return Navigator.of(this).push<T>(
      MaterialPageRoute(builder: (context) => screen),
    );
  }
  
  /// Navigate to a new screen and replace current
  Future<T?> navigateToReplacement<T>(Widget screen) {
    return Navigator.of(this).pushReplacement<T, dynamic>(
      MaterialPageRoute(builder: (context) => screen),
    );
  }
  
  /// Navigate back
  void navigateBack<T>([T? result]) {
    Navigator.of(this).pop(result);
  }
  
  /// Check if can navigate back
  bool get canNavigateBack => Navigator.of(this).canPop();
}
