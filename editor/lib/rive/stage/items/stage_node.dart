import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/node.dart';

import '../stage_item.dart';

class StageNode extends StageItem<Node> {
  @override
  AABB get aabb => AABB.fromValues(0, 0, 1, 1);
}
