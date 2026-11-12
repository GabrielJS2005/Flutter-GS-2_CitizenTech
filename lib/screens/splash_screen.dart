import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../app/app_theme.dart';
import '../services/preferences_service.dart';
import '../utils/app_constants.dart';

/// Tela 0 — SplashScreen (Requisito 1: 1,0 ponto).
/// Exibe o logo com Image.asset, consulta o SharedPreferences e redireciona
/// automaticamente após 2 segundos para Onboarding ou HomeRadarScreen.
class SplashScreen extends StatefulWidget {
  final PreferencesService? preferencesService;

  const SplashScreen({
    super.key,
    this.preferencesService,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final PreferencesService _preferencesService;

  @override
  void initState() {
    super.initState();
    _preferencesService = widget.preferencesService ?? PreferencesService();
    _checkSessionAndRedirect();
  }

  Future<void> _checkSessionAndRedirect() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _preferencesService.shouldSkipOnboarding(),
      Future<void>.delayed(AppConstants.splashDelay),
    ]);

    if (!mounted) return;

    final bool skipOnboarding = results[0] as bool;
    final String targetRoute =
        skipOnboarding ? AppRoutes.homeRadar : AppRoutes.onboarding;

    Navigator.pushReplacementNamed(context, targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryNavy,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 136,
                  height: 136,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      AppConstants.logoAssetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (BuildContext context, Object error,
                          StackTrace? stackTrace) {
                        return const Icon(
                          Icons.accessible_forward_rounded,
                          size: 72,
                          color: AppTheme.primaryNavy,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  AppConstants.appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  AppConstants.appTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE0EAFF),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Verificando preferências de acessibilidade...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFD0D5DD),
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

