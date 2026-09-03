import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr_example/interaction.dart';
import 'package:test/test.dart';

void main() {
  group('summariseInteraction', () {
    test('stays short', () {
      final action = A2uiClientAction(
        name: 'signUp',
        surfaceId: 'reply0',
        sourceComponentId: 'send',
        timestamp: DateTime.utc(2026),
        context: const {},
      );

      expect(summariseInteraction(action), 'Submitted "signUp"');
    });
  });
}
