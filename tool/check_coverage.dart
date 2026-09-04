/// Enforces a minimum line-coverage percentage on an lcov file.
///
/// `very_good_cli`'s own `--min-coverage` does not honor `coverage:ignore`
/// comments in this package: its `HitMap.parseFiles` resolves `packagePath`
/// in a way that never finds this package's sources, so the markers around
/// the lines only a browser can execute are silently never read, and it
/// reports this package under its true bar. `format_coverage --check-ignore`
/// reads them correctly, so `tool/coverage.sh` calls that directly and hands
/// the result here instead.
///
/// Usage: `dart tool/check_coverage.dart <lcov-file> <min-percent>`
library;

import 'dart:io';

void main(List<String> args) {
  final lines = File(args[0]).readAsLinesSync();
  final min = double.parse(args[1]);

  var total = 0;
  var covered = 0;
  final missed = <String>[];
  String? current;
  for (final line in lines) {
    if (line.startsWith('SF:')) {
      current = line.substring(3);
    } else if (line.startsWith('DA:') && current != null) {
      final parts = line.substring(3).split(',');
      total++;
      if (int.parse(parts[1]) > 0) {
        covered++;
      } else {
        missed.add('$current:${parts[0]}');
      }
    }
  }

  final percent = total == 0 ? 0.0 : covered / total * 100;
  stdout.writeln(
    'Coverage: $covered/$total lines (${percent.toStringAsFixed(1)}%), '
    'minimum $min%.',
  );
  for (final line in missed) {
    stdout.writeln('  uncovered: $line');
  }
  if (percent < min) {
    exitCode = 1;
  }
}
