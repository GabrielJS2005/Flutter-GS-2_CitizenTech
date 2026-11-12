import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/onboarding_page_data.dart';
import '../utils/app_constants.dart';

/// Item reutilizável de página do Onboarding (Requisito 2).
/// Contém Imagem (Image.asset) + Ícone ilustrativo, Título, Descrição e conexão com ODS.
class OnboardingPageViewItem extends StatelessWidget {
  final OnboardingPageData page;

  const OnboardingPageViewItem({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Identidade visual combinando Image.asset e o ícone da página
          Stack(
            alignment: Alignment.bottomRight,
            children: <Widget>[
              Container(
                width: 118,
                height: 118,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: page.accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: page.accentColor, width: 2.2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    AppConstants.logoAssetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (BuildContext context, Object error,
                        StackTrace? stackTrace) {
                      return Icon(
                        page.icon,
                        size: 56,
                        color: page.accentColor,
                      );
                    },
                  ),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: page.accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: Icon(
                  page.icon,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Selo superior da dimensão CitizenTech
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: page.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: page.accentColor, width: 1.2),
            ),
            child: Text(
              page.badgeText,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: page.accentColor,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Título obrigatório da página
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.highContrastText,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),

          // Descrição obrigatória da proposta
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),

          // Card de alinhamento com os ODS da ONU
          Card(
            margin: EdgeInsets.zero,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.public_rounded,
                    color: page.accentColor,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      page.odsHighlight,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.highContrastText,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

