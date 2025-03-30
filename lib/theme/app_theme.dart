// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color backgroundColor = Color(0xFF1F2128);
  static const Color cardColor = Color(0xFF2A2D36);
  static const Color primaryColor = Colors.orange;
  static const Color textColor = Colors.white;
  static const Color textColorSecondary = Colors.white70;
  static const Color textColorTertiary = Colors.white54;

  // Text Styles
  static const TextStyle headlineStyle = TextStyle(
    color: textColor,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle titleStyle = TextStyle(
    color: textColor,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: textColorSecondary,
    fontSize: 16,
  );

  static const TextStyle bodyStyle = TextStyle(color: textColor, fontSize: 16);

  static const TextStyle labelStyle = TextStyle(
    color: textColorSecondary,
    fontSize: 14,
  );

  static const TextStyle valueStyle = TextStyle(
    color: textColor,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const TextStyle unitStyle = TextStyle(
    color: textColorTertiary,
    fontSize: 12,
    height: 1.2,
  );

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: textColor,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: cardColor,
    foregroundColor: textColor,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: textColorSecondary,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  );

  // Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(16),
  );

  // Input Decoration
  static InputDecoration getInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: textColorTertiary),
      prefixIcon: Icon(prefixIcon, color: textColorSecondary, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: textColorTertiary.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // Dialog Theme
  static DialogTheme dialogTheme = DialogTheme(
    backgroundColor: cardColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    titleTextStyle: titleStyle,
    contentTextStyle: subtitleStyle,
  );

  // App Bar Theme
  static AppBarTheme appBarTheme = const AppBarTheme(
    backgroundColor: backgroundColor,
    elevation: 0,
    iconTheme: IconThemeData(color: textColor),
    titleTextStyle: titleStyle,
  );

  // Status Colors
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orange;
  static const Color errorColor = Colors.red;

  // Common Spacings
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // Common Paddings
  static const EdgeInsets paddingAll = EdgeInsets.all(spacingM);
  static const EdgeInsets paddingH = EdgeInsets.symmetric(horizontal: spacingM);
  static const EdgeInsets paddingV = EdgeInsets.symmetric(vertical: spacingM);
}
