import 'package:core/debounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_core/component.dart';
import 'package:core/core.dart' as core;
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/transform_space.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/paint/gradient_stop.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart' as core;
import 'package:rive_core/shapes/paint/radial_gradient.dart' as core;
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_editor/widgets/inspector/color/color_type.dart';

/// Color change callback used by the various color picker components.
typedef ChangeColor = void Function(HSVColor);

/// Abstraction of the currently inspected color.
class InspectingColor {
  static const Color defaultSolidColor = Color(0xFF747474);
  static const Color defaultGradientColorA =
      Color(0xFFFFFFFF); //Color(0xFFFF5678);
  static const Color defaultGradientColorB =
      Color(0xFF000000); //Color(0xFFD041AB);

  /// Whether the inspecting color is a solid or a linear/radial gradient.
  final ValueNotifier<ColorType> type = ValueNotifier<ColorType>(null);

  /// The colors to show in the preview swatch.
  final ValueNotifier<List<Color>> preview = ValueNotifier<List<Color>>([]);

  /// The editing index in the list of color stops.
  final ValueNotifier<int> editingIndex = ValueNotifier<int>(0);

  /// The value of the currently editing color.
  final ValueNotifier<HSVColor> editingColor =
      ValueNotifier<HSVColor>(HSVColor.fromColor(const Color(0xFFFF0000)));

  /// The list of color stops used if the current type is a gradient.
  final ValueNotifier<List<InspectingColorStop>> stops =
      ValueNotifier<List<InspectingColorStop>>(null);

  /// Track which properties we're listening to on each component. This varies
  /// depending on whether it's a solid color, gradient, etc.
  final Map<Component, Set<int>> _listeningToCoreProperties = {};
  final Set<ChangeNotifier> _listeningTo = {};

  /// Whether we should perform an update in response to a core value change.
  /// This allows us to not re-process updates as we're interactively changing
  /// values from this inspector.
  bool _suppressUpdating = false;

  Iterable<ShapePaint> shapePaints;
  InspectingColor(this.shapePaints) {
    for (final paint in shapePaints) {
      paint.paintMutatorChanged.addListener(_mutatorChanged);
    }
    _updatePaints();
  }

  /// Because radial gradients inherit from linear ones, we can share some of
  /// the common aspects of creating one here.
  core.LinearGradient _initGradient(Shape shape, core.LinearGradient gradient) {
    var file = shape.context;
    var bounds = shape.computeBounds(TransformSpace.local);
    gradient
      ..startX = bounds.left
      ..startY = bounds.centerLeft.dy
      ..endX = bounds.right
      ..endY = bounds.centerLeft.dy;

    // Add two stops.
    var gradientStopA = GradientStop()
      ..color = defaultGradientColorA
      ..position = 0;
    var gradientStopB = GradientStop()
      ..color = defaultGradientColorB
      ..position = 1;

    file.add(gradient);
    file.add(gradientStopA);
    file.add(gradientStopB);
    gradient.appendChild(gradientStopA);
    gradient.appendChild(gradientStopB);

    editingIndex.value = 0;
    return gradient;
  }

  /// Add a gradient stop at [position].
  void addStop(double position) {
    assert(position >= 0 && position <= 1);
    assert(type.value == ColorType.linear || type.value == ColorType.radial);

    var file = context;

    // Find the interpolated color value that's at the position.
    var gradientStops = stops.value;
    Color colorAtPosition;
    int index =
        gradientStops.indexWhere((element) => element.position >= position);
    int newIndex;
    if (index == -1) {
      // All stops are less than the currently supplied position.
      colorAtPosition = gradientStops.last.color;
      // At end.
      newIndex = gradientStops.length;
    } else if (index == 0) {
      // All stops are greater than the currently supplied position.
      colorAtPosition = gradientStops.first.color;
      // At start.
      newIndex = 0;
    } else {
      // Interpolate between index and index+1
      var from = gradientStops[index - 1];
      var to = gradientStops[index];
      colorAtPosition = Color.lerp(from.color, to.color,
          (position - from.position) / (to.position - from.position));
      newIndex = index;
    }

    // Batch the operation so that we can pick apart the hierarchy and then
    // resolve once we're done changing everything.
    file.batchAdd(() {
      for (final paint in shapePaints) {
        // This works because radial are also linear gradients.
        var gradient = paint.paintMutator as core.LinearGradient;
        var gradientStop = GradientStop()
          ..color = colorAtPosition
          ..position = position;
        file.add(gradientStop);
        gradient.appendChild(gradientStop);
        gradient.update(ComponentDirt.stops);
      }
    });
    editingIndex.value = newIndex;
    _updatePaints();

    completeChange();
  }

