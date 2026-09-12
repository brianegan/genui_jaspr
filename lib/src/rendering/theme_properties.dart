import 'package:jaspr/dom.dart';

/// Turns a surface theme into CSS custom properties.
///
/// Keys become `--a2ui-`-prefixed custom properties in kebab case, so
/// `primaryColor` arrives as `--a2ui-primary-color`. The catalog's theme schema
/// allows properties beyond the one it names, and this passes all of them
/// through rather than recognising a fixed list.
Styles themeProperties(Map<String, dynamic> theme) {
  final properties = <String, String>{};
  theme.forEach((key, value) {
    if (value == null || value is Map || value is List) return;
    properties['--a2ui-${_kebabCase(key)}'] = '$value';
  });
  return Styles(raw: properties);
}

String _kebabCase(String value) {
  return value
      .replaceAllMapped(
        RegExp('([a-z0-9])([A-Z])'),
        (match) => '${match[1]}-${match[2]!.toLowerCase()}',
      )
      .toLowerCase();
}
