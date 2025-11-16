import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final root = Directory.current.path;
  final brickDir = Directory('$root/__brick__');
  if (!brickDir.existsSync()) {
    stderr.writeln('Run from the template root (directory containing __brick__).');
    exit(1);
  }
  final files = <File>[];
  await for (final entity in brickDir.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      final name = entity.path.split('/').last;
      if (name.startsWith('.')) continue;
      files.add(entity);
    }
  }
  int conditionalTags = 0;
  int totalLines = 0;
  for (final f in files) {
    final content = await f.readAsString();
    totalLines += '\n'.allMatches(content).length + 1;
    conditionalTags += RegExp(r'{{#').allMatches(content).length;
    conditionalTags += RegExp(r'{{\^').allMatches(content).length;
  }
  final result = {
    'files': files.length,
    'total_lines': totalLines,
    'conditional_tags': conditionalTags,
    'inline_conditional_density': totalLines == 0 ? 0 : conditionalTags / totalLines,
  };
  print(const JsonEncoder.withIndent('  ').convert(result));
}


