import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:test/test.dart';

import '../support/harness.dart';

/// A component the minimal catalog does not have.
class _DividerApi extends ComponentApi {
  @override
  String get name => 'Divider';

  @override
  Schema get schema => Schema.object(properties: {});
}

class _UpperFunction extends FunctionImplementation {
  @override
  String get name => 'upper';

  @override
  A2uiReturnType get returnType => A2uiReturnType.string;

  @override
  Schema get argumentSchema => Schema.object(properties: {});

  @override
  Object? execute(
    Map<String, dynamic> args,
    DataContext context, [
    CancellationSignal? cancellationSignal,
  ]) => '${args['value']}'.toUpperCase();
}

void main() {
  group('Catalog.copyWith', () {
    test('adds a component under a new id', () {
      final catalog = MinimalJasprCatalog().copyWith(
        id: 'com.example.catalog',
        add: [JasprComponent.inline(_DividerApi(), (scope) => hr())],
      );

      expect(catalog.id, 'com.example.catalog');
      expect(catalog.components.keys, contains('Divider'));
      expect(catalog.components.keys, containsAll(['Text', 'Button']));
      // The original is untouched.
      expect(MinimalJasprCatalog().components.keys, isNot(contains('Divider')));
    });

    test('replaces a component of the same name', () async {
      final catalog = MinimalJasprCatalog().copyWith(
        add: [
          JasprComponent.inline(
            MinimalTextApi(),
            (scope) => span([
              Component.text(scope.string('text') ?? ''),
            ], classes: 'swapped'),
          ),
        ],
      );

      final html = await renderSurface([
        {'id': 'root', 'component': 'Text', 'text': 'hi'},
      ], catalog: catalog);

      expect(html, '<span class="swapped">hi</span>');
    });

    test('removes a component by name', () {
      final catalog = MinimalJasprCatalog().copyWith(remove: ['TextField']);

      expect(catalog.components.keys, isNot(contains('TextField')));
      expect(catalog.components, hasLength(4));
    });

    test('keeps the id, functions and theme schema unless told otherwise', () {
      final original = MinimalJasprCatalog();
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.functions.keys, original.functions.keys);
      expect(copy.themeSchema, same(original.themeSchema));
    });

    test('merges functions and swaps the theme schema', () {
      final theme = Schema.object(properties: {'accent': Schema.string()});
      final catalog = MinimalJasprCatalog().copyWith(
        addFunctions: [_UpperFunction()],
        themeSchema: theme,
      );

      expect(catalog.functions.keys, containsAll(['capitalize', 'upper']));
      expect(catalog.themeSchema, same(theme));
    });
  });
}
