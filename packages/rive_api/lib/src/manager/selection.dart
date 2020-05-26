import 'package:rive_api/plumber.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';

class SelectionManager with Subscriptions {
  static SelectionManager _instance = SelectionManager._();
  factory SelectionManager() => _instance;

  SelectionManager._() {
    _plumber = Plumber();
    _attach();
  }

  SelectionManager.tester() {
    _plumber = Plumber();
    _attach();
  }

  // Note: useful to cache this?
  Plumber _plumber;

  // For tests...
  void _attach() {
    subscribe<CurrentDirectory>(clearSelection);
  }

  void clearSelection([_]) {
    _plumber.flush<Selection>();
  }

  void selectFile(File file) {
    _plumber.message(Selection(files: <File>{file}));
  }

  void selectFolder(Folder folder) {
    _plumber.message(Selection(folders: <Folder>{folder}));
  }
}
