import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// Widget do estado de Carregamento (RequestState.loading) do WebService (Requisito 4).
class LoadingStateWidget extends StatelessWidget {
  final String message;

  const LoadingStateWidget({
    super.key,
    this.message = 'Sincronizando malha de calçadas e barreiras...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                strokeWidth: 4.5,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.highContrastText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Consultando API REST Caminho Livre (São Paulo - SP) e calculando Score B2G...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
