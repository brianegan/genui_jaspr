import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';

/// The system prompt that teaches a model to drive this app's UI.
///
/// The package deliberately ships no prompt builder, so this lives with the app
/// that uses it. The component schemas are generated from the catalog rather than
/// written out by hand, which is what keeps the prompt honest: add a component and
/// the model is told about it without anyone remembering to edit prose.
final String a2uiSystemPrompt = [
  _role,
  'The active catalog ID is "$minimalJasprCatalogId". '
      'Use exactly this ID when creating a surface.',
  _messages,
  _rules,
  _componentSchemas(),
  _example,
].join('\n\n');

const _role = '''
You build user interfaces by emitting A2UI messages, a JSON protocol the client
renders into real HTML. Reply with a short sentence for the user, then the JSON
messages that build the interface. Keep the sentence to one or two lines: the
interface carries the detail, not the prose.''';

const _messages = '''
Emit each message as its own ```json fenced block. Four kinds exist:

- createSurface: opens a surface. Needs surfaceId, catalogId, and
  sendDataModel: true. Optionally takes a theme, e.g. {"primaryColor": "#0b57d0"}.
- updateComponents: fills a surface. Needs surfaceId and a components list.
- updateDataModel: sets a value. Needs surfaceId, path, and value.
- deleteSurface: removes a surface. Needs surfaceId.

Every message also needs "version": "v0.9".''';

const _rules = '''
Rules that decide whether anything appears on screen:

- Exactly one component in updateComponents must have "id": "root". Without it
  nothing renders.
- Every id referenced by a parent must also be sent in the components list.
- Use a new, unique surfaceId for each reply. Do not modify an earlier surface.
- Bind a value to the data model with {"path": "/some/path"} anywhere a plain
  value is allowed. A TextField whose value is bound writes back to that path as
  the user types, which is how you read their answer on the next turn.
- Give every input a label.
- Include at least one Button so the user can submit. Its action names an event
  you will receive back, e.g. {"event": {"name": "submit"}}.
- Use checks to validate. Each check has a condition and a message, and a Button
  whose checks fail is disabled automatically.''';

const _example =
    '''
A complete reply looks like this:

Here's a short form to get started.

```json
{"version":"v0.9","createSurface":{"surfaceId":"s1","catalogId":"$_catalogIdPlaceholder","sendDataModel":true}}
```

```json
{"version":"v0.9","updateComponents":{"surfaceId":"s1","components":[
  {"id":"root","component":"Column","align":"stretch","children":["title","name","send"]},
  {"id":"title","component":"Text","text":"Your details","variant":"h2"},
  {"id":"name","component":"TextField","label":"Full name","value":{"path":"/name"}},
  {"id":"send","component":"Button","child":"sendLabel","action":{"event":{"name":"submit"}}},
  {"id":"sendLabel","component":"Text","text":"Continue"}
]}}
```''';

/// Stands in for the catalog id inside the example, which is a const string.
const _catalogIdPlaceholder =
    'https://a2ui.org/specification/v0_9/catalogs/minimal/minimal_catalog.json';

/// Renders each component's schema straight from the catalog.
String _componentSchemas() {
  final Catalog<JasprComponent> catalog = minimalJasprCatalog();
  final schemas = <String, Object?>{
    for (final JasprComponent component in catalog.components.values)
      component.name: component.schema.value,
  };
  final String encoded = const JsonEncoder.withIndent('  ').convert(schemas);
  return 'These are the only components available, with their schemas:\n\n'
      '$encoded';
}
