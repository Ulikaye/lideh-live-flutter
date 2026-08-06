import 'package:flutter/material.dart';

/// Central color palette for LiDeH Live.
/// Derived from the original Django site's brand colors, refreshed
/// for a modern Material 3 look.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1DA1F2); // brand accent (sky blue)
  static const Color primaryDark = Color(0xFF0D7FC4);
  static const Color secondary = Color(0xFFFFB020); // gospel-gold accent
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5F6B7A);
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFE74C3C);
  static const Color border = Color(0xFFE3E8EF);

  // Booking status colors
  static const Color statusPending = Color(0xFFF5A623);
  static const Color statusAccepted = Color(0xFF2ECC71);
  static const Color statusDeclined = Color(0xFFE74C3C);
  static const Color statusCompleted = Color(0xFF1DA1F2);
  static const Color statusCancelled = Color(0xFF9AA5B1);
}
