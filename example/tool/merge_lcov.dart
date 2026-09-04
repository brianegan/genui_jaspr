/// Merges the per-platform records in an lcov file and enforces a minimum.
///
/// `format_coverage` writes one record per platform for the same source file:
/// the VM suite and the Chrome suite each carry their own line table, and each
/// alone falls short (no VM test can enter `chat.dart`, and the browser suite
/// does not run the server route). This folds every record for a file into one,
/// counting a line covered when any platform covered it.
///
/// Usage: `dart tool/merge_lcov.dart <in.info> <out.info> <min-percent>`
library;

import 'dart:io';

void main(List<String> args) {
  final lines = File(args[0]).readAsLinesSync();
  final out = File(args[1]);
  final min = double.parse(args[2]);

  // file -> line number -> hit count summed across records.
  final files = <String, Map<int, int>>{};
  String? current;
  for (final line in lines) {
    if (line.startsWith('SF:')) {
      current = line.substring(3);
      files.putIfAbsent(current, () => {});
    } else if (line.startsWith('DA:') && current != null) {
      final parts = line.substring(3).split(',');
      final number = int.parse(parts[0]);
      final hits = int.parse(parts[1]);
      files[current]!.update(
        number,
        (seen) => seen + hits,
        ifAbsent: () => hits,
      );
    }
  }

  final buffer = StringBuffer();
  var total = 0;
  var covered = 0;
  final missed = <String>[];
  for (final entry in files.entries) {
    buffer.writeln('SF:${entry.key}');
    final numbers = entry.value.keys.toList()..sort();
    for (final number in numbers) {
      final hits = entry.value[number]!;
      buffer.writeln('DA:$number,$hits');
      total++;
      if (hits > 0) {
        covered++;
      } else {
        missed.add('${entry.key}:$number');
      }
    }
    buffer
      ..writeln('LF:${entry.value.length}')
      ..writeln('LH:${entry.value.values.where((hits) => hits > 0).length}')
      ..writeln('end_of_record');
  }
  out.writeAsStringSync(buffer.toString());

  final percent = total == 0 ? 0.0 : covered / total * 100;
  stdout.writeln(
    'Merged coverage: $covered/$total lines '
    '(${percent.toStringAsFixed(1)}%), minimum $min%.',
  );
  for (final line in missed) {
    stdout.writeln('  uncovered: $line');
  }
  if (percent < min) {
    exitCode = 1;
  }
}
