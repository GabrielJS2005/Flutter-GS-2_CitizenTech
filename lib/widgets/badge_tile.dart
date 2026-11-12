import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/guardian_progress.dart';

/// Card reutilizável de insígnia (selo) exibido no GridView do Painel Guardião.
class BadgeTile extends StatelessWidget {
  final GuardianBadge badge;

  const BadgeTile({
    super.key,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final bool unlocked = badge.isUnlocked;
    final Color accentColor =
        unlocked ? AppTheme.secondaryTeal : const Color(0xFF98A2B3);

    return Semantics(
      label:
          'Insígnia ${badge.title}, ${unlocked ? "desbloqueada" : "bloqueada, requer ${badge.requiredXp} XP"}',
      child: Card(
        margin: EdgeInsets.zero,
        elevation: unlocked ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: unlocked ? AppTheme.secondaryTeal : const Color(0xFFD0D5DD),
            width: unlocked ? 1.8 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  unlocked ? badge.icon : Icons.lock_outline_rounded,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: unlocked
                      ? AppTheme.highContrastText
                      : AppTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  badge.description,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.secondaryText,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unlocked ? 'DESBLOQUEADA' : 'Meta: ${badge.requiredXp} XP',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

