import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/mobility_profile.dart';

/// Barra horizontal de seleção dinâmica de Perfil Biomecânico (Interação 2).
/// Permite alternar entre Cadeirante, Deficiência Visual, Idoso, Carrinho de Bebê e Guardião Scout.
class ProfileSelectorBar extends StatelessWidget {
  final MobilityProfile selectedProfile;
  final ValueChanged<MobilityProfile> onProfileSelected;

  const ProfileSelectorBar({
    super.key,
    required this.selectedProfile,
    required this.onProfileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFD0D5DD), width: 1.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.tune_rounded,
                size: 18,
                color: AppTheme.primaryNavy,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Perfil Biomecânico Ativo (Recálculo em Tempo Real):',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.highContrastText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: MobilityProfile.values.map((MobilityProfile profile) {
                final bool isSelected = profile == selectedProfile;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    label: 'Perfil ${profile.label}',
                    child: ChoiceChip(
                      showCheckmark: false,
                      avatar: Icon(
                        profile.icon,
                        size: 18,
                        color:
                            isSelected ? Colors.white : AppTheme.primaryNavy,
                      ),
                      label: Text(profile.label),
                      selected: isSelected,
                      onSelected: (_) => onProfileSelected(profile),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  selectedProfile.icon,
                  size: 18,
                  color: AppTheme.primaryNavy,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${selectedProfile.shortDescription} '
                    '(Largura mín.: ${selectedProfile.minWidthMeters.toStringAsFixed(2)}m • '
                    'Inclin. máx.: ${selectedProfile.maxInclinePercent.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

