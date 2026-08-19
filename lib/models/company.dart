import 'package:isar/isar.dart';
part 'company.g.dart';

@collection
class CompanyModel {
  @Index(unique: true, replace: true)
  late Id id;

  @Index(unique: true, replace: true)
  late String uuid;

  String name = '';
  String? phone,
      mail,
      adresse,
      description,
      bp,
      slogan,
      site,
      fax,
      msgPersonFacture;

  void setMap(Map company) {
    Map map = company['company'] ?? company;
    id = map['id'] ?? id;
    name = map['name'] ?? name;
    uuid = map['uuid'] ?? uuid;
    phone = map['phone'] ?? phone;
    mail = map['mail'] ?? mail;
    adresse = map['adresse'] ?? adresse;
    bp = map['bp'] ?? bp;
    description = map['description'] ?? description;
    slogan = map['slogan'] ?? slogan;
    site = map['site'] ?? site;
    fax = map['fax'] ?? fax;
    msgPersonFacture = map['msgPersonFacture'] ?? msgPersonFacture;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      "adresse": adresse,
      "mail": mail,
      'uuid': uuid,
      'bp': bp,
      'description': description,
      'site': site,
      'slogan': slogan,
      'fax': fax,
      'msgPersonFacture': msgPersonFacture
    };
  }
}
