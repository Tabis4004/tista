import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:intl/intl.dart';
import 'i18n.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String getText(String name, [Map<String, String>? map]) {
    dynamic traduction = localized[name]?[locale.languageCode] ?? name;
    if (map == null || map.isEmpty) return traduction;
    map.forEach((String key, String value) {
      if (traduction.indexOf(RegExp('{{ ?$key ?}}')) != -1) {
        traduction = traduction.replaceFirst(RegExp('{{ ?$key ?}}'), value);
      }
    });
    return traduction;
  }

  String? tryGetText(String name, [Map<String, String>? map]) {
    dynamic traduction = localized[name]?[locale.languageCode];
    if (map == null || map.isEmpty || traduction == null) return traduction;
    map.forEach((String key, String value) {
      if (traduction.indexOf(RegExp('{{ ?$key ?}}')) != -1) {
        traduction = traduction.replaceFirst(RegExp('{{ ?$key ?}}'), value);
      }
    });
    return traduction;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    Locale ll = locale;
    try {
      //String l = await findSystemLocale();
      String l = Intl.defaultLocale ??
          Intl.systemLocale; //; ?? Intl.getCurrentLocale();
      l = 'fr-FR';
      List<String> split = l.split('_');
      ll = Locale(split[0], split.last.toUpperCase());
    } catch (e) {
      ll = locale;
    }

    if (!isSupported(ll)) {
      ll = const Locale('fr', 'FR');
    }

    return SynchronousFuture<AppLocalizations>(AppLocalizations(ll));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => true;
}
