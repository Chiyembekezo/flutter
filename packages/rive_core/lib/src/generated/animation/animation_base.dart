/// Core automatically generated
/// lib/src/generated/animation/animation_base.dart.
/// Do not modify manually.

import 'package:core/core.dart';
import 'package:meta/meta.dart';
import 'package:rive_core/src/generated/rive_core_context.dart';

abstract class AnimationBase<T extends RiveCoreContext> extends Core<T> {
  static const int typeKey = 27;
  @override
  int get coreType => AnimationBase.typeKey;
  @override
  Set<int> get coreTypes => {AnimationBase.typeKey};

  /// --------------------------------------------------------------------------
  /// ArtboardId field with key 54.
  Id _artboardId;
  static const int artboardIdPropertyKey = 54;

  /// Identifier used to track the artboard this animation belongs to.
  Id get artboardId => _artboardId;

  /// Change the [_artboardId] field value.
  /// [artboardIdChanged] will be invoked only if the field's value has changed.
  set artboardId(Id value) {
    if (_artboardId == value) {
      return;
    }
    Id from = _artboardId;
    _artboardId = value;
    artboardIdChanged(from, value);
  }

  @mustCallSuper
  void artboardIdChanged(Id from, Id to) {
    onPropertyChanged(artboardIdPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Name field with key 55.
  String _name;
  static const int namePropertyKey = 55;

  /// Name of the animation.
  String get name => _name;

  /// Change the [_name] field value.
  /// [nameChanged] will be invoked only if the field's value has changed.
  set name(String value) {
    if (_name == value) {
      return;
    }
    String from = _name;
    _name = value;
    nameChanged(from, value);
  }

  @mustCallSuper
  void nameChanged(String from, String to) {
    onPropertyChanged(namePropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Fps field with key 56.
  int _fps;
  static const int fpsPropertyKey = 56;

  /// Frames per second used to quantize keyframe times to discrete values that
  /// match this rate.
  int get fps => _fps;

  /// Change the [_fps] field value.
  /// [fpsChanged] will be invoked only if the field's value has changed.
  set fps(int value) {
    if (_fps == value) {
      return;
    }
    int from = _fps;
    _fps = value;
    fpsChanged(from, value);
  }

  @mustCallSuper
  void fpsChanged(int from, int to) {
    onPropertyChanged(fpsPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Duration field with key 57.
  int _duration;
  static const int durationPropertyKey = 57;

  /// Duration expressed in number of frames.
  int get duration => _duration;

  /// Change the [_duration] field value.
  /// [durationChanged] will be invoked only if the field's value has changed.
  set duration(int value) {
    if (_duration == value) {
      return;
    }
    int from = _duration;
    _duration = value;
    durationChanged(from, value);
  }

  @mustCallSuper
  void durationChanged(int from, int to) {
    onPropertyChanged(durationPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Speed field with key 58.
  double _speed;
  static const int speedPropertyKey = 58;

  /// Playback speed multiplier.
  double get speed => _speed;

  /// Change the [_speed] field value.
  /// [speedChanged] will be invoked only if the field's value has changed.
  set speed(double value) {
    if (_speed == value) {
      return;
    }
    double from = _speed;
    _speed = value;
    speedChanged(from, value);
  }

  @mustCallSuper
  void speedChanged(double from, double to) {
    onPropertyChanged(speedPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Loop field with key 59.
  int _loop;
  static const int loopPropertyKey = 59;

  /// Loop value option matches LoopType enumeration.
  int get loop => _loop;

  /// Change the [_loop] field value.
  /// [loopChanged] will be invoked only if the field's value has changed.
  set loop(int value) {
    if (_loop == value) {
      return;
    }
    int from = _loop;
    _loop = value;
    loopChanged(from, value);
  }

  @mustCallSuper
  void loopChanged(int from, int to) {
    onPropertyChanged(loopPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// WorkStart field with key 60.
  int _workStart;
  static const int workStartPropertyKey = 60;

  /// Start of the work area in frames.
  int get workStart => _workStart;

  /// Change the [_workStart] field value.
  /// [workStartChanged] will be invoked only if the field's value has changed.
  set workStart(int value) {
    if (_workStart == value) {
      return;
    }
    int from = _workStart;
    _workStart = value;
    workStartChanged(from, value);
  }

  @mustCallSuper
  void workStartChanged(int from, int to) {
    onPropertyChanged(workStartPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// WorkEnd field with key 61.
  int _workEnd;
  static const int workEndPropertyKey = 61;

  /// End of the work area in frames.
  int get workEnd => _workEnd;

  /// Change the [_workEnd] field value.
  /// [workEndChanged] will be invoked only if the field's value has changed.
  set workEnd(int value) {
    if (_workEnd == value) {
      return;
    }
    int from = _workEnd;
    _workEnd = value;
    workEndChanged(from, value);
  }

  @mustCallSuper
  void workEndChanged(int from, int to) {
    onPropertyChanged(workEndPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// EnableWorkArea field with key 62.
  bool _enableWorkArea;
  static const int enableWorkAreaPropertyKey = 62;

  /// Whether or not the work area is enabled.
  bool get enableWorkArea => _enableWorkArea;

  /// Change the [_enableWorkArea] field value.
  /// [enableWorkAreaChanged] will be invoked only if the field's value has
  /// changed.
  set enableWorkArea(bool value) {
    if (_enableWorkArea == value) {
      return;
    }
    bool from = _enableWorkArea;
    _enableWorkArea = value;
    enableWorkAreaChanged(from, value);
  }

  @mustCallSuper
  void enableWorkAreaChanged(bool from, bool to) {
    onPropertyChanged(enableWorkAreaPropertyKey, from, to);
  }

  @override
  void changeNonNull() {
    if (artboardId != null) {
      onPropertyChanged(artboardIdPropertyKey, artboardId, artboardId);
    }
    if (name != null) {
      onPropertyChanged(namePropertyKey, name, name);
    }
    if (fps != null) {
      onPropertyChanged(fpsPropertyKey, fps, fps);
    }
    if (duration != null) {
      onPropertyChanged(durationPropertyKey, duration, duration);
    }
    if (speed != null) {
      onPropertyChanged(speedPropertyKey, speed, speed);
    }
    if (loop != null) {
      onPropertyChanged(loopPropertyKey, loop, loop);
    }
    if (workStart != null) {
      onPropertyChanged(workStartPropertyKey, workStart, workStart);
    }
    if (workEnd != null) {
      onPropertyChanged(workEndPropertyKey, workEnd, workEnd);
    }
    if (enableWorkArea != null) {
      onPropertyChanged(
          enableWorkAreaPropertyKey, enableWorkArea, enableWorkArea);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case artboardIdPropertyKey:
        return artboardId as K;
      case namePropertyKey:
        return name as K;
      case fpsPropertyKey:
        return fps as K;
      case durationPropertyKey:
        return duration as K;
      case speedPropertyKey:
        return speed as K;
      case loopPropertyKey:
        return loop as K;
      case workStartPropertyKey:
        return workStart as K;
      case workEndPropertyKey:
        return workEnd as K;
      case enableWorkAreaPropertyKey:
        return enableWorkArea as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case artboardIdPropertyKey:
      case namePropertyKey:
      case fpsPropertyKey:
      case durationPropertyKey:
      case speedPropertyKey:
      case loopPropertyKey:
      case workStartPropertyKey:
      case workEndPropertyKey:
      case enableWorkAreaPropertyKey:
        return true;
      default:
        return super.getProperty(propertyKey);
    }
  }
}
