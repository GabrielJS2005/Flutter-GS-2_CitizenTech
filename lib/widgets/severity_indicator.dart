import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// Indicador visual de gravidade da barreira (escala de 1 a 5).
class SeverityIndicator extends StatelessWidget {
  final int severity;

  const SeverityIndicator({
    super.key,
    required this.severity,
  });

  Color get _activeColor {
    if (severity >= 5) return AppTheme.criticalRed;
    if (severity == 4) return AppTheme.accentAmber;
    return AppTheme.primaryNavy;
  }

  @override
  Widget build(BuildContext context) {
    final int clamped = severity.clamp(1, 5);
    return Semantics(
      label: 'Gravidade nível $clamped de 5',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Gravidade $clamped/5',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _activeColor,
            ),
          ),
          const SizedBox(width: 6),
          ...List<Widget>.generate(5, (int index) {
            final bool filled = index < clamped;
            return Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Container(
                width: 8,
                height: 14,
                decoration: BoxDecoration(
                  color: filled ? _activeColor : const Color(0xFFD0D5DD),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

