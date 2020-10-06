import 'package:flutter_test/flutter_test.dart';

import 'package:rive_core/shapes/rectangle.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/rive/stage/tools/auto_tool.dart';
import 'package:rive_editor/rive/stage/tools/rectangle_tool.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

import '../helpers/inspector_helper.dart';
import '../helpers/test_helpers.dart';

void main() {
  testWidgets('Correct inspectors are shown when a rectangle is selected',
      (tester) async {
    // TestWidgetsFlutterBinding.ensureInitialized();
    var file = await makeFile();
    var core = file.core;
    var stage = file.stage;

    // Place the mouse at an initial position...
    stage.mouseMove(1, 100, 100);

    // Select the pen tool and expect it to validate.
    stage.tool = RectangleTool.instance;
    expect(stage.tool, RectangleTool.instance);

    // Click and drag from 100, 100 to 300, 200
    stage.mouseDown(1, 100, 100);
    stage.mouseDrag(1, 100, 100);

    stage.mouseDrag(1, 300, 200);
    stage.mouseUp(1, 300, 200);

    expect(core.objectsOfType<Rectangle>().length, 1,
        reason: 'there should be one rectangle');

    // The autotool should be automatically selected after rectangle creation
    expect(stage.tool, AutoTool.instance);

    // Rectangle should be auto-selected
    expect(file.selection.isEmpty, false);

    final shape = core.objectsOfType<Shape>().first;

    // Complete any scheduled operations on the stage.
    stage.debounceAll(force: true);

    // Move the mouse over the rectangle
    // No hover if mouse isn't over anything
    stage.mouseMove(1, 150, 150);
    expect(stage.hoverItem, shape.stageItem);

    // Select the rectangle
    stage.mouseDown(1, 150, 150);
    stage.mouseUp(1, 150, 150);
    expect(file.selection.isEmpty, false);

    // The inspector should be displaying the correct inspector tools for a
    // rectangle
    await tester.pumpWidget(TestInspector(file: file));

    // timers need to settle
    await tester.pumpAndSettle();

    // await expectLater(
    //   find.byType(InspectorPanel),
    //   matchesGoldenFile('../assets/goldens/rectangle_inspector_test.png'),
    // );
  });
}
