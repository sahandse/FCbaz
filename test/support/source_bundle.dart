import 'dart:io';

/// Reads a Dart library together with every `part` file it declares.
///
/// Source-scan tests keep guarding the approved UI structure; this lets them
/// follow code that moved into part files during the module split.
String readSourceBundle(String path) {
  final file = File(path);
  final source = file.readAsStringSync();
  final parts = RegExp(r"^part '([^']+)';$", multiLine: true);
  final buffer = StringBuffer(source);
  for (final match in parts.allMatches(source)) {
    buffer.writeln(
      File('${file.parent.path}/${match.group(1)}').readAsStringSync(),
    );
  }
  return buffer.toString();
}
