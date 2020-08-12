import 'package:peon_process/converters.dart';
import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/transform_component.dart';

class KeyFrameOpacity extends KeyFrameConverter {
  const KeyFrameOpacity(num value, int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

  @override
  void convertKey(Component component, LinearAnimation animation, int frame) {
    generateKey<KeyFrameDoubleBase>(
        component, animation, frame, TransformComponentBase.opacityPropertyKey)
      ..value = (value as num).toDouble();
  }
}
