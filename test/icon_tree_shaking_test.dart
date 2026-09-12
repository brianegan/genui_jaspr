@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

const _iconTableMarker = 'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10s10-4.48';

/// A compound selector only `ChoicePicker`'s rules declare, standing for
/// Basic-only style code.
///
/// Its `build` emits both class names, but never adjacent with the second
/// dotted, so this literal reaches the output through the rules alone. A bare
/// class name would not: `build` writes those too, and the marker would pass on
/// catalog code while style code went unmeasured.
const _basicOnlyStyleMarker =
    'a2ui-choice-picker--invalid .a2ui-choice-picker__label';

/// A string only `ChoicePicker`'s `build` contains, standing for Basic-only
/// catalog code.
///
/// Style code and catalog code shake out independently, so each gets a marker
/// of its own. One string that appears in both would let either half carry the
/// assertion while the other went unmeasured.
const _basicOnlyBuildMarker = 'mutuallyExclusive';

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
    'a minimal catalog retains no Basic-only catalog or style code',
    () async {
      final outputDirectory = await Directory.systemTemp.createTemp(
        'genui_jaspr_styles_',
      );
      addTearDown(() => outputDirectory.delete(recursive: true));

      final minimalOnly = await _compile('minimal_styles', outputDirectory);
      final withBasic = await _compile('minimal_with_basic', outputDirectory);

      // The paired presence assertions are what give the absence ones teeth: a
      // wrong marker string would make an absence pass while checking nothing.
      expect(withBasic, contains(_basicOnlyStyleMarker));
      expect(withBasic, contains(_basicOnlyBuildMarker));
      expect(minimalOnly, isNot(contains(_basicOnlyStyleMarker)));
      expect(minimalOnly, isNot(contains(_basicOnlyBuildMarker)));
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
