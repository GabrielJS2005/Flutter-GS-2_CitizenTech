import '../models/barrier_category.dart';
import '../models/mobility_profile.dart';
import '../utils/app_constants.dart';

/// Resultado estruturado da avaliação biomecânica de uma barreira para um perfil.
class ProfileImpactResult {
  final String summaryLabel;
  final String technicalExplanation;
  final String routeCostDisplay;
  final bool isPhysicalBlock;
  final bool isCriticalPenalty;

  const ProfileImpactResult({
    required this.summaryLabel,
    required this.technicalExplanation,
    required this.routeCostDisplay,
    required this.isPhysicalBlock,
    required this.isCriticalPenalty,
  });
}

/// Serviço de domínio responsável por avaliar o impacto biomecânico no grafo
/// segundo a equação Custo(e, P) = L_e * (W_base + Σ P_barreira).
class ImpactCalculator {
  const ImpactCalculator._();

  /// Retorna o rótulo oficial de impacto biomecânico (compatível com a Seção 7.2 da Especificação).
  static String getImpactLabel({
    required BarrierCategory category,
    required MobilityProfile profile,
  }) {
    if (profile == MobilityProfile.guardiao) {
      return 'Missão de Auditoria (+15 XP)';
    }
    if (category == BarrierCategory.ausenciaRampa &&
        profile == MobilityProfile.cadeirante) {
      return 'BLOQUEIO FÍSICO (Custo = ∞)';
    }
    if (category == BarrierCategory.calcadaEstreita &&
        (profile == MobilityProfile.cadeirante ||
            profile == MobilityProfile.carrinhoBebe)) {
      return 'BLOQUEIO FÍSICO (Custo = ∞)';
    }
    if (category == BarrierCategory.buracoPisoQuebrado &&
        profile == MobilityProfile.cadeirante) {
      return 'BLOQUEIO FÍSICO (Custo = ∞)';
    }
    if (category == BarrierCategory.semPisoTatil &&
        profile == MobilityProfile.deficienciaVisual) {
      return 'Penalidade Crítica (+250%)';
    }
    if (category == BarrierCategory.obstaculoPasseio &&
        profile == MobilityProfile.deficienciaVisual) {
      return 'Penalidade Crítica (+250%)';
    }
    if ((category == BarrierCategory.buracoPisoQuebrado ||
            category == BarrierCategory.iluminacaoPrecaria) &&
        profile == MobilityProfile.idoso) {
      return 'Penalidade Crítica (+250%)';
    }
    return 'Penalidade Severa (+120% esforço)';
  }

  /// Verifica se a barreira representa impedimento absoluto (P_barreira = ∞) para o perfil.
  static bool isPhysicalBlock({
    required BarrierCategory category,
    required MobilityProfile profile,
  }) {
    return getImpactLabel(category: category, profile: profile)
        .contains('BLOQUEIO FÍSICO');
  }

  /// Calcula o detalhamento completo do Custo_Trecho para exibição na tela de detalhes.
  static ProfileImpactResult evaluate({
    required BarrierCategory category,
    required MobilityProfile profile,
    required int severity,
  }) {
    final String label = getImpactLabel(category: category, profile: profile);
    final bool blocked = label.contains('BLOQUEIO FÍSICO');
    final bool critical = label.contains('+250%');

    const double baseLength = AppConstants.referenceSegmentMeters;
    const double baseWeight = 1.0;

    if (profile == MobilityProfile.guardiao) {
      return ProfileImpactResult(
        summaryLabel: label,
        technicalExplanation:
            'No perfil Guardião Scout, barreiras ativas têm custo de atração para incentivar a validação comunitária em campo.',
        routeCostDisplay:
            'Custo_Trecho (100m) = ${baseLength.toInt()} u.c. (Prioridade de Auditoria)',
        isPhysicalBlock: false,
        isCriticalPenalty: false,
      );
    }

    if (blocked) {
      return ProfileImpactResult(
        summaryLabel: label,
        technicalExplanation:
            'Aresta removida virtualmente do grafo (P_barreira = ∞). O motor A* desvia automaticamente este quarteirão para ${profile.label}.',
        routeCostDisplay: 'Custo_Trecho (100m) = ∞ (Aresta Intransponível)',
        isPhysicalBlock: true,
        isCriticalPenalty: true,
      );
    }

    final double penaltyMultiplier = critical ? 2.5 : 1.2;
    final double severityFactor = 1.0 + (severity - 1) * 0.15;
    final double totalCost =
        baseLength * (baseWeight + (penaltyMultiplier * severityFactor));

    return ProfileImpactResult(
      summaryLabel: label,
      technicalExplanation: critical
          ? 'Risco acentuado de acidente ou desorientação espacial para ${profile.label}. Recomenda-se rota alternativa.'
          : 'Exige esforço biomecânico adicional (+120%) para ${profile.label} segundo parâmetros da ABNT NBR 9050.',
      routeCostDisplay:
          'Custo_Trecho (100m) = ${totalCost.toStringAsFixed(0)} m equivalentes',
      isPhysicalBlock: false,
      isCriticalPenalty: critical,
    );
  }
}

