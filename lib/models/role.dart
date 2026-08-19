import 'package:isar/isar.dart';
part 'role.g.dart';

@collection
class RoleModel {
  @Index(unique: true, replace: true)
  late Id id;

  @Index(unique: true, replace: true)
  late String uuid;

  late String name, company;
  List<String> droits = [];
  List<String> stations = [];

  void setMap(Map role) {
    Map map = role['role'] ?? role;
    id = map['id'] ?? id;
    uuid = map['uuid'] ?? uuid;
    name = map['name'] ?? name;
    company = map['company'] ?? company;
    if (map['stations'] != null) {
      stations = map['stations'].map<String>((s) {
        return '$s';
      }).toList();
    }
    if (map['droits'] != null) {
      droits = map['droits'].map<String>((d) {
        return '$d';
      }).toList();
    }
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'uuid': uuid, 'name': name, 'droits': droits};
  }
}
