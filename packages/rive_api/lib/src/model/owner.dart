import 'package:meta/meta.dart';
import 'package:rive_api/src/data_model/data_model.dart';

abstract class Owner {
  const Owner({
    @required this.ownerId,
    @required this.name,
    @required this.username,
    this.avatarUrl,
  });
  final int ownerId;
  final String name;
  final String username;
  final String avatarUrl;

  OwnerDM get asDM;
}
