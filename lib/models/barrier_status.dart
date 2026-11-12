import 'package:flutter/material.dart';

/// Estágios auditáveis do ciclo de vida do chamado no Painel do Gestor Público (B2G).
enum BarrierStatus {
  aberto(
    label: 'Aberto',
    color: Color(0xFFB71C1C),
    icon: Icons.error_outline,
  ),
  emAnalise(
    label: 'Em Análise',
    color: Color(0xFFE65100),
    icon: Icons.engineering_outlined,
  ),
  resolvido(
    label: 'Resolvido',
    color: Color(0xFF1B5E20),
    icon: Icons.check_circle_outline,
  );

  const BarrierStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  static BarrierStatus fromLabel(String? label) {
    final String normalized = (label ?? '').trim().toLowerCase();
    return BarrierStatus.values.firstWhere(
      (status) => status.label.toLowerCase() == normalized,
      orElse: () => BarrierStatus.aberto,
    );
  }
}

