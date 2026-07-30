# genui_jaspr

Render A2UI generative user interfaces in [Jaspr](https://jaspr.site), so a web
app can offer a generative UI without shipping Flutter web.

A model replies with [A2UI](https://a2ui.org) messages instead of prose, and this
package turns them into real HTML: headings are headings, inputs are inputs, and
the browser supplies its own keyboards, validation, and focus handling.

This is the Jaspr counterpart to Flutter's
[`genui`](https://github.com/flutter/genui/tree/main/packages/genui). It renders
the same protocol to a different target.

## How it fits together

The protocol runtime is not reimplemented here. It lives in
[`a2ui_core`](https://pub.dev/packages/a2ui_core), which is pure Dart and owns the
message model, the data model, expression evaluation, and the binder that resolves
a component's properties into concrete values. This package adds the parts that
have to know about Jaspr:

| | |
|---|---|
| `Surface` | renders a surface, and keeps rendering as messages arrive |
| `minimalJasprCatalog()` | the components a model may use, and how each becomes HTML |
| `A2uiTransportAdapter` | turns a model's text stream into A2UI messages |
| `genuiJasprStyles` | a default appearance you can use, extend, or replace |
| `SignalBuilder` | rebuilds a component when the data it reads changes |

## Components

This release renders the five components of the A2UI **minimal catalog**:
`Text`, `Row`, `Column`, `Button`, and `TextField`.

Their schemas come from `a2ui_core` unchanged, and the catalog keeps that
catalog's own id, so what a model is told it may send and what this renders cannot
drift apart.

`Text` becomes `h1` through `h5`, `small`, or `p` depending on its variant.
`Row` and `Column` become flex containers. `Button` dispatches an action and
disables itself while its `checks` fail. `TextField` becomes an `input` or
`textarea`, picks an input type from its variant, and writes what the user types
back to the data model so the next request carries it.

A component the catalog does not implement renders a visible placeholder rather
than throwing, so one unknown component does not take down the surface around it.

### Not included yet

Flutter's `genui` ships a larger basic catalog. `Card`, `Divider`, `List`,
`Image`, `Icon`, `Modal`, `Tabs`, `Slider`, `DateTimeInput`, `ChoicePicker`,
`AudioPlayer`, and `Video` are not here. Most are inexpensive in HTML, so the gap
is scope rather than difficulty.

There is also no prompt builder. The system prompt that teaches a model this
protocol lives in the app, and `example/lib/prompt.dart` is a working one you can
copy. It generates the component schemas from the catalog rather than restating
them, which is worth keeping if you adapt it.

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

Add `genuiJasprStyles` to your app's styles for a usable default appearance:

```dart
runApp(Document(styles: [...genuiJasprStyles, ...myStyles], body: MyApp()));
```

### Styling

Components emit stable class names, all prefixed `a2ui-`. Two kinds of styling
are deliberately kept apart:

- Layout the model chose per component, such as `justify` and `align`, is written
  inline, because it varies per instance and cannot live in a stylesheet.
- Appearance goes through class names, so `genuiJasprStyles` can be replaced
  wholesale without touching the renderer.

A surface publishes the theme from its `createSurface` message as CSS custom
properties on its root element, kebab-cased and `--a2ui-` prefixed. So
`{"primaryColor": "#0b57d0"}` arrives as `--a2ui-primary-color`, which is how a
static stylesheet reacts to a colour the model picked at runtime.

### Rendering on the server

The renderer imports no `dart:html` or `dart:js_interop`, so it compiles on the
server. A generated surface still cannot be server-rendered in any useful way,
because it only exists once the model has answered something the user did. Render
the shell on the server and let a client island own the conversation, which is
what the example does.

## Running the example

The example is a Jaspr app with a server-rendered shell, the chat as a `@client`
island, and the model call behind a server route so the API key never reaches the
browser. It talks to Gemini through [Genkit](https://pub.dev/packages/genkit).

```sh
dart pub global activate jaspr_cli
export GEMINI_API_KEY=...              # or GOOGLE_API_KEY
cd example
dart run build_runner build            # generates the client and server options
jaspr serve
```

Then open http://localhost:8080 and ask for something: "a signup form", "a
three-question quiz", "a checklist for moving house".

The generated `lib/main.*.options.dart` files are committed, so the tests run
without a build step. Re-run `build_runner` after adding or removing an `@client`
component.

## Tests

```sh
dart test                 # the package
cd example && dart test   # the example, including a real HTTP round trip
```

The example's round-trip test starts a real server and drives the real route with
a stand-in for the model, so everything between browser and model is covered
without a key. Only the model call itself needs one.

## Additional information

Issues and pull requests: https://github.com/brianegan/genui_jaspr

- A2UI protocol: https://a2ui.org
- Jaspr: https://jaspr.site
- Flutter's genui: https://github.com/flutter/genui
