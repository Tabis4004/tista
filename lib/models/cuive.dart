import 'package:isar/isar.dart';
part 'cuive.g.dart';

@collection
class CuiveModel {
  @Index(unique: true, replace: true)
  late Id id;

  @Index(unique: true, replace: true)
  late String uuid;

  late String name, station;
  String? product, contenance;

  String? stock;

  void setMap(Map cuive) {
    Map map = cuive['cuive'] ?? cuive;
    id = map['id'] ?? id;
    name = map['name'] ?? name;
    uuid = map['uuid'] ?? uuid;
    station = map['station'] ?? station;
    product = map['product'] ?? product;
    contenance = map['contenance'] ?? contenance;
    stock = map['stock'] ?? stock;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'station': station,
      "contenance": contenance,
      "product": product,
      'uuid': uuid
    };
  }
}
