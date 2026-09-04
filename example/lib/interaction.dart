import 'package:a2ui_core/a2ui_core.dart';

/// What the transcript shows for an interaction, as opposed to what the model is
/// told, which is `GenUiConversation.actionText`.
String summariseInteraction(A2uiClientAction action) =>
    'Submitted "${action.name}"';
