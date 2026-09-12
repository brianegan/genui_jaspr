import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:test/test.dart';

final _context = DataContext(DataModel(), (_, _, _) => null, '/');

void main() {
  group('OpenUrlFunction', () {
    test('matches the pinned function API', () {
      final function = OpenUrlFunction(opener: (_) {});

      expect(function.name, 'openUrl');
      expect(function.returnType, A2uiReturnType.void_);
      expect(
        function.argumentSchema.value,
        Schema.object(
          properties: {'url': Schema.string(format: 'uri')},
          required: ['url'],
          additionalProperties: false,
        ).value,
      );
    });

    test('passes a parsed URI through the injected opener', () {
      final opened = <Uri>[];
      final function = OpenUrlFunction(opener: opened.add);

      expect(
        function.execute({'url': 'mailto:ada@example.com'}, _context),
        isNull,
      );
      expect(opened, [Uri.parse('mailto:ada@example.com')]);
    });

    test('ignores missing and malformed URL values', () {
      final opened = <Uri>[];
      final function = OpenUrlFunction(opener: opened.add);

      expect(function.execute(const {}, _context), isNull);
      expect(function.execute({'url': 42}, _context), isNull);
      expect(function.execute({'url': 'http://['}, _context), isNull);
      expect(opened, isEmpty);
    });

    test('the default opener is safe during server rendering', () {
      expect(
        () => OpenUrlFunction().execute(
          {'url': 'https://example.com'},
          _context,
        ),
        returnsNormally,
      );
    });
  });
}
