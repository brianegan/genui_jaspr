@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

const _iconTableMarker = 'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10s10-4.48';

/// A class only `ChoicePicker` emits, so it stands for the Basic-only catalog
/// and style code together: the string appears in the component's `build` and
/// in the rules its `styles` declares, and nowhere a minimal catalog reaches.
const _basicOnlyMarker = 'a2ui-choice-picker';

void main() {
  test(
    'only the built-in icon and Basic catalog retain built-in icon paths',
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
      final basicDefault = await _compile(
        'basic_default',
        outputDirectory,
      );

      expect(importOnly, isNot(contains(_iconTableMarker)));
      expect(customRenderer, isNot(contains(_iconTableMarker)));
      expect(defaultRenderer, contains(_iconTableMarker));
      expect(basicDefault, contains(_iconTableMarker));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'a minimal catalog reading its styles retains no Basic-only style code',
    () async {
      final outputDirectory = await Directory.systemTemp.createTemp(
        'genui_jaspr_styles_',
      );
      addTearDown(() => outputDirectory.delete(recursive: true));

      final minimalOnly = await _compile('import_only', outputDirectory);
      final withBasic = await _compile('minimal_with_basic', outputDirectory);

      // The paired presence assertion is what gives the absence one teeth: a
      // wrong marker string would make the absence pass while checking nothing.
      expect(withBasic, contains(_basicOnlyMarker));
      expect(minimalOnly, isNot(contains(_basicOnlyMarker)));
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
