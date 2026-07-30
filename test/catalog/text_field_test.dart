import 'package:a2ui_core/a2ui_core.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../support/harness.dart';

void main() {
  group('TextField', () {
    test('wraps a text input in its label', () async {
      final html = await renderSurface([
        {'id': 'root', 'component': 'TextField', 'label': 'Your name'},
      ]);

      expect(
        html,
        '<label class="a2ui-field">'
        '<span class="a2ui-field__label">Your name</span>'
        '<input class="a2ui-field__input" type="text"/>'
        '</label>',
      );
    });

    test('shows the value bound from the data model', () async {
      final html = await renderSurface(
        [
          {
            'id': 'root',
            'component': 'TextField',
            'label': 'Name',
            'value': {'path': '/name'},
          },
        ],
        data: {'/name': 'Ada'},
      );

      expect(html, contains('value="Ada"'));
    });

    test(
      'asks the browser for the keyboard that matches the variant',
      () async {
        for (final (variant, type) in const [
          ('shortText', 'text'),
          ('number', 'number'),
          ('obscured', 'password'),
        ]) {
          final html = await renderSurface([
            {
              'id': 'root',
              'component': 'TextField',
              'label': 'Field',
              'variant': variant,
            },
          ]);

          expect(html, contains('type="$type"'), reason: 'variant $variant');
        }
      },
    );

    test('renders long text as a textarea holding its value', () async {
      final html = await renderSurface(
        [
          {
            'id': 'root',
            'component': 'TextField',
            'label': 'Notes',
            'variant': 'longText',
            'value': {'path': '/notes'},
          },
        ],
        data: {'/notes': 'a long story'},
      );

      expect(
        html,
        contains('<textarea class="a2ui-field__input">a long story</textarea>'),
      );
    });

    test('passes a validation pattern to the browser', () async {
      final html = await renderSurface([
        {
          'id': 'root',
          'component': 'TextField',
          'label': 'Code',
          'validationRegexp': r'^\d{4}$',
        },
      ]);

      expect(html, contains(r'pattern="^\d{4}$"'));
    });

    test('shows the message for a failing check', () async {
      final html = await renderSurface(
        [
          {
            'id': 'root',
            'component': 'TextField',
            'label': 'Email',
            'value': {'path': '/email'},
            'checks': [
              {
                'condition': {'path': '/emailOk'},
                'message': 'Enter a valid email',
              },
            ],
          },
        ],
        data: {'/email': 'nope', '/emailOk': false},
      );

      expect(html, contains('class="a2ui-field a2ui-field--invalid"'));
      expect(
        html,
        contains(
          '<small class="a2ui-field__error">Enter a valid email</small>',
        ),
      );
    });

    test('shows no message while its checks pass', () async {
      final html = await renderSurface(
        [
          {
            'id': 'root',
            'component': 'TextField',
            'label': 'Email',
            'checks': [
              {
                'condition': {'path': '/emailOk'},
                'message': 'Enter a valid email',
              },
            ],
          },
        ],
        data: {'/emailOk': true},
      );

      expect(html, isNot(contains('a2ui-field--invalid')));
      expect(html, isNot(contains('a2ui-field__error')));
    });

    // The browser turns a keystroke into a call to this setter. That final hop
    // lives in Jaspr's own event handling and needs a real input element, so what
    // is verified here is the contract the renderer offers the builder: a bound
    // value comes with a setter, and it writes where the model asked.
    group('write-back', () {
      testComponents('a bound value writes through to the model', (
        tester,
      ) async {
        final captured = await captureScope(
          tester,
          MinimalTextFieldApi(),
          [
            {
              'id': 'root',
              'component': 'TextField',
              'label': 'Name',
              'value': {'path': '/name'},
            },
          ],
          data: {'/name': 'Ada'},
        );

        expect(captured.scope.string('value'), 'Ada');

        final write = captured.scope.setter('value');
        expect(write, isNotNull);

        write!('Grace');
        await tester.pump();

        expect(captured.surface.dataModel.get('/name'), 'Grace');
      });

      testComponents('a literal value provides no setter', (tester) async {
        final captured = await captureScope(tester, MinimalTextFieldApi(), [
          {
            'id': 'root',
            'component': 'TextField',
            'label': 'Name',
            'value': 'fixed',
          },
        ]);

        expect(captured.scope.setter('value'), isNull);
      });
    });
  });
}
