import 'package:flutter/material.dart';

/// Representa uma insígnia (selo) de impacto social da camada Guardiões da Calçada.
class GuardianBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int requiredXp;
  final bool isUnlocked;

  const GuardianBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredXp,
    required this.isUnlocked,
  });
}

/// Estado consolidado de gamificação do usuário no programa Guardiões da Calçada (Scouts).
class GuardianProgress {
  final int totalXp;
  final int level;
  final String rankTitle;
  final int xpIntoCurrentLevel;
  final int xpForNextLevel;
  final int protectedCitizensEstimate;
  final List<GuardianBadge> badges;

  const GuardianProgress({
    required this.totalXp,
    required this.level,
    required this.rankTitle,
    required this.xpIntoCurrentLevel,
    required this.xpForNextLevel,
    required this.protectedCitizensEstimate,
    required this.badges,
  });

  double get levelProgress =>
      xpForNextLevel == 0 ? 1.0 : (xpIntoCurrentLevel / xpForNextLevel).clamp(0.0, 1.0);
}

