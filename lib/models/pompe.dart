import 'package:isar/isar.dart';
part 'pompe.g.dart';

@collection
class PompeModel {
  @Index(unique: true, replace: true)
  late Id id;

  @Index(unique: true, replace: true)
  late String uuid;

  late String name, station;
  String? cuive;
  List<PistoletModel> pistolets = [];

  void setMap(Map pompe) {
    Map map = pompe['pompe'] ?? pompe;
    id = map['id'] ?? id;
    name = map['name'] ?? name;
    uuid = map['uuid'] ?? uuid;
    station = map['station'] ?? station;
    cuive = map['cuive'] ?? cuive;
    if (pompe['pistolets'] != null || map['pistolets'] != null) {
      pistolets = (pompe['pistolets'] ?? map['pistolets'] ?? [])
          .map<PistoletModel>((p) {
        return PistoletModel()..setMap(p);
      }).toList();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'station': station,
      "cuive": cuive,
      'uuid': uuid
    };
  }
}

@embedded
class PistoletModel {
  late String code, index, indexStart, name;

  void setMap(Map pistolet) {
    Map map = pistolet['pistolet'] ?? pistolet;
    code = map['code'] ?? code;
    name = map['name'] ?? name;
    index = map['index'] ?? index;
    indexStart = map['indexStart'] ?? indexStart;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      "index": index,
      'indexStart': indexStart
    };
  }
}
