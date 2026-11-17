import 'package:flutter/material.dart';

/// Palet warna kurasi modern untuk SakuBuku.
/// Menggabungkan estetika finansial premium dengan kontras Pink dan Navy.
class AppColors {
  // Brand / Primary Colors (Tema Pink & Navy)
  static const Color primary = Color(0xFFEC4899); // Vibrant Pink
  static const Color primaryDark = Color(0xFFBE185D); // Deep Pink
  static const Color primaryLight = Color(0xFFFBCFE8); // Soft Pink
  static const Color accent = Color(0xFF1E3A8A); // Deep Navy Blue

  // Financial Status Colors (Tetap dipertahankan Hijau/Merah agar UX keuangan tetap jelas)
  static const Color income = Color(0xFF10B981); // Emerald Green
  static const Color incomeDark = Color(0xFF059669);
  static const Color incomeLight = Color(0xFFD1FAE5);

  static const Color expense = Color(0xFFEF4444); // Rose Red
  static const Color expenseDark = Color(0xFFDC2626);
  static const Color expenseLight = Color(0xFFFEE2E2);

  // Neutral Colors (Light Mode) - Latar Pink Pastel
  static const Color backgroundLight = Color(0xFFFDF2F8); // Pink sangat pudar (Tailwind Pink 50)
  static const Color surfaceLight = Color(0xFFFCE7F3); // Soft pink (Tailwind Pink 100)
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFFBCFE8); 
  static const Color textPrimaryLight = Color(0xFF0F172A); 
  static const Color textSecondaryLight = Color(0xFF64748B); 
  static const Color textMutedLight = Color(0xFF94A3B8); 

  // Neutral Colors (Dark Mode) - Latar Pink Gelap Pudar (Plum/Mauve)
  static const Color backgroundDark = Color(0xFF281320); // Hitam dengan semburat pink gelap
  static const Color surfaceDark = Color(0xFF381A2D); // Pink mauve gelap
  static const Color cardDark = Color(0xFF4A253E); // Warna kartu sedikit lebih terang rdari background
  static const Color borderDark = Color(0xFF703358); 
  static const Color textPrimaryDark = Color(0xFFF8FAFC); 
  static const Color textSecondaryDark = Color(0xFFFBCFE8); // Teks sekunder jadi pink pudar
  static const Color textMutedDark = Color(0xFF94A3B8);

  // Gradients
  // Gradasi kartu saldo diubah menjadi Navy agar elegan dan teks putih tetap terbaca jelas
  static const LinearGradient balanceGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF312E81)],
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