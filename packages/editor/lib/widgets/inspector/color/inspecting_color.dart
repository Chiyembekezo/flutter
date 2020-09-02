import 'package:core/debounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_core/component.dart';
import 'package:core/core.dart' as core;
import 'package:utilities/list_equality.dart' as utils;
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:rive_core/shapes/paint/gradient_stop.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart' as core;
import 'package:rive_core/shapes/paint/radial_gradient.dart' as core;
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/items/stage_gradient_stop.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/widgets/inspector/color/color_type.dart';
import 'package:utilities/restorer.dart';

/// Color change callback used by the various color picker components.
typedef ChangeColor = void Function(HSVColor);

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

/// Abstraction of the currently inspected color.
abstract class InspectingColor {
  static const HSVColor defaultEditingColor = HSVColor.fromAHSV(1, 0, 0, 0);
  static const Color defaultSolidColor = Color(0xFF747474);
  static const Color defaultGradientColorA = Color(0xFFFFFFFF);
  static const Color defaultGradientColorB = Color(0xFF000000);

  OpenFileContext _context;
  OpenFileContext get context => _context;

  bool startEditing(OpenFileContext context) {
    assert(context != null);
    if (_context == context) {
      return false;
    }
    _context = context;
    debounce(editorOpened);
    return true;
  }

  void stopEditing() {
    _context = null;
    debounce(editorClosed);
  }

  bool get isEditing => _context != null;

  @protected
  void editorOpened();

  @protected
  void editorClosed();

  // The user clicked on the close guard for the popup owning the inspecting
  // color. Return to close. This method returns a future in case you need to
  // debounce or wait for another action to determine if the close should occur.
  Future<bool> shouldClickGuardClosePopup() async {
    return true;
  }

  /// Whether the inspecting color is a solid or a linear/radial gradient.
  final ValueNotifier<ColorType> type = ValueNotifier<ColorType>(null);

  /// The colors to show in the preview swatch.
  final ValueNotifier<List<Color>> preview = ValueNotifier<List<Color>>([]);

  /// The editing index in the list of color stops.
  final ValueNotifier<int> editingIndex = ValueNotifier<int>(0);

  /// The opacity value of the inspecting color.
  final ValueNotifier<double> opacity = ValueNotifier<double>(1);

  bool get canChangeType;

  /// The value of the currently editing color.
  final ValueNotifier<HSVColor> editingColor =
      ValueNotifier<HSVColor>(defaultEditingColor);

  /// The list of color stops used if the current type is a gradient.
  final ValueNotifier<List<InspectingColorStop>> stops =
      ValueNotifier<List<InspectingColorStop>>(null);

  InspectingColor();

  factory InspectingColor.forShapePaints(
    Iterable<ShapePaint> paints, {
    bool canChangeType = true,
  }) =>
      ShapesInspectingColor(paints, canChangeType: canChangeType);

  factory InspectingColor.forSolidProperty(
          Iterable<core.Core> objects, int propertyKey) =>
      _CorePropertyInspectingColor(objects, propertyKey);

  @mustCallSuper
  void dispose() {
    stopEditing();
    cancelDebounce(editorOpened);
    cancelDebounce(editorClosed);
  }

  /// Change the color type.
  void changeType(ColorType colorType);

  /// Add a gradient stop at [position].
  void addStop(double position);

  /// Change the position of the currently selected (determined by
  /// [editingIndex]) gradient stop.
  void changeStopPosition(double position);

  /// Change the editing color stop index.
  void changeStopIndex(int index);

  /// Change the currently editing color
  void changeColor(HSVColor color);

  void _changeEditingColor(HSVColor color, {bool force = false}) {
    if (!force && color.toColor() == editingColor.value.toColor()) {
      return;
    }
    editingColor.value = color;
  }

  /// Complete the set of changes performed thus far.
  void completeChange() {
    context?.core?.captureJournalEntry();
  }

  /// Change the opacity of the inspecting color.
  void changeOpacity(double opacity);
}

