import 'package:a2ui_core/a2ui_core.dart';
import 'package:genkit/client.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:universal_web/web.dart' as web;

import 'interaction.dart';

/// One entry in the transcript.
class Turn {
  Turn.user(this.text) : surface = null, fromUser = true;
  Turn.model(this.text, this.surface) : fromUser = false;

  final String text;

  /// The surface this turn generated, if it generated one.
  final SurfaceModel<JasprComponent>? surface;

  final bool fromUser;
}

/// Streams the model's reply to [prompt] as text chunks.
///
/// The seam [ChatView] is tested at: production passes the genkit client,
/// a browser test passes a fake and never touches the network.
typedef SendPrompt = Stream<String> Function(String prompt);

/// The conversation, running entirely in the browser.
///
/// A generated surface only exists once the model has answered something the user
/// did, so there is nothing for the server to pre-render. The server's job is to
/// hold the API key and stream text back, which it does through the route this
/// talks to.
///
/// A `@client` component's parameters must serialize for hydration, so the
/// injectable send function cannot live here. This stays the param-free client
/// boundary and [ChatView] carries the seam.
@client
class Chat extends StatefulComponent {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  /// Calls the server route. Genkit's client handles the frames and surfaces a
  /// server-side failure as an error on the stream.
  ///
  /// The two decoder closures run only against a live server, which no test
  /// provides, so they are ignored for coverage.
  final _chat = defineRemoteAction<String, String, String, void>(
    url: '/api/chat',
    fromStreamChunk: (json) => json as String, // coverage:ignore-line
    fromResponse: (json) => json as String, // coverage:ignore-line
  );

  @override
  Component build(BuildContext context) {
    return ChatView(send: (prompt) => _chat.stream(input: prompt));
  }
}

/// The conversation UI, talking to the model only through [send].
class ChatView extends StatefulComponent {
  const ChatView({required this.send, super.key});

  final SendPrompt send;

  @override
  State<ChatView> createState() => _ChatViewState();
}

// The `coverage:ignore-line` markers below mark dart2js source-map artifacts:
// the browser suite executes those lines, but dart2js folds them into a
// neighbouring line in its source map, so no platform's line table can
// attribute them. Editing this file can shift which lines fold; move the
// marker with the line. tool/merge_lcov.dart explains how the VM and Chrome
// reports combine.
class _ChatViewState extends State<ChatView> {
  late final MessageProcessor<JasprComponent> _processor;

  final List<Turn> _turns = [];
  String _draft = '';
  bool _busy = false;
  String? _error;

  /// Surfaces are numbered so each reply renders into its own.
  int _replies = 0;

  /// An empty element after the last turn, scrolled into view to follow the
  /// conversation.
  ///
  /// Scrolling to an anchor rather than to a computed offset means the browser
  /// works out the distance, which matters here because a generated surface's
  /// height is not known until it has been laid out.
  final _end = GlobalNodeKey<web.Element>();

  @override
  void initState() {
    super.initState();
    _processor = MessageProcessor<JasprComponent>(
      catalogs: [minimalJasprCatalog()],
      onAction: _onSurfaceAction,
    );
  }

  /// A button in a generated surface was pressed.
  ///
  /// The interaction becomes the next thing the model hears, along with whatever
  /// the user typed into that surface, which the data model already holds.
  void _onSurfaceAction(A2uiClientAction action) {
    final SurfaceModel<JasprComponent>? surface = _processor.groupModel
        .getSurface(action.surfaceId);
    _send(
      describeInteraction(action, surface?.dataModel.get('/')),
      show: summariseInteraction(action), // coverage:ignore-line
    );
  }

  Future<void> _sendDraft() async {
    final String text = _draft.trim();
    if (text.isEmpty || _busy) return;
    setState(() => _draft = '');
    await _send(text, show: text);
  }

  Future<void> _send(String prompt, {required String show}) async {
    if (_busy) return;

    final adapter = A2uiTransportAdapter(); // coverage:ignore-line
    final surfaceId = 'reply${_replies++}'; // coverage:ignore-line
    final prose = StringBuffer(); // coverage:ignore-line

    setState(() {
      _busy = true;
      _error = null;
      _turns.add(Turn.user(show));
    });

    // Each reply targets a surface named here rather than one the model invents,
    // so a model that reuses an id cannot overwrite an earlier answer.
    adapter.incomingMessages.listen((message) {
      try {
        _processor.processMessages([retargetSurface(message, surfaceId)]);
      } catch (error) {
        setState(() => _error = '$error');
      }
    });
    adapter.incomingText.listen((chunk) {
      prose.write(chunk);
      setState(() {});
    });

    try {
      await for (final String chunk in component.send(prompt)) {
        adapter.addChunk(chunk); // coverage:ignore-line
      }
      await adapter.flush();
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      adapter.dispose(); // coverage:ignore-line
      final SurfaceModel<JasprComponent>? surface = _processor.groupModel
          .getSurface(surfaceId); // coverage:ignore-line
      final String text = prose.toString().trim();
      setState(() {
        _busy = false;
        // A turn with neither words nor a surface would render as an empty
        // bubble, which is what a failed request used to leave behind.
        if (text.isNotEmpty || surface != null) {
          _turns.add(Turn.model(text, surface));
        }
      });
    }
  }

  /// Follows the conversation after the next frame is laid out.
  ///
  /// Reading the DOM before then would measure the previous content. The key
  /// yields null when there is no browser, so this is inert during server
  /// rendering.
  void _followConversation(BuildContext context) {
    context.binding.addPostFrameCallback(() {
      _end.currentNode?.scrollIntoView(
        // coverage:ignore-start
        web.ScrollIntoViewOptions(behavior: 'smooth', block: 'end'),
        // coverage:ignore-end
      );
    });
  }

  @override
  Component build(BuildContext context) {
    _followConversation(context);
    return div([
      div([
        for (final turn in _turns) _turnView(turn),
        if (_busy) p([Component.text('Thinking...')], classes: 'status'),
        if (_error != null)
          p(
            [Component.text(_error!)],
            classes: 'error',
            attributes: const {'role': 'alert'},
          ),
        div([], key: _end, classes: 'transcript__end'),
      ], classes: 'transcript'),
      _composer(),
    ], classes: 'chat');
  }

  // coverage:ignore-start
  Component _turnView(Turn turn) {
    // coverage:ignore-end
    return div([
      if (turn.text.isNotEmpty) p([Component.text(turn.text)]),
      if (turn.surface != null) Surface(surface: turn.surface!),
    ], classes: turn.fromUser ? 'turn turn--user' : 'turn turn--model');
  }

  /// The prompt bar, pinned to the bottom of the viewport.
  ///
  /// It is a real form with a submit button, which is what makes Enter send the
  /// prompt. The browser's implicit submission handles the keystroke, so there is
  /// no key handling here, and clicking the button takes the same path.
  Component _composer() {
    return div([
      form(
        [
          input<String>(
            type: InputType.text,
            value: _draft,
            disabled: _busy,
            attributes: const {
              'placeholder': 'Ask for a form, a quiz, a checklist',
              'autocomplete': 'off',
            },
            onInput: (value) => _draft = value,
            onChange: (value) => _draft = value,
          ),
          button(
            [Component.text('Send')],
            type: ButtonType.submit,
            disabled: _busy,
          ),
        ],
        classes: 'composer__inner',
        events: {
          'submit': (event) {
            // Without this the browser navigates and the page reloads.
            event.preventDefault();
            _sendDraft();
          },
        },
      ),
    ], classes: 'composer');
  }
}
