import 'package:flutter_test/flutter_test.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_key_binding.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_keys.dart';

void main() {
  test('shortcuts work', () {
    var keyBinding = ShortcutKeyBinding(
      [
        Shortcut(
          ShortcutAction.copy,
          {
            ShortcutKey.systemCmd,
            ShortcutKey.c,
          },
        ),
        Shortcut(
          ShortcutAction.paste,
          {
            ShortcutKey.systemCmd,
            ShortcutKey.v,
          },
        ),
        Shortcut(
          ShortcutAction.cut,
          {
            ShortcutKey.systemCmd,
            ShortcutKey.x,
          },
        ),
        Shortcut(
          ShortcutAction.undo,
          {
            ShortcutKey.systemCmd,
            ShortcutKey.z,
          },
        ),
        Shortcut(
          ShortcutAction.redo,
          {
            ShortcutKey.shift,
            ShortcutKey.systemCmd,
            ShortcutKey.z,
          },
        ),
      ],
    );

    // Shortcut system automatically determines which command key to use based
    // on platform, so let's similarly pick the appropriate one that maps our
    // abstraction to check for.
    // var systemCommandKeyLeft = Platform.instance.isMac
    //     ? PhysicalKeyboardKey.metaLeft
    //     : PhysicalKeyboardKey.controlLeft;

    // var systemCommandKeyRight = Platform.instance.isMac
    //     ? PhysicalKeyboardKey.metaRight
    //     : PhysicalKeyboardKey.controlRight;
    // Verify that key chords resolve to expected actions
    expect(
      keyBinding.lookupAction(
        [
          ShortcutKey.systemCmd,
          ShortcutKey.c,
        ],
        ShortcutKey.c,
      ),
      [
        ShortcutAction.copy,
      ],
    );
  });
}
