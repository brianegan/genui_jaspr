import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import 'chat.dart';

/// The server-rendered page.
///
/// The heading and layout arrive as HTML on first paint. The conversation itself
/// is a `@client` component, because a generated surface only exists after the
/// model has answered.
class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return div([
      header([
        h1([Component.text('GenUI for Jaspr')]),
        p([
          Component.text(
            'Ask for an interface. A model answers with A2UI messages, and '
            'this page renders them as HTML.',
          ),
        ], classes: 'lede'),
      ]),
      const Chat(),
    ], classes: 'page');
  }
}

/// The app's own styles, alongside the catalog's defaults.
///
/// The catalog rules are included rather than reimplemented, which is the
/// intended way to use them: take the defaults, then add whatever the
/// surrounding app needs.
List<StyleRule> get appStyles => [
  ...genuiJasprStyles,
  StyleRule(
    selector: const Selector('body'),
    styles: const Styles(
      raw: {
        'margin': '0',
        'font-family': 'system-ui, sans-serif',
        'background': '#fbfbfb',
        'color': '#1a1a1a',
      },
    ),
  ),
  StyleRule(
    selector: const Selector('.page'),
    styles: const Styles(
      raw: {
        'max-width': '46rem',
        'margin': '0 auto',
        // The bottom padding keeps the last turn clear of the pinned composer,
        // which is out of flow and would otherwise cover it.
        'padding': '2rem 1rem 8rem',
      },
    ),
  ),
  StyleRule(
    selector: const Selector('.lede'),
    styles: const Styles(raw: {'color': '#5f6368', 'margin-bottom': '2rem'}),
  ),
  StyleRule(
    selector: const Selector('.transcript'),
    styles: const Styles(
      raw: {'display': 'flex', 'flex-direction': 'column', 'gap': '1rem'},
    ),
  ),
  // The anchor the conversation scrolls to. `scrollIntoView` would align it with
  // the bottom of the viewport, which the composer covers, so this reserves the
  // composer's height and the newest turn ends up above it rather than behind it.
  StyleRule(
    selector: const Selector('.transcript__end'),
    styles: const Styles(raw: {'scroll-margin-bottom': '6rem'}),
  ),
  StyleRule(
    selector: const Selector('.turn'),
    styles: const Styles(
      raw: {
        'padding': '0.75rem 1rem',
        'border-radius': '0.75rem',
        'background': '#ffffff',
        'border': '1px solid #e3e3e3',
      },
    ),
  ),
  StyleRule(
    selector: const Selector('.turn--user'),
    styles: const Styles(
      raw: {'background': '#eef3fd', 'border-color': '#d3e2fd'},
    ),
  ),
  // Pinned to the bottom of the viewport, so the prompt stays reachable however
  // long the conversation gets.
  StyleRule(
    selector: const Selector('.composer'),
    styles: const Styles(
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
  StyleRule(
    selector: const Selector('.composer__inner'),
    styles: const Styles(
      raw: {
        'display': 'flex',
        'gap': '0.5rem',
        'max-width': '46rem',
        'margin': '0 auto',
      },
    ),
  ),
  StyleRule(
    selector: const Selector('.composer input'),
    styles: const Styles(
      raw: {
        'flex': '1',
        'font': 'inherit',
        'padding': '0.625rem 0.75rem',
        'border': '1px solid #c4c7c5',
        'border-radius': '0.5rem',
      },
    ),
  ),
  StyleRule(
    selector: const Selector('.composer button'),
    styles: const Styles(
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
  StyleRule(
    selector: const Selector('.status'),
    styles: const Styles(raw: {'color': '#5f6368'}),
  ),
  StyleRule(
    selector: const Selector('.error'),
    styles: const Styles(raw: {'color': '#b3261e'}),
  ),
];
