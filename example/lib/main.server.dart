import 'package:jaspr/server.dart';

import 'app.dart';
import 'main.server.options.dart';
import 'server/chat_route.dart';
import 'server/genkit_reply.dart';

/// Serves the page, and the route the browser streams model replies from.
///
/// The model is only ever called from here, so the API key stays on the server
/// and only generated text crosses the wire.
void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  final Handler chat = chatRoute(genkitReply());

  // Everything except the chat route falls through to the rendered page.
  ServerApp.addMiddleware(
    (Handler inner) => (Request request) async {
      if (request.url.path == 'api/chat') return chat(request);
      return inner(request);
    },
  );

  runApp(
    Document(
      title: 'GenUI for Jaspr',
      lang: 'en',
      styles: appStyles,
      body: const App(),
    ),
  );
}
