import 'dart:async';
import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../support/render.dart';

Map<String, dynamic> createSurface(String id, {String? catalogId}) => {
  'version': 'v0.9',
  'createSurface': {
    'surfaceId': id,
    'catalogId': catalogId ?? MinimalJasprCatalog.catalogId,
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

Map<String, dynamic> deleteSurface(String id) => {
  'version': 'v0.9',
  'deleteSurface': {'surfaceId': id},
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

/// The surfaces a reply opened.
List<SurfaceModel<JasprComponent>> surfacesIn(List<GenUiEvent> events) =>
    events.whereType<GenUiSurface>().map((e) => e.surface).toList();

/// The prose a reply wrote.
String textOf(List<GenUiEvent> events) =>
    events.whereType<GenUiText>().map((e) => e.text).join();

/// The mistakes a reply made.
List<A2uiClientError> errorsIn(List<GenUiEvent> events) =>
    events.whereType<GenUiError>().map((e) => e.error).toList();

A2uiClientAction submit() => A2uiClientAction(
  name: 'submit',
  surfaceId: 's1',
  sourceComponentId: 'root',
  timestamp: DateTime.utc(2026),
  context: const {},
);

/// Lets stream listeners run.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late GenUiConversation conversation;

  setUp(() {
    conversation = GenUiConversation(catalogs: [MinimalJasprCatalog()]);
  });

  tearDown(() => conversation.dispose());

  group('GenUiConversation.receive', () {
    test('reports the prose and the surfaces of a reply, in order', () async {
      final events = await conversation
          .receive(Stream.fromIterable(greetingReply()))
          .toList();

      expect(textOf(events), 'Here you go.\n\n');
      expect(surfacesIn(events).map((s) => s.id), ['s1']);
      expect(errorsIn(events), isEmpty);
      // The surface is reported once, when it is opened, before it is filled.
      expect(events.map((e) => e.runtimeType), [GenUiText, GenUiSurface]);
    });

    test('reports events as the stream arrives', () async {
      final chunks = StreamController<String>();
      final received = <GenUiEvent>[];
      var done = false;
      conversation
          .receive(chunks.stream)
          .listen(received.add, onDone: () => done = true);

      chunks.add('Here ');
      await settle();
      expect(received, [isA<GenUiText>()]);

      chunks.add(_encode(createSurface('s1')));
      await settle();
      expect(received.last, isA<GenUiSurface>());
      expect(done, isFalse);

      await chunks.close();
      await settle();
      expect(done, isTrue);
    });

    test('does nothing until it is listened to', () async {
      final stream = conversation.receive(Stream.fromIterable(greetingReply()));
      await settle();
      expect(conversation.surfaces, isEmpty);

      await stream.drain<void>();
      expect(conversation.surfaces, hasLength(1));
    });

    test("renders a reply's surface", () async {
      final events = await conversation
          .receive(Stream.fromIterable(greetingReply(text: 'Rendered')))
          .toList();

      final html = stripSurface(
        await renderHtml(Surface(surface: surfacesIn(events).single)),
      );

      expect(html, '<p class="a2ui-text a2ui-text--body">Rendered</p>');
    });

    test('lets a later reply revise an earlier surface', () async {
      await conversation
          .receive(Stream.fromIterable(greetingReply()))
          .drain<void>();

      final second = await conversation
          .receive(
            Stream.fromIterable([
              _encode(
                updateComponents('s1', [
                  {'id': 'root', 'component': 'Text', 'text': 'Revised'},
                ]),
              ),
            ]),
          )
          .toList();

      // The surface belongs to the reply that opened it.
      expect(second, isEmpty);
      expect(
        conversation.surface('s1')!.componentsModel.get('root')!.properties,
        {'text': 'Revised'},
      );
    });

    test('exposes every surface the model has created', () async {
      await conversation
          .receive(Stream.fromIterable(greetingReply()))
          .drain<void>();
      await conversation
          .receive(Stream.fromIterable(greetingReply(surfaceId: 's2')))
          .drain<void>();

      expect(conversation.surfaces.map((s) => s.id), ['s1', 's2']);
      expect(conversation.surface('s2'), isNotNull);
      expect(conversation.surface('nope'), isNull);
    });

    test('pauses and resumes the source with its own subscription', () async {
      final chunks = StreamController<String>();
      final received = <GenUiEvent>[];
      final subscription =
          conversation.receive(chunks.stream).listen(received.add)..pause();
      chunks.add('Waiting ');
      await settle();
      expect(received, isEmpty);

      subscription.resume();
      await settle();
      expect(received, hasLength(1));

      await subscription.cancel();
      await chunks.close();
    });
  });

  group('GenUiConversation.receiveMessages', () {
    test('applies messages that arrive already parsed', () async {
      final events = await conversation
          .receiveMessages(
            Stream.fromIterable([
              A2uiMessage.fromJson(createSurface('s1')),
              A2uiMessage.fromJson(
                updateComponents('s1', [
                  {'id': 'root', 'component': 'Text', 'text': 'Parsed'},
                ]),
              ),
            ]),
          )
          .toList();

      expect(textOf(events), isEmpty);
      expect(surfacesIn(events).map((s) => s.id), ['s1']);
      expect(
        surfacesIn(events).single.componentsModel.get('root')!.properties,
        {'text': 'Parsed'},
      );
    });

    test('retargets and reports errors like receive does', () async {
      final events = await conversation
          .receiveMessages(
            Stream.fromIterable([
              A2uiMessage.fromJson(createSurface('model-chose-this')),
              A2uiMessage.fromJson(createSurface('model-chose-this')),
            ]),
            surfaceId: 'reply0',
          )
          .toList();

      expect(surfacesIn(events).map((s) => s.id), ['reply0']);
      expect(errorsIn(events).single.surfaceId, 'reply0');
    });

    test('a failed message stream fails the reply', () {
      expect(
        conversation
            .receiveMessages(
              Stream<A2uiMessage>.error(StateError('agent unreachable')),
            )
            .toList(),
        throwsStateError,
      );
    });
  });

  group('GenUiConversation.receive with a surfaceId', () {
    test('renders the reply into the surface the app named', () async {
      final events = await conversation
          .receive(
            Stream.fromIterable(greetingReply(surfaceId: 'model-chose-this')),
            surfaceId: 'reply0',
          )
          .toList();

      expect(surfacesIn(events).map((s) => s.id), ['reply0']);
      expect(conversation.surface('model-chose-this'), isNull);
    });

    test('redirects data-model updates too', () async {
      final events = await conversation
          .receive(
            Stream.fromIterable([
              ...greetingReply(),
              _encode(updateDataModel('s1', '/name', 'Ada')),
            ]),
            surfaceId: 'reply0',
          )
          .toList();

      expect(errorsIn(events), isEmpty);
      expect(conversation.surface('reply0')!.dataModel.get('/name'), 'Ada');
    });

    test(
      'stops a model reusing an id from overwriting an earlier reply',
      () async {
        final first = await conversation
            .receive(
              Stream.fromIterable(greetingReply(text: 'first')),
              surfaceId: 'reply0',
            )
            .toList();
        final second = await conversation
            .receive(
              Stream.fromIterable(greetingReply(text: 'second')),
              surfaceId: 'reply1',
            )
            .toList();

        expect(errorsIn(second), isEmpty);
        expect(
          surfacesIn(first).single.componentsModel.get('root')!.properties,
          {'text': 'first'},
        );
        expect(
          surfacesIn(second).single.componentsModel.get('root')!.properties,
          {'text': 'second'},
        );
      },
    );
  });

  group('GenUiConversation errors', () {
    test('reports a message the parser rejects and carries on', () async {
      final reported = <A2uiClientError>[];
      conversation = GenUiConversation(
        catalogs: [MinimalJasprCatalog()],
        onError: reported.add,
      );

      const oldVersionMessage =
          '```json\n{"version":"v0.8","createSurface":{"surfaceId":"s1"}}\n'
          '```\n';
      final events = await conversation
          .receive(
            Stream.fromIterable([oldVersionMessage, ...greetingReply()]),
          )
          .toList();
      await settle();

      final errors = errorsIn(events);
      expect(errors, hasLength(1));
      expect(errors.single.code, 'VALIDATION_ERROR');
      expect(errors.single.message, contains('v0.9'));
      expect(reported, errors);
      // The good messages after it still applied.
      expect(surfacesIn(events), hasLength(1));
    });

    test('reports a surface created twice, naming the surface', () async {
      final events = await conversation
          .receive(
            Stream.fromIterable([
              ...greetingReply(),
              _encode(createSurface('s1')),
            ]),
          )
          .toList();

      final error = errorsIn(events).single;
      expect(error.code, 'STATE_ERROR');
      expect(error.surfaceId, 's1');
      expect(error.message, contains('already exists'));
    });

    test('reports a catalog the app does not have', () async {
      final events = await conversation
          .receive(
            Stream.fromIterable([
              _encode(
                createSurface('s1', catalogId: 'https://example.com/nope'),
              ),
            ]),
          )
          .toList();

      expect(errorsIn(events).single.message, contains('Catalog not found'));
      expect(surfacesIn(events), isEmpty);
    });

    test('reports an update aimed at a surface that does not exist', () async {
      final events = await conversation
          .receive(
            Stream.fromIterable([
              _encode(
                updateComponents('ghost', [
                  {'id': 'root', 'component': 'Text', 'text': 'x'},
                ]),
              ),
            ]),
            surfaceId: 'reply0',
          )
          .toList();

      expect(errorsIn(events).single.surfaceId, 'reply0');
    });

    test(
      'reports a data-model update for a surface that does not exist',
      () async {
        final events = await conversation
            .receive(
              Stream.fromIterable([_encode(updateDataModel('ghost', '/a', 1))]),
            )
            .toList();

        expect(errorsIn(events).single.code, 'STATE_ERROR');
        expect(errorsIn(events).single.surfaceId, 'ghost');
      },
    );

    test('a failed model call is an error on the stream, not a mistake', () {
      final reported = <A2uiClientError>[];
      conversation = GenUiConversation(
        catalogs: [MinimalJasprCatalog()],
        onError: reported.add,
      );

      expect(
        conversation
            .receive(Stream<String>.error(StateError('model unavailable')))
            .toList(),
        throwsStateError,
      );
      expect(reported, isEmpty);
    });

    test('delivers what arrived before the stream failed', () async {
      final chunks = StreamController<String>();
      final received = <GenUiEvent>[];
      Object? failure;
      conversation
          .receive(chunks.stream)
          .listen(received.add, onError: (Object e) => failure = e);

      chunks
        ..add('Partial ')
        ..addError(StateError('cut off'));
      await chunks.close();
      await settle();

      expect(textOf(received), 'Partial ');
      expect(failure, isA<StateError>());
    });
  });

  group('GenUiConversation actions', () {
    test("reports a generated button's action", () async {
      final actions = <A2uiClientAction>[];
      conversation = GenUiConversation(
        catalogs: [MinimalJasprCatalog()],
        onAction: actions.add,
      );
      final events = await conversation
          .receive(Stream.fromIterable(greetingReply()))
          .toList();

      await surfacesIn(events).single.dispatchAction({
        'event': {'name': 'submit'},
      }, 'root');
      await settle();

      expect(actions.single.name, 'submit');
      expect(actions.single.surfaceId, 's1');
    });

    test('reports an error a surface raises after its reply', () async {
      final errors = <A2uiClientError>[];
      conversation = GenUiConversation(
        catalogs: [MinimalJasprCatalog()],
        onError: errors.add,
      );
      final events = await conversation
          .receive(Stream.fromIterable(greetingReply()))
          .toList();

      await surfacesIn(events).single.dispatchError(
        A2uiClientError(code: 'X', surfaceId: 's1', message: 'later'),
      );
      await settle();

      expect(errors.single.message, 'later');
    });

    test('composes the text to send the model for an action', () async {
      final events = await conversation
          .receive(Stream.fromIterable(greetingReply()))
          .toList();
      surfacesIn(events).single.dataModel.set('/name', 'Ada');

      final lines = conversation.actionText(submit()).split('\n');

      expect(lines, hasLength(2));
      expect(jsonDecode(lines[0]), a2uiActionMessage(submit()));
      expect(jsonDecode(lines[1]), conversation.clientDataModel());
    });

    test('sends only the action when no surface asked for its data', () {
      expect(
        jsonDecode(conversation.actionText(submit())),
        a2uiActionMessage(submit()),
      );
    });

    test('reports what the user has entered', () async {
      final events = await conversation
          .receive(Stream.fromIterable(greetingReply()))
          .toList();

      expect(conversation.clientDataModel(), {
        'version': 'v0.9',
        'surfaces': {'s1': <String, Object?>{}},
      });

      surfacesIn(events).single.dataModel.set('/name', 'Ada');

      expect(conversation.clientDataModel(), {
        'version': 'v0.9',
        'surfaces': {
          's1': {'name': 'Ada'},
        },
      });
    });
  });

  group('GenUiConversation surfaces deleted by the model', () {
    test('are reported by id and forgotten', () async {
      final deleted = <String>[];
      conversation = GenUiConversation(
        catalogs: [MinimalJasprCatalog()],
        onSurfaceDeleted: deleted.add,
      );

      await conversation
          .receive(
            Stream.fromIterable([
              ...greetingReply(),
              _encode(deleteSurface('s1')),
            ]),
          )
          .drain<void>();
      await settle();

      expect(deleted, ['s1']);
      expect(conversation.surfaces, isEmpty);
    });

    test('render their placeholder once rebuilt', () async {
      final events = await conversation
          .receive(Stream.fromIterable(greetingReply()))
          .toList();
      final surface = surfacesIn(events).single;
      await conversation
          .receive(Stream.fromIterable([_encode(deleteSurface('s1'))]))
          .drain<void>();

      final html = stripSurface(
        await renderHtml(
          Surface(
            surface: surface,
            placeholder: (context) => const Component.text('gone'),
          ),
        ),
      );

      expect(html, 'gone');
    });
  });

  group('GenUiConversation.dispose', () {
    test('releases the surfaces and stops calling back', () async {
      final actions = <A2uiClientAction>[];
      final local = GenUiConversation(
        catalogs: [MinimalJasprCatalog()],
        onAction: actions.add,
      );
      final events = await local
          .receive(Stream.fromIterable(greetingReply()))
          .toList();
      final surface = surfacesIn(events).single;

      local.dispose();

      expect(local.surfaces, isEmpty);
      await surface.dispatchAction({
        'event': {'name': 'submit'},
      }, 'root');
      expect(actions, isEmpty);
    });
  });
}
