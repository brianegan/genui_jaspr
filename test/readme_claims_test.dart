import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:test/test.dart';

/// Checks the claims the README makes about scope.
///
/// Documentation drifts silently, and the scope statement is the part a reader
/// relies on most, so the parts of it that are machine-checkable are checked.
void main() {
  group('documented scope', () {
    test('renders exactly the five minimal-catalog components', () {
      expect(MinimalJasprCatalog().components.keys.toSet(), {
        'Text',
        'Row',
        'Column',
        'Button',
        'TextField',
      });
    });

    test('uses the A2UI minimal catalog\'s own id', () {
      expect(MinimalJasprCatalog.catalogId, MinimalCatalog().id);
    });

    test('reuses the upstream schemas rather than restating them', () {
      final ours = MinimalJasprCatalog().components;
      final upstream = MinimalCatalog().components;

      for (final name in ours.keys) {
        expect(
          ours[name]!.schema.value,
          upstream[name]!.schema.value,
          reason: '$name has drifted from the A2UI minimal catalog',
        );
      }
    });

    test('nothing beyond the minimal catalog has crept in unannounced', () {
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
        MinimalJasprCatalog().components.keys,
        isNot(anyElement(isIn(deferred))),
      );
    });
  });
}
