import 'package:a2ui_core/a2ui_core.dart';

import '../transport/generation_events.dart';

/// The client-to-server envelope for an [action], ready to send to a model.
///
/// A2UI v0.9 defines what a client says back when the user does something:
/// `{"version": "v0.9", "action": {...}}`, where the body carries the event
/// name, the surface and component it came from, a timestamp, and the context
/// the model attached to the action when it built the UI. Encode this as JSON
/// and send it as the next turn, or wrap it however your model client prefers.
Map<String, dynamic> a2uiActionMessage(A2uiClientAction action) {
  return {'version': 'v0.9', 'action': action.toJson()};
}

/// The client-to-server envelope for an [error], ready to send to a model.
///
/// Telling the model what went wrong is what lets it correct itself on the
/// next turn. The shape is `{"version": "v0.9", "error": {...}}`, with a code,
/// the surface it concerns, and a message.
Map<String, dynamic> a2uiErrorMessage(A2uiClientError error) {
  return {'version': 'v0.9', 'error': error.toJson()};
}

/// Turns anything thrown while handling A2UI into the error the protocol
/// reports.
///
/// The runtime's own errors carry a code, which is kept. A message the parser
/// could not understand is a validation error. Anything else is an internal
/// error, described by its `toString`.
A2uiClientError clientErrorFrom(Object error, {String surfaceId = ''}) {
  if (error is A2uiClientError) return error;
  return switch (error) {
    A2uiError(:final code, :final message) => A2uiClientError(
      code: code,
      surfaceId: surfaceId,
      message: message,
      details: switch (error) {
        A2uiValidationError(:final details) => details,
        A2uiDataError(:final path?) => {'path': path},
        _ => null,
      },
    ),
    A2uiValidationException(:final message, :final json) => A2uiClientError(
      code: 'VALIDATION_ERROR',
      surfaceId: surfaceId,
      message: message,
      details: json,
    ),
    _ => A2uiClientError(
      code: 'INTERNAL_ERROR',
      surfaceId: surfaceId,
      message: '$error',
    ),
  };
}
