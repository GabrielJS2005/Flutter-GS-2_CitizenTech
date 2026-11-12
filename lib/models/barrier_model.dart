import '../services/impact_calculator.dart';
import 'barrier_category.dart';
import 'barrier_status.dart';
import 'mobility_profile.dart';

/// Entidade principal de Barreira Urbana, contendo regras matemáticas de Score B2G,
/// avaliação de impacto por perfil e serialização JSON para a API REST Caminho Livre
/// (`barriers_sp.json`).
class BarrierModel {
  final String id;
  final String title;
  final BarrierCategory category;
  final String address;
  final int severity; // 1 a 5
  int confirmations;
  final double proximityFactor; // 2.5 (<100m UBS), 2.0 (<200m Escola), 1.0 (Rua comum)
  final double ageDecay; // 1.0 (Recente) a 0.4 (Antiga)
  String status; // 'Aberto', 'Em Análise', 'Resolvido'
  final String imageUrl;
  bool isMonitored;

  BarrierModel({
    required this.id,
    required this.title,
    required this.category,
    required this.address,
    required this.severity,
    required this.confirmations,
    required this.proximityFactor,
    required this.ageDecay,
    required this.status,
    required this.imageUrl,
    this.isMonitored = false,
  });

  /// Equação Oficial de Score B2G do Caminho Livre:
  /// Score = Gravidade * (1 + Confirmações) * Fator_Proximidade * Decaimento_Idade
  double get priorityScore {
    return severity * (1 + confirmations) * proximityFactor * ageDecay;
  }

  /// Retorna o enum tipado correspondente ao status textual da barreira.
  BarrierStatus get statusEnum => BarrierStatus.fromLabel(status);

  /// Descrição legível do equipamento público próximo conforme o fator de proximidade.
  String get proximityDescription {
    if (proximityFactor >= 2.5) {
      return 'Raio < 100m de UBS / Hospital (Fator 2,5x)';
    }
    if (proximityFactor >= 2.0) {
      return 'Raio < 200m de Escola / Transporte (Fator 2,0x)';
    }
    return 'Via Urbana Comum (Fator 1,0x)';
  }

  /// Avalia o impacto biomecânico no grafo para o perfil selecionado.
  String getImpactForProfile(MobilityProfile profile) {
    return ImpactCalculator.getImpactLabel(
      category: category,
      profile: profile,
    );
  }

  /// Indica se a barreira representa bloqueio físico (Custo = ∞) para o perfil ativo.
  bool isBlockingForProfile(MobilityProfile profile) {
    return ImpactCalculator.isPhysicalBlock(
      category: category,
      profile: profile,
    );
  }

  /// Registra uma validação comunitária ("Ainda está lá?"):
  /// incrementa as confirmações e, caso a barreira esteja com status "Resolvido",
  /// retorna automaticamente para o status "Aberto" (reabertura por auditoria cidadã).
  bool registerCommunityValidation() {
    confirmations += 1;
    final bool wasReopened = statusEnum == BarrierStatus.resolvido;
    if (wasReopened) {
      status = BarrierStatus.aberto.label;
    }
    return wasReopened;
  }

  /// Cria uma cópia atualizada preservando imutabilidade nas transições entre telas.
  BarrierModel copyWith({
    String? id,
    String? title,
    BarrierCategory? category,
    String? address,
    int? severity,
    int? confirmations,
    double? proximityFactor,
    double? ageDecay,
    String? status,
    String? imageUrl,
    bool? isMonitored,
  }) {
    return BarrierModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      address: address ?? this.address,
      severity: severity ?? this.severity,
      confirmations: confirmations ?? this.confirmations,
      proximityFactor: proximityFactor ?? this.proximityFactor,
      ageDecay: ageDecay ?? this.ageDecay,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      isMonitored: isMonitored ?? this.isMonitored,
    );
  }

  /// Conversor JSON oficial para o endpoint `barriers_sp.json`.
  factory BarrierModel.fromJson(Map<String, dynamic> json) {
    return BarrierModel(
      id: json['id']?.toString() ?? 'SP-0000',
      title: json['title'] as String? ?? 'Barreira Urbana',
      category: BarrierCategory.fromLabel(json['category'] as String?),
      address: json['address'] as String? ?? 'São Paulo - SP',
      severity: (json['severity'] as num?)?.toInt() ?? 4,
      confirmations: (json['confirmations'] as num?)?.toInt() ?? 1,
      proximityFactor: (json['proximityFactor'] as num?)?.toDouble() ?? 2.0,
      ageDecay: (json['ageDecay'] as num?)?.toDouble() ?? 1.0,
      status: json['status'] as String? ?? 'Aberto',
      imageUrl: json['imageUrl'] as String? ??
          'https://picsum.photos/seed/calcada/600/400',
    );
  }

  /// Serializa a instância em Map JSON compatível com a API `barriers_sp.json`.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'category': category.label,
      'address': address,
      'severity': severity,
      'confirmations': confirmations,
      'proximityFactor': proximityFactor,
      'ageDecay': ageDecay,
      'status': status,
      'imageUrl': imageUrl,
    };
  }
}
