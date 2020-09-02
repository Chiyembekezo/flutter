import 'dart:math';

import 'package:peon_process/converters.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/cubic_asymmetric_vertex.dart';
import 'package:rive_core/shapes/cubic_detached_vertex.dart';
import 'package:rive_core/shapes/cubic_mirrored_vertex.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/straight_vertex.dart';

class PathPointConverter extends ComponentConverter {
  PathPointConverter(
      String pointType, RiveFile context, ContainerComponent maybeParent)
      : super(_getVertexFrom(pointType), context, maybeParent);

  static PathVertex _getVertexFrom(String pointType) {
    switch (pointType) {
      case 'S':
        return StraightVertex();
      case 'M':
        return CubicMirroredVertex();
      case 'D':
        return CubicDetachedVertex();
      case 'A':
        return CubicAsymmetricVertex();
      default:
        throw UnsupportedError('===== UNKNOWN VERTEX TYPE $pointType');
    }
  }

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);

    final translation = jsonData['translation'];
    final inVec = jsonData['in'];
    final outVec = jsonData['out'];
    final radius = jsonData['radius'];

    final pathVertex = component as PathVertexBase;

    if (translation is List) {
      pathVertex
        ..x = (translation[0] as num).toDouble()
        ..y = (translation[1] as num).toDouble();
    }

    if (pathVertex is StraightVertex) {
      pathVertex.radius = (radius as num).toDouble();
    } else if (pathVertex is CubicMirroredVertex) {
      // Cubic Mirrored Vertex needs a rotation and a distance.
      // In Flare a Mirrored vertex had:
      //    a translation, an in-point and an out-point.
      // Rotation and distance can be calculated from these:
      // - distance is just the distance between translation and either in or out
      // - rotation
      pathVertex
        ..rotation = getRotation(translation as List, outVec as List)
        ..distance = getDistance(translation as List, outVec as List);
    } else if (pathVertex is CubicDetachedVertex) {
      pathVertex
        ..inRotation = getRotation(translation as List, inVec as List)
        ..inDistance = getDistance(translation as List, inVec as List)
        ..outRotation = getRotation(translation as List, outVec as List)
        ..outDistance = getDistance(translation as List, outVec as List);
    } else if (pathVertex is CubicAsymmetricVertex) {
      pathVertex
        ..rotation = getRotation(translation as List, outVec as List)
        ..inDistance = getDistance(translation as List, inVec as List)
        ..outDistance = getDistance(translation as List, outVec as List);
    }
  }

  static double getDistance(List start, List end) {
    final x1 = (start[0] as num).toDouble();
    final x2 = (end[0] as num).toDouble();
    final y1 = (start[1] as num).toDouble();
    final y2 = (end[1] as num).toDouble();

    var dx = x1 - x2;
    var dy = y1 - y2;
    return sqrt(dx * dx + dy * dy);
  }

  static double getRotation(List first, List second) {
    final x1 = (first[0] as num).toDouble();
    final x2 = (second[0] as num).toDouble();
    final y1 = (first[1] as num).toDouble();
    final y2 = (second[1] as num).toDouble();
    final angle = atan2(y2 - y1, x2 - x1);
    return angle;
  }
}
