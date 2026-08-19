import 'package:flutter/material.dart';

const Color appPrimaryColor = Color(0XFF22577A); //0XFF0c54a0
const Color appSecondaryColor = Color(0XFF38A3A5);
const Color validationColor = Color(0XFF439291);
const Color actionColor = Color(0XFFd48f36);
final Color evenColor = Colors.grey.shade300;
const simpleText =
    TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: Colors.black);
const headingText =
    TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black);
const defaultPadding = 16.0;

const Color bgColor = Color.fromARGB(255, 245, 246, 241);
ThemeData theme = ThemeData(
  useMaterial3: false,
  highlightColor: Colors.transparent,
  splashColor: Colors.transparent,
  focusColor: Colors.transparent,
  hoverColor: Colors.transparent,
  outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
    foregroundColor: WidgetStateProperty.all(Colors.black),
    //side: WidgetStateProperty.all(const BorderSide(color: Colors.black))
  )),
  sliderTheme: SliderThemeData(
      trackHeight: 2,
      trackShape: const RectangularSliderTrackShape(),
      thumbShape: SliderComponentShape.noThumb),
  appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      foregroundColor: Colors.white,
      backgroundColor: appPrimaryColor,
      iconTheme: IconThemeData(color: Colors.white, size: 20.0)),
  primaryColor: appPrimaryColor,
  /* accentColor: Color(0XFF101017),
            buttonColor: Color(0XFFcad3d2), */
  /* bottomAppBarColor: const Color(0XFF543879),
    //canvasColor: Color(0XFF7b6fc0)
    indicatorColor: const Color(0XFFb79b74),
    inputDecorationTheme: const InputDecorationTheme(
        suffixIconColor: Colors.black,
        labelStyle: TextStyle(color: Colors.black)),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: appPrimaryColor, foregroundColor: Colors.white),
    checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.all(Colors.black),
        checkColor: WidgetStateProperty.all(Colors.white)), */
  //backgroundColor: const Color(0XFFf3f8ff),
  scaffoldBackgroundColor: bgColor,
  //colorScheme: ColorScheme.fromSeed(
  //seedColor: const Color(0XFFd4b489),
  //background:const Color(0XFFd4b489)
  //) // const Color.fromARGB(255, 222, 227, 230)
);

TextStyle swipeStyle =
    const TextStyle(fontWeight: FontWeight.w300, fontSize: 13);
