import 'package:flutter/material.dart';

import 'app/app_routes.dart';
import 'app/app_theme.dart';
import 'models/barrier_model.dart';
import 'models/mobility_profile.dart';
import 'screens/barrier_detail_screen.dart';
import 'screens/guardian_b2g_screen.dart';
import 'screens/home_radar_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/report_barrier_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/app_constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CaminhoLivreApp());
}

/// Aplicativo Cross-Platform Caminho Livre (CitizenTech — Global Solution FIAP).
class CaminhoLivreApp extends StatelessWidget {
  const CaminhoLivreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightHighContrastTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case AppRoutes.splash:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const SplashScreen(),
            );

          case AppRoutes.onboarding:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const OnboardingScreen(),
            );

          case AppRoutes.homeRadar:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const HomeRadarScreen(),
            );

          case AppRoutes.barrierDetail:
            final Object? rawArgs = settings.arguments;
            if (rawArgs is BarrierDetailArgs) {
              return MaterialPageRoute<BarrierModel>(
                settings: settings,
                builder: (_) => BarrierDetailScreen(args: rawArgs),
              );
            }
            if (rawArgs is BarrierModel) {
              return MaterialPageRoute<BarrierModel>(
                settings: settings,
                builder: (_) => BarrierDetailScreen(
                  args: BarrierDetailArgs(
                    barrier: rawArgs,
                    activeProfile: MobilityProfile.cadeirante,
                  ),
                ),
              );
            }
            return _fallbackRoute(settings);

          case AppRoutes.reportBarrier:
            return MaterialPageRoute<BarrierModel>(
              settings: settings,
              builder: (_) => const ReportBarrierScreen(),
            );

          case AppRoutes.login:
            final Object? rawArgs = settings.arguments;
            final LoginScreenArgs typedArgs = rawArgs is LoginScreenArgs
                ? rawArgs
                : const LoginScreenArgs(
                    barriers: <BarrierModel>[],
                    activeProfile: MobilityProfile.cadeirante,
                  );
            return MaterialPageRoute<List<BarrierModel>>(
              settings: settings,
              builder: (_) => LoginScreen(args: typedArgs),
            );

          case AppRoutes.guardianB2G:
            final Object? rawArgs = settings.arguments;
            final GuardianB2GArgs typedArgs = rawArgs is GuardianB2GArgs
                ? rawArgs
                : const GuardianB2GArgs(
                    barriers: <BarrierModel>[],
                    activeProfile: MobilityProfile.cadeirante,
                  );
            return MaterialPageRoute<List<BarrierModel>>(
              settings: settings,
              builder: (_) => GuardianB2GScreen(args: typedArgs),
            );

          default:
            return _fallbackRoute(settings);
        }
      },
    );
  }

  Route<void> _fallbackRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const HomeRadarScreen(),
    );
  }
}
