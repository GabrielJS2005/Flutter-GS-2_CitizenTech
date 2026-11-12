import 'package:flutter/material.dart';

import '../models/guardian_progress.dart';
import '../utils/app_constants.dart';

/// Serviço de regras de negócio da camada de gamificação "Guardiões da Calçada" (Scouts).
/// Mantém o cálculo de nível, patentes, contador de empatia e insígnias fora dos widgets.
class GuardianService {
  const GuardianService._();

  static GuardianProgress buildProgress(int totalXp) {
    final int safeXp = totalXp < 0 ? 0 : totalXp;
    final int level = (safeXp ~/ AppConstants.xpPerLevel) + 1;
    final int xpIntoCurrentLevel = safeXp % AppConstants.xpPerLevel;
    final String rankTitle = _rankTitleForLevel(level);

    // Estimativa tangível de empatia ("Suas auditorias protegeram X cidadãos")
    final int protectedCitizens = (safeXp ~/ 15) * 4;

    final List<GuardianBadge> badges = <GuardianBadge>[
      GuardianBadge(
        id: 'sentinela_guia',
        title: 'Sentinela da Guia',
        description: 'Iniciou auditoria comunitária de rampas e travessias.',
        icon: Icons.accessible_forward,
        requiredXp: 50,
        isUnlocked: safeXp >= 50,
      ),
      GuardianBadge(
        id: 'olhos_tatil',
        title: 'Farol Tátil',
        description: 'Validou barreiras críticas para pessoas com baixa visão.',
        icon: Icons.visibility,
        requiredXp: 120,
        isUnlocked: safeXp >= 120,
      ),
      GuardianBadge(
        id: 'escudo_ubs',
        title: 'Guardião da Saúde (UBS)',
        description: 'Auditou calçadas no raio de 200m de hospitais e UBSs.',
        icon: Icons.local_hospital_outlined,
        requiredXp: 160,
        isUnlocked: safeXp >= 160,
      ),
      GuardianBadge(
        id: 'mestre_zeladoria',
        title: 'Mestre da Zeladoria B2G',
        description: 'Contribuiu decisivamente para o Score de obras públicas.',
        icon: Icons.workspace_premium_outlined,
        requiredXp: 220,
        isUnlocked: safeXp >= 220,
      ),
      GuardianBadge(
        id: 'pioneiro_bairro',
        title: 'Explorador Anti-ColdStart',
        description: 'Venceu a escassez de dados mapeando novos quarteirões.',
        icon: Icons.explore_outlined,
        requiredXp: 300,
        isUnlocked: safeXp >= 300,
      ),
      GuardianBadge(
        id: 'lenda_caminho_livre',
        title: 'Lenda Caminho Livre',
        description: 'Referência máxima de impacto cívico e inclusão urbana.',
        icon: Icons.emoji_events_outlined,
        requiredXp: 400,
        isUnlocked: safeXp >= 400,
      ),
    ];

    return GuardianProgress(
      totalXp: safeXp,
      level: level,
      rankTitle: rankTitle,
      xpIntoCurrentLevel: xpIntoCurrentLevel,
      xpForNextLevel: AppConstants.xpPerLevel,
      protectedCitizensEstimate: protectedCitizens,
      badges: badges,
    );
  }

  static String _rankTitleForLevel(int level) {
    if (level <= 1) return 'Scout Iniciante';
    if (level == 2) return 'Auditor de Quarteirão';
    if (level == 3) return 'Guardião da Calçada';
    if (level == 4) return 'Sentinela Urbano';
    return 'Embaixador CitizenTech';
  }
}

