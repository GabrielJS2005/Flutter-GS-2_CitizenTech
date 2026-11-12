/// Constantes globais de domínio, gamificação e endpoints do Caminho Livre.
class AppConstants {
  AppConstants._();

  static const String appName = 'Caminho Livre';
  static const String appTagline =
      'Mobilidade Urbana Inclusiva & Zeladoria Preditiva (CitizenTech)';

  // Caminho do logo local para uso em Image.asset (Requisito 1 e 5)
  static const String logoAssetPath = 'assets/images/logo_caminho_livre.png';

  // Tempo de exibição da Splash Screen antes do redirecionamento automático
  static const Duration splashDelay = Duration(seconds: 2);

  // Regras de pontuação de experiência (XP) - Guardiões da Calçada
  static const int xpPerValidation = 15;
  static const int xpPerNewReport = 50;
  static const int xpPerLevel = 100;

  // Fatores de proximidade espacial a equipamentos públicos (Score B2G)
  static const double proximityUbsHospital = 2.5; // < 100m UBS / Hospital
  static const double proximitySchoolTransport = 2.0; // < 200m Escola / Ônibus
  static const double proximityRegularStreet = 1.0; // Via comum

  // Decaimento de idade fixo para fase de testes (item 6 das decisões)
  static const double defaultAgeDecay = 1.0;

  // Comprimento médio de referência de quadra (metros) para exibição de Custo(e,P)
  static const double referenceSegmentMeters = 100.0;
}

