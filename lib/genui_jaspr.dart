/// Renders A2UI generative user interfaces in Jaspr.
///
/// The A2UI protocol runtime lives in `package:a2ui_core`, which is pure Dart.
/// It owns the message model, the data model, expression evaluation, and the
/// binder that resolves a component's properties into concrete values. This
/// library supplies the parts that have to know about Jaspr: a renderer for a
/// surface, a catalog of components that emit HTML, and a conversation that
/// turns a model's text stream into surfaces to render.
library;

export 'src/catalog/catalog_extension.dart';
export 'src/catalog/jaspr_component.dart';
export 'src/catalog/minimal_catalog.dart';
export 'src/conversation/client_messages.dart';
export 'src/conversation/gen_ui_conversation.dart';
export 'src/prompt/a2ui_instructions.dart';
export 'src/rendering/signal_builder.dart';
export 'src/rendering/surface.dart';
export 'src/styles.dart';
export 'src/transport/a2ui_parser_transformer.dart';
export 'src/transport/generation_events.dart';
