import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// Widget do estado Inicial (RequestState.initial) do WebService (Requisito 4).
class InitialStateWidget extends StatelessWidget {
  final VoidCallback onStartScan;

  const InitialStateWidget({
    super.key,
    required this.onStartScan,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.radar_rounded,
                    size: 42,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Radar de Microacessibilidade Pronto',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.highContrastText,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Toque no botão abaixo para consultar em tempo real a API de '
                  'barreiras urbanas de São Paulo (rampas, piso tátil, calçadas '
                  'e travessias) e calcular o impacto para o seu perfil biomecânico.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onStartScan,
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Escanear Malha Urbana (São Paulo - SP)'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
