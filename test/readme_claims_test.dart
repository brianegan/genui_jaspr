import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:test/test.dart';

/// Checks the catalog's scope against what the README describes.
///
/// Documentation drifts silently, so the parts of the scope statement that are
/// machine-checkable are checked here.
void main() {
  group('documented scope', () {
    test('renders exactly the five minimal-catalog components', () {
      expect(minimalJasprCatalog().components.keys.toSet(), {
        'Text',
        'Row',
        'Column',
        'Button',
        'TextField',
      });
    });

    test('uses the A2UI minimal catalog\'s own id', () {
      expect(minimalJasprCatalogId, MinimalCatalog().id);
    });

    test('reuses the upstream schemas rather than restating them', () {
      final ours = minimalJasprCatalog().components;
      final upstream = MinimalCatalog().components;

      for (final name in ours.keys) {
        expect(
          ours[name]!.schema.value,
          upstream[name]!.schema.value,
          reason: '$name has drifted from the A2UI minimal catalog',
        );
      }
    });

    test('the basic catalog components beyond the minimal set are absent', () {
      const deferred = [
        'Card',
        'Divider',
        'List',
        'Image',
        'Icon',
        'Modal',
        'Tabs',
        'Slider',
        'DateTimeInput',
        'ChoicePicker',
        'AudioPlayer',
        'Video',
      ];

      expect(
        minimalJasprCatalog().components.keys,
        isNot(anyElement(isIn(deferred))),
      );
    });
  });
}
