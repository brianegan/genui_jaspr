import 'package:genkit/genkit.dart';
import 'package:genkit_shelf/genkit_shelf.dart';
import 'package:shelf/shelf.dart';

import '../prompt.dart';

/// The path the browser reaches the agent at. Two more hang off it, for reading
/// a session back and for aborting a turn, which the Genkit client expects.
const String chatPath = 'api/chat';

/// The agent that answers the user, with the conversation's history.
///
/// A Genkit agent keeps each session's messages in its [store] and sends them
/// to the model on every turn, so the model remembers the UI it built when the
/// user's interaction with it comes back. The browser holds only a session id.
/// In memory here: sessions last as long as the process. `FileSessionStore` from
/// `package:genkit/io.dart` is the one-line change to survive a restart.
///
/// The [model] is a parameter so a test can stand in for Gemini with one that
/// replays a canned reply.
Agent<dynamic> chatAgent(
  Genkit ai, {
  required ModelRef<dynamic> model,
  SessionStore? store,
}) {
  return ai.defineAgent(
    name: 'chat',
    model: model,
    system: a2uiSystemPrompt,
    store: store ?? InMemorySessionStore(),
  );
}

/// Serves [agent] over HTTP in the shape Genkit's client speaks.
///
/// The wire format, streaming, and the mapping of failures onto HTTP statuses
/// all come from `genkit_shelf`, so nothing here has to know how a frame looks.
/// Mount it in front of the page: `main.server.dart` routes everything under
/// [chatPath] here and lets the rest fall through to the rendered app.
Handler chatHandler(Agent<dynamic> agent) {
  final Handler turn = shelfHandler(agent.action);
  final Handler snapshot = shelfHandler(agent.getSnapshotDataAction);
  final Handler abort = shelfHandler(agent.abortAgentAction);

  return (Request request) => switch (request.url.path) {
    chatPath => turn(request),
    '$chatPath/getSnapshot' => snapshot(request),
    '$chatPath/abort' => abort(request),
    _ => Response.notFound('No such route.'),
  };
}
