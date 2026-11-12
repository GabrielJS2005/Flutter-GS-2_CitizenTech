import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/barrier_model.dart';
import '../models/mobility_profile.dart';
import 'priority_score_badge.dart';
import 'severity_indicator.dart';

/// Card personalizado e reutilizável para exibir uma barreira urbana (Requisitos 5, 6 e 7).
/// Destaca automaticamente em vermelho os trechos com Bloqueio Físico (Custo = ∞)
/// para o Perfil Biomecânico ativo.
class BarrierCard extends StatelessWidget {
  final BarrierModel barrier;
  final MobilityProfile activeProfile;
  final VoidCallback onTap;
  final VoidCallback onToggleMonitor;

  const BarrierCard({
    super.key,
    required this.barrier,
    required this.activeProfile,
    required this.onTap,
    required this.onToggleMonitor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPhysicalBlock = barrier.isBlockingForProfile(activeProfile);
    final String impactText = barrier.getImpactForProfile(activeProfile);
    final Color borderColor = isPhysicalBlock
        ? AppTheme.criticalRed
        : const Color(0xFFD0D5DD);

    return Semantics(
      button: true,
      label:
          '${barrier.title}, categoria ${barrier.category.label}, impacto $impactText',
      child: Card(
        elevation: isPhysicalBlock ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: borderColor,
            width: isPhysicalBlock ? 2.4 : 1.2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Linha superior: Categoria + Status + Botão de Monitorar/Favoritar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: barrier.category.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: barrier.category.color,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            barrier.category.icon,
                            size: 16,
                            color: barrier.category.color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            barrier.category.label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: barrier.category.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: barrier.statusEnum.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        barrier.status,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: barrier.statusEnum.color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: barrier.isMonitored
                          ? 'Remover monitoramento de reparo'
                          : 'Monitorar reparo municipal',
                      onPressed: onToggleMonitor,
                      icon: Icon(
                        barrier.isMonitored
                            ? Icons.notifications_active
                            : Icons.notifications_none_outlined,
                        color: barrier.isMonitored
                            ? AppTheme.accentAmber
                            : AppTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Título da barreira
                Text(
                  barrier.title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.highContrastText,
                  ),
                ),
                const SizedBox(height: 6),

                // Endereço / Coordenada
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: AppTheme.secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        barrier.address,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppTheme.secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Destaque de impacto para o perfil biomecânico selecionado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isPhysicalBlock
                        ? AppTheme.criticalRed.withValues(alpha: 0.12)
                        : activeProfile == MobilityProfile.guardiao
                            ? AppTheme.secondaryTeal.withValues(alpha: 0.12)
                            : AppTheme.primaryNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPhysicalBlock
                          ? AppTheme.criticalRed
                          : activeProfile == MobilityProfile.guardiao
                              ? AppTheme.secondaryTeal
                              : AppTheme.primaryNavy.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        isPhysicalBlock
                            ? Icons.block_flipped
                            : activeProfile.icon,
                        size: 18,
                        color: isPhysicalBlock
                            ? AppTheme.criticalRed
                            : activeProfile == MobilityProfile.guardiao
                                ? AppTheme.secondaryTeal
                                : AppTheme.primaryNavy,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${activeProfile.label}: $impactText',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isPhysicalBlock
                                ? AppTheme.criticalRed
                                : activeProfile == MobilityProfile.guardiao
                                    ? AppTheme.secondaryTeal
                                    : AppTheme.primaryNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Rodapé: Gravidade, Confirmações e Score B2G
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    SeverityIndicator(severity: barrier.severity),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: AppTheme.secondaryTeal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${barrier.confirmations} validações',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondaryTeal,
                          ),
                        ),
                      ],
                    ),
                    PriorityScoreBadge(
                      score: barrier.priorityScore,
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

