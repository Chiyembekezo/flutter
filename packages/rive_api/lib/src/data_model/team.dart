import 'package:meta/meta.dart';
import 'package:utilities/deserialize.dart';

import 'owner.dart';

class TeamDM extends OwnerDM {
  const TeamDM({
    @required int ownerId,
    @required String name,
    @required String username,
    @required this.permission,
    @required this.avatarUrl,
    @required this.status,
  }) : super(ownerId, name, username);

  final String avatarUrl;
  final String permission;
  final String status;

  static Iterable<TeamDM> fromDataList(List<Map<String, dynamic>> data) =>
      data.map((d) => TeamDM.fromData(d));

  factory TeamDM.fromData(Map<String, dynamic> data) => TeamDM(
        ownerId: data.getInt('ownerId'),
        name: data.getString('name'),
        username: data.getString('username'),
        avatarUrl: data.getString('avatar'),
        permission: data.getString('permission'),
        status: data.getString('status'),
      );

  @override
  String toString() => 'TeamDM($ownerId, $name)';

  @override
  bool operator ==(Object o) => o is TeamDM && o.ownerId == ownerId;

  @override
  int get hashCode => ownerId;
}
