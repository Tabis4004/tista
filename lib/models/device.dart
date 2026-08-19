import 'package:isar/isar.dart';
part 'device.g.dart';

@collection
class DeviceModel {
  @Index(unique: true, replace: true)
  late Id id;

  @Index(unique: true, replace: true)
  late String code;

  String? uuid, name, version, device;
  int? createdAt, connectedAt;

  void setMap(Map map) {
    id = map['id'] ?? id;
    code = map['code'] ?? code;
    name = map['name'] ?? name;
    uuid = map['uuid'] ?? uuid;
    version = map['version'] ?? version;
    device = map['device'] ?? device;
    if (map['createdAt'] != null) {
      createdAt = int.tryParse("${map['createdAt']}") ?? createdAt;
    }
    if (map['connectedAt'] != null) {
      connectedAt = int.tryParse("${map['connectedAt']}") ?? connectedAt;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'version': version,
      'uuid': uuid
    };
  }
}
