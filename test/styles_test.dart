import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:genui_jaspr/src/catalog/components/check_box.dart';
import 'package:genui_jaspr/src/catalog/components/choice_picker.dart';
import 'package:genui_jaspr/src/catalog/components/date_time_input.dart';
import 'package:genui_jaspr/src/catalog/components/slider.dart';
import 'package:jaspr_test/jaspr_test.dart';

import 'support/harness.dart';

/// Every class name the catalog can emit, gathered by rendering a surface that
/// uses all five components across their variants.
Future<Set<String>> emittedClassNames() async {
  final html = <String>[];

  for (final variant in const [
    'body',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'caption',
  ]) {
    html.add(
      await renderSurfaceRaw([
        {'id': 'root', 'component': 'Text', 'text': 'x', 'variant': variant},
      ]),
    );
  }

  for (final variant in const ['primary', 'borderless']) {
    html.add(
      await renderSurfaceRaw([
        {
          'id': 'root',
          'component': 'Button',
          'child': 'label',
          'variant': variant,
          'action': {
            'event': {'name': 'go'},
          },
        },
        {'id': 'label', 'component': 'Text', 'text': 'Go'},
      ]),
    );
  }

  for (final variant in const ['shortText', 'number', 'obscured', 'longText']) {
    html.add(
      await renderSurfaceRaw([
        {
          'id': 'root',
          'component': 'TextField',
          'label': 'L',
          'variant': variant,
        },
      ]),
    );
  }

  // An invalid field, for the error classes.
  html.add(
    await renderSurfaceRaw(
      [
        {
          'id': 'root',
          'component': 'TextField',
          'label': 'L',
          'checks': [
            {
              'condition': {'path': '/ok'},
              'message': 'nope',
            },
          ],
        },
      ],
      data: {'/ok': false},
    ),
  );

  final checkBoxCatalog = MinimalJasprCatalog().copyWith(
    add: [CheckBoxComponent()],
  );

  html
    ..add(
      await renderSurfaceModel(
        buildSurfaceModel([
          {'id': 'root', 'component': 'CheckBox', 'label': 'Subscribe'},
        ], catalog: checkBoxCatalog),
      ),
    )
    // An invalid checkbox, for the error classes.
    ..add(
      await renderSurfaceModel(
        buildSurfaceModel(
          [
            {
              'id': 'root',
              'component': 'CheckBox',
              'label': 'Subscribe',
              'checks': [
                {
                  'condition': {'path': '/ok'},
                  'message': 'nope',
                },
              ],
            },
          ],
          data: {'/ok': false},
          catalog: checkBoxCatalog,
        ),
      ),
    );

  final choicePickerCatalog = MinimalJasprCatalog().copyWith(
    add: [ChoicePickerComponent()],
  );
  final choicePickerOptions = [
    {'label': 'Red', 'value': 'red'},
    {'label': 'Blue', 'value': 'blue'},
  ];

  html
    ..add(
      await renderSurfaceModel(
        buildSurfaceModel([
          {
            'id': 'root',
            'component': 'ChoicePicker',
            'label': 'Colour',
            'variant': 'mutuallyExclusive',
            'options': choicePickerOptions,
            'value': 'red',
          },
        ], catalog: choicePickerCatalog),
      ),
    )
    ..add(
      await renderSurfaceModel(
        buildSurfaceModel([
          {
            'id': 'root',
            'component': 'ChoicePicker',
            'variant': 'multipleSelection',
            'options': choicePickerOptions,
            'value': ['red'],
          },
        ], catalog: choicePickerCatalog),
      ),
    )
    // An invalid choice picker, for the error classes.
    ..add(
      await renderSurfaceModel(
        buildSurfaceModel(
          [
            {
              'id': 'root',
              'component': 'ChoicePicker',
              'label': 'Colour',
              'options': choicePickerOptions,
              'value': 'red',
              'checks': [
                {
                  'condition': {'path': '/ok'},
                  'message': 'nope',
                },
              ],
            },
          ],
          data: {'/ok': false},
          catalog: choicePickerCatalog,
        ),
      ),
    );

  final sliderCatalog = MinimalJasprCatalog().copyWith(
    add: [SliderComponent()],
  );

  html
    ..add(
      await renderSurfaceModel(
        buildSurfaceModel([
          {
            'id': 'root',
            'component': 'Slider',
            'label': 'Amount',
            'value': 5,
          },
        ], catalog: sliderCatalog),
      ),
    )
    // An invalid slider, for the error classes.
    ..add(
      await renderSurfaceModel(
        buildSurfaceModel(
          [
            {
              'id': 'root',
              'component': 'Slider',
              'label': 'Amount',
              'value': 5,
              'checks': [
                {
                  'condition': {'path': '/ok'},
                  'message': 'nope',
                },
              ],
            },
          ],
          data: {'/ok': false},
          catalog: sliderCatalog,
        ),
      ),
    );

  final dateTimeInputCatalog = MinimalJasprCatalog().copyWith(
    add: [DateTimeInputComponent()],
  );

  html
    ..add(
      await renderSurfaceModel(
        buildSurfaceModel([
          {
            'id': 'root',
            'component': 'DateTimeInput',
            'label': 'When',
            'value': '2024-01-01',
          },
        ], catalog: dateTimeInputCatalog),
      ),
    )
    // An invalid date/time input, for the error classes.
    ..add(
      await renderSurfaceModel(
        buildSurfaceModel(
          [
            {
              'id': 'root',
              'component': 'DateTimeInput',
              'label': 'When',
              'value': '2024-01-01',
              'checks': [
                {
                  'condition': {'path': '/ok'},
                  'message': 'nope',
                },
              ],
            },
          ],
          data: {'/ok': false},
          catalog: dateTimeInputCatalog,
        ),
      ),
    );

  for (final component in const ['Row', 'Column']) {
    html.add(
      await renderSurfaceRaw([
        {'id': 'root', 'component': component, 'children': <String>[]},
      ]),
    );
  }

  // The fallback for a component this catalog does not implement.
  html.add(
    await renderSurfaceRaw([
      {'id': 'root', 'component': 'NotARealComponent'},
    ]),
  );

  final names = <String>{};
  final pattern = RegExp('class="([^"]+)"');
  for (final markup in html) {
    for (final match in pattern.allMatches(markup)) {
      names.addAll(match.group(1)!.split(' ').where((n) => n.isNotEmpty));
    }
  }
  return names;
}

