import 'package:flutter/material.dart';
import 'light_mode.dart';
import 'package:car_culture_fyp/themes/dark_mode.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = lightMode;

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData == darkMode;

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }

  void setLightMode() {
    if (_themeData != lightMode) {
      themeData = lightMode;
    }
  }
}