import 'package:rive_api/api.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_api/src/data_model/data_model.dart';
import 'package:rive_api/src/manager/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/src/model/current_directory.dart';
import 'package:rive_api/src/model/folder_contents.dart';

class FolderContentsManager with Subscriptions {
  FolderContentsManager._()
      : _fileApi = FileApi(),
        _folderApi = FolderApi() {
    // Start listening for when a directory changes.
    subscribe<CurrentDirectory>((directory) {
      _getFolderContents(directory);
    });

    subscribe<Me>((me) {
      // Upon init, go get the current users' top folder.
      final myFiles = CurrentDirectory(me, 1);
      _getFolderContents(myFiles);
    });
  }

  static FolderContentsManager _instance = FolderContentsManager._();
  factory FolderContentsManager() => _instance;

  final FileApi _fileApi;
  final FolderApi _folderApi;

  void _loadFileDetails(List<int> fileIds, int teamOwnerId) {
    _fileApi.getFileDetails(fileIds, ownerId: teamOwnerId).then((fileDetails) {
      final plumber = Plumber();
      final fileDetailsList = File.fromDMList(fileDetails);
      for (final file in fileDetailsList) {
        plumber.message<File>(file, '${file.id}');
      }
    });
  }

  List<Folder> _filterByParent(
      List<FolderDM> folders, CurrentDirectory directory) {
    final parentId = directory.folderId;

    return folders
        .map((folderDM) {
          // Add to results if:
          // - parent id is the same
          // - downloading top folder: we want to show 'Deleted Files' folder..
          if (folderDM.parent == parentId ||
              (parentId == 1 && folderDM.id == 0)) {
            print("Adding this: $folderDM");
            return Folder.fromDM(folderDM);
          }
        })
        .where((folder) => folder != null)
        .toList(growable: false);
  }

  void _getFolderContents(CurrentDirectory directory) async {
    List<FileDM> files;
    List<FolderDM> folders;
    var owner = directory.owner;

    if (owner is Team) {
      files = await _fileApi.teamFiles(owner.ownerId, directory.folderId);
      folders = await _folderApi.teamFolders(owner.ownerId);
    } else {
      files = await _fileApi.myFiles(directory.folderId);
      folders = await _folderApi.myFolders();
    }

    print("Got my files & folders:\n$files\n$folders");
    if (files.isNotEmpty) {
      // Load and prepare pipes for files.
      var fileIds = files.map((e) => e.id).toList(growable: false);
      final directoryOwner =
          directory.owner is Team ? directory.owner.ownerId : null;
      _loadFileDetails(fileIds, directoryOwner);
    }

    final filteredFolders = _filterByParent(folders, directory);

    var contents = FolderContents(File.fromDMList(files), filteredFolders);

    Plumber().message<FolderContents>(contents);
  }
}
