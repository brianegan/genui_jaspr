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

  // Image. The fit is set inline because the model chooses it per instance.
  const StyleRule(
    selector: Selector('.a2ui-image'),
    styles: Styles(
      raw: {'display': 'block', 'max-width': '100%'},
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-image--icon'),
    styles: Styles(raw: {'width': '1.5rem', 'height': '1.5rem'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-image--avatar'),
    styles: Styles(
      raw: {'width': '2.5rem', 'height': '2.5rem', 'border-radius': '50%'},
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-image--small-feature'),
    styles: Styles(raw: {'width': '6.25rem', 'height': '6.25rem'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-image--medium-feature'),
    styles: Styles(raw: {'width': '100%', 'max-width': '18.75rem'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-image--large-feature'),
    styles: Styles(raw: {'width': '100%', 'max-height': '25rem'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-image--header'),
    styles: Styles(raw: {'width': '100%', 'height': '12.5rem'}),
  ),

  // Audio
  const StyleRule(
    selector: Selector('.a2ui-audio-player'),
    styles: Styles(raw: {'display': 'block', 'width': '100%'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-video'),
    styles: Styles(
      raw: {'display': 'block', 'width': '100%', 'max-width': '100%'},
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
  const StyleRule(
    selector: Selector('.a2ui-list'),
    styles: Styles(
      raw: {
        'gap': '0.5rem',
        'min-width': '0',
        'min-height': '0',
        'padding': '0',
        'margin': '0',
      },
    ),
  ),

  // Card. A transparent surface plus an outline keeps nested cards distinct
  // without tracking their depth or alternating background colours.
  const StyleRule(
    selector: Selector('.a2ui-card'),
    styles: Styles(
      raw: {
        'box-sizing': 'border-box',
        'padding': '1rem',
        'background': 'transparent',
        'border': '1px solid var(--a2ui-border-color, #c4c7c5)',
        'border-radius': '0.5rem',
      },
    ),
  ),

  // Divider
  const StyleRule(
    selector: Selector('.a2ui-divider'),
    styles: Styles(
      raw: {
        'width': '100%',
        'height': '0',
        'margin': '0',
        'border': '0',
        'border-top': '1px solid var(--a2ui-border-color, #c4c7c5)',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-divider--vertical'),
    styles: Styles(
      raw: {
        'width': '0',
        'height': '100%',
        'border-top': '0',
        'border-left': '1px solid var(--a2ui-border-color, #c4c7c5)',
      },
    ),
  ),

  // Tabs
  const StyleRule(
    selector: Selector('.a2ui-tabs'),
    styles: Styles(raw: {'min-width': '0'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-tabs__list'),
    styles: Styles(
      raw: {
        'display': 'flex',
        'gap': '0.25rem',
        'border-bottom': '1px solid var(--a2ui-border-color, #c4c7c5)',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-tabs__tab'),
    styles: Styles(
      raw: {
        'font': 'inherit',
        'padding': '0.5rem 0.75rem',
        'background': 'transparent',
        'border': '0',
        'border-bottom': '2px solid transparent',
        'cursor': 'pointer',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-tabs__tab--selected'),
    styles: Styles(
      raw: {
        'color': 'var(--a2ui-primary-color, #1a73e8)',
        'border-bottom-color': 'currentColor',
        'font-weight': '600',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-tabs__panel'),
    styles: Styles(raw: {'padding-top': '0.75rem'}),
  ),

  // Modal
  const StyleRule(
    selector: Selector('.a2ui-modal'),
    styles: Styles(raw: {'display': 'contents'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-modal__trigger'),
    styles: Styles(raw: {'display': 'inline-block'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-modal__dialog'),
    styles: Styles(
      raw: {
        'box-sizing': 'border-box',
        'width': 'min(32rem, calc(100% - 2rem))',
        'max-height': 'calc(100% - 2rem)',
        'padding': '1rem',
        'color': 'inherit',
        'background': 'var(--a2ui-surface-color, #ffffff)',
        'border': '1px solid var(--a2ui-border-color, #c4c7c5)',
        'border-radius': '0.5rem',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-modal__dialog::backdrop'),
    styles: Styles(raw: {'background': 'rgb(0 0 0 / 45%)'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-modal__close'),
    styles: Styles(
      raw: {
        'float': 'right',
        'font': 'inherit',
        'cursor': 'pointer',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-modal__content'),
    styles: Styles(raw: {'clear': 'both'}),
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
    styles: Styles(raw: {'border-color': 'var(--a2ui-error-color, #b3261e)'}),
  ),

  // Checkbox
  const StyleRule(
    selector: Selector('.a2ui-checkbox'),
    styles: Styles(
      raw: {
        'display': 'inline-flex',
        'align-items': 'center',
        'gap': '0.5rem',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-checkbox__input'),
    styles: Styles(
      raw: {'width': '1.125rem', 'height': '1.125rem'},
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-checkbox__label'),
    styles: Styles(raw: {'font-size': '0.9375rem'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-checkbox__error'),
    styles: Styles(
      raw: {
        'color': 'var(--a2ui-error-color, #b3261e)',
        'font-size': '0.8125rem',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-checkbox--invalid .a2ui-checkbox__label'),
    styles: Styles(raw: {'color': 'var(--a2ui-error-color, #b3261e)'}),
  ),

  // Choice picker
  const StyleRule(
    selector: Selector('.a2ui-choice-picker'),
    styles: Styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': '0.375rem',
        'border': 'none',
        'padding': '0',
        'margin': '0',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-choice-picker__label'),
    styles: Styles(
      raw: {'font-size': '0.875rem', 'font-weight': '500', 'padding': '0'},
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-choice-picker__option'),
    styles: Styles(
      raw: {
        'display': 'inline-flex',
        'align-items': 'center',
        'gap': '0.5rem',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-choice-picker__input'),
    styles: Styles(
      raw: {'width': '1.125rem', 'height': '1.125rem'},
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-choice-picker__option-label'),
    styles: Styles(raw: {'font-size': '0.9375rem'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-choice-picker__error'),
    styles: Styles(
      raw: {
        'color': 'var(--a2ui-error-color, #b3261e)',
        'font-size': '0.8125rem',
      },
    ),
  ),
  const StyleRule(
    selector: Selector(
      '.a2ui-choice-picker--invalid .a2ui-choice-picker__label',
    ),
    styles: Styles(raw: {'color': 'var(--a2ui-error-color, #b3261e)'}),
  ),

  // Slider
  const StyleRule(
    selector: Selector('.a2ui-slider'),
    styles: Styles(
      raw: {'display': 'flex', 'flex-direction': 'column', 'gap': '0.25rem'},
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-slider__label'),
    styles: Styles(raw: {'font-size': '0.875rem', 'font-weight': '500'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-slider__input'),
    styles: Styles(raw: {'accent-color': 'var(--a2ui-primary-color, #1a73e8)'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-slider__error'),
    styles: Styles(
      raw: {
        'color': 'var(--a2ui-error-color, #b3261e)',
        'font-size': '0.8125rem',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-slider--invalid .a2ui-slider__label'),
    styles: Styles(raw: {'color': 'var(--a2ui-error-color, #b3261e)'}),
  ),

  // Date/time input
  const StyleRule(
    selector: Selector('.a2ui-date-time-input'),
    styles: Styles(
      raw: {'display': 'flex', 'flex-direction': 'column', 'gap': '0.25rem'},
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-date-time-input__label'),
    styles: Styles(raw: {'font-size': '0.875rem', 'font-weight': '500'}),
  ),
  const StyleRule(
    selector: Selector('.a2ui-date-time-input__input'),
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
    selector: Selector('.a2ui-date-time-input__input:focus-visible'),
    styles: Styles(
      raw: {'outline': '2px solid var(--a2ui-primary-color, #1a73e8)'},
    ),
  ),
  const StyleRule(
    selector: Selector('.a2ui-date-time-input__error'),
    styles: Styles(
      raw: {
        'color': 'var(--a2ui-error-color, #b3261e)',
        'font-size': '0.8125rem',
      },
    ),
  ),
  const StyleRule(
    selector: Selector(
      '.a2ui-date-time-input--invalid .a2ui-date-time-input__input',
    ),
    styles: Styles(raw: {'border-color': 'var(--a2ui-error-color, #b3261e)'}),
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
