import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:test/test.dart';

import '../support/harness.dart';

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
    test('assembles the complete pinned basic catalog', () {
      final catalog = BasicJasprCatalog();

      expect(
        catalog.id,
        'https://a2ui.org/specification/v0_9/catalogs/basic/catalog.json',
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

    test('resolves every value function through a rendered surface', () async {
      Map<String, Object?> call(
        String name,
        Map<String, Object?> args,
        String returnType,
      ) => {'call': name, 'args': args, 'returnType': returnType};

      final strings = <(String, Map<String, Object?>)>[
        (
          'formatString',
          call('formatString', {'value': r'Hello ${/name}'}, 'string'),
        ),
        (
          'formatNumber',
          call('formatNumber', {'value': 1234.5, 'decimals': 1}, 'string'),
        ),
        (
          'formatCurrency',
          call(
            'formatCurrency',
            {'value': 12, 'currency': 'USD'},
            'string',
          ),
        ),
        (
          'formatDate',
          call(
            'formatDate',
            {'value': '2026-01-16T14:30:00Z', 'format': 'yyyy-MM-dd'},
            'string',
          ),
        ),
        (
          'pluralize',
          call(
            'pluralize',
            {'value': 2, 'one': 'item', 'other': 'items'},
            'string',
          ),
        ),
      ];
      final booleans = <(String, Map<String, Object?>)>[
        ('required', call('required', {'value': 'present'}, 'boolean')),
        (
          'regex',
          call(
            'regex',
            {'value': 'ABC-12', 'pattern': r'^[A-Z]+-[0-9]+$'},
            'boolean',
          ),
        ),
        (
          'length',
          call('length', {'value': 'four', 'min': 4, 'max': 4}, 'boolean'),
        ),
        (
          'numeric',
          call('numeric', {'value': 12.5, 'min': 10}, 'boolean'),
        ),
        ('email', call('email', {'value': 'ada@example.com'}, 'boolean')),
        (
          'and',
          call('and', {
            'values': [true, true],
          }, 'boolean'),
        ),
        (
          'or',
          call('or', {
            'values': [false, true],
          }, 'boolean'),
        ),
        ('not', call('not', {'value': false}, 'boolean')),
      ];

      final html = await renderSurface(
        [
          {
            'id': 'root',
            'component': 'Column',
            'children': [
              for (final (id, _) in strings) id,
              for (final (id, _) in booleans) id,
            ],
          },
          for (final (id, value) in strings)
            {'id': id, 'component': 'Text', 'text': value},
          for (final (id, value) in booleans)
            {
              'id': id,
              'component': 'CheckBox',
              'label': id,
              'value': value,
            },
        ],
        data: {'/name': 'Ada'},
        catalog: BasicJasprCatalog(locale: 'en_US'),
      );

      expect(html, contains('Hello Ada'));
      expect(html, contains('1,234.5'));
      expect(html, contains(r'$12.00'));
      expect(html, contains('2026-01-16'));
      expect(html, contains('items'));
      expect(RegExp(' checked(?:="")?').allMatches(html), hasLength(8));
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