void main() {
  group('genuiJasprStyles', () {
    test('has a rule for every class the catalog emits', () async {
      final css = genuiJasprStyles.map((rule) => rule.toCss()).join('\n');
      final names = await emittedClassNames();

      // Guard the guard: if rendering stopped producing classes, this test
      // would pass while checking nothing.
      expect(names, hasLength(greaterThan(10)));

      final uncovered = names.where((n) => !css.contains('.$n')).toList()
        ..sort();
      expect(uncovered, isEmpty, reason: 'classes with no style rule');
    });
  });

  group('surface theme', () {
    test(
      'publishes theme values as custom properties on the surface',
      () async {
        final html = await renderSurfaceRaw(
          [
            {'id': 'root', 'component': 'Text', 'text': 'x'},
          ],
          theme: {'primaryColor': '#ff0000'},
        );

        expect(html, startsWith('<div class="a2ui-surface"'));
        expect(html, contains('--a2ui-primary-color: #ff0000'));
      },
    );

    test('wraps the surface even without a theme', () async {
      final html = await renderSurfaceRaw([
        {'id': 'root', 'component': 'Text', 'text': 'x'},
      ]);

      expect(html, startsWith('<div class="a2ui-surface"'));
      expect(html, isNot(contains('--a2ui-primary-color')));
    });

    test('the primary button resolves against the theme property', () async {
      final css = genuiJasprStyles.map((rule) => rule.toCss()).join('\n');

      expect(css, contains('var(--a2ui-primary-color'));
    });
  });
}
