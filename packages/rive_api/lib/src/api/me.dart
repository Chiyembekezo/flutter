/// API calls for the logged-in user

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/data_model/data_model.dart';

final _log = Logger('Rive API Me');

class MeApi {
  MeApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  Future<MeDM> get whoami async {
    final res = await api.getFromPath('/api/me');
    try {
      final data = json.decode(res.body) as Map<String, dynamic>;
      // Check that the user's signed in
      if (!_isSignedIn(data)) {
        return null;
      }
      return MeDM.fromData(data);
    } on FormatException catch (e) {
      _log.severe('Error formatting whoami api response: $e');
      rethrow;
    }
  }

  /// Checks to see if the user's signed in
  bool _isSignedIn(Map<String, Object> data) => data['signedIn'];

  Future<bool> signout() async {
    var response = await api.getFromPath('/signout');
    if (response.statusCode == 200 || response.statusCode == 302) {
      await api.clearCookies();
      return true;
    }
    return false;
  }
}