  /// Change the position of the currently selected (determined by
  /// [editingIndex]) gradient stop.
  void changeStopPosition(double position) {
    assert(type.value == ColorType.linear || type.value == ColorType.radial);
    int index = editingIndex.value;
    int newStopIndex = -1;
    for (final paint in shapePaints) {
      var gradient = paint.paintMutator as core.LinearGradient;
      var stop = gradient.gradientStops[index];
      stop.position = position;
      // Force update the stops as we change them. This is pretty hideous but we
      // don't want to bloat LinearGradient to handle this differently as at
      // runtime most people will just be setting the position on a
      // GradientStop. We need to immediately know the correct order of the
      // stops, this forces the re-sort.
      gradient.update(ComponentDirt.stops);
      // Find where the index ended up. We can assume if one stop changes all of
      // them do.
      if (newStopIndex == -1) {
        newStopIndex = gradient.gradientStops.indexOf(stop);
      }
    }
    if (newStopIndex != index) {
      editingIndex.value = newStopIndex;
    }

    _updatePaints();
  }

  void changeType(ColorType colorType) {
    if (type.value == colorType) {
      return;
    }

    var file = context;

    // Batch the operation so that we can pick apart the hierarchy and then
    // resolve once we're done changing everything.
    file.batchAdd(() {
      for (final paint in shapePaints) {
        var mutator = paint.paintMutator as Component;

        var shape =
            mutator == null ? paint.parent as Shape : paint.paintMutator.shape;
        // Remove the old paint mutator (this is what a color component is
        // referenced as in the fill/stroke).
        if (mutator is ContainerComponent) {
          // If it's a container (like a gradient which contains color stops)
          // make sure to remove everything.
          mutator.removeRecursive();
        } else if (mutator != null) {
          mutator.remove();
        }
        Component colorComponent;
        switch (colorType) {
          case ColorType.solid:
            colorComponent = SolidColor();
            file.add(colorComponent);
            break;
          case ColorType.linear:
            colorComponent = _initGradient(shape, core.LinearGradient());
            break;
          case ColorType.radial:
            colorComponent = _initGradient(shape, core.RadialGradient());
            break;
        }
        if (colorComponent != null) {
          paint.appendChild(colorComponent);
        }
      }
    });

    // Hierarchy has now resolved, new mutators have been assined to shapePaints
    // (fills/strokes).

    _updatePaints();

    completeChange();
  }

  /// Change the currently editing color
  void changeColor(HSVColor color) {
    editingColor.value = color;
    switch (type.value) {
      case ColorType.solid:
        _changeSolidColor(color.toColor());
        break;
      default:
        break;
    }
  }

  RiveFile get context => shapePaints.first.context;

  void completeChange() {
    context?.captureJournalEntry();
  }

  void dispose() {
    for (final paint in shapePaints) {
      paint.paintMutatorChanged.removeListener(_mutatorChanged);
    }
    _clearListeners();
  }

  void _clearListeners() {
    // clear out old listeners
    _listeningToCoreProperties.forEach((component, value) {
      for (final propertyKey in value) {
        component.removeListener(propertyKey, _valueChanged);
      }
    });
    _listeningToCoreProperties.clear();
    for (final notifier in _listeningTo) {
      notifier.removeListener(_notified);
    }
    _listeningTo.clear();
  }

  void _changeSolidColor(Color color) {
    _suppressUpdating = true;

    // Track whether or not we added new core objects.
    bool added = false;
    var context = shapePaints.first.context;
    // Do the change in a batch add as it can create new core objects.
    // context.batchAdd(() {

    // make sure we have SolidColors, make them if we don't and delete
    // existing mutators.
    for (final paint in shapePaints) {
      SolidColor solid;
      if (paint.paintMutator is SolidColor) {
        solid = paint.paintMutator as SolidColor;
      } else {
        if (paint.paintMutator != null) {
          /// Remove the old color.
          context.remove(paint.paintMutator as Component);
        }
        added = true;
        solid = SolidColor();
        context.add(solid);
        paint.appendChild(solid);
      }
      solid.color = color;
    }

    _suppressUpdating = false;

    if (added) {
      // Re-build the listeners if we added objects.
      _updatePaints();
    }
    // Force update the preview.
    preview.value = [editingColor.value.toColor()];

    // });
  }

  void _listenToCoreProperty(Component component, int propertyKey) {
    if (component.addListener(propertyKey, _valueChanged)) {
      var keySet = _listeningToCoreProperties[component] ??= {};
      keySet.add(propertyKey);
    }
  }

