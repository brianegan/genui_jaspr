import 'package:genui_jaspr/genui_jaspr.dart';

/// The catalog this app renders with by default.
///
/// The Basic catalog, so the demo exercises every component the package ships
/// rather than the five-component minimum. Shared rather than constructed per
/// use, so the styles the page ships, the components the renderer can build,
/// and the protocol the model is told about all come from one value.
final appCatalog = BasicJasprCatalog();
