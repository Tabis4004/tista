import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

enum FormType {
  latLong,
  time,
  checkbox,
  textField,
  select,
  select2,
  date,
  file,
  file2,
  line,
  select3
}

enum PaymentType { accountCreation, recharge }

class AppRequestOptions {
  Options options = Options();
  Map<String, dynamic>? queryParameters;
}

class FormModel {
  FormType formType;
  String? type;
  List? menus;
  bool mandatory = false, enabled = true;
  int? minLines;
  int? minLength;
  int? maxLength;
  String title;
  String code;
  double width;
  dynamic valeur, selectedValue, otherValue;
  bool visibility = true;
  TextEditingController value = TextEditingController();
  String? hint, help, suffix;
  String? collection;
  DateTime? firstDate, lastDate, initialDate;

  String? fieldLibelle, fieldValue;
  FormModel(
      {String text = '',
      this.type,
      this.width = 1.0,
      this.visibility = true,
      this.enabled = true,
      this.valeur,
      this.menus,
      this.selectedValue,
      this.otherValue,
      this.collection,
      this.suffix,
      this.fieldValue,
      this.fieldLibelle,
      this.formType = FormType.textField,
      required this.title,
      required this.code,
      this.mandatory = false,
      this.minLines,
      this.minLength,
      this.maxLength,
      this.help,
      this.hint,
      this.firstDate,
      this.lastDate,
      this.initialDate}) {
    value.text = text;
  }
  bool isValid() {
    if (!mandatory || !visibility || !enabled) {
      if (value.text.isEmpty || valeur != null) return true;
    }
    return selectedValue != null || valeur != null || value.text.isNotEmpty;
  }
}

class ResponseWrapper<T> {
  Headers headers;
  T json;
  int? status;
  ResponseWrapper(this.headers, this.json, this.status);
}

class UserAccount {
  late int id;
  String? name, prenoms;
  String? mail;
  String? phone, indicatif;
  String? displayName;
  int? createdAt, connection;
  String? photoUrl, uuid;
  List<String> roles = [];
  bool pin = false, manager = false;

  String? role;
  List? stations;

  String get lastName {
    return '$name $prenoms'.split(' ').last;
  }

  bool get isAdmin {
    return roles.contains('SUPERADMIN');
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'manager': manager,
      'name': name,
      'prenoms': prenoms,
      'mail': mail,
      'id': id,
      'photoUrl': photoUrl,
      'phone': phone,
      'indicatif': indicatif,
      'createdAt': createdAt,
      'connection': connection,
      'roles': roles
    };
  }

  UserAccount.addFromMap(Map user) {
    Map model = user['user'] ?? user;

    id = model['id'] ?? id;
    pin = model['pin'] ?? pin;
    manager = model['manager'] ?? manager;
    uuid = model['uuid'] ?? uuid;
    photoUrl = model['photoUrl'] ?? photoUrl;
    mail = model['mail'] ?? mail;
    phone = model['phone'] ?? phone;
    displayName = model['displayName'] ?? displayName;
    name = model['name'] ?? name;
    prenoms = model['prenoms'] ?? prenoms;
    indicatif = model['indicatif'] ?? indicatif;
    role = model['role'] ?? role;
    if (model['stations'] != null) {
      if (model['stations'] is List) {
        stations = model['stations'] ?? stations;
      } else {
        stations = "${model['stations']}".split(',');
      }
    }
    createdAt = int.tryParse("${model['createdAt']}") ?? createdAt;
    connection = int.tryParse("${model['connection']}") ?? connection;
    if (model['roles'] != null) {
      roles = (model['roles'] ?? []).map<String>((r) => '$r').toList();
    }
  }

  void fromMap(Map user) {
    Map model = user['user'] ?? user;

    id = model['id'] ?? id;
    pin = model['pin'] ?? pin;
    manager = model['manager'] ?? manager;
    uuid = model['uuid'] ?? uuid;
    photoUrl = model['photoUrl'] ?? photoUrl;
    mail = model['mail'] ?? mail;
    phone = model['phone'] ?? phone;
    displayName = model['displayName'] ?? displayName;
    name = model['name'] ?? name;
    prenoms = model['prenoms'] ?? prenoms;
    indicatif = model['indicatif'] ?? indicatif;
    role = model['role'] ?? role;
    if (model['stations'] != null) {
      if (model['stations'] is List) {
        stations = model['stations'] ?? stations;
      } else {
        stations = "${model['stations']}".split(',');
      }
    }
    connection = int.tryParse("${model['connection']}") ?? connection;
    createdAt = int.tryParse("${model['createdAt']}") ?? createdAt;
    if (model['roles'] != null) {
      roles = (model['roles'] ?? []).map<String>((r) => '$r').toList();
    }
  }
}
