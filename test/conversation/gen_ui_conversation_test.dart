import 'dart:async';
import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../support/render.dart';

Map<String, dynamic> createSurface(String id, {String? catalogId}) => {
  'version': 'v0.9',
  'createSurface': {
    'surfaceId': id,
    'catalogId': catalogId ?? minimalJasprCatalogId,
    'sendDataModel': true,
  },
};

Map<String, dynamic> updateComponents(
  String id,
  List<Map<String, dynamic>> components,
) => {
  'version': 'v0.9',
  'updateComponents': {'surfaceId': id, 'components': components},
};

Map<String, dynamic> updateDataModel(String id, String path, Object? value) => {
  'version': 'v0.9',
  'updateDataModel': {'surfaceId': id, 'path': path, 'value': value},
};

/// A complete reply: a sentence, a surface, and a component to show in it.
List<String> greetingReply({String surfaceId = 's1', String text = 'Hello'}) =>
    [
      'Here you go.\n\n',
      _encode(createSurface(surfaceId)),
      _encode(
        updateComponents(surfaceId, [
          {'id': 'root', 'component': 'Text', 'text': text},
        ]),
      ),
    ];

/// A message the way a model writes it: fenced JSON on its own lines.
String _encode(Map<String, dynamic> json) =>
    '```json\n${jsonEncode(json)}\n```\n';

