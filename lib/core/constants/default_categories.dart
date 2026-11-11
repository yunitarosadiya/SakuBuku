import 'package:flutter/material.dart';

class CategoryItem {
  final String name;
  final IconData icon;
  final Color color;
  final String type; // 'EXPENSE' or 'INCOME'

  const CategoryItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });
}

class DefaultCategories {
  static const List<CategoryItem> expenseCategories = [
    CategoryItem(
      name: 'Makanan & Minuman',
      icon: Icons.restaurant,
      color: Color(0xFFF97316), // Orange
      type: 'EXPENSE',
    ),
    CategoryItem(
      name: 'Transportasi',
      icon: Icons.directions_car,
      color: Color(0xFF06B6D4), // Cyan
      type: 'EXPENSE',
    ),
    CategoryItem(
      name: 'Belanja',
      icon: Icons.shopping_bag,
      color: Color(0xFFEC4899), // Pink
      type: 'EXPENSE',
    ),
    CategoryItem(
      name: 'Tagihan & Utilitas',
      icon: Icons.receipt_long,
      color: Color(0xFF8B5CF6), // Purple
      type: 'EXPENSE',
    ),
    CategoryItem(
      name: 'Hiburan',
      icon: Icons.sports_esports,
      color: Color(0xFFEAB308), // Yellow
      type: 'EXPENSE',
    ),
    CategoryItem(
      name: 'Kesehatan',
      icon: Icons.local_hospital,
      color: Color(0xFF10B981), // Emerald
      type: 'EXPENSE',
    ),
    CategoryItem(
      name: 'Pendidikan',
      icon: Icons.school,
      color: Color(0xFF3B82F6), // Blue
      type: 'EXPENSE',
    ),
    CategoryItem(
      name: 'Lainnya',
      icon: Icons.more_horiz,
      color: Color(0xFF64748B), // Slate
      type: 'EXPENSE',
    ),
  ];

  static const List<CategoryItem> incomeCategories = [
    CategoryItem(
      name: 'Gaji Utama',
      icon: Icons.account_balance_wallet,
      color: Color(0xFF10B981), // Emerald
      type: 'INCOME',
    ),
    CategoryItem(
      name: 'Bisnis / UMKM',
      icon: Icons.storefront,
      color: Color(0xFF3B82F6), // Blue
      type: 'INCOME',
    ),
    CategoryItem(
      name: 'Investasi',
      icon: Icons.trending_up,
      color: Color(0xFF8B5CF6), // Purple
      type: 'INCOME',
    ),
    CategoryItem(
      name: 'Hadiah / Bonus',
      icon: Icons.card_giftcard,
      color: Color(0xFFF59E0B), // Amber
      type: 'INCOME',
    ),
    CategoryItem(
      name: 'Pendapatan Lain',
      icon: Icons.attach_money,
      color: Color(0xFF06B6D4), // Cyan
      type: 'INCOME',
    ),
  ];

  static CategoryItem getCategoryByName(String name, String type) {
    final list = type == 'INCOME' ? incomeCategories : expenseCategories;
    return list.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => CategoryItem(
        name: name,
        icon: Icons.category,
        color: const Color(0xFF64748B),
        type: type,
      ),
    );
  }
}
