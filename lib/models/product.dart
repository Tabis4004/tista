import 'package:isar/isar.dart';
part 'product.g.dart';

@collection
class ProductModel {
  @Index(unique: true, replace: true)
  late Id id;

  @Index(unique: true, replace: true)
  late String uuid;

  late String name;
  String? remise, price, stock;

  void setMap(Map product) {
    Map map = product['product'] ?? product;
    id = map['id'] ?? id;
    name = map['name'] ?? name;
    uuid = map['uuid'] ?? uuid;
    remise = map['remise'] ?? remise;
    price = map['price'] ?? price;
    stock = map['stock'] ?? stock;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'remise': remise,
      "price": price,
      'uuid': uuid
    };
  }
}
