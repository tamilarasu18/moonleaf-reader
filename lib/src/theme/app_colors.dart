import 'package:flutter/material.dart';

/// Moonleaf brand palette. Single source of truth for brand colours.
class AppColors {
  AppColors._();

  static const Color night = Color(0xFF15152E);
  static const Color nightDeep = Color(0xFF10101F);
  static const Color indigo = Color(0xFF2E2E5F);
  static const Color indigoLight = Color(0xFF4A4A8A);
  static const Color gold = Color(0xFFE6BE72);
  static const Color cream = Color(0xFFF4E9C9);

  /// Bookshelf decoration.
  static const Color shelfEdge = Color(0xFFB8956A);
  static const Color shelfShadow = Color(0x33594024);

  /// Gradient used for the splash and brand surfaces.
  static const List<Color> nightGradient = [Color(0xFF34345F), Color(0xFF10101F)];
}
