# genui_jaspr

A model replies with [A2UI](https://a2ui.org) messages instead of plain text, and
your web app renders them as real HTML. Headings are headings, inputs are inputs,
and the browser handles keyboards, validation, and focus, without shipping
Flutter web.

This is the [Jaspr](https://jaspr.site) counterpart to Flutter's
[`genui`](https://github.com/flutter/genui/tree/main/packages/genui). It renders
the same protocol to a different target.

## What it gives you

The protocol runtime lives in
[`a2ui_core`](https://pub.dev/packages/a2ui_core), which is pure Dart and handles
the message model, data model, expression evaluation, and property binding. This
package adds the Jaspr-specific parts: a surface renderer, a catalog of components
that emit HTML, a transport adapter that turns a model's text stream into A2UI
messages, and a default stylesheet you can use or replace.

There is no prompt builder in the package. The system prompt that teaches a model
this protocol lives in the app, and `example/lib/prompt.dart` is a working one
you can copy. It generates the component schemas from the catalog rather than
restating them, which is worth keeping if you adapt it.

Right now it renders the five components from the A2UI minimal catalog: `Text`,
`Row`, `Column`, `Button`, and `TextField`. Their schemas come from `a2ui_core`
unchanged, and the catalog keeps that catalog's own id, so what a model is told
it may send and what this renders cannot drift apart. If the model sends a
component the catalog doesn't know about, you get a visible placeholder instead
of an exception, so one unknown component won't take down the rest of the surface.

## Getting started

Add the dependency:

```yaml
dependencies:
  genui_jaspr: ^0.1.0
```

Then `dart pub get`.

## Usage

```dart
import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';

// One processor per conversation, one catalog.
final processor = MessageProcessor<JasprComponent>(
  catalogs: [minimalJasprCatalog()],
  onAction: (action) {
    // A button in a generated surface was pressed. Tell the model.
  },
);

// Feed the model's output in as it arrives.
final adapter = A2uiTransportAdapter();
adapter.incomingMessages.listen((m) => processor.processMessages([m]));
adapter.incomingText.listen(appendToTranscript);

await for (final chunk in yourModelStream) {
  adapter.addChunk(chunk);
}
await adapter.flush();

// Render it.
Surface(surface: processor.groupModel.getSurface('main')!);
```

Add `genuiJasprStyles` to your app's styles for a default appearance:

```dart
runApp(Document(styles: [...genuiJasprStyles, ...myStyles], body: MyApp()));
```

### Styling

Components emit stable class names, all prefixed `a2ui-`. Two kinds of styling
are kept apart on purpose:

- Layout the model chose per component, such as `justify` and `align`, is written
  inline, because it varies per instance and can't live in a stylesheet.
- Appearance goes through class names, so you can replace `genuiJasprStyles`
  wholesale without touching the renderer.

A surface also publishes the theme from its `createSurface` message as CSS custom
properties on the root element, kebab-cased and `--a2ui-` prefixed. So
`{"primaryColor": "#0b57d0"}` arrives as `--a2ui-primary-color`, and that's how
your stylesheet reacts to a colour the model picked at runtime.

### Server rendering

The renderer imports no `dart:html` or `dart:js_interop`, so it compiles on the
server. That said, a generated surface can't be server-rendered in any useful way,
because it only exists once the model has answered something the user did. Render
the shell on the server and let a `@client` component own the conversation. That's
what the example does.

## Running the example

The example is a Jaspr app with a server-rendered shell, the chat running as a
`@client` component, and the model call behind a server route so the API key
never reaches the browser. It talks to Gemini through
[Genkit](https://pub.dev/packages/genkit).

```sh
dart pub global activate jaspr_cli
export GEMINI_API_KEY=...              # or GOOGLE_API_KEY
cd example
dart run build_runner build            # generates the client and server options
jaspr serve
```

Open http://localhost:8080 and ask for something: "a signup form", "a
three-question quiz", "a checklist for moving house".

It uses `gemini-3.5-flash-lite` by default. Set `MODEL` to try another:

```sh
MODEL=gemini-3.5-flash jaspr serve
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for test commands and development details.
