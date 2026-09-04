// The expected markup below is built from adjacent string literals joined
// with no space, so it matches the rendered HTML exactly.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:genui_jaspr/src/catalog/components/choice_picker.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../support/harness.dart';
import '../support/render.dart';

Future<String> renderChoicePicker(
  List<Map<String, dynamic>> components, {
  Map<String, Object?> data = const {},
}) async => normalizeHtml(
  await renderSurface(
    components,
    data: data,
    catalog: MinimalJasprCatalog().copyWith(add: [ChoicePickerComponent()]),
  ),
);

List<Map<String, dynamic>> pickerSurface(Map<String, dynamic> extra) => [
  {
    'id': 'root',
    'component': 'ChoicePicker',
    'options': [
      {'label': 'Red', 'value': 'red'},
      {'label': 'Blue', 'value': 'blue'},
    ],
    ...extra,
  },
];

void main() {
  group('ChoicePicker', () {
    group('mutuallyExclusive', () {
      test('renders a radio input per option', () async {
        final html = await renderChoicePicker(
          pickerSurface({
            'label': 'Colour',
            'variant': 'mutuallyExclusive',
            'value': 'blue',
          }),
        );

        expect(
          html,
          '<fieldset class="a2ui-choice-picker">'
          '<legend class="a2ui-choice-picker__label">Colour</legend>'
          '<label class="a2ui-choice-picker__option">'
          '<input class="a2ui-choice-picker__input" type="radio" name="root"/>'
          '<span class="a2ui-choice-picker__option-label">Red</span>'
          '</label>'
          '<label class="a2ui-choice-picker__option">'
          '<input class="a2ui-choice-picker__input" type="radio" name="root" checked/>'
          '<span class="a2ui-choice-picker__option-label">Blue</span>'
          '</label>'
          '</fieldset>',
        );
      });

      test('checks none of them when the value matches no option', () async {
        final html = await renderChoicePicker(
          pickerSurface({'variant': 'mutuallyExclusive', 'value': 'green'}),
        );

        expect(html, isNot(contains('checked')));
      });
    });

    group('multipleSelection', () {
      test('renders a checkbox input per option', () async {
        final html = await renderChoicePicker(
          pickerSurface({
            'variant': 'multipleSelection',
            'value': ['red'],
          }),
        );

        expect(
          html,
          contains(
            '<input class="a2ui-choice-picker__input" type="checkbox" checked/>'
            '<span class="a2ui-choice-picker__option-label">Red</span>',
          ),
        );
        expect(
          html,
          contains(
            '<input class="a2ui-choice-picker__input" type="checkbox"/>'
            '<span class="a2ui-choice-picker__option-label">Blue</span>',
          ),
        );
      });

      test('checks none of them when the value is a scalar', () async {
        // The schema admits a plain string for `value` regardless of variant,
        // so a scalar under multipleSelection must render, not crash.
        final html = await renderChoicePicker(
          pickerSurface({'variant': 'multipleSelection', 'value': 'red'}),
        );

        expect(
          html,
          contains(
            '<input class="a2ui-choice-picker__input" type="checkbox" checked/>'
            '<span class="a2ui-choice-picker__option-label">Red</span>',
          ),
        );
      });

      test(
        'shows the message for a failing check on the invalid class',
        () async {
          final html = await renderChoicePicker(
            pickerSurface({
              'variant': 'multipleSelection',
              'value': ['red'],
              'checks': [
                {
                  'condition': {'path': '/ok'},
                  'message': 'Pick at least one',
                },
              ],
            }),
            data: {'/ok': false},
          );

          expect(
            html,
            contains('class="a2ui-choice-picker a2ui-choice-picker--invalid"'),
          );
        },
      );
    });

    test('checks the matching option when the value is a list', () async {
      // The reference implementation's own example data sends a
      // single-element list even under mutuallyExclusive.
      final html = await renderChoicePicker(
        pickerSurface({
          'variant': 'mutuallyExclusive',
          'value': ['blue'],
        }),
      );

      expect(
        html,
        contains(
          '<input class="a2ui-choice-picker__input" type="radio" name="root" checked/>'
          '<span class="a2ui-choice-picker__option-label">Blue</span>',
        ),
      );
    });

    test('shows the message for a failing check', () async {
      final html = await renderChoicePicker(
        pickerSurface({
          'value': 'red',
          'checks': [
            {
              'condition': {'path': '/ok'},
              'message': 'Pick one',
            },
          ],
        }),
        data: {'/ok': false},
      );

      expect(
        html,
        contains('class="a2ui-choice-picker a2ui-choice-picker--invalid"'),
      );
      expect(
        html,
        contains('<small class="a2ui-choice-picker__error">Pick one</small>'),
      );
    });

    test('shows no message while its checks pass', () async {
      final html = await renderChoicePicker(
        pickerSurface({
          'value': 'red',
          'checks': [
            {
              'condition': {'path': '/ok'},
              'message': 'Pick one',
            },
          ],
        }),
        data: {'/ok': true},
      );

      expect(html, isNot(contains('a2ui-choice-picker--invalid')));
      expect(html, isNot(contains('a2ui-choice-picker__error')));
    });

    test('renders with no legend when no label is given', () async {
      final html = await renderChoicePicker(
        pickerSurface({'value': 'red'}),
      );

      expect(html, isNot(contains('a2ui-choice-picker__label')));
    });

    group('write-back', () {
      testComponents(
        'selecting an option writes its value through, mutually exclusive',
        (tester) async {
          final captured = await captureScope(
            tester,
            ChoicePickerApi(),
            pickerSurface({
              'variant': 'mutuallyExclusive',
              'value': {'path': '/colour'},
            }),
            data: {'/colour': 'red'},
          );

          expect(captured.scope.props['value'], 'red');

          final write = captured.scope.setter('value');
          expect(write, isNotNull);

          write!('blue');
          await tester.pump();

          expect(captured.surface.dataModel.get('/colour'), 'blue');
        },
      );

      testComponents(
        'selecting options writes the list through, multiple selection',
        (tester) async {
          final captured = await captureScope(
            tester,
            ChoicePickerApi(),
            pickerSurface({
              'variant': 'multipleSelection',
              'value': {'path': '/colours'},
            }),
            data: {
              '/colours': ['red'],
            },
          );

          expect(captured.scope.props['value'], ['red']);

          final write = captured.scope.setter('value');
          expect(write, isNotNull);

          write!(['red', 'blue']);
          await tester.pump();

          expect(captured.surface.dataModel.get('/colours'), [
            'red',
            'blue',
          ]);
        },
      );

      testComponents('a literal value provides no setter', (tester) async {
        final captured = await captureScope(
          tester,
          ChoicePickerApi(),
          pickerSurface({'value': 'red'}),
        );

        expect(captured.scope.setter('value'), isNull);
      });
    });
  });
}
