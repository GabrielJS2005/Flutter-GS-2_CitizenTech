import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// Selo visual reutilizável do Score B2G de priorização de reparos municipais.
class PriorityScoreBadge extends StatelessWidget {
  final double score;
  final bool compact;

  const PriorityScoreBadge({
    super.key,
    required this.score,
    this.compact = false,
  });

  Color get _badgeColor {
    if (score >= 45) return AppTheme.criticalRed;
    if (score >= 25) return AppTheme.accentAmber;
    return AppTheme.primaryNavy;
  }

  String get _urgencyLabel {
    if (score >= 45) return 'Urgência Máxima B2G';
    if (score >= 25) return 'Prioridade Alta B2G';
    return 'Prioridade Moderada';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Score de priorização B2G ${score.toStringAsFixed(1)}, $_urgencyLabel',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: _badgeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _badgeColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.analytics_outlined,
              size: compact ? 16 : 18,
              color: _badgeColor,
            ),
            const SizedBox(width: 6),
            Text(
              compact
                  ? 'Score B2G: ${score.toStringAsFixed(1)}'
                  : 'Score B2G: ${score.toStringAsFixed(1)} • $_urgencyLabel',
              style: TextStyle(
                fontSize: compact ? 12.5 : 13.5,
                fontWeight: FontWeight.w800,
                color: _badgeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

