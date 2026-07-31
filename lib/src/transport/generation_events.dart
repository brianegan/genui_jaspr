import 'package:a2ui_core/a2ui_core.dart';

/// Something a model produced, once the parser has worked out which kind it is.
sealed class GenerationEvent {
  const GenerationEvent();
}

/// Prose the model wrote for the user to read.
final class TextEvent extends GenerationEvent {
  const TextEvent(this.text);

  /// The text, with protocol markers removed.
  final String text;
}

/// An A2UI message the model produced to change the UI.
final class A2uiMessageEvent extends GenerationEvent {
  const A2uiMessageEvent(this.message);

  final A2uiMessage message;
}

/// Thrown when a payload was clearly meant as an A2UI message but could not be
/// understood.
///
/// Distinguishing this from prose matters: a model that sends a malformed
/// message should be corrected, whereas a model that happens to write a JSON
/// snippet in conversation should just be shown.
class A2uiValidationException implements Exception {
  A2uiValidationException(this.message, {this.json, this.cause});

  /// What was wrong.
  final String message;

  /// The payload that could not be parsed.
  final Object? json;

  /// The error underneath this one, when there was one.
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer('A2uiValidationException: $message');
    if (cause != null) buffer.write('\nCause: $cause');
    if (json != null) buffer.write('\nJSON: $json');
    return buffer.toString();
  }
}
