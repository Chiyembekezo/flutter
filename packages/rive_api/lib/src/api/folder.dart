/// API calls for a user's volumes

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/data_model/data_model.dart';

final _log = Logger('Rive API Volume');

class FolderApi {
  FolderApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  Future<Iterable<Folder>> folders(Owner owner) async {
    if (owner is Me) {
      return _myFolders();
    } else if (owner is Team) {
      return _teamFolders(owner);
    } else {
      throw Exception('$owner must be either a team or a me');
    }
  }

  Future<Iterable<Folder>> _myFolders() async =>
      _folders('/api/my/files/folders');

  Future<Iterable<Folder>> _teamFolders(Team team) async =>
      _folders('/api/teams/${team.ownerId}/folders');

  Future<Iterable<Folder>> _folders(String path) async {
    final res = await api.getFromPath(path);
    try {
      final data = json.decode(res.body) as Map<String, dynamic>;
      // Check that the user's signed in
      print(data);
      if (!data.containsKey('folders')) {
        _log.severe('Incorrectly formatted folders json response: $res.body');
        throw FormatException('Incorrectly formatted folders json response');
      }
      return Folder.fromDataList(data['folders']);
    } on FormatException catch (e) {
      _log.severe('Error formatting folder api response: $e');
      rethrow;
    }
  }
}
