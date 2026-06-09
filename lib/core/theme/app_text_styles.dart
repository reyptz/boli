import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get _base => GoogleFonts.outfit(
    color: AppColors.textPrimary,
  );

  static TextStyle get h1 => _base.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    height: 1.2,
  );

  static TextStyle get h2 => _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.3,
  );

  static TextStyle get h3 => _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.4,
  );

  static TextStyle get bodyLarge => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static TextStyle get bodyMedium => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get bodySmall => _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.5,
  );

  static TextStyle get button => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static TextStyle get caption => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );
}
