import 'package:flutter/material.dart';

/// Modelo de dados para cada página da tela de Introdução/Onboarding (Requisito 2).
class OnboardingPageData {
  final String badgeText;
  final String title;
  final String description;
  final String odsHighlight;
  final IconData icon;
  final Color accentColor;

  const OnboardingPageData({
    required this.badgeText,
    required this.title,
    required this.description,
    required this.odsHighlight,
    required this.icon,
    required this.accentColor,
  });
}

