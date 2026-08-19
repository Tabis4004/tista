import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Identité TiSta+
// ---------------------------------------------------------------------------
// Le pétrole est la couleur de marque ; l'ambre, l'indigo et le rose complètent
// la série. Cet ordre a été validé pour rester distinguable en vision
// daltonienne (écart minimum ΔE 11,9 en protanopie, 21,9 en vision normale) et
// pour tenir 3:1 de contraste sur la surface claire. Modifier une valeur oblige
// à repasser cette validation, sinon deux couleurs voisines deviennent
// identiques pour environ 8 % des hommes.
//
// Une entité garde la même teinte partout : espèces en pétrole, dépenses en
// ambre, carte en indigo, bon en rose. C'est ce qui fait de la couleur une
// information et non une décoration.

const Color tistaSerie1 = Color(0xFF0A9384); // espèces, ventes, marque
const Color tistaSerie2 = Color(0xFFC97A00); // dépenses
const Color tistaSerie3 = Color(0xFF4457C7); // carte
const Color tistaSerie4 = Color(0xFFD8567A); // bon

/// Lavis : les mêmes teintes très diluées, pour teinter une surface.
const Color tistaWash1 = Color(0xFFE4F4F1);
const Color tistaWash2 = Color(0xFFFBF0DC);
const Color tistaWash3 = Color(0xFFECEEFB);
const Color tistaWash4 = Color(0xFFFDEEF3);

/// Couleurs d'état — réservées. Jamais réutilisées comme « cinquième teinte » :
/// une dépense normale n'est pas une alerte. Elles portent toujours un mot ou
/// une icône, jamais la couleur seule.
const Color tistaBon = Color(0xFF0CA30C);
const Color tistaAlerte = Color(0xFFFAB219);
const Color tistaCritique = Color(0xFFD03B3B);

/// Encres.
const Color tistaInk = Color(0xFF10120F);
const Color tistaInk2 = Color(0xFF4E534D);
const Color tistaInkMuted = Color(0xFF85897F);
const Color tistaHairline = Color(0xFFE3E1D8);

const Color appPrimaryColor = tistaSerie1;
const Color appSecondaryColor = Color(0xFF0E6F65);
const Color validationColor = tistaBon;
const Color actionColor = tistaSerie2;
final Color evenColor = Colors.grey.shade300;
const simpleText =
    TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: Colors.black);
const headingText =
    TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black);
const defaultPadding = 16.0;

const Color bgColor = Color(0xFFF6F4EF);
const Color surfaceColor = Color(0xFFFBFAF7);
const double rayon = 14;
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
  colorScheme: const ColorScheme.light(
    primary: appPrimaryColor,
    secondary: appSecondaryColor,
    surface: surfaceColor,
    error: tistaCritique,
  ),
  // Des cartes franchement posées sur le fond : bord net, coin rond, pas
  // d'ombre. L'ombre simule une profondeur que l'écran n'a pas, et sur un
  // téléphone en plein soleil elle ne se voit tout simplement pas.
  cardTheme: CardThemeData(
    elevation: 0,
    color: surfaceColor,
    margin: const EdgeInsets.symmetric(vertical: 5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(rayon),
      side: const BorderSide(color: tistaHairline),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: appPrimaryColor,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: appPrimaryColor,
    unselectedLabelColor: tistaInk2,
    indicatorColor: appPrimaryColor,
    dividerColor: tistaHairline,
  ),
  dividerTheme: const DividerThemeData(color: tistaHairline, thickness: 1),
  progressIndicatorTheme:
      const ProgressIndicatorThemeData(color: appPrimaryColor),
  //colorScheme: ColorScheme.fromSeed(
  //seedColor: const Color(0XFFd4b489),
  //background:const Color(0XFFd4b489)
  //) // const Color.fromARGB(255, 222, 227, 230)
);

TextStyle swipeStyle =
    const TextStyle(fontWeight: FontWeight.w300, fontSize: 13);
