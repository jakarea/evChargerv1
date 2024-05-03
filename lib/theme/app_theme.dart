import 'package:fluent_ui/fluent_ui.dart';

class AppTheme {
  // Define static constants for light and dark theme colors
  static const Color windowsLightColor = Color(0xFFeaeaea); // Light gray
  static const Color windowsDarkColor = Color(0xFF202020); // Dark gray

  // Method to get the current theme color
  static Color getCurrentThemeColor(BuildContext context) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    return isDarkMode ? windowsDarkColor : windowsLightColor;
  }
}
