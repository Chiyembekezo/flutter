import 'package:rive/src/core/core.dart';
import 'package:logging/logging.dart';
import 'package:rive/src/rive_core/animation/interpolator.dart';
import 'package:rive/src/rive_core/animation/keyed_property.dart';
import 'package:rive/src/rive_core/animation/keyframe_interpolation.dart';
import 'package:rive/src/rive_core/animation/linear_animation.dart';
import 'package:rive/src/generated/animation/keyframe_base.dart';
export 'package:rive/src/generated/animation/keyframe_base.dart';

final _log = Logger('animation');

abstract class KeyFrame extends KeyFrameBase<RuntimeArtboard>
    implements KeyFrameInterface {
  double _timeInSeconds;
  double get seconds => _timeInSeconds;
  KeyFrameInterpolation get interpolation => interpolationType == null
      ? null
      : KeyFrameInterpolation.values[interpolationType];
  set interpolation(KeyFrameInterpolation value) {
    interpolationType = value.index;
  }

  @override
  void interpolationTypeChanged(int from, int to) {}
  @override
  void interpolatorIdChanged(int from, int to) {
    interpolator = context?.resolve(to);
  }

  @override
  void onAdded() {}
  void computeSeconds(LinearAnimation animation) {
    _timeInSeconds = frame / animation.fps;
  }

  @override
  void onAddedDirty() {
    if (interpolatorId != null) {
      interpolator = context?.resolve(interpolatorId);
      if (interpolator == null) {
        _log.finest("Failed to resolve interpolator with id $interpolatorId");
      }
    }
  }

  @override
  void onRemoved() {}
  @override
  void frameChanged(int from, int to) {}
  void apply(Core object, int propertyKey, double mix);
  void applyInterpolation(Core object, int propertyKey, double seconds,
      covariant KeyFrame nextFrame, double mix);
  Interpolator _interpolator;
  Interpolator get interpolator => _interpolator;
  set interpolator(Interpolator value) {
    if (_interpolator == value) {
      return;
    }
    _interpolator = value;
    interpolatorId = value?.id;
  }
}
