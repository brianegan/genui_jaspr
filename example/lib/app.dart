import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:genui_jaspr_example/chat.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The server-rendered page.
///
/// The heading and layout arrive as HTML on first paint. The conversation
/// itself is a `@client` component, because a generated surface only exists
/// after the model has answered.
class App extends StatelessComponent {
  /// Creates the [App].
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return const div([
      header([
        h1([Component.text('GenUI for Jaspr')]),
        p([
          Component.text(
            'Ask for an interface. A model answers with A2UI messages, and '
            'this page renders them as HTML.',
          ),
        ], classes: 'lede'),
      ]),
      Chat(),
    ], classes: 'page');
  }
}

/// The app's own styles, alongside the catalog's defaults.
///
/// The catalog rules are included rather than reimplemented, which is the
/// intended way to use them: take the defaults for whatever catalog the app
/// renders with, then add what the surrounding page needs. The surface wrapper
/// and the renderer's missing-component fallback are styled here, because they
/// belong to no component and the package ships no rules for them.
List<StyleRule> get appStyles => [
  ...MinimalJasprCatalog().styles,
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
  const StyleRule(
    selector: Selector('body'),
    styles: Styles(
      raw: {
        'margin': '0',
        'font-family': 'system-ui, sans-serif',
        'background': '#fbfbfb',
        'color': '#1a1a1a',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.page'),
    styles: Styles(
      raw: {
        'max-width': '46rem',
        'margin': '0 auto',
        // The bottom padding keeps the last turn clear of the pinned composer,
        // which is out of flow and would otherwise cover it.
        'padding': '2rem 1rem 8rem',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.lede'),
    styles: Styles(raw: {'color': '#5f6368', 'margin-bottom': '2rem'}),
  ),
  const StyleRule(
    selector: Selector('.transcript'),
    styles: Styles(
      raw: {'display': 'flex', 'flex-direction': 'column', 'gap': '1rem'},
    ),
  ),
  // The anchor the conversation scrolls to. `scrollIntoView` would align it
  // with the bottom of the viewport, which the composer covers, so this
  // reserves the composer's height and the newest turn ends up above it
  // rather than behind it.
  const StyleRule(
    selector: Selector('.transcript__end'),
    styles: Styles(raw: {'scroll-margin-bottom': '6rem'}),
  ),
  const StyleRule(
    selector: Selector('.turn'),
    styles: Styles(
      raw: {
        'padding': '0.75rem 1rem',
        'border-radius': '0.75rem',
        'background': '#ffffff',
        'border': '1px solid #e3e3e3',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.turn--user'),
    styles: Styles(
      raw: {'background': '#eef3fd', 'border-color': '#d3e2fd'},
    ),
  ),
  // Pinned to the bottom of the viewport, so the prompt stays reachable however
  // long the conversation gets.
  const StyleRule(
    selector: Selector('.composer'),
    styles: Styles(
      raw: {
        'position': 'fixed',
        'left': '0',
        'right': '0',
        'bottom': '0',
        'padding': '1rem',
        'background': '#fbfbfb',
        'border-top': '1px solid #e3e3e3',
        // Above a generated surface, which can be tall.
        'z-index': '10',
      },
    ),
  ),
  // Kept to the same column as the page content, since the bar itself spans the
  // full width.
  const StyleRule(
    selector: Selector('.composer__inner'),
    styles: Styles(
      raw: {
        'display': 'flex',
        'gap': '0.5rem',
        'max-width': '46rem',
        'margin': '0 auto',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.composer input'),
    styles: Styles(
      raw: {
        'flex': '1',
        'font': 'inherit',
        'padding': '0.625rem 0.75rem',
        'border': '1px solid #c4c7c5',
        'border-radius': '0.5rem',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.composer button'),
    styles: Styles(
      raw: {
        'font': 'inherit',
        'padding': '0.625rem 1.25rem',
        'border': 'none',
        'border-radius': '0.5rem',
        'background': '#0b57d0',
        'color': '#ffffff',
        'cursor': 'pointer',
      },
    ),
  ),
  const StyleRule(
    selector: Selector('.status'),
    styles: Styles(raw: {'color': '#5f6368'}),
  ),
  const StyleRule(
    selector: Selector('.error'),
    styles: Styles(raw: {'color': '#b3261e'}),
  ),
];
