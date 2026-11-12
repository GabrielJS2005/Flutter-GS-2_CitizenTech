import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../app/app_theme.dart';
import '../models/onboarding_page_data.dart';
import '../services/preferences_service.dart';
import '../widgets/onboarding_page_view_item.dart';

/// Tela 0.5 — OnboardingScreen (Requisito 2: 1,5 ponto).
/// Estrutura um PageView com 3 páginas, botões Voltar e Avançar/Concluir e
/// CheckboxListTile "Não mostrar novamente" persistido no SharedPreferences.
class OnboardingScreen extends StatefulWidget {
  final PreferencesService? preferencesService;

  const OnboardingScreen({
    super.key,
    this.preferencesService,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  late final PreferencesService _preferencesService;

  int _currentPage = 0;
  bool _dontShowAgain = false;

  static const List<OnboardingPageData> _pages = <OnboardingPageData>[
    OnboardingPageData(
      badgeText: '1/3 • Roteamento Biomecânico',
      title: 'Mobilidade Adaptada ao Seu Corpo',
      description:
          'Calçadas esburacadas, degraus sem rampa e falta de piso tátil não '
          'têm o mesmo impacto para todos. Selecione seu perfil (Cadeirante, '
          'Deficiência Visual, Idoso ou Carrinho de Bebê) e veja o aplicativo '
          'identificar bloqueios físicos (Custo = ∞) em tempo real.',
      odsHighlight:
          'ODS 11 (Metas 11.2 e 11.7) & ODS 10 (Meta 10.2): Espaços públicos seguros, inclusivos e acessíveis.',
      icon: Icons.accessible_forward_rounded,
      accentColor: AppTheme.primaryNavy,
    ),
    OnboardingPageData(
      badgeText: '2/3 • Crowdsourcing Gamificado',
      title: 'Missão Guardiões da Calçada',
      description:
          'Para vencer a escassez inicial de dados nas cidades (cold start), '
          'cidadãos e voluntários atuam como Scouts: relate barreiras em '
          'apenas 3 toques ou responda "Ainda está lá?" para ganhar XP, '
          'subir de nível e desbloquear insígnias de impacto social.',
      odsHighlight:
          'ODS 3 (Saúde e Bem-Estar): Prevenção direta de quedas severas em idosos e acidentes no passeio.',
      icon: Icons.shield_outlined,
      accentColor: AppTheme.secondaryTeal,
    ),
    OnboardingPageData(
      badgeText: '3/3 • Inteligência Pública (B2G)',
      title: 'Zeladoria Preditiva (B2G)',
      description:
          'Cada relato confirmado alimenta uma equação matemática de Score de '
          'Priorização que multiplica a urgência de reparos próximos a UBSs, '
          'hospitais e escolas, orientando o orçamento da prefeitura com '
          'transparência auditável.',
      odsHighlight:
          'ODS 9 (Inovação e Infraestrutura): Alocação inteligente de obras públicas baseada em dados abertos.',
      icon: Icons.account_balance_outlined,
      accentColor: AppTheme.accentAmber,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _preferencesService = widget.preferencesService ?? PreferencesService();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _goToNextOrFinish() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    await _preferencesService.setSkipOnboarding(_dontShowAgain);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.homeRadar);
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bem-vindo ao Caminho Livre'),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              await _preferencesService.setSkipOnboarding(_dontShowAgain);
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, AppRoutes.homeRadar);
            },
            child: const Text(
              'Pular',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (int index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (BuildContext context, int index) {
                  return OnboardingPageViewItem(page: _pages[index]);
                },
              ),
            ),

            // Indicador visual de página (3 pontos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(_pages.length, (int index) {
                  final bool active = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: active ? 28 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: active
                          ? AppTheme.primaryNavy
                          : const Color(0xFF98A2B3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
            ),

            // Opção obrigatória "Não mostrar novamente" + Botões Voltar e Avançar/Concluir
            Material(
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFD0D5DD), width: 1.2),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CheckboxListTile(
                      value: _dontShowAgain,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppTheme.primaryNavy,
                      title: const Text(
                        'Não mostrar novamente',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.highContrastText,
                        ),
                      ),
                      subtitle: const Text(
                        'Salva sua preferência no dispositivo (SharedPreferences).',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      onChanged: (bool? value) {
                        setState(() {
                          _dontShowAgain = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                _currentPage > 0 ? _goToPreviousPage : null,
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Voltar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _goToNextOrFinish,
                            icon: Icon(
                              isLastPage
                                  ? Icons.check_circle_outline
                                  : Icons.arrow_forward_rounded,
                            ),
                            label: Text(isLastPage ? 'Concluir' : 'Avançar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
