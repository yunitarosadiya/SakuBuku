import 'package:flutter/material.dart';

/// Palet warna kurasi modern untuk SakuBuku.
/// Menggabungkan estetika finansial premium dengan kontras tinggi.
class AppColors {
  // Brand / Primary Colors
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color accent = Color(0xFF3B82F6);

  // Financial Status Colors
  static const Color income = Color(0xFF10B981); // Emerald Green
  static const Color incomeDark = Color(0xFF059669);
  static const Color incomeLight = Color(0xFFD1FAE5);

  static const Color expense = Color(0xFFEF4444); // Rose Red
  static const Color expenseDark = Color(0xFFDC2626);
  static const Color expenseLight = Color(0xFFFEE2E2);

  // Neutral Colors (Light Mode)
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate 400

  // Neutral Colors (Dark Mode)
  static const Color backgroundDark = Color(0xFF090D16); // Deep Navy Black
  static const Color surfaceDark = Color(0xFF131B2E);
  static const Color cardDark = Color(0xFF1E293B); // Slate 800
  static const Color borderDark = Color(0xFF334155); // Slate 700
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color textMutedDark = Color(0xFF64748B); // Slate 500

  // Gradients
  static const LinearGradient balanceGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
