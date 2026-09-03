import 'package:flutter/material.dart';

class CardColorTheme {
  final String name;
  final Color lightBackground;
  final Color lightBorder;
  final Color lightText;
  final Color darkBackground;
  final Color darkBorder;
  final Color darkText;
  final Color previewColor;

  const CardColorTheme({
    required this.name,
    required this.lightBackground,
    required this.lightBorder,
    required this.lightText,
    required this.darkBackground,
    required this.darkBorder,
    required this.darkText,
    required this.previewColor,
  });

  Color getBackground(bool isDark) => isDark ? darkBackground : lightBackground;
  Color getBorder(bool isDark) => isDark ? darkBorder : lightBorder;
  Color getText(bool isDark) => isDark ? darkText : lightText;
}

class CardPalette {
  static const List<CardColorTheme> colors = [
    // 0: Default
    CardColorTheme(
      name: 'Mặc định',
      lightBackground: Color(0xFFFFFFFF),
      lightBorder: Color(0xFFE2E8F0),
      lightText: Color(0xFF1E293B),
      darkBackground: Color(0xFF1E293B),
      darkBorder: Color(0xFF334155),
      darkText: Color(0xFFF8FAFC),
      previewColor: Color(0xFF94A3B8),
    ),
    // 1: San hô nhẹ (Coral Pink)
    CardColorTheme(
      name: 'Cam san hô',
      lightBackground: Color(0xFFFFF1F2),
      lightBorder: Color(0xFFFECDD3),
      lightText: Color(0xFF881337),
      darkBackground: Color(0xFF4C1D24),
      darkBorder: Color(0xFF881337),
      darkText: Color(0xFFFFE4E6),
      previewColor: Color(0xFFFB7185),
    ),
    // 2: Xanh ngọc (Mint Teal)
    CardColorTheme(
      name: 'Xanh ngọc',
      lightBackground: Color(0xFFF0FDF4),
      lightBorder: Color(0xFFBBF7D0),
      lightText: Color(0xFF14532D),
      darkBackground: Color(0xFF143823),
      darkBorder: Color(0xFF166534),
      darkText: Color(0xFFDCFCE7),
      previewColor: Color(0xFF4ADE80),
    ),
    // 3: Tím mộng mơ (Lavender)
    CardColorTheme(
      name: 'Tím oải hương',
      lightBackground: Color(0xFFFAF5FF),
      lightBorder: Color(0xFFE9D5FF),
      lightText: Color(0xFF581C87),
      darkBackground: Color(0xFF32194D),
      darkBorder: Color(0xFF6B21A8),
      darkText: Color(0xFFF3E8FF),
      previewColor: Color(0xFFA855F7),
    ),
    // 4: Vàng bơ (Sunny Butter)
    CardColorTheme(
      name: 'Vàng bơ',
      lightBackground: Color(0xFFFEFCE8),
      lightBorder: Color(0xFFFEF08A),
      lightText: Color(0xFF713F12),
      darkBackground: Color(0xFF3D320B),
      darkBorder: Color(0xFF854D0E),
      darkText: Color(0xFFFEF9C3),
      previewColor: Color(0xFFFACC15),
    ),
    // 5: Xanh da trời (Sky Blue)
    CardColorTheme(
      name: 'Xanh da trời',
      lightBackground: Color(0xFFF0F9FF),
      lightBorder: Color(0xFFBAE6FD),
      lightText: Color(0xFF0C4A6E),
      darkBackground: Color(0xFF0F2E47),
      darkBorder: Color(0xFF0369A1),
      darkText: Color(0xFFE0F2FE),
      previewColor: Color(0xFF38BDF8),
    ),
    // 6: Hồng kẹo ngọt (Sweet Rose)
    CardColorTheme(
      name: 'Hồng phấn',
      lightBackground: Color(0xFFFDF2F8),
      lightBorder: Color(0xFFFBCFE8),
      lightText: Color(0xFF701A75),
      darkBackground: Color(0xFF3D163F),
      darkBorder: Color(0xFF86198F),
      darkText: Color(0xFFFCE7F3),
      previewColor: Color(0xFFF472B6),
    ),
    // 7: Xanh ngọc lam (Cyan / Aqua)
    CardColorTheme(
      name: 'Ngọc lam',
      lightBackground: Color(0xFFECFEFF),
      lightBorder: Color(0xFFA5F3FC),
      lightText: Color(0xFF164E63),
      darkBackground: Color(0xFF11343B),
      darkBorder: Color(0xFF155E75),
      darkText: Color(0xFFCFFAFE),
      previewColor: Color(0xFF22D3EE),
    ),
    // 8: Nâu trà sữa (Warm Sepia)
    CardColorTheme(
      name: 'Nâu trà sữa',
      lightBackground: Color(0xFFFFFBEB),
      lightBorder: Color(0xFFFDE68A),
      lightText: Color(0xFF78350F),
      darkBackground: Color(0xFF392512),
      darkBorder: Color(0xFF92400E),
      darkText: Color(0xFFFEF3C7),
      previewColor: Color(0xFFF59E0B),
    ),
    // 9: Than chì hiện đại (Slate Charcoal)
    CardColorTheme(
      name: 'Than chì',
      lightBackground: Color(0xFFF1F5F9),
      lightBorder: Color(0xFFCBD5E1),
      lightText: Color(0xFF0F172A),
      darkBackground: Color(0xFF0F172A),
      darkBorder: Color(0xFF1E293B),
      darkText: Color(0xFFF1F5F9),
      previewColor: Color(0xFF64748B),
    ),
  ];

  static CardColorTheme getColor(int index) {
    if (index < 0 || index >= colors.length) {
      return colors[0];
    }
    return colors[index];
  }
}
