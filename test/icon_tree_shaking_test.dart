@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

const _iconTableMarker = 'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10s10-4.48';

void main() {
  test(
    'the public barrel and custom renderer do not retain built-in icon paths',
    () async {
      final outputDirectory = await Directory.systemTemp.createTemp(
        'genui_jaspr_icons_',
      );
      addTearDown(() => outputDirectory.delete(recursive: true));

      final importOnly = await _compile(
        'import_only',
        outputDirectory,
      );
      final customRenderer = await _compile(
        'custom_renderer',
        outputDirectory,
      );
      final defaultRenderer = await _compile(
        'default_renderer',
        outputDirectory,
      );
      final basicCustomRenderer = await _compile(
        'basic_custom_renderer',
        outputDirectory,
      );
      final basicWithoutIcons = await _compile(
        'basic_without_icons',
        outputDirectory,
      );
      final basicDefault = await _compile(
        'basic_default',
        outputDirectory,
      );

      expect(importOnly, isNot(contains(_iconTableMarker)));
      expect(customRenderer, isNot(contains(_iconTableMarker)));
      expect(defaultRenderer, contains(_iconTableMarker));
      expect(basicCustomRenderer, isNot(contains(_iconTableMarker)));
      expect(basicWithoutIcons, isNot(contains(_iconTableMarker)));
      expect(basicDefault, contains(_iconTableMarker));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<String> _compile(String fixture, Directory outputDirectory) async {
  final output = '${outputDirectory.path}/$fixture.js';
  final result = await Process.run(Platform.resolvedExecutable, [
    'compile',
    'js',
    '-O4',
    '-o',
    output,
    'test/fixtures/icon_tree_shaking/$fixture.dart',
  ]);

  expect(
    result.exitCode,
    0,
    reason: '${result.stdout}\n${result.stderr}',
  );
  return File(output).readAsString();
}
