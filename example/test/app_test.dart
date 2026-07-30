import 'package:genui_jaspr_example/app.dart';
import 'package:genui_jaspr_example/main.server.options.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_test/server_test.dart';

void main() {
  group('the page', () {
    // No API key and no model call: the shell is server-rendered, and the
    // conversation only starts once someone types something.
    setUpAll(() {
      Jaspr.initializeApp(options: defaultServerOptions, useIsolates: false);
    });

    testServer('renders the shell on the server', (tester) async {
      tester.pumpComponent(
        Document(
          title: 'GenUI for Jaspr',
          styles: appStyles,
          body: const App(),
        ),
      );

      final response = await tester.request('/');

      expect(response.statusCode, 200);
      expect(response.document?.querySelector('h1')?.text, 'GenUI for Jaspr');
    });

    testServer('mounts the chat island for the browser to take over', (
      tester,
    ) async {
      tester.pumpComponent(
        Document(
          title: 'GenUI for Jaspr',
          styles: appStyles,
          body: const App(),
        ),
      );

      final response = await tester.request('/');
      final String body = response.body;

      // Jaspr brackets the island in comments so the client knows what to
      // hydrate. Without them the page renders once and never responds to
      // anything, which looks fine in a screenshot and is broken in a browser.
      expect(body, contains('<!--@chat-->'));
      expect(body, contains('<!--/@chat-->'));
      expect(body, contains('main.client.dart.js'));
    });

    testServer('ships the composer so the first turn is possible', (
      tester,
    ) async {
      tester.pumpComponent(
        Document(
          title: 'GenUI for Jaspr',
          styles: appStyles,
          body: const App(),
        ),
      );

      final response = await tester.request('/');

      expect(response.document?.querySelector('.composer input'), isNotNull);
      expect(response.document?.querySelector('.composer button'), isNotNull);
    });

    testServer('includes the catalog styles the surfaces need', (tester) async {
      tester.pumpComponent(
        Document(
          title: 'GenUI for Jaspr',
          styles: appStyles,
          body: const App(),
        ),
      );

      final response = await tester.request('/');

      // The app composes the package's defaults rather than restating them, so a
      // generated surface is styled without extra work.
      expect(response.body, contains('.a2ui-button'));
      expect(response.body, contains('var(--a2ui-primary-color'));
    });
  });
}
