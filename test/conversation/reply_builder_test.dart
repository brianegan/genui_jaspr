import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_test/jaspr_test.dart';

/// Renders a reply the way a transcript would.
Component transcriptEntry(BuildContext context, Reply reply) => div([
  p([Component.text(reply.text)], classes: 'prose'),
  for (final surface in reply.surfaces) Surface(surface: surface),
  for (final error in reply.errors)
    p([Component.text(error.message)], classes: 'mistake'),
  if (reply.failure != null)
    p([Component.text('failed: ${reply.failure}')], classes: 'failure'),
  if (reply.isComplete) p([Component.text('done')], classes: 'done'),
]);

SurfaceModel<JasprComponent> emptySurface(GenUiConversation conversation) {
  conversation.processor.processMessages([
    A2uiMessage.fromJson({
      'version': 'v0.9',
      'createSurface': {
        'surfaceId': 's1',
        'catalogId': MinimalJasprCatalog.catalogId,
        'sendDataModel': true,
      },
    }),
  ]);
  return conversation.surface('s1')!;
}

void main() {
  late GenUiConversation conversation;

  setUp(() {
    conversation = GenUiConversation(catalogs: [MinimalJasprCatalog()]);
  });

  tearDown(() => conversation.dispose());

  group('ReplyBuilder', () {
    testComponents('starts from an empty reply', (tester) async {
      final events = StreamController<GenUiEvent>();
      tester.pumpComponent(
        ReplyBuilder(events: events.stream, builder: transcriptEntry),
      );

      expect(find.text(''), findsOneComponent);
      expect(find.byType(Surface), findsNothing);
      expect(find.text('done'), findsNothing);
      await events.close();
    });

    testComponents('accumulates prose as it arrives', (tester) async {
      final events = StreamController<GenUiEvent>();
      tester.pumpComponent(
        ReplyBuilder(events: events.stream, builder: transcriptEntry),
      );

      events.add(const GenUiText('Hello, '));
      await tester.pump();
      expect(find.text('Hello, '), findsOneComponent);

      events.add(const GenUiText('world'));
      await tester.pump();
      expect(find.text('Hello, world'), findsOneComponent);
      await events.close();
    });

    testComponents('renders each surface the reply opens', (tester) async {
      final events = StreamController<GenUiEvent>();
      final surface = emptySurface(conversation);
      tester.pumpComponent(
        ReplyBuilder(events: events.stream, builder: transcriptEntry),
      );

      events.add(GenUiSurface(surface));
      await tester.pump();
      expect(find.byType(Surface), findsOneComponent);

      // The surface fills in on its own after it was reported.
      surface.componentsModel.addComponent(
        ComponentModel('root', 'Text', {'text': 'Filled in'}),
      );
      await tester.pump();
      expect(find.text('Filled in'), findsOneComponent);
      await events.close();
    });

    testComponents('lists the mistakes the model made', (tester) async {
      final events = StreamController<GenUiEvent>();
      tester.pumpComponent(
        ReplyBuilder(events: events.stream, builder: transcriptEntry),
      );

      events.add(
        GenUiError(A2uiClientError(code: 'X', surfaceId: 's', message: 'oops')),
      );
      await tester.pump();

      expect(find.text('oops'), findsOneComponent);
      await events.close();
    });

    testComponents('marks the reply complete when the stream ends', (
      tester,
    ) async {
      final events = StreamController<GenUiEvent>();
      tester.pumpComponent(
        ReplyBuilder(events: events.stream, builder: transcriptEntry),
      );

      events.add(const GenUiText('All'));
      await events.close();
      await tester.pump();

      expect(find.text('done'), findsOneComponent);
      expect(find.text('All'), findsOneComponent);
    });

    testComponents('records a failed stream and what came before it', (
      tester,
    ) async {
      final events = StreamController<GenUiEvent>();
      tester.pumpComponent(
        ReplyBuilder(events: events.stream, builder: transcriptEntry),
      );

      events.add(const GenUiText('Partial'));
      events.addError(StateError('cut off'));
      await events.close();
      await tester.pump();

      expect(find.text('Partial'), findsOneComponent);
      expect(find.textContaining('cut off'), findsOneComponent);
      expect(find.text('done'), findsOneComponent);
    });

    testComponents('reports the finished reply once, to onComplete', (
      tester,
    ) async {
      final events = StreamController<GenUiEvent>();
      final completed = <Reply>[];
      tester.pumpComponent(
        ReplyBuilder(
          events: events.stream,
          builder: transcriptEntry,
          onComplete: completed.add,
        ),
      );

      events.add(const GenUiText('Hi'));
      await tester.pump();
      expect(completed, isEmpty);

      await events.close();
      await tester.pump();

      expect(completed, hasLength(1));
      expect(completed.single.text, 'Hi');
      expect(completed.single.isComplete, isTrue);
      expect(completed.single.failure, isNull);
    });

    testComponents('hands onComplete the failure when the stream broke', (
      tester,
    ) async {
      final events = StreamController<GenUiEvent>();
      Reply? completed;
      tester.pumpComponent(
        ReplyBuilder(
          events: events.stream,
          builder: transcriptEntry,
          onComplete: (reply) => completed = reply,
        ),
      );

      events.addError(StateError('cut off'));
      await events.close();
      await tester.pump();

      expect(completed?.failure, isA<StateError>());
      expect(completed?.isEmpty, isTrue);
    });

    testComponents('folds a real reply from the conversation', (tester) async {
      final events = conversation.receive(
        Stream.fromIterable([
          'Here you go.\n\n',
          '```json\n{"version":"v0.9","createSurface":{"surfaceId":"s1",'
              '"catalogId":"${MinimalJasprCatalog.catalogId}","sendDataModel":true}}\n```\n',
          '```json\n{"version":"v0.9","updateComponents":{"surfaceId":"s1",'
              '"components":[{"id":"root","component":"Text","text":"Hi"}]}}\n```\n',
        ]),
      );
      tester.pumpComponent(
        ReplyBuilder(events: events, builder: transcriptEntry),
      );
      await tester.pump();

      expect(find.text('Here you go.\n\n'), findsOneComponent);
      expect(find.text('Hi'), findsOneComponent);
      expect(find.text('done'), findsOneComponent);
    });
  });

  group('Reply', () {
    test('is empty until it has words or a surface', () {
      expect(const Reply.empty().isEmpty, isTrue);
      expect(const Reply.empty().isComplete, isFalse);
      expect(const Reply.empty().failure, isNull);
    });
  });
}
