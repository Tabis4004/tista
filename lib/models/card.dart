import 'package:isar/isar.dart';
part 'card.g.dart';

@collection
class CardModel {
  @Index(unique: true, replace: true)
  late Id id;

  @Index(unique: true, replace: true)
  late String uuid;

  late String solde, expiredAt, type, createdAt;
  bool graver = false;

  void setMap(Map card) {
    Map map = card['card'] ?? card;
    id = map['id'] ?? id;
    uuid = map['uuid'] ?? uuid;
    solde = map['solde'] ?? solde;
    expiredAt = map['expiredAt'] ?? expiredAt;
    createdAt = map['createdAt'] ?? createdAt;
    type = map['type'] ?? type;
    graver = map['graver'] ?? graver;
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'uuid': uuid};
  }
}
