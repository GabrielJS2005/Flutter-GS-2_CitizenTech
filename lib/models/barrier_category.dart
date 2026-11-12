import 'package:flutter/material.dart';

/// Categorias de barreiras urbanas da malha de acessibilidade de São Paulo.
enum BarrierCategory {
  buracoPisoQuebrado(
    label: 'Buraco/Piso Quebrado',
    icon: Icons.broken_image_outlined,
    color: Color(0xFFD84315),
  ),
  ausenciaRampa(
    label: 'Ausência de Rampa',
    icon: Icons.stairs_outlined,
    color: Color(0xFFB71C1C),
  ),
  obstaculoPasseio(
    label: 'Obstáculo no Passeio',
    icon: Icons.warning_amber_rounded,
    color: Color(0xFFE65100),
  ),
  iluminacaoPrecaria(
    label: 'Iluminação Precária',
    icon: Icons.lightbulb_outline,
    color: Color(0xFF4527A0),
  ),
  travessiaPerigosa(
    label: 'Travessia Perigosa',
    icon: Icons.directions_walk,
    color: Color(0xFFC62828),
  ),
  calcadaEstreita(
    label: 'Calçada Estreita',
    icon: Icons.compress,
    color: Color(0xFFAD1457),
  ),
  semPisoTatil(
    label: 'Sem Piso Tátil',
    icon: Icons.texture,
    color: Color(0xFF00695C),
  );

  const BarrierCategory({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  static BarrierCategory fromLabel(String? label) {
    final String normalized = (label ?? '').trim().toLowerCase();
    return BarrierCategory.values.firstWhere(
      (category) => category.label.toLowerCase() == normalized,
      orElse: () => BarrierCategory.obstaculoPasseio,
    );
  }
}

