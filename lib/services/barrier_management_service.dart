import '../models/barrier_category.dart';
import '../models/barrier_model.dart';
import '../models/barrier_status.dart';
import '../models/mobility_profile.dart';
import '../utils/app_constants.dart';

/// Serviço de regras de negócio para filtragem, ordenação B2G, ciclo de vida de obras
/// e criação de relatos comunitários, mantendo as telas (`screens/`) 100% desacopladas
/// da lógica de domínio (Requisito 7 da avaliação).
class BarrierManagementService {
  const BarrierManagementService._();

  /// Filtra a lista de barreiras conforme busca textual, monitoramento e bloqueio físico.
  static List<BarrierModel> filterBarriers({
    required List<BarrierModel> barriers,
    required MobilityProfile activeProfile,
    String searchQuery = '',
    bool onlyMonitored = false,
    bool onlyBlockingForProfile = false,
  }) {
    final String query = searchQuery.trim().toLowerCase();
    return barriers.where((BarrierModel b) {
      if (onlyMonitored && !b.isMonitored) return false;
      if (onlyBlockingForProfile && !b.isBlockingForProfile(activeProfile)) {
        return false;
      }
      if (query.isNotEmpty) {
        final bool matchesTitle = b.title.toLowerCase().contains(query);
        final bool matchesAddress = b.address.toLowerCase().contains(query);
        final bool matchesCategory =
            b.category.label.toLowerCase().contains(query);
        return matchesTitle || matchesAddress || matchesCategory;
      }
      return true;
    }).toList();
  }

  /// Conta quantas barreiras representam bloqueio físico (Custo = ∞) para o perfil ativo.
  static int countBlockingForProfile(
    List<BarrierModel> barriers,
    MobilityProfile activeProfile,
  ) {
    return barriers
        .where((BarrierModel b) => b.isBlockingForProfile(activeProfile))
        .length;
  }

  /// Filtra por status municipal (opcional) e ordena decrescentemente pelo Score B2G.
  static List<BarrierModel> rankAndFilterB2GQueue({
    required List<BarrierModel> barriers,
    BarrierStatus? statusFilter,
  }) {
    final List<BarrierModel> filtered = statusFilter == null
        ? List<BarrierModel>.from(barriers)
        : barriers
            .where((BarrierModel b) => b.statusEnum == statusFilter)
            .toList();

    filtered.sort(
      (BarrierModel a, BarrierModel b) =>
          b.priorityScore.compareTo(a.priorityScore),
    );
    return filtered;
  }

  /// Determina o próximo estágio no ciclo de vida B2G da obra pública
  /// (Aberto -> Em Análise -> Resolvido -> Aberto).
  static BarrierStatus nextLifecycleStatus(BarrierStatus current) {
    if (current == BarrierStatus.aberto) {
      return BarrierStatus.emAnalise;
    } else if (current == BarrierStatus.emAnalise) {
      return BarrierStatus.resolvido;
    } else {
      return BarrierStatus.aberto;
    }
  }

  /// Calcula a prévia do Score B2G para um novo relato em 3 toques.
  static double calculatePreviewScore({
    required int severity,
    required double proximityFactor,
    int initialConfirmations = 1,
    double ageDecay = AppConstants.defaultAgeDecay,
  }) {
    return severity * (1 + initialConfirmations) * proximityFactor * ageDecay;
  }

  /// Gera o título técnico padronizado a partir da categoria selecionada no relato rápido.
  static String buildAutoTitle(BarrierCategory category) {
    switch (category) {
      case BarrierCategory.ausenciaRampa:
        return 'Travessia sem Rebaixamento de Guia (Relato Guardião)';
      case BarrierCategory.buracoPisoQuebrado:
        return 'Cratera / Piso Quebrado no Passeio Público';
      case BarrierCategory.obstaculoPasseio:
        return 'Obstáculo Fixo Bloqueando Largura Livre (< 1,20m)';
      case BarrierCategory.iluminacaoPrecaria:
        return 'Trecho Pedonal com Iluminação Pública Inoperante';
      case BarrierCategory.travessiaPerigosa:
        return 'Travessia Sem Foco Sonoro / Semáforo Pedonal Curto';
      case BarrierCategory.calcadaEstreita:
        return 'Estrangulamento Severo de Calçada';
      case BarrierCategory.semPisoTatil:
        return 'Esquina Desprovida de Piso Tátil Alerta/Direcional';
    }
  }

  /// Instancia um novo [BarrierModel] proveniente do fluxo de Relato em 3 Toques.
  static BarrierModel createReportedBarrier({
    required BarrierCategory category,
    required int severity,
    required double proximityFactor,
    required String rawAddress,
  }) {
    final int timestampSeed = DateTime.now().millisecondsSinceEpoch % 100000;
    final String cleanAddress = rawAddress.trim().isEmpty
        ? 'Região Av. Paulista / Bela Vista - São Paulo/SP'
        : rawAddress.trim();

    return BarrierModel(
      id: 'scout_$timestampSeed',
      title: buildAutoTitle(category),
      category: category,
      address: cleanAddress,
      severity: severity,
      confirmations: 1,
      proximityFactor: proximityFactor,
      ageDecay: AppConstants.defaultAgeDecay,
      status: BarrierStatus.aberto.label,
      imageUrl: 'https://picsum.photos/seed/scout$timestampSeed/600/400',
      isMonitored: true,
    );
  }
}

