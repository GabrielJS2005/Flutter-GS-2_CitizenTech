import 'package:flutter/material.dart';

/// Enum dos 5 perfis biomecânicos de deslocamento do Caminho Livre
/// conforme a Especificação Técnica (Seção 7.1) e a Solução Desenvolvida (Seção 4.1).
enum MobilityProfile {
  cadeirante(
    label: 'Cadeirante',
    shortDescription:
        'Exige rampa (rebaixamento de guia), largura livre ≥ 1,20 m e inclinação ≤ 8,33%.',
    icon: Icons.accessible_forward,
    maxInclinePercent: 8.33,
    minWidthMeters: 1.20,
    requiresRamp: true,
    requiresTactilePaving: false,
  ),
  deficienciaVisual(
    label: 'Deficiência Visual',
    shortDescription:
        'Prioriza piso tátil alerta/direcional, travessia segura e calçadas livres de obstáculos aéreos.',
    icon: Icons.visibility_off,
    maxInclinePercent: 10.0,
    minWidthMeters: 1.20,
    requiresRamp: false,
    requiresTactilePaving: true,
  ),
  idoso(
    label: 'Idoso',
    shortDescription:
        'Evita piso irregular, degraus altos, rampas íngremes e trechos sem iluminação pública.',
    icon: Icons.elderly,
    maxInclinePercent: 6.0,
    minWidthMeters: 1.10,
    requiresRamp: true,
    requiresTactilePaving: false,
  ),
  carrinhoBebe(
    label: 'Carrinho de Bebê',
    shortDescription:
        'Exige passeio contínuo ≥ 1,20 m, guias rebaixadas e superfície sem buracos.',
    icon: Icons.child_friendly,
    maxInclinePercent: 8.33,
    minWidthMeters: 1.20,
    requiresRamp: true,
    requiresTactilePaving: false,
  ),
  guardiao(
    label: 'Guardião Scout',
    shortDescription:
        'Auditor comunitário gamificado: busca barreiras ativas no território para validar e ganhar XP.',
    icon: Icons.shield,
    maxInclinePercent: 15.0,
    minWidthMeters: 0.90,
    requiresRamp: false,
    requiresTactilePaving: false,
  );

  const MobilityProfile({
    required this.label,
    required this.shortDescription,
    required this.icon,
    required this.maxInclinePercent,
    required this.minWidthMeters,
    required this.requiresRamp,
    required this.requiresTactilePaving,
  });

  final String label;
  final String shortDescription;
  final IconData icon;
  final double maxInclinePercent;
  final double minWidthMeters;
  final bool requiresRamp;
  final bool requiresTactilePaving;

  /// Restaura o perfil salvo no SharedPreferences pelo nome do enum.
  static MobilityProfile fromName(String? name) {
    return MobilityProfile.values.firstWhere(
      (profile) => profile.name == name,
      orElse: () => MobilityProfile.cadeirante,
    );
  }
}