void main() {
  late GenUiConversation conversation;

  setUp(() {
    conversation = GenUiConversation(catalogs: [minimalJasprCatalog()]);
  });

  tearDown(() => conversation.dispose());

  group('GenUiConversation.receive', () {
    test('collects the prose and the surfaces of a reply', () async {
      final reply = conversation.receive(Stream.fromIterable(greetingReply()));
      await reply.done;

      expect(reply.text, 'Here you go.\n\n');
      expect(reply.surfaces.map((s) => s.id), ['s1']);
      expect(reply.isComplete, isTrue);
      expect(reply.failure, isNull);
      expect(reply.errors, isEmpty);
      expect(reply.isEmpty, isFalse);
    });

    test('fills in as the stream arrives, notifying each time', () async {
      final chunks = StreamController<String>();
      final reply = conversation.receive(chunks.stream);
      var notifications = 0;
      reply.addListener(() => notifications++);

      expect(reply.text, isEmpty);
      expect(reply.isComplete, isFalse);

      chunks.add('Here ');
      await Future<void>.delayed(Duration.zero);
      expect(reply.text, 'Here ');
      expect(reply.surfaces, isEmpty);

      chunks.add(_encode(createSurface('s1')));
      await Future<void>.delayed(Duration.zero);
      expect(reply.surfaces, hasLength(1));
      expect(reply.isComplete, isFalse);

      await chunks.close();
      await reply.done;
      expect(reply.isComplete, isTrue);
      expect(notifications, 3);
    });

    test('renders a reply\'s surface', () async {
      final reply = conversation.receive(
        Stream.fromIterable(greetingReply(text: 'Rendered')),
      );
      await reply.done;

      final html = stripSurface(
        await renderHtml(Surface(surface: reply.surfaces.single)),
      );

      expect(html, '<p class="a2ui-text a2ui-text--body">Rendered</p>');
    });

    test('reports a reply with neither words nor a surface as empty', () async {
      final reply = conversation.receive(Stream.fromIterable(const []));
      await reply.done;

      expect(reply.isEmpty, isTrue);
    });

    test('lets a later reply revise an earlier surface', () async {
      await conversation.receive(Stream.fromIterable(greetingReply())).done;

      final second = conversation.receive(
        Stream.fromIterable([
          _encode(
            updateComponents('s1', [
              {'id': 'root', 'component': 'Text', 'text': 'Revised'},
            ]),
          ),
        ]),
      );
      await second.done;

      // The surface belongs to the reply that created it.
      expect(second.surfaces, isEmpty);
      expect(second.errors, isEmpty);
      expect(
        conversation.surface('s1')!.componentsModel.get('root')!.properties,
        {'text': 'Revised'},
      );
    });

    test('exposes every surface the model has created', () async {
      await conversation.receive(Stream.fromIterable(greetingReply())).done;
      await conversation
          .receive(Stream.fromIterable(greetingReply(surfaceId: 's2')))
          .done;

      expect(conversation.surfaces.map((s) => s.id), ['s1', 's2']);
      expect(conversation.surface('s2'), isNotNull);
      expect(conversation.surface('nope'), isNull);
    });
  });

  group('GenUiConversation.receiveMessages', () {
    test('applies messages that arrive already parsed', () async {
      final reply = conversation.receiveMessages(
        Stream.fromIterable([
          A2uiMessage.fromJson(createSurface('s1')),
          A2uiMessage.fromJson(
            updateComponents('s1', [
              {'id': 'root', 'component': 'Text', 'text': 'Parsed'},
            ]),
          ),
        ]),
      );
      await reply.done;

      expect(reply.text, isEmpty);
      expect(reply.surfaces.map((s) => s.id), ['s1']);
      expect(reply.surfaces.single.componentsModel.get('root')!.properties, {
        'text': 'Parsed',
      });
    });

    test('retargets and records errors like receive does', () async {
      final reply = conversation.receiveMessages(
        Stream.fromIterable([
          A2uiMessage.fromJson(createSurface('model-chose-this')),
          A2uiMessage.fromJson(createSurface('model-chose-this')),
        ]),
        surfaceId: 'reply0',
      );
      await reply.done;

      expect(reply.surfaces.map((s) => s.id), ['reply0']);
      expect(reply.errors.single.surfaceId, 'reply0');
    });

    test('a failed message stream is a failure', () async {
      final reply = conversation.receiveMessages(
        Stream<A2uiMessage>.error(StateError('agent unreachable')),
      );
      await reply.done;

      expect(reply.failure, isA<StateError>());
    });
  });

  group('GenUiConversation.receive with a surfaceId', () {
    test('renders the reply into the surface the app named', () async {
      final reply = conversation.receive(
        Stream.fromIterable(greetingReply(surfaceId: 'model-chose-this')),
        surfaceId: 'reply0',
      );
      await reply.done;

      expect(reply.surfaces.map((s) => s.id), ['reply0']);
      expect(conversation.surface('model-chose-this'), isNull);
    });

    test('redirects data-model updates too', () async {
      final reply = conversation.receive(
        Stream.fromIterable([
          ...greetingReply(),
          _encode(updateDataModel('s1', '/name', 'Ada')),
        ]),
        surfaceId: 'reply0',
      );
      await reply.done;

      expect(reply.errors, isEmpty);
      expect(conversation.surface('reply0')!.dataModel.get('/name'), 'Ada');
    });

    test(
      'stops a model reusing an id from overwriting an earlier reply',
      () async {
        final first = conversation.receive(
          Stream.fromIterable(greetingReply(text: 'first')),
          surfaceId: 'reply0',
        );
        await first.done;

        final second = conversation.receive(
          Stream.fromIterable(greetingReply(text: 'second')),
          surfaceId: 'reply1',
        );
        await second.done;

        expect(second.errors, isEmpty);
        expect(first.surfaces.single.componentsModel.get('root')!.properties, {
          'text': 'first',
        });
        expect(second.surfaces.single.componentsModel.get('root')!.properties, {
          'text': 'second',
        });
      },
    );
  });

  group('GenUiConversation errors', () {
    test('records a message the parser rejects and carries on', () async {
      final errors = <A2uiClientError>[];
      conversation = GenUiConversation(
        catalogs: [minimalJasprCatalog()],
        onError: errors.add,
      );

      final reply = conversation.receive(
        Stream.fromIterable([
          '```json\n{"version":"v0.8","createSurface":{"surfaceId":"s1"}}\n```\n',
          ...greetingReply(),
        ]),
      );
      await reply.done;

      expect(reply.errors, hasLength(1));
      expect(reply.errors.single.code, 'VALIDATION_ERROR');
      expect(reply.errors.single.message, contains('v0.9'));
      expect(errors, reply.errors);
      // The good messages after it still applied.
      expect(reply.surfaces, hasLength(1));
      expect(reply.failure, isNull);
    });

    test('records a surface created twice, naming the surface', () async {
      final reply = conversation.receive(
        Stream.fromIterable([...greetingReply(), _encode(createSurface('s1'))]),
      );
      await reply.done;

      expect(reply.errors.single.code, 'STATE_ERROR');
      expect(reply.errors.single.surfaceId, 's1');
      expect(reply.errors.single.message, contains('already exists'));
    });

    test('records a catalog the app does not have', () async {
      final reply = conversation.receive(
        Stream.fromIterable([
          _encode(createSurface('s1', catalogId: 'https://example.com/nope')),
        ]),
      );
      await reply.done;

      expect(reply.errors.single.code, 'STATE_ERROR');
      expect(reply.errors.single.message, contains('Catalog not found'));
      expect(reply.surfaces, isEmpty);
    });

    test('records an update aimed at a surface that does not exist', () async {
      final reply = conversation.receive(
        Stream.fromIterable([
          _encode(
            updateComponents('ghost', [
              {'id': 'root', 'component': 'Text', 'text': 'x'},
            ]),
          ),
        ]),
        surfaceId: 'reply0',
      );
      await reply.done;

      expect(reply.errors.single.surfaceId, 'reply0');
    });

    test(
      'records a data-model update for a surface that does not exist',
      () async {
        final reply = conversation.receive(
          Stream.fromIterable([_encode(updateDataModel('ghost', '/a', 1))]),
        );
        await reply.done;

        expect(reply.errors.single.code, 'STATE_ERROR');
        expect(reply.errors.single.surfaceId, 'ghost');
      },
    );

    test('a failed stream is a failure, not a model error', () async {
      final reply = conversation.receive(
        Stream<String>.error(StateError('model unavailable')),
      );
      await reply.done;

      expect(reply.isComplete, isTrue);
      expect(reply.failure, isA<StateError>());
      expect(reply.errors, isEmpty);
    });

    test('keeps what arrived before the stream failed', () async {
      final chunks = StreamController<String>();
      final reply = conversation.receive(chunks.stream);

      chunks.add('Partial ');
      chunks.addError(StateError('cut off'));
      await chunks.close();
      await reply.done;

      expect(reply.text, 'Partial ');
      expect(reply.failure, isA<StateError>());
    });
  });

  group('GenUiConversation actions', () {
    test('forwards a generated button\'s action', () async {
      final actions = <A2uiClientAction>[];
      conversation = GenUiConversation(
        catalogs: [minimalJasprCatalog()],
        onAction: actions.add,
      );
      final reply = conversation.receive(Stream.fromIterable(greetingReply()));
      await reply.done;

      await reply.surfaces.single.dispatchAction({
        'event': {'name': 'submit'},
      }, 'root');

      expect(actions.single.name, 'submit');
      expect(actions.single.surfaceId, 's1');
    });

    test('forwards an error a surface raises after its reply', () async {
      final errors = <A2uiClientError>[];
      conversation = GenUiConversation(
        catalogs: [minimalJasprCatalog()],
        onError: errors.add,
      );
      final reply = conversation.receive(Stream.fromIterable(greetingReply()));
      await reply.done;

      await reply.surfaces.single.dispatchError(
        A2uiClientError(code: 'X', surfaceId: 's1', message: 'later'),
      );

      expect(errors.single.message, 'later');
      // Not this reply's mistake: it was already complete.
      expect(reply.errors, isEmpty);
    });

    test('composes the text to send the model for an action', () async {
      final reply = conversation.receive(Stream.fromIterable(greetingReply()));
      await reply.done;
      reply.surfaces.single.dataModel.set('/name', 'Ada');
      final action = A2uiClientAction(
        name: 'submit',
        surfaceId: 's1',
        sourceComponentId: 'root',
        timestamp: DateTime.utc(2026),
        context: const {},
      );

      final lines = conversation.actionText(action).split('\n');

      expect(lines, hasLength(2));
      expect(jsonDecode(lines[0]), a2uiActionMessage(action));
      expect(jsonDecode(lines[1]), conversation.clientDataModel());
    });

    test('sends only the action when no surface asked for its data', () async {
      final action = A2uiClientAction(
        name: 'submit',
        surfaceId: 's1',
        sourceComponentId: 'root',
        timestamp: DateTime.utc(2026),
        context: const {},
      );

      expect(
        jsonDecode(conversation.actionText(action)),
        a2uiActionMessage(action),
      );
    });

    test('reports what the user has entered', () async {
      final reply = conversation.receive(Stream.fromIterable(greetingReply()));
      await reply.done;

      expect(conversation.clientDataModel(), {
        'version': 'v0.9',
        'surfaces': {'s1': <String, Object?>{}},
      });

      reply.surfaces.single.dataModel.set('/name', 'Ada');

      expect(conversation.clientDataModel(), {
        'version': 'v0.9',
        'surfaces': {
          's1': {'name': 'Ada'},
        },
      });
    });
  });

  group('GenUiConversation.dispose', () {
    test('releases the surfaces and stops forwarding', () async {
      final actions = <A2uiClientAction>[];
      final local = GenUiConversation(
        catalogs: [minimalJasprCatalog()],
        onAction: actions.add,
      );
      final reply = local.receive(Stream.fromIterable(greetingReply()));
      await reply.done;
      final surface = reply.surfaces.single;

      local.dispose();

      expect(local.surfaces, isEmpty);
      await surface.dispatchAction({
        'event': {'name': 'submit'},
      }, 'root');
      expect(actions, isEmpty);
    });

    test('a surface deleted by the model is forgotten', () async {
      final reply = conversation.receive(
        Stream.fromIterable([
          ...greetingReply(),
          _encode({
            'version': 'v0.9',
            'deleteSurface': {'surfaceId': 's1'},
          }),
        ]),
      );
      await reply.done;

      expect(conversation.surfaces, isEmpty);
      expect(reply.errors, isEmpty);
    });
  });
}
