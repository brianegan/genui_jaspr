import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:test/test.dart';

const _componentNames = {
  'Text',
  'Image',
  'Icon',
  'Video',
  'AudioPlayer',
  'Row',
  'Column',
  'List',
  'Card',
  'Tabs',
  'Modal',
  'Divider',
  'Button',
  'TextField',
  'CheckBox',
  'ChoicePicker',
  'Slider',
  'DateTimeInput',
};

const _functionNames = {
  'required',
  'regex',
  'length',
  'numeric',
  'email',
  'formatString',
  'formatNumber',
  'formatCurrency',
  'formatDate',
  'pluralize',
  'openUrl',
  'and',
  'or',
  'not',
};

void main() {
  group('BasicJasprCatalog', () {
    test('assembles the complete pinned standard catalog', () {
      final catalog = BasicJasprCatalog();

      expect(
        catalog.id,
        'https://a2ui.org/specification/v0_9/standard_catalog.json',
      );
      expect(catalog.id, BasicJasprCatalog.catalogId);
      expect(catalog.components.keys.toSet(), _componentNames);
      expect(catalog.functions.keys.toSet(), _functionNames);
      expect(
        catalog.themeSchema!.value,
        Schema.object(
          properties: {
            'primaryColor': Schema.string(pattern: r'^#[0-9a-fA-F]{6}$'),
            'iconUrl': Schema.string(format: 'uri'),
            'agentDisplayName': Schema.string(),
          },
          additionalProperties: true,
        ).value,
      );
      expect(catalog.functions, isNot(contains('capitalize')));
    });

    test('supports custom and icon-free construction without lying by id', () {
      final custom = BasicJasprCatalog.withIconRenderer(
        (name) => Component.text('custom:$name'),
      );
      final iconFree = BasicJasprCatalog.withoutIcons(
        id: 'com.example.basic-without-icons',
      );

      expect(custom.id, BasicJasprCatalog.catalogId);
      expect(custom.components.keys.toSet(), _componentNames);
      expect(iconFree.id, 'com.example.basic-without-icons');
      expect(iconFree.components, isNot(contains('Icon')));
      expect(iconFree.components, hasLength(17));
      expect(iconFree.functions.keys.toSet(), _functionNames);
      expect(
        () => BasicJasprCatalog.withoutIcons(
          id: BasicJasprCatalog.catalogId,
        ),
        throwsArgumentError,
      );
    });

    test('passes openUrl through the application policy hook', () {
      final opened = <Uri>[];
      final catalog = BasicJasprCatalog(urlOpener: opened.add);
      final context = DataContext(DataModel(), catalog.invoke, '/');

      catalog.invoke(
        'openUrl',
        {'url': 'https://example.com/path'},
        context,
      );

      expect(opened, [Uri.parse('https://example.com/path')]);
    });

    test('does not change the minimal catalog', () {
      expect(MinimalJasprCatalog().components.keys.toSet(), {
        'Text',
        'Row',
        'Column',
        'Button',
        'TextField',
      });
      expect(MinimalJasprCatalog().functions.keys, ['capitalize']);
      expect(MinimalJasprCatalog.catalogId, MinimalCatalog().id);
    });

    test('publishes every Basic capability in the generated prompt', () {
      final catalog = BasicJasprCatalog();
      final prompt = a2uiInstructions(catalog);
      final components =
          jsonDecode(
                prompt
                    .split('with their schemas:\n\n')[1]
                    .split('\n\nThese functions')[0],
              )
              as Map<String, dynamic>;
      final functions =
          jsonDecode(
                prompt
                    .split('anywhere a value is allowed:\n\n')[1]
                    .split('\n\nA createSurface')[0],
              )
              as Map<String, dynamic>;

      expect(prompt, contains('The active catalog ID is "${catalog.id}"'));
      expect(components.keys.toSet(), _componentNames);
      expect(functions.keys.toSet(), _functionNames);
      for (final entry in catalog.functions.entries) {
        expect(functions[entry.key], {
          'returnType': entry.value.returnType.jsonValue,
          'args': entry.value.argumentSchema.value,
        });
      }
      expect(prompt, contains('"primaryColor"'));
      expect(prompt, contains('"iconUrl"'));
      expect(prompt, contains('"agentDisplayName"'));
    });
  });
}
