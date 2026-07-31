## 0.1.0

First release. Renders A2UI generative user interfaces in Jaspr, building on
`a2ui_core` for the protocol runtime.

- `Surface` renders a surface and fills in as messages arrive, with a visible
  placeholder for components the catalog does not implement.
- `minimalJasprCatalog()` renders the five components of the A2UI minimal
  catalog: `Text`, `Row`, `Column`, `Button`, and `TextField`. Schemas and the
  catalog id come from `a2ui_core` unchanged.
- `A2uiTransportAdapter` and `A2uiParserTransformer` turn a model's text stream
  into A2UI messages, buffering across chunk boundaries so a reply renders as it
  arrives.
- `genuiJasprStyles` provides a default appearance against stable class names. A
  surface publishes its theme as CSS custom properties.
- `SignalBuilder` bridges `preact_signals` to Jaspr rebuilds.
- The example app serves a server-rendered shell with the conversation as a
  `@client` component, and calls Gemini through Genkit from a server route.
