import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tista/providers/localizations.dart';

extension Traduction on String {
  String tr(BuildContext context, [Map<String, String>? map]) {
    return AppLocalizations.of(context).getText(this, map);
  }

  String? tryTr(BuildContext context, [Map<String, String>? map]) {
    return AppLocalizations.of(context).tryGetText(this, map);
  }
}

extension CurrencyFormat on num? {
  String currencyFormat({String? symbol}) {
    if (this == null) return '';
    NumberFormat cf = NumberFormat.currency(
        locale: 'fr_FR', //Intl.systemLocale,
        symbol: (symbol ?? '').split(' ').first,
        decimalDigits: 0);
    return cf.format(this);
  }
}

extension CurrencyFormat2 on String? {
  String currencyFormat({String? symbol}) {
    if (this == null) return '';
    NumberFormat cf = NumberFormat.currency(
        locale: 'fr_FR', //Intl.systemLocale,
        symbol: (symbol ?? '').split(' ').first,
        decimalDigits: 0);
    return cf.format(double.parse(this!));
  }
}

extension AppDateFormat on String? {
  String formatTime(
      {bool withDay = false,
      bool withHour = true,
      bool withDate = true,
      bool showSuffix = true,
      bool abrev = false,
      String? hint,
      String separator = 'à'}) {
    int? expiration = int.tryParse(this ?? '');
    if (expiration == null || expiration == -1 || expiration == 0) {
      return hint ?? "--";
    }
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(expiration);
    late DateFormat d;
    if (withDate) {
      if (abrev) {
        d = DateFormat.yMd('fr_FR'); //Intl.systemLocale);
        if (withDay) d = DateFormat.yMEd('fr_FR'); //Intl.systemLocale);
      } else {
        d = DateFormat.yMMMMd('fr_FR'); //Intl.systemLocale);
        if (withDay) d = DateFormat.yMMMMEEEEd('fr_FR'); //Intl.systemLocale);
      }
    } else {
      d = DateFormat();
    }
    if (withHour) d = d.addPattern('Hm', ' $separator ');
    return d.format(dateTime);
  }
}

extension AppDateFormat2 on int? {
  String formatTime(
      {bool withDay = false,
      bool withHour = true,
      bool withDate = true,
      bool showSuffix = true,
      bool abrev = false,
      String? hint,
      String separator = 'à'}) {
    int? expiration = this;
    if (expiration == null || expiration == -1 || expiration == 0) {
      return hint ?? "--";
    }
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(expiration);
    late DateFormat d;
    if (abrev) {
      d = DateFormat.yMd('fr_FR'); //Intl.systemLocale);
      if (withDay) d = DateFormat.yMEd('fr_FR'); //Intl.systemLocale);
    } else {
      d = DateFormat.yMMMMd('fr_FR'); //Intl.systemLocale);
      if (withDay) d = DateFormat.yMMMMEEEEd('fr_FR'); //Intl.systemLocale);
    }
    if (withHour) d = d.addPattern('Hm', ' $separator ');
    return d.format(dateTime);
  }
}

extension FormatToInt on String {
  int toInt([int? defaultValue]) {
    return int.tryParse(this) ?? defaultValue ?? 0;
  }

  num toFloat() {
    double d = double.tryParse(this) ?? 0;
    return d == d.toInt() ? d.toInt() : d;
  }
}
