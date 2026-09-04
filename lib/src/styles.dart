import 'package:jaspr/dom.dart';

/// A readable default appearance for every component in the catalog.
///
/// Add these to a Jaspr app's styles to get a surface that looks finished, or
/// leave them out and write your own against the same class names. Nothing in
/// the renderer depends on these rules, so replacing them wholesale is a
/// supported way to use the package.
///
/// Colours read from custom properties, which a surface publishes from the
/// theme the model sent with `createSurface`. That is what lets a model
/// choose an accent at runtime while the rules themselves stay static. Each
/// `var()` carries a fallback, so an untouched theme still renders sensibly.
final List<StyleRule> genuiJasprStyles = [
  const StyleRule(
    selector: Selector('.a2ui-surface'),
    styles: Styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': '0.75rem',
        'font-family': 'system-ui, sans-serif',
        'color': 'var(--a2ui-text-color, #1a1a1a)',
      },
    ),
  ),

  // Text
  const StyleRule(
    selector: Selector('.a2ui-text'),
    styles: Styles(raw: {'margin': '0'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-text--body'),
    styles: Styles(raw: {'font-size': '1rem', 'line-height': '1.5'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-text--caption'),
    styles: Styles(raw: {'font-size': '0.8125rem', 'opacity': '0.7'}),
  ),
  for (final (className, size) in const [
    ('a2ui-text--h1', '2rem'),
    ('a2ui-text--h2', '1.5rem'),
    ('a2ui-text--h3', '1.25rem'),
    ('a2ui-text--h4', '1.125rem'),
    ('a2ui-text--h5', '1rem'),
  ])
    StyleRule(
      selector: Selector('.$className'),
      styles: Styles(
        raw: {'font-size': size, 'line-height': '1.25', 'font-weight': '600'},
      ),
    ),

  // Layout. Direction and alignment are set inline per component, because the
  // model chooses them per instance; only the shared spacing lives here.
  const StyleRule(
    selector: Selector('.a2ui-row'),
    styles: Styles(raw: {'gap': '0.5rem'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-column'),
    styles: Styles(raw: {'gap': '0.5rem'}),
  ),

  // Button
  const StyleRule(
    selector: Selector('.a2ui-button'),
    styles: Styles(
      raw: {
        'font': 'inherit',
        'padding': '0.5rem 1rem',
        'border-radius': '0.375rem',
        'border': '1px solid transparent',
        'cursor': 'pointer',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-button:disabled'),
    styles: Styles(raw: {'opacity': '0.5', 'cursor': 'not-allowed'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-button--primary'),
    styles: Styles(
      raw: {
        'background': 'var(--a2ui-primary-color, #1a73e8)',
        'color': 'var(--a2ui-primary-text-color, #ffffff)',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-button--borderless'),
    styles: Styles(
      raw: {
        'background': 'transparent',
        'color': 'var(--a2ui-primary-color, #1a73e8)',
      },
    ),
  ),

  // Text field
  const StyleRule(
    selector: Selector('.a2ui-field'),
    styles: Styles(
      raw: {'display': 'flex', 'flex-direction': 'column', 'gap': '0.25rem'},
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-field__label'),
    styles: Styles(raw: {'font-size': '0.875rem', 'font-weight': '500'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-field__input'),
    styles: Styles(
      raw: {
        'font': 'inherit',
        'padding': '0.5rem',
        'border': '1px solid var(--a2ui-border-color, #c4c7c5)',
        'border-radius': '0.375rem',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-field__input:focus-visible'),
    styles: Styles(
      raw: {'outline': '2px solid var(--a2ui-primary-color, #1a73e8)'},
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-field__error'),
    styles: Styles(
      raw: {
        'color': 'var(--a2ui-error-color, #b3261e)',
        'font-size': '0.8125rem',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-field--invalid .a2ui-field__input'),
    styles: Styles(
      raw: {'border-color': 'var(--a2ui-error-color, #b3261e)'},
    ),
  ),

  // The renderer's own fallback for a component the catalog cannot build.
  const StyleRule(
    selector: Selector('.a2ui-missing'),
    styles: Styles(
      raw: {
        'padding': '0.5rem 0.75rem',
        'border': '1px dashed var(--a2ui-error-color, #b3261e)',
        'border-radius': '0.375rem',
        'color': 'var(--a2ui-error-color, #b3261e)',
        'font-size': '0.875rem',
      },
    ),
  ),
];

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