  void _listenTo(ChangeNotifier notifier) {
    if (_listeningTo.add(notifier)) {
      notifier.addListener(_notified);
    }
  }

  ColorType _determineColorType() =>
      core.equalValue<ShapePaint, ColorType>(shapePaints, (shapePaint) {
        // determine which concrete color type this shapePaint is using.
        var colorComponent = shapePaint.paintMutator as Component;
        if (colorComponent == null) {
          return null;
        }
        switch (colorComponent.coreType) {
          case SolidColorBase.typeKey:
            return ColorType.solid;
          case core.LinearGradientBase.typeKey:
            return ColorType.linear;
          case core.RadialGradientBase.typeKey:
            return ColorType.radial;
        }
        return null;
      });

  /// Update current color type and state, also register (and cleanup) listeners
  /// for changes due to undo/redo.
  void _updatePaints() {
    // Are we all the same type?
    var colorType = _determineColorType();

    _clearListeners();

    var first = shapePaints.first.paintMutator;
    switch (colorType) {
      case ColorType.solid:
        // If the full list is solid then we definitely have a SolidColor
        // mutator.
        editingColor.value = HSVColor.fromColor((first as SolidColor).color);

        if (preview.value.length != 1 ||
            preview.value.first != editingColor.value.toColor()) {
          // check all colors are the same
          Color color = core.equalValue<ShapePaint, Color>(shapePaints,
              (shapePaint) => (shapePaint.paintMutator as SolidColor).color);
          preview.value = color == null ? [] : [color];
        }

        // Since they're all solid, we know they'll all have a Core colorValue
        // that change that we want to listen to.
        for (final shapePaint in shapePaints) {
          _listenToCoreProperty(shapePaint.paintMutator as Component,
              SolidColorBase.colorValuePropertyKey);
        }

        break;
      case ColorType.linear:
      case ColorType.radial:
        // Check if all the colorStops are the same across the selected
        // shapePaints. This is pretty verbose, but what it boils down to is
        // needing a custom equality check for GradientStops as we didn't want
        // to override the equality check on the core values as their default
        // equality should be based on exact reference. Since the GradienStops
        // are stored in Lists, we need a custom equality check for the
        // equalValue call too.
        List<GradientStop> colorStops =
            core.equalValue<ShapePaint, List<GradientStop>>(
          shapePaints,
          (shapePaint) =>
              (shapePaint.paintMutator as core.LinearGradient).gradientStops,
          // Override the equality check for the equalValue as we want it to use
          // listEquals
          equalityCheck: (a, b) => core.listEquals(
            a,
            b,
            // Override the listEquals equality as in this case we consider
            // GradientStops equal if they have the same value and color.
            equalityCheck: (GradientStop a, GradientStop b) =>
                a.colorValue == b.colorValue && a.position == b.position,
          ),
        );

        // Set the preview swatch color and the stops abstraction for the whole
        // selected set.
        if (colorStops == null) {
          preview.value = [];
          stops.value = [];
        } else {
          preview.value =
              colorStops.map((stop) => stop.color).toList(growable: true);
          stops.value = colorStops
              .map((stop) => InspectingColorStop(stop))
              .toList(growable: true);
        }
        if (editingIndex.value >= stops.value.length) {
          editingIndex.value = stops.value.length - 1;
        }

        // Listen to events we are interested in. These will trigger another
        // _updatePaints call.
        for (final shapePaint in shapePaints) {
          var gradient = shapePaint.paintMutator as core.LinearGradient;
          _listenTo(gradient.stopsChanged);
          for (final stop in gradient.gradientStops) {
            _listenToCoreProperty(stop, GradientStopBase.positionPropertyKey);
          }
        }
        break;
    }
    type.value = colorType;
  }

  void _notified() {
    if (_suppressUpdating) {
      return;
    }
    debounce(_updatePaints);
  }

  void _valueChanged(dynamic from, dynamic to) {
    if (_suppressUpdating) {
      return;
    }
    debounce(_updatePaints);
  }

  void _mutatorChanged() {
    if (_suppressUpdating) {
      return;
    }
    debounce(_updatePaints);
  }
}

/// Inspector specific data for the color stop. We need the common gradient
/// properties across the full selection set. This is a simplified data
/// representation just for the purposes of the inspector.
class InspectingColorStop {
  final double position;
  final Color color;

  InspectingColorStop(GradientStop stop)
      : position = stop.position,
        color = stop.color;

  InspectingColorStop.fromValues(this.position, this.color);
}
