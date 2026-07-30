import 'package:a2ui_core/a2ui_core.dart';

/// Turns a user's interaction with a generated surface into a prompt.
///
/// The model has no view of the page, so an interaction has to be described to
/// it: which event fired, any context the model attached to that action when it
/// built the UI, and whatever the user had entered, which the surface's data
/// model already holds because bound inputs write straight to it.
String describeInteraction(A2uiClientAction action, Object? surfaceData) {
  final description = StringBuffer('The user triggered "${action.name}".');
  if (action.context.isNotEmpty) {
    description.write(' Context: ${action.context}.');
  }
  if (surfaceData is Map && surfaceData.isNotEmpty) {
    description.write(' They had entered: $surfaceData.');
  }
  return description.toString();
}

/// What the transcript shows for an interaction, as opposed to what the model is
/// told.
String summariseInteraction(A2uiClientAction action) =>
    'Submitted "${action.name}"';

/// Rewrites [message] to target [surfaceId].
///
/// Each reply renders into a surface this app names, not one the model invents,
/// so a model that reuses an id across turns cannot overwrite an earlier answer.
/// Every message body carries its own `surfaceId`, so the rewrite is the same
/// regardless of which of the four kinds it is.
A2uiMessage retargetSurface(A2uiMessage message, String surfaceId) {
  final Map<String, dynamic> json = message.toJson();
  for (final Object? body in json.values) {
    if (body is Map<String, dynamic> && body.containsKey('surfaceId')) {
      body['surfaceId'] = surfaceId;
    }
  }
  return A2uiMessage.fromJson(json);
}
