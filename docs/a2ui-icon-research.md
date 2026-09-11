# A2UI v0.9 icons in Jaspr

Research date: 2026-09-10

## Conclusion

Jaspr does not provide a first-party Material icon set. Its core package deliberately
provides web primitives rather than pre-styled Material or Cupertino widgets, and its
documentation lists icon libraries under community-maintained packages
([Jaspr package](https://pub.dev/packages/jaspr),
[Jaspr third-party packages](https://docs.jaspr.site/going_further/packages)).

The closest ready-made option is [`jaspr_icons`](https://pub.dev/packages/jaspr_icons).
It renders inline SVG, includes Material Icons in five styles, represents icons as
`static const IconData`, and documents the collection as tree-shakeable. This is a
community package, not part of Jaspr itself. By contrast,
[`jaspr_material`](https://pub.dev/packages/jaspr_material) renders icon-name
ligatures and requires the application to load Material icon-font stylesheets; that
external font is not reduced by Dart tree shaking.

For `BasicJasprCatalog`, the recommended implementation is a small built-in inline-SVG
renderer covering the A2UI standard set, plus a structurally separate constructor for
applications that supply their own renderer. This avoids imposing either a
comprehensive icon package or a font/network requirement on every package consumer,
and lets Dart remove even the built-in 59-icon subset when that constructor is not
used.

## Why the built-in set is small

The current A2UI v0.9 basic catalog does not permit arbitrary Material icon names. Its
`Icon.name` value is one of **59 names**, an object containing `svgPath`, or a data
binding that resolves to one of those shapes. This is the current upstream contract,
not the thousands of glyphs in Material
([A2UI v0.9 basic catalog schema](https://raw.githubusercontent.com/a2ui-project/a2ui/main/specification/v0_9/catalogs/basic/catalog.json)).

This repository's pinned `standard_catalog.json` revision retains the older
`https://a2ui.org/specification/v0_9/standard_catalog.json` ID named in issue #17.
Its `{ "path": "..." }` alternative is a data binding, not custom SVG data: it is
the same shape as `a2ui_core`'s `DataBinding`, and the binder resolves any such
property against the surface data model. The pinned contract therefore accepts a
literal or bound standard name only. Supporting upstream's newer
`{ "svgPath": "..." }` form would require a separate catalog migration.

A literal or bound standard name is looked up in a 59-entry map of 24px SVG path
data.

Jaspr already exposes native `svg` and `path` DOM components, so this needs no runtime
HTML parser and works in server rendering as well as the browser
([Jaspr SVG DOM source](https://github.com/schultek/jaspr/blob/main/packages/jaspr/lib/src/dom/html/svg.dart)).
The shell should use `viewBox="0 0 24 24"`, `fill="currentColor"`, a 24px default
size, the existing `a2ui-icon` CSS class, and `aria-hidden="true"` because the A2UI
v0.9 `Icon` API has no accessible-label property.

An injectable callback can preserve portability without weakening the default
contract. It should be exposed through a separate constructor whose reachable body
does not mention the built-in renderer, for example conceptually:

```dart
typedef A2uiIconRenderer = Component Function(String iconName);

BasicJasprCatalog(); // Includes the standard 59-icon renderer.
BasicJasprCatalog.withIconRenderer(A2uiIconRenderer renderer); // Does not.
```

The custom renderer should be responsible for every `Icon` value. A single optional
callback with `custom(icon) ?? builtIn(icon)` keeps the built-in renderer reachable and
therefore cannot offer the same size guarantee. An explicitly named fallback variant
could be offered, but its documented cost would include the built-in paths.

## Tree-shaking implications

Dart's production JavaScript compiler removes unused classes, functions, and methods
and says unused imported libraries have no impact on output size
([Dart production compiler documentation](https://dart.dev/tools/dart-compile#javascript)).
Consequently, depending on `genui_jaspr`, importing its public barrel, or using only
`MinimalJasprCatalog` does **not** retain a private icon-path table merely because
`BasicJasprCatalog` is exported from that barrel. Public versus private declarations,
top-level versus static constants, and separate source libraries are not the
fundamental boundary; reachability from the entry point is. A separate private icon
library is still useful for keeping that boundary obvious and reviewable.

The expected production behavior for the proposed API is:

| Downstream use | Built-in 59 paths retained? | Reason |
|---|---:|---|
| Package dependency/import only | No | Imports and exports do not root unused declarations. |
| `MinimalJasprCatalog` only | No | No reachable reference to the basic icon component. |
| Default `BasicJasprCatalog()`, even if no Icon has arrived yet | Yes | It registers an Icon renderer for runtime messages. |
| `BasicJasprCatalog.withIconRenderer(custom)` | No | The distinct constructor assembles the catalog without referencing the built-in renderer. |
| A custom renderer with built-in fallback | Yes | The fallback makes the built-in table reachable. |

This also makes `jaspr_icons` a reasonable alternative: map the 59 A2UI names
explicitly to 59 `MaterialIcons.*` constants, and unrelated Material styles and other
icon families should remain unreachable.

There is an important limit: an A2UI icon name arrives as runtime data. A complete
standard renderer must therefore reference all 59 supported icons, so those 59 cannot
be tree-shaken individually. Tree shaking prevents the *rest* of a comprehensive icon
library from entering the client bundle; it cannot predict which valid A2UI names the
server will send later. This is the same reachability shape as a runtime registry: the
Dart SDK's tree-shaking discussion demonstrates that entries registered in a map stay
reachable even when a particular execution only looks up one key
([Dart SDK issue #33920](https://github.com/dart-lang/sdk/issues/33920)). Constructing
the complete catalog and subsequently removing `Icon` with `copyWith` is therefore not
a sound bundle-size guarantee; the safe path never constructs or registers that
renderer.

### Compiler experiment

A throwaway pure-Dart web experiment compiled six entry points with Dart 3.12.1 and
`dart compile js -O4`. It placed unique markers in a 59-entry path map and modeled the
catalog/runtime-dispatch boundary. Results were:

| Entry point | Minified JS bytes | Icon marker present? |
|---|---:|---:|
| No import | 5,356 | No |
| Public barrel imported but unused | 5,358 | No |
| Minimal catalog | 31,483 | No |
| Default basic catalog | 36,633 | Yes |
| Basic catalog through a distinct custom-renderer constructor | 31,848 | No |
| Custom renderer with built-in fallback | 36,765 | Yes |

These numbers are evidence for the reachability boundary, not a forecast for the
actual Jaspr bundle: the fixture was synthetic, was not gzip-compressed, and did not
include Jaspr. Exact bytes can change with compiler version and optimization level.
A production size/marker regression test is appropriate if the no-icon guarantee is
part of the package API.

`jaspr_icons` is consequently viable if avoiding maintained path data is worth a
community dependency and its large source package. Vendoring only the 59 licensed
paths produces the narrowest dependency and build footprint. Material Icons are
Apache-2.0 licensed, so either route must preserve the required license notice
([Google Material Icons guide](https://developers.google.com/fonts/docs/material_icons)).

## Font-backed alternative

Google Material Symbols supports explicit server-side font subsetting with an
alphabetically sorted `icon_names` query parameter. Google's example reduces a default
3,800-plus-glyph, roughly 295 KB request to about 1.7 KB for three named glyphs
([Material Symbols guide](https://developers.google.com/fonts/docs/material_symbols?hl=en)).
The catalog could therefore map the A2UI names to Material ligature names and request
one fixed 59-glyph subset.

This is not Dart/Jaspr tree shaking: the subset is fixed in the font URL. It also adds
a Google Fonts request (or a self-hosted font asset), font loading behavior, and CSP
and privacy considerations. It is a reasonable application-level opt-in renderer,
but a poorer zero-configuration default for a portable catalog package.

## Recommendation for the plan

- Add `IconApi` matching the repository's pinned union exactly: 59 literal names or
  a `{path}` data binding that resolves to one of those names. Treat the current
  upstream `{svgPath}` form as part of a separate catalog migration.
- Render with Jaspr's native inline SVG primitives.
- Bundle only the 59 standard paths and the shared SVG shell; do not add a full icon
  font.
- Keep the built-in paths and renderer in a private source library. Exporting
  `BasicJasprCatalog` from the package barrel is safe.
- Make `BasicJasprCatalog()` use the standard built-in renderer, and expose a distinct
  `BasicJasprCatalog.withIconRenderer(...)` whose implementation has no reference to
  the built-in renderer or paths. Do not silently fall back from this constructor.
- For applications that want the other basic components but no `Icon` at all, provide
  an assembly path that never constructs `IconComponent` and requires a non-standard
  catalog ID. The official basic-catalog ID promises `Icon` and should not describe a
  17-component catalog.
- Test every standard name, bound values, unknown/malformed values,
  CSS/current-color behavior, and server-rendered markup.
- Add a production web build regression that checks a no-icon entry point does not
  contain a unique icon-table marker; avoid asserting an exact byte count.

If maintaining 59 path constants locally is undesirable, use `jaspr_icons` with an
explicit 59-entry switch as the second-best implementation. It gives a no-font inline
SVG result and allows the Dart compiler to discard unrelated icons, but it remains a
community dependency.