/// Concrete implementation of InspectingColor for [ShapePaint]s.
class ShapesInspectingColor extends InspectingColor {
  // Keep track of what we've added to the stage so far.
  final Set<StageItem> _addedToStage = {};

  @override
  bool canChangeType;

  /// Track which properties we're listening to on each component. This varies
  /// depending on whether it's a solid color, gradient, etc.
  final Map<Component, Set<int>> _listeningToCoreProperties = {};
  final Set<ChangeNotifier> _listeningTo = {};

  /// Whether we should perform an update in response to a core value change.
  /// This allows us to not re-process updates as we're interactively changing
  /// values from this inspector.
  bool _suppressUpdating = false;

  Iterable<ShapePaint> shapePaints;
  ShapesInspectingColor(
    this.shapePaints, {
    this.canChangeType = true,
  }) {
    for (final paint in shapePaints) {
      paint.paintMutatorChanged.addListener(_mutatorChanged);
    }
    _updatePaints();
  }

  /// We override this method to check if a stage gradient handle was clicked on
  /// to prevent closing the popup.
  @override
  Future<bool> shouldClickGuardClosePopup() async {
    return Future.delayed(const Duration(milliseconds: 20), () {
      var didSelect = _didSelectGradientHandle;
      _didSelectGradientHandle = false;
      return !didSelect;
    });
  }

  /// Because radial gradients inherit from linear ones, we can share some of
  /// the common aspects of creating one here.
  core.LinearGradient _initGradient(
      ShapePaintContainer shape, core.LinearGradient gradient) {
    var file = shape.context;
    var bounds = shape.localBounds;
    var rect = Rect.fromLTRB(bounds[0], bounds[1], bounds[2], bounds[3]);
    gradient
      ..startX = rect.left
      ..startY = rect.centerLeft.dy
      ..endX = rect.right
      ..endY = rect.centerLeft.dy;

    // Add two stops.
    var gradientStopA = GradientStop()
      ..color = InspectingColor.defaultGradientColorA
      ..position = 0;
    var gradientStopB = GradientStop()
      ..color = InspectingColor.defaultGradientColorB
      ..position = 1;

    file.addObject(gradient);
    file.addObject(gradientStopA);
    file.addObject(gradientStopB);
    gradient.appendChild(gradientStopA);
    gradient.appendChild(gradientStopB);

    changeStopIndex(0, updatePaints: false);
    return gradient;
  }

