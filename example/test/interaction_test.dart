import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr_example/interaction.dart';
import 'package:test/test.dart';

A2uiClientAction pressed(
  String name, {
  Map<String, dynamic> context = const {},
}) {
  return A2uiClientAction(
    name: name,
    surfaceId: 'reply0',
    sourceComponentId: 'send',
    timestamp: DateTime(2026),
    context: context,
  );
}

void main() {
  group('describeInteraction', () {
    test('names the event that fired', () {
      expect(
        describeInteraction(pressed('signUp'), null),
        'The user triggered "signUp".',
      );
    });

    test('includes the context the model attached to the action', () {
      expect(
        describeInteraction(pressed('pick', context: {'choice': 'blue'}), null),
        contains('Context: {choice: blue}.'),
      );
    });

    test('carries what the user entered, so the model can act on it', () {
      final description = describeInteraction(pressed('signUp'), {
        'email': 'ada@example.com',
      });

      expect(description, contains('signUp'));
      expect(description, contains('ada@example.com'));
    });

    test('says nothing about data when the surface holds none', () {
      expect(
        describeInteraction(pressed('signUp'), <String, Object?>{}),
        isNot(contains('entered')),
      );
    });

    test('the transcript summary stays short', () {
      expect(summariseInteraction(pressed('signUp')), 'Submitted "signUp"');
    });
  });

  group('retargetSurface', () {
    A2uiMessage message(Map<String, dynamic> json) =>
        A2uiMessage.fromJson({'version': 'v0.9', ...json});

    test('redirects a createSurface to this reply\'s surface', () {
      final retargeted = retargetSurface(
        message({
          'createSurface': {
            'surfaceId': 'whatever-the-model-chose',
            'catalogId': 'c',
            'sendDataModel': true,
          },
        }),
        'reply7',
      );

      expect((retargeted as CreateSurfaceMessage).surfaceId, 'reply7');
    });

    test('redirects updateComponents and keeps the components', () {
      final retargeted =
          retargetSurface(
                message({
                  'updateComponents': {
                    'surfaceId': 'model-chose-this',
                    'components': [
                      {'id': 'root', 'component': 'Text', 'text': 'hi'},
                    ],
                  },
                }),
                'reply7',
              )
              as UpdateComponentsMessage;

      expect(retargeted.surfaceId, 'reply7');
      expect(retargeted.components.single['text'], 'hi');
    });

    test('redirects updateDataModel and keeps path and value', () {
      final retargeted =
          retargetSurface(
                message({
                  'updateDataModel': {
                    'surfaceId': 'model-chose-this',
                    'path': '/name',
                    'value': 'Ada',
                  },
                }),
                'reply7',
              )
              as UpdateDataModelMessage;

      expect(retargeted.surfaceId, 'reply7');
      expect(retargeted.path, '/name');
      expect(retargeted.value, 'Ada');
    });

    test('stops a model reusing an id from overwriting an earlier reply', () {
      // Two replies that both call their surface "main" must not collide.
      final first = retargetSurface(
        message({
          'createSurface': {
            'surfaceId': 'main',
            'catalogId': 'c',
            'sendDataModel': true,
          },
        }),
        'reply0',
      );
      final second = retargetSurface(
        message({
          'createSurface': {
            'surfaceId': 'main',
            'catalogId': 'c',
            'sendDataModel': true,
          },
        }),
        'reply1',
      );

      expect((first as CreateSurfaceMessage).surfaceId, 'reply0');
      expect((second as CreateSurfaceMessage).surfaceId, 'reply1');
    });
  });
}
