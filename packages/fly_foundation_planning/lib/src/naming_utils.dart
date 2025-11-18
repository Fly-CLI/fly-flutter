/// Utility class for name case conversions.
class NamingUtils {
  /// Simple snake_case conversion helper.
  static String toSnakeCase(String input) {
    if (input.isEmpty) return input;

    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == char.toUpperCase() && i > 0) {
        buffer.write('_');
      }
      buffer.write(char.toLowerCase());
    }
    return buffer.toString();
  }

  /// Converts to camelCase.
  static String toCamelCase(String input) {
    final words =
        input.split(RegExp(r'[\s_-]')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return input.toLowerCase();

    final firstWord = words.first.toLowerCase();
    final otherWords = words.skip(1).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });

    return '$firstWord${otherWords.join()}';
  }

  /// Converts to PascalCase.
  static String toPascalCase(String input) {
    final words =
        input.split(RegExp(r'[\s_-]')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return input;

    return words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join();
  }
}

