import 'package:isar/isar.dart';
part 'station.g.dart';

@collection
class StationModel {
  @Index(unique: true, replace: true)
  late Id id;

  @Index(unique: true, replace: true)
  late String uuid;

  late String name;
  String? phone, mail, adresse, caisse;
  int? cuives, pompes;

  void setMap(Map station) {
    Map map = station['station'] ?? station;
    id = map['id'] ?? id;
    name = map['name'] ?? name;
    uuid = map['uuid'] ?? uuid;
    phone = map['phone'] ?? phone;
    mail = map['mail'] ?? mail;
    adresse = map['adresse'] ?? adresse;
    caisse = map['caisse'] ?? caisse;
    cuives = map['cuives'] ?? cuives;
    pompes = map['pompes'] ?? pompes;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      "adresse": adresse,
      "mail": mail,
      'uuid': uuid
    };
  }
}
