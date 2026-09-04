// The expected markup below is built from adjacent string literals joined
// with no space, so it matches the rendered HTML exactly.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'package:a2ui_core/a2ui_core.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../support/harness.dart';

/// A button with a label, and whatever extra properties a test needs.
List<Map<String, dynamic>> buttonSurface(Map<String, dynamic> extra) => [
  {
    'id': 'root',
    'component': 'Button',
    'child': 'label',
    'action': {
      'event': {'name': 'submit'},
    },
    ...extra,
  },
  {'id': 'label', 'component': 'Text', 'text': 'Send'},
];

void main() {
  group('Button', () {
    test('renders its child inside a button element', () async {
      final html = await renderSurface(buttonSurface(const {}));

      expect(
        html,
        '<button class="a2ui-button a2ui-button--primary" type="button">'
        '<p class="a2ui-text a2ui-text--body">Send</p>'
        '</button>',
      );
    });

    test('carries the variant as a class', () async {
      final html = await renderSurface(
        buttonSurface(const {'variant': 'borderless'}),
      );

      expect(html, contains('class="a2ui-button a2ui-button--borderless"'));
    });

    testComponents('dispatches its action when clicked', (tester) async {
      final actions = <A2uiClientAction>[];
      final surface = buildSurfaceModel(
        buttonSurface(const {}),
        onAction: actions.add,
      );

      tester.pumpComponent(surfaceComponent(surface));
      await tester.click(find.tag('button'));

      expect(actions, hasLength(1));
      expect(actions.single.name, 'submit');
      expect(actions.single.sourceComponentId, 'root');
      expect(actions.single.surfaceId, 'main');
    });

    testComponents('carries the action context through to the listener', (
      tester,
    ) async {
      final actions = <A2uiClientAction>[];
      final surface = buildSurfaceModel([
        {
          'id': 'root',
          'component': 'Button',
          'child': 'label',
          'action': {
            'event': {
              'name': 'pick',
              'context': {'choice': 'blue'},
            },
          },
        },
        {'id': 'label', 'component': 'Text', 'text': 'Blue'},
      ], onAction: actions.add);

      tester.pumpComponent(surfaceComponent(surface));
      await tester.click(find.tag('button'));

      expect(actions.single.context, {'choice': 'blue'});
    });

    group('when its checks fail', () {
      List<Map<String, dynamic>> guarded() => buttonSurface({
        'checks': [
          {
            'condition': {'path': '/agreed'},
            'message': 'You must agree first',
          },
        ],
      });

      test('is disabled', () async {
        final html = await renderSurface(guarded(), data: {'/agreed': false});

        expect(html, contains('disabled'));
      });

      testComponents('dispatches nothing when clicked', (tester) async {
        final actions = <A2uiClientAction>[];
        final surface = buildSurfaceModel(
          guarded(),
          data: {'/agreed': false},
          onAction: actions.add,
        );

        tester.pumpComponent(surfaceComponent(surface));
        await tester.click(find.tag('button'));

        expect(actions, isEmpty);
      });

      testComponents('becomes usable once the check passes', (tester) async {
        final actions = <A2uiClientAction>[];
        final surface = buildSurfaceModel(
          guarded(),
          data: {'/agreed': false},
          onAction: actions.add,
        );

        tester.pumpComponent(surfaceComponent(surface));
        surface.dataModel.set('/agreed', true);
        await tester.pump();

        await tester.click(find.tag('button'));

        expect(actions, hasLength(1));
      });
    });
  });
}