  @override
  void addStop(double position) {
    assert(position >= 0 && position <= 1);
    assert(type.value == ColorType.linear || type.value == ColorType.radial);

    var file = context.core;

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
        file.addObject(gradientStop);
        gradient.appendChild(gradientStop);
        gradient.update(ComponentDirt.stops);
      }
    });
    changeStopIndex(newIndex, updatePaints: true);
    completeChange();
  }

  @override
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
      changeStopIndex(newStopIndex, updatePaints: false);
    }

    _updatePaints();
  }

  @override
  void changeStopIndex(int index, {bool updatePaints = true}) {
    editingIndex.value = index;
    if (shapePaints.length == 1 && isEditing) {
      // Find the gradient stop.
      var gradient = shapePaints.first.paintMutator as core.LinearGradient;
      if (gradient != null) {
        var stop = gradient.gradientStops[index];
        if (stop.stageItem != null) {
          // Select all shapes and the stop.
          _context.selection.selectMultiple(shapePaints
              .map((shapePaint) =>
                  (shapePaint.paintMutator.shapePaintContainer as Component)
                      .stageItem)
              .toList()
                ..add(stop.stageItem));
        }
      }
    }
    if (updatePaints) {
      _updatePaints();
    }
  }

  /// Change the color type. This will clear out the existing paint mutators
  /// from all the shapePaints (fills/strokes) and create new one matching the
  /// desired type.
  @override
  void changeType(ColorType colorType) {
    if (type.value == colorType) {
      return;
    }

    var file = context.core;

    // Batch the operation so that we can pick apart the hierarchy and then
    // resolve once we're done changing everything.
    file.batchAdd(() {
      for (final paint in shapePaints) {
        var mutator = paint.paintMutator as Component;

        var paintContainer = mutator == null
            ? paint.parent as Shape
            : paint.paintMutator.shapePaintContainer;
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
            file.addObject(colorComponent);
            break;
          case ColorType.linear:
            colorComponent =
                _initGradient(paintContainer, core.LinearGradient());
            break;
          case ColorType.radial:
            colorComponent =
                _initGradient(paintContainer, core.RadialGradient());
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

  @override
  void changeColor(HSVColor color) {
    _changeEditingColor(color, force: true);
    switch (type.value) {
      case ColorType.solid:
        _changeSolidColor(color.toColor());
        break;
      default:
        _changeGradientColor(color.toColor());
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();

    for (final item in _addedToStage) {
      item.stage?.removeItem(item);
    }
    _addedToStage.clear();

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

  void _changeGradientColor(Color color) {
    var index = editingIndex.value;
    for (final paint in shapePaints) {
      // This works because radial are also linear gradients.
      var gradient = paint.paintMutator as core.LinearGradient;
      gradient.gradientStops[index].color = color;
    }
    _updatePaints();
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
          context.removeObject(paint.paintMutator as Component);
        }
        added = true;
        solid = SolidColor();
        context.addObject(solid);
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
    opacity.value = color.alpha / 255;

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
      utils.equalValue<ShapePaint, ColorType>(shapePaints, (shapePaint) {
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

    Set<StageItem> wantOnStage = {};

    var first = shapePaints.first.paintMutator;
    switch (colorType) {
      case ColorType.solid:
        // If the full list is solid then we definitely have a SolidColor
        // mutator.
        var color = (first as SolidColor).color;
        _changeEditingColor(HSVColor.fromColor(color));
        opacity.value = color.alpha / 255;

        if (preview.value.length != 1 ||
            preview.value.first != editingColor.value.toColor()) {
          // check all colors are the same
          Color color = utils.equalValue<ShapePaint, Color>(shapePaints,
              (shapePaint) => (shapePaint.paintMutator as SolidColor).color);
          preview.value = color == null ? [] : [color];
        }

        break;
      case ColorType.linear:
      case ColorType.radial:
        // Only show the stage color stops if we only have one shape selected.
        bool showStageStops = shapePaints.length == 1;

        // Check if all the colorStops are the same across the selected
        // shapePaints. This is pretty verbose, but what it boils down to is
        // needing a custom equality check for GradientStops as we didn't want
        // to override the equality check on the core values as their default
        // equality should be based on exact reference. Since the GradienStops
        // are stored in Lists, we need a custom equality check for the
        // equalValue call too.
        List<GradientStop> colorStops =
            utils.equalValue<ShapePaint, List<GradientStop>>(
          shapePaints,
          (shapePaint) =>
              (shapePaint.paintMutator as core.LinearGradient).gradientStops,
          // Override the equality check for the equalValue as we want it to use
          // listEquals
          equalityCheck: (a, b) => utils.listEquals(
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
          // Set the color type to null as they are different, we need to change
          // the type in the dropdown to get to something common.
          colorType = null;
        } else {
          preview.value =
              colorStops.map((stop) => stop.color).toList(growable: false);
          stops.value = colorStops
              .map((stop) => InspectingColorStop(stop))
              .toList(growable: false);

          if (editingIndex.value >= stops.value.length) {
            changeStopIndex(stops.value.length - 1, updatePaints: false);
          } else if (editingIndex.value != null) {
            // re-update the stop index so it selects the stage item (if we want
            // it).
            changeStopIndex(editingIndex.value, updatePaints: false);
          }
          if (editingIndex.value >= 0) {
            _changeEditingColor(
                HSVColor.fromColor(stops.value[editingIndex.value].color));
          }
        }

        // Determine what we want on the stage.
        for (final shapePaint in shapePaints) {
          var gradient = shapePaint.paintMutator as core.LinearGradient;
          if (gradient.stageItem != null && showStageStops) {
            wantOnStage.add(gradient.stageItem);
          }
          for (final stop in gradient.gradientStops) {
            if (showStageStops && stop.stageItem != null) {
              wantOnStage.add(stop.stageItem);
            }
          }
        }
        break;
    }

    // Listen to any property change on any shape paint regardless of current
    // shared type.
    for (final shapePaint in shapePaints) {
      var mutator = shapePaint.paintMutator;
      if (mutator is core.LinearGradient) {
        _listenTo(mutator.stopsChanged);
        _listenToCoreProperty(
            mutator, core.LinearGradientBase.opacityPropertyKey);
        for (final stop in mutator.gradientStops) {
          _listenToCoreProperty(stop, GradientStopBase.positionPropertyKey);
          _listenToCoreProperty(stop, GradientStopBase.colorValuePropertyKey);
        }
      } else if (mutator is SolidColor) {
        _listenToCoreProperty(mutator, SolidColorBase.colorValuePropertyKey);
      }
    }

    type.value = colorType;
    if (colorType == null) {
      _changeEditingColor(InspectingColor.defaultEditingColor);
      preview.value = [];
    }

    // Check if all opacity values are equal.
    double commonOpacity =
        utils.equalValue<ShapePaint, double>(shapePaints, (shapePaint) {
      var mutator = shapePaint.paintMutator;
      if (mutator is core.LinearGradient) {
        return mutator.opacity;
      } else if (mutator is SolidColor) {
        return mutator.color.opacity;
      }
      return 0;
    });

    opacity.value = commonOpacity;

    // Determine what we want on stage vs what we've already added to remove the
    // old ones. Even if some get removed via deletion outside of this
    // inspector, the leak is short lived (as soon as the inspector is closed it
    // is cleared), and we check for stage before removing from it, so we won't
    // have contention with null stage values.

    if (!isEditing) {
      // We don't want anything on the stage if the editor isn't open yet.
      wantOnStage.clear();
    }

    var removeFromStage = _addedToStage.difference(wantOnStage);

    for (final remove in removeFromStage) {
      remove.stage?.removeItem(remove);
    }

    var stage = _context?.stage;
    if (stage != null) {
      wantOnStage.forEach(stage.addItem);
    }

    _addedToStage.clear();
    _addedToStage.addAll(wantOnStage);
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

  Restorer _selectionHandlerRestorer;

  @override
  bool startEditing(OpenFileContext context) {
    if (super.startEditing(context)) {
      _selectionHandlerRestorer?.restore();
      context.removeActionHandler(_handleShortcut);

      _selectionHandlerRestorer =
          context.stage.addSelectionHandler(_stageSelected);
      context.addActionHandler(_handleShortcut);
      return true;
    }
    return false;
  }

  bool _handleShortcut(ShortcutAction action) {
    if (context == null || action != ShortcutAction.delete) {
      return false;
    }
    var stops = context.selection.items.whereType<StageGradientStop>();
    if (stops.isEmpty) {
      return false;
    }

    // Delete the selected stops and handle the shortcut. Make a copy of it so
    // it doesn't get modified as we iterate.
    for (final stageStop in stops.toList(growable: false)) {
      // Make sure this operation doesn't leave the gradient with less than 2
      // stops.
      var gradient = stageStop.component.parent as core.LinearGradient;
      if (gradient.gradientStops.length > 2) {
        stageStop.component.remove();
      }
    }
    context.core.captureJournalEntry();
    return true;
  }

  Restorer _hiddenHandles;

  @override
  void stopEditing() {
    _selectionHandlerRestorer?.restore();
    context?.removeActionHandler(_handleShortcut);

    _hiddenHandles?.restore();
    super.stopEditing();
  }

  // N.B. this may not be called if it's canceled during dispose, so do all
  // cleanup in stopEditing.
  @override
  void editorClosed() => _updatePaints();

  @override
  void editorOpened() {
    _hiddenHandles?.restore();
    _hiddenHandles = context?.stage?.hideHandles();
    _updatePaints();
  }

  bool _didSelectGradientHandle = false;
  bool _stageSelected(StageItem item) {
    if (item is StageGradientStop) {
      _didSelectGradientHandle = true;
      var gradient = item.component.parent as core.LinearGradient;
      var stopIndex = gradient.gradientStops.indexOf(item.component);
      changeStopIndex(stopIndex, updatePaints: false);
      _changeEditingColor(
          HSVColor.fromColor(stops.value[editingIndex.value].color));
    }
    // We never handle stage selection, always allow the stage to proceed as it
    // needs. #1097
    return false;
  }

  @override
  void changeOpacity(double value) {
    var validValue = value.clamp(0, 1).toDouble();

    // If there are any solid colors, use a valid valid in 8 bit range.
    if (shapePaints.firstWhere((shape) => shape.paintMutator is SolidColor,
            orElse: () => null) !=
        null) {
      // put valid value in 0-255 range so that all values are equal
      // regardless of backing storage.
      validValue = const Color(0xFFFFFFFF).withOpacity(validValue).opacity;
    }

    for (final shape in shapePaints) {
      var mutator = shape.paintMutator;
      if (mutator is core.LinearGradient) {
        mutator.opacity = validValue;
      } else if (mutator is SolidColor) {
        var color = mutator.color.withOpacity(validValue);
        mutator.color = color;
      }
    }
    _updatePaints();
  }
}

/// Concrete implementation of InspectingColor for any core property that
/// exposes a solid color as an integer. Doesn't allow changing types from solid
/// color.
class _CorePropertyInspectingColor extends InspectingColor {
  @override
  bool get canChangeType => false;

  /// Whether we should perform an update in response to a core value change.
  /// This allows us to not re-process updates as we're interactively changing
  /// values from this inspector.
  bool _suppressUpdating = false;

  final Iterable<core.Core> objects;
  final int propertyKey;

  _CorePropertyInspectingColor(this.objects, this.propertyKey) {
    type.value = ColorType.solid;
    for (final object in objects) {
      object.addListener(propertyKey, _propertyKeyChange);
    }
    _updatePaints();
  }

  void _propertyKeyChange(dynamic from, dynamic to) {
    if (_suppressUpdating) {
      return;
    }
    debounce(_updatePaints);
  }

  @override
  void dispose() {
    super.dispose();
    for (final object in objects) {
      object.removeListener(propertyKey, _propertyKeyChange);
    }
  }

  Color _colorValue(core.Core object) =>
      Color(object.getProperty<int>(propertyKey));

  void _updatePaints() {
    if (objects.isEmpty) {
      preview.value = [];
      return;
    }

    var first = _colorValue(objects.first);
    editingColor.value = HSVColor.fromColor(first);
    opacity.value = first.alpha / 255;

    if (preview.value.length != 1 ||
        preview.value.first != editingColor.value.toColor()) {
      // check all colors are the same
      Color color = utils.equalValue<core.Core, Color>(objects, _colorValue);
      preview.value = color == null ? [] : [color];
    }
  }

  @override
  void changeColor(HSVColor color) {
    editingColor.value = color;
    opacity.value = color.alpha / 255;
    _suppressUpdating = true;

    var value = color.toColor().value;
    for (final object in objects) {
      object.context.setObjectProperty(object, propertyKey, value);
    }

    _suppressUpdating = false;

    preview.value = [editingColor.value.toColor()];
  }

  @override
  void addStop(double position) {
    throw UnsupportedError('Cannot add color stop to a solid core color.');
  }

  @override
  void changeStopIndex(int index) {
    throw UnsupportedError('Cannot change stop index for a solid core color.');
  }

  @override
  void changeStopPosition(double position) {
    throw UnsupportedError(
        'Cannot change stop position for a solid core color.');
  }

  @override
  void changeType(ColorType type) {
    throw UnsupportedError('Cannot change type for a solid core color.');
  }

  @override
  void editorClosed() {}

  @override
  void editorOpened() {}

  @override
  void changeOpacity(double opacity) {
    var colorType = type.value;
    if (colorType == null) {
      return;
    }
    switch (colorType) {
      case ColorType.solid:
        changeColor(editingColor.value.withAlpha(opacity));
        break;
      case ColorType.linear:
      case ColorType.radial:
        break;
    }
  }
}
