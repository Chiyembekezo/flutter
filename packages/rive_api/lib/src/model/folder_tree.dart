/// Tree of directories
import 'package:meta/meta.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rxdart/subjects.dart';

class FolderTree {
  FolderTree({
    @required this.owner,
    @required this.root,
  });
  final Owner owner;
  final FolderTreeItem root;

  factory FolderTree.fromOwner(Owner owner) {
    return FolderTree(owner: owner, root: FolderTreeItem.dummy(owner));
  }

  factory FolderTree.fromFolderList(Owner owner, List<Folder> folders) {
    final indexMap = Map<int, List<Folder>>();

    // map em out
    folders.forEach((Folder folder) {
      if (folder.parent != null) {
        indexMap[folder.parent] ??= [];
        indexMap[folder.parent].add(folder);
      }
    });

    var _rootFolder =
        folders.firstWhere((element) => element.name == 'Your Files');
    return FolderTree(
        owner: owner,
        root: FolderTreeItem.create(_rootFolder, indexMap, owner));
  }
}

class FolderTreeItem {
  FolderTreeItem({@required this.folder, @required this.children, this.owner}) {
    hover.add(false);
    selected.add(false);
  }
  final Folder folder;
  final hover = BehaviorSubject<bool>();
  final selected = BehaviorSubject<bool>();
  final Owner owner;
  final List<FolderTreeItem> children;

  String get iconURL {
    return owner?.avatarUrl;
  }

  String get name {
    return (owner == null) ? this.folder.name : owner.displayName;
  }

  factory FolderTreeItem.dummy(Owner owner) {
    return FolderTreeItem(
      folder: null,
      children: [],
      owner: owner,
    );
  }

  factory FolderTreeItem.create(Folder root, Map<int, List<Folder>> indexMap,
      [Owner owner]) {
    // Note: Cycles gonna kill us.
    final List<FolderTreeItem> _children = (indexMap.containsKey(root.id))
        ? indexMap[root.id]
            .map((childFolder) => FolderTreeItem.create(childFolder, indexMap))
            .toList()
        : [];
    return FolderTreeItem(
      folder: root,
      children: _children,
      owner: owner,
    );
  }
}
