import 'package:a2ui_core/a2ui_core.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../catalog/jaspr_component.dart';
import '../styles.dart';
import 'signal_builder.dart';

/// Renders an A2UI surface, starting from the component named [rootId].
///
/// A surface arrives empty and fills in as messages are applied, so this
/// renders nothing until its root component exists and then appears on its own.
class Surface extends StatefulComponent {
  const Surface({required this.surface, this.rootId = 'root', super.key});

  /// The surface to render. Owned by the caller, not disposed here.
  final SurfaceModel<JasprComponent> surface;

  /// The id of the component to render as the root of the tree.
  final String rootId;

  @override
  State<Surface> createState() => _SurfaceState();
}

class _SurfaceState extends State<Surface> {
  @override
  void initState() {
    super.initState();
    _listen(component.surface);
  }

  @override
  void didUpdateComponent(Surface oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.surface != component.surface) {
      _stopListening(oldComponent.surface);
      _listen(component.surface);
    }
  }

  void _listen(SurfaceModel<JasprComponent> surface) {
    surface.componentsModel.onCreated.addListener(_onComponentsChanged);
    surface.componentsModel.onDeleted.addListener(_onComponentsChanged);
  }

  void _stopListening(SurfaceModel<JasprComponent> surface) {
    surface.componentsModel.onCreated.removeListener(_onComponentsChanged);
    surface.componentsModel.onDeleted.removeListener(_onComponentsChanged);
  }

  /// Components are added and removed while a response streams in, so the tree
  /// has to be reconsidered whenever the set changes.
  void _onComponentsChanged(Object? _) {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _stopListening(component.surface);
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // The surface root carries the theme as custom properties, so the static
    // stylesheet can react to colours the model chose at runtime.
    return div(
      [
        if (component.surface.componentsModel.get(component.rootId) != null)
          A2uiComponent(
            surface: component.surface,
            componentId: component.rootId,
          ),
      ],
      classes: 'a2ui-surface',
      styles: themeProperties(component.surface.theme),
    );
  }
}

/// Renders one component of a surface, and through its children the subtree
/// beneath it.
///
/// Each instance owns a [GenericBinder] for its component. The binder resolves
/// the component's raw properties into concrete values and republishes them
/// whenever the data they depend on changes, which is what makes a surface
/// reactive without the renderer tracking dependencies itself.
class A2uiComponent extends StatefulComponent {
  const A2uiComponent({
    required this.surface,
    required this.componentId,
    this.basePath = '/',
    super.key,
  });

  final SurfaceModel<JasprComponent> surface;
  final String componentId;

  /// The data-model path children resolve against.
  ///
  /// A component repeated over a list is rendered once per element, each with a
  /// base path pointing at its own element, so relative bindings inside the
  /// template resolve to the right row.
  final String basePath;

  @override
  State<A2uiComponent> createState() => _A2uiComponentState();
}

class _A2uiComponentState extends State<A2uiComponent> {
  GenericBinder? _binder;
  JasprComponent? _entry;
  ComponentModel? _model;

  @override
  void initState() {
    super.initState();
    _bind();
    _watchForReplacement(component.surface);
  }

  @override
  void didUpdateComponent(A2uiComponent oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.componentId != component.componentId ||
        oldComponent.basePath != component.basePath ||
        oldComponent.surface != component.surface) {
      if (oldComponent.surface != component.surface) {
        _stopWatching(oldComponent.surface);
        _watchForReplacement(component.surface);
      }
      _unbind();
      _bind();
    }
  }

  void _watchForReplacement(SurfaceModel<JasprComponent> surface) {
    surface.componentsModel.onCreated.addListener(_onComponentCreated);
    surface.componentsModel.onDeleted.addListener(_onComponentDeleted);
  }

  void _stopWatching(SurfaceModel<JasprComponent> surface) {
    surface.componentsModel.onCreated.removeListener(_onComponentCreated);
    surface.componentsModel.onDeleted.removeListener(_onComponentDeleted);
  }

  /// Re-binds when this component's model is replaced rather than edited.
  ///
  /// Changing a component's type is applied by removing it and adding a fresh
  /// model under the same id. The id did not change, so nothing else here would
  /// notice, and this would keep rendering the previous type against a model that
  /// is no longer in the surface.
  void _onComponentCreated(ComponentModel model) {
    if (model.id != component.componentId || model == _model) return;
    if (!mounted) return;
    setState(() {
      _unbind();
      _bind();
    });
  }

  void _onComponentDeleted(String id) {
    if (id != component.componentId || !mounted) return;
    // Only drop the binding. A replacement usually follows in the same message,
    // and the create handler picks it up.
    setState(_unbind);
  }

  void _bind() {
    final ComponentModel? model = component.surface.componentsModel.get(
      component.componentId,
    );
    if (model == null) return;
    _model = model;

    final JasprComponent? entry =
        component.surface.catalog.components[model.type];
    if (entry == null) return;
    _entry = entry;

    _binder = GenericBinder(
      ComponentContext(component.surface, model, basePath: component.basePath),
      entry.schema,
    );
  }

  void _unbind() {
    _binder?.dispose();
    _binder = null;
    _entry = null;
    _model = null;
  }

  @override
  void dispose() {
    _stopWatching(component.surface);
    _unbind();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final ComponentModel? model = _model;
    if (model == null) {
      return _missing('No component with id "${component.componentId}".');
    }

    final JasprComponent? entry = _entry;
    final GenericBinder? binder = _binder;
    if (entry == null || binder == null) {
      // The model asked for a component this catalog does not implement. Say so
      // in the page rather than throwing, so one unknown component does not
      // take down the surrounding surface.
      return _missing('Unknown component "${model.type}".');
    }

    return SignalBuilder<Map<String, dynamic>>(
      signal: binder.resolvedProps,
      builder: (context, props) => entry.build(
        ComponentScope(
          id: component.componentId,
          type: model.type,
          props: props,
          theme: component.surface.theme,
          buildChild: _buildChild,
          buildChildren: _buildChildren,
        ),
      ),
    );
  }

  Component _buildChild(String componentId) {
    return A2uiComponent(
      surface: component.surface,
      componentId: componentId,
      basePath: component.basePath,
    );
  }

  List<Component> _buildChildren(Object? childrenProp) {
    if (childrenProp is! List) return const [];
    final children = <Component>[];
    for (final Object? entry in childrenProp) {
      if (entry is ChildNode) {
        children.add(
          A2uiComponent(
            surface: component.surface,
            componentId: entry.id,
            basePath: entry.basePath,
          ),
        );
      } else if (entry != null) {
        children.add(_buildChild('$entry'));
      }
    }
    return children;
  }

  Component _missing(String message) {
    return div(
      [Component.text(message)],
      classes: 'a2ui-missing',
      attributes: const {'role': 'alert'},
    );
  }
}
