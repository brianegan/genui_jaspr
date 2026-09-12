import 'package:genui_jaspr/genui_jaspr.dart';

/// The one catalog this app renders with.
///
/// Shared rather than constructed per use, so the styles the page ships, the
/// components the renderer can build, and the protocol the model is told about
/// all come from the same value. Three separate constructions would drift the
/// moment one of them changed catalog.
final appCatalog = MinimalJasprCatalog();
