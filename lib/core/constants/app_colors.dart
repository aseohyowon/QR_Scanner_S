import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0A0A14);
  static const Color surface = Color(0xFF12121F);
  static const Color cardBackground = Color(0xFF1A1A2E);
  static const Color cardBorder = Color(0xFF2A2A3E);

  // Primary / Accent
  static const Color primary = Color(0xFF7C4DFF);
  static const Color primaryLight = Color(0xFF9C6FFF);
  static const Color primaryDark = Color(0xFF5C2DE0);
  static const Color secondary = Color(0xFF00E5FF);
  static const Color secondaryDark = Color(0xFF00B8CC);

  // Status
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFD740);

  // Text
  static const Color textPrimary = Color(0xFFEEEEF5);
  static const Color textSecondary = Color(0xFF8888A8);
  static const Color textHint = Color(0xFF55556A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF12121F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scannerOverlayGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFF00E5FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
