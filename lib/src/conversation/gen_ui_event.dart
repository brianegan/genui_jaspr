import 'package:a2ui_core/a2ui_core.dart';

import 'package:genui_jaspr/src/catalog/jaspr_component.dart';

/// Something a model reply produced, as `GenUiConversation.receive` reports it.
///
/// A reply is a stream of these. Prose arrives as [GenUiText], each surface the
/// model opens arrives once as [GenUiSurface], and a message the model got
/// wrong arrives as [GenUiError] while the stream carries on. A failure of the
/// model call itself is an error on the stream, which then ends.
///
/// Later messages in the same reply that fill or change a surface produce no
/// further events: the `SurfaceModel` in a [GenUiSurface] is live, and a
/// `Surface` rendering it follows those changes on its own.
sealed class GenUiEvent {
  const GenUiEvent();
}

/// A piece of the prose the model wrote, exactly as it wrote it.
///
/// Pieces arrive as the stream delivers them, so concatenating them gives back
/// the model's words with their whitespace intact.
final class GenUiText extends GenUiEvent {
  /// Creates a [GenUiText] carrying [text].
  const GenUiText(this.text);

  /// The piece of prose this event carries.
  final String text;
}

/// A surface the model opened in this reply.
///
/// Emitted once, when the surface is created and still empty. Render it with
/// `Surface`, which fills in as the components arrive.
final class GenUiSurface extends GenUiEvent {
  /// Creates a [GenUiSurface] carrying [surface].
  const GenUiSurface(this.surface);

  /// The surface the model opened.
  final SurfaceModel<JasprComponent> surface;
}

/// A message in this reply that could not be applied.
///
/// A malformed message, a surface created twice, or a catalog the app does not
/// have all arrive here rather than ending the reply. The error is in the shape
/// the protocol sends back to a model, see `a2uiErrorMessage`.
final class GenUiError extends GenUiEvent {
  /// Creates a [GenUiError] carrying [error].
  const GenUiError(this.error);

  /// The error, in the shape the protocol sends back to a model.
  final A2uiClientError error;
}
