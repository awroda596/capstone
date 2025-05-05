import 'package:flutter/material.dart';
//handle all the theming here: 


//colors for theming
final Color BaiCha = Color.fromARGB(255, 248, 244, 235);
final Color Matcha = Color.fromARGB(255, 82, 129, 76);
final Color HuangCha = Color.fromARGB(255, 210, 211, 178);
final Color LuCha = Color.fromARGB(255, 175, 221, 149);
final Color HeiCha = Color(0xFF3E3E3E); //

//swatch, not used currently.
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) strengths.add(0.1 * i);
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

final MaterialColor customPrimary = createMaterialColor(LuCha);

final appTheme = ThemeData(
  scaffoldBackgroundColor: BaiCha,
  appBarTheme: AppBarTheme(backgroundColor: Matcha, foregroundColor: BaiCha),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: LuCha),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: HuangCha,
      foregroundColor: HeiCha,
    ),
  ),
  cardColor: LuCha,
  drawerTheme: DrawerThemeData(backgroundColor: LuCha),
  dialogTheme:  DialogTheme(
  backgroundColor: LuCha,
  surfaceTintColor: Colors.transparent, 
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(color: HeiCha, fontFamily: 'Georgia'),
    displayMedium: TextStyle(color: HeiCha, fontFamily: 'Georgia'),
    displaySmall: TextStyle(color: HeiCha, fontFamily: 'Georgia'),
    headlineLarge: TextStyle(color: HeiCha, fontFamily: 'Georgia'),
    headlineMedium: TextStyle(color: HeiCha, fontFamily: 'Georgia'),
    headlineSmall: TextStyle(color: HeiCha, fontFamily: 'Georgia'),
    titleLarge: TextStyle(color: HeiCha, fontFamily: 'Georgia'),
    titleMedium: TextStyle(color: HeiCha, fontFamily: 'Georgia'),
    titleSmall: TextStyle(color: HeiCha, fontFamily: 'Georgia'),
    bodyLarge: TextStyle(color: HeiCha, fontFamily: 'Georgia'),
    bodyMedium: TextStyle(color: HeiCha, fontFamily: 'Georgia'),
    bodySmall: TextStyle(color: HeiCha, fontFamily: 'Georgia'),
    labelLarge: TextStyle(color: HeiCha, fontFamily: 'Georgia'),
    labelMedium: TextStyle(color: HeiCha, fontFamily: 'Georgia'),
    labelSmall: TextStyle(color: HeiCha, fontFamily: 'Georgia'),
  ),
   cardTheme: CardTheme(
      elevation: 4,
      color: LuCha,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    ),
);
