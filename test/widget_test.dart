import 'package:caminho_livre/models/barrier_category.dart';
import 'package:caminho_livre/models/barrier_model.dart';
import 'package:caminho_livre/models/mobility_profile.dart';
import 'package:caminho_livre/models/user_role.dart';
import 'package:caminho_livre/screens/guardian_b2g_screen.dart';
import 'package:caminho_livre/screens/home_radar_screen.dart';
import 'package:caminho_livre/screens/login_screen.dart';
import 'package:caminho_livre/screens/onboarding_screen.dart';
import 'package:caminho_livre/services/auth_service.dart';
import 'package:caminho_livre/services/barrier_api_service.dart';
import 'package:caminho_livre/services/barrier_management_service.dart';
import 'package:caminho_livre/services/guardian_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFailingApiService extends BarrierApiService {
  @override
  Future<List<BarrierModel>> fetchBarriers() async {
    throw BarrierApiException('Falha simulada de conexão para teste.');
  }
}

class _FakeSuccessApiService extends BarrierApiService {
  @override
  Future<List<BarrierModel>> fetchBarriers() async {
    return <BarrierModel>[
      BarrierModel(
        id: 'SP-1001',
        title: 'Escadaria sem Rampa de Acesso',
        category: BarrierCategory.ausenciaRampa,
        address: 'Av. Paulista, 1106 - Bela Vista',
        severity: 5,
        confirmations: 12,
        proximityFactor: 2.0,
        ageDecay: 1.0,
        status: 'Aberto',
        imageUrl: 'https://picsum.photos/seed/sp1001/600/400',
      ),
    ];
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Regras de Negócio e Modelos (Caminho Livre)', () {
    test('Calcula corretamente a equação oficial de Score B2G', () {
      final BarrierModel barrier = BarrierModel(
        id: 'SP-1001',
        title: 'Meio-fio Elevado sem Rebaixamento',
        category: BarrierCategory.ausenciaRampa,
        address: 'Av. Paulista, 1000',
        severity: 5,
        confirmations: 3, // (1 + 3) = 4
        proximityFactor: 2.5, // < 100m de UBS
        ageDecay: 1.0,
        status: 'Aberto',
        imageUrl: 'https://picsum.photos/seed/1/600/400',
      );

      // Score = 5 * (1 + 3) * 2.5 * 1.0 = 50.0
      expect(barrier.priorityScore, closeTo(50.0, 0.001));
    });

    test('Avalia o impacto biomecânico polimórfico por perfil', () {
      final BarrierModel rampBarrier = BarrierModel(
        id: 'SP-1002',
        title: 'Degrau Alto na Travessia',
        category: BarrierCategory.ausenciaRampa,
        address: 'Rua Vergueiro, 500',
        severity: 5,
        confirmations: 2,
        proximityFactor: 2.0,
        ageDecay: 1.0,
        status: 'Aberto',
        imageUrl: 'https://picsum.photos/seed/2/600/400',
      );

      expect(
        rampBarrier.getImpactForProfile(MobilityProfile.cadeirante),
        equals('BLOQUEIO FÍSICO (Custo = ∞)'),
      );
      expect(
        rampBarrier.getImpactForProfile(MobilityProfile.guardiao),
        equals('Missão de Auditoria (+15 XP)'),
      );
      expect(
        rampBarrier.getImpactForProfile(MobilityProfile.idoso),
        equals('Penalidade Severa (+120% esforço)'),
      );
    });

    test('Converte objetos JSON da API barriers_sp.json com segurança', () {
      final Map<String, dynamic> spBarrierJson = <String, dynamic>{
        'id': 'SP-1001',
        'title': 'Meio-fio Elevado sem Rebaixamento (kerb=raised)',
        'category': 'Ausência de Rampa',
        'address': 'Av. Paulista, 1106 - Bela Vista (Próx. Metrô Trianon-Masp)',
        'severity': 5,
        'confirmations': 12,
        'proximityFactor': 2.0,
        'ageDecay': 1.0,
        'status': 'Aberto',
        'imageUrl': 'https://picsum.photos/seed/sp1001/600/400',
      };

      final BarrierModel model = BarrierModel.fromJson(spBarrierJson);
      expect(model.id, 'SP-1001');
      expect(model.category, BarrierCategory.ausenciaRampa);
      expect(model.severity, 5);
      expect(model.confirmations, 12);
      expect(model.proximityFactor, 2.0);
      expect(model.ageDecay, 1.0);
      expect(
        model.address,
        'Av. Paulista, 1106 - Bela Vista (Próx. Metrô Trianon-Masp)',
      );
      // Score = 5 * (1 + 12) * 2.0 * 1.0 = 130.0
      expect(model.priorityScore, closeTo(130.0, 0.001));
    });

    test(
        'Reabre barreira com status Resolvido para Aberto ao receber validação comunitária',
        () {
      final BarrierModel resolvedBarrier = BarrierModel(
        id: 'SP-1004',
        title: 'Rampa de Acessibilidade Requalificada (PEC Prefeitura SP)',
        category: BarrierCategory.ausenciaRampa,
        address: 'Av. Paulista, 1578 - Bela Vista (Em frente ao MASP)',
        severity: 3,
        confirmations: 5,
        proximityFactor: 2.0,
        ageDecay: 1.0,
        status: 'Resolvido',
        imageUrl: 'https://picsum.photos/seed/sp1004/600/400',
      );

      final bool wasReopened = resolvedBarrier.registerCommunityValidation();

      expect(wasReopened, isTrue);
      expect(resolvedBarrier.status, equals('Aberto'));
      expect(resolvedBarrier.confirmations, equals(6));
    });

    test('Endpoint oficial da API aponta para barriers_sp.json', () {
      final Uri uri = BarrierApiService.buildApiUri();
      expect(
        uri.toString(),
        equals(
          'https://gist.githubusercontent.com/GabrielJS2005/1299682cf15857deae0ebcb58494988f/raw/barriers_sp.json',
        ),
      );
    });

    test('BarrierManagementService filtra e ordena a fila B2G por Score', () {
      final List<BarrierModel> list = <BarrierModel>[
        BarrierModel(
          id: 'SP-1',
          title: 'Calçada Estreita',
          category: BarrierCategory.calcadaEstreita,
          address: 'Rua A',
          severity: 3,
          confirmations: 1,
          proximityFactor: 1.0,
          ageDecay: 1.0,
          status: 'Aberto',
          imageUrl: 'https://picsum.photos/seed/1/600/400',
        ),
        BarrierModel(
          id: 'SP-2',
          title: 'Ausência de Rampa UBS',
          category: BarrierCategory.ausenciaRampa,
          address: 'Av. Paulista',
          severity: 5,
          confirmations: 10,
          proximityFactor: 2.5,
          ageDecay: 1.0,
          status: 'Aberto',
          imageUrl: 'https://picsum.photos/seed/2/600/400',
        ),
      ];

      final List<BarrierModel> ranked =
          BarrierManagementService.rankAndFilterB2GQueue(barriers: list);
      expect(ranked.first.id, equals('SP-2'));

      final List<BarrierModel> searchFiltered =
          BarrierManagementService.filterBarriers(
        barriers: list,
        activeProfile: MobilityProfile.cadeirante,
        searchQuery: 'Paulista',
      );
      expect(searchFiltered.length, equals(1));
      expect(searchFiltered.first.id, equals('SP-2'));
    });

    test('Calcula nível e insígnias do Guardião Scout por XP', () {
      final progress = GuardianService.buildProgress(230);
      expect(progress.level, 3);
      expect(progress.badges.where((b) => b.isUnlocked).length, 4);
    });

    test('Valida autenticação diferenciada de Cidadão Comum e Gestor Público B2G', () {
      final citizen = AuthService.authenticate(
        login: 'cidadao@caminholivre.com.br',
        password: '123456',
      );
      expect(citizen, isNotNull);
      expect(citizen!.role, UserRole.cidadao);
      expect(citizen.role.isGestor, isFalse);

      final manager = AuthService.authenticate(
        login: 'gestor@sp.gov.br',
        password: 'gestor123',
      );
      expect(manager, isNotNull);
      expect(manager!.role, UserRole.gestor);
      expect(manager.role.isGestor, isTrue);

      final invalid = AuthService.authenticate(
        login: 'cidadao@caminholivre.com.br',
        password: 'senha_errada',
      );
      expect(invalid, isNull);
    });
  });

  group('Testes de Interface e Estados Obrigatórios', () {
    testWidgets('OnboardingScreen exibe 3 páginas e opção Não mostrar novamente',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      expect(find.text('Mobilidade Adaptada ao Seu Corpo'), findsOneWidget);
      expect(find.text('Não mostrar novamente'), findsOneWidget);

      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();
      expect(find.text('Missão Guardiões da Calçada'), findsOneWidget);

      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();
      expect(find.text('Zeladoria Preditiva (B2G)'), findsOneWidget);
      expect(find.text('Concluir'), findsOneWidget);
    });

    testWidgets(
        'HomeRadarScreen trata estado Inicial e estado de Erro com Tentar Novamente',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeRadarScreen(
            apiService: _FakeFailingApiService(),
          ),
        ),
      );
      await tester.pump();

      // Estado 1: Inicial
      expect(find.text('Radar de Microacessibilidade Pronto'), findsOneWidget);

      // Dispara escaneamento -> cai no Estado 4: Erro
      final Finder scanButton =
          find.text('Escanear Malha Urbana (São Paulo - SP)');
      await tester.ensureVisible(scanButton);
      await tester.pumpAndSettle();
      await tester.tap(scanButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Falha na Comunicação com o WebService'),
        findsOneWidget,
      );
      expect(find.text('Tentar Novamente'), findsOneWidget);
    });

    testWidgets(
        'HomeRadarScreen renderiza lista de barreiras no estado de Sucesso',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeRadarScreen(
            apiService: _FakeSuccessApiService(),
            autoFetchOnInit: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Escadaria sem Rampa de Acesso'), findsOneWidget);
      expect(
        find.textContaining('BLOQUEIO FÍSICO (Custo = ∞)'),
        findsOneWidget,
      );
    });

    testWidgets(
        'GuardianB2GScreen restringe visão quando logado como Cidadão Comum',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GuardianB2GScreen(
            args: GuardianB2GArgs(
              barriers: <BarrierModel>[],
              activeProfile: MobilityProfile.cadeirante,
              currentUser: AuthService.citizenUser,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Painel Guardião Scout'), findsOneWidget);
      expect(find.text('Cidadão Scout'), findsOneWidget);
      // Fila de Obras B2G não deve estar acessível nem visível para cidadão
      expect(find.text('Fila de Obras B2G'), findsNothing);
    });

    testWidgets(
        'GuardianB2GScreen exibe Fila de Obras quando logado como Gestor Público B2G',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GuardianB2GScreen(
            args: GuardianB2GArgs(
              barriers: <BarrierModel>[],
              activeProfile: MobilityProfile.cadeirante,
              currentUser: AuthService.managerUser,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Painel B2G • Gestão Pública'), findsOneWidget);
      expect(find.text('Gestor B2G'), findsOneWidget);
      expect(find.text('Fila de Obras B2G'), findsOneWidget);
    });

    testWidgets('LoginScreen permite preencher atalhos de teste e autenticar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(
            args: LoginScreenArgs(
              barriers: <BarrierModel>[],
              activeProfile: MobilityProfile.cadeirante,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Autenticação de Acesso ao Painel'), findsOneWidget);

      final Finder fillCitizenBtn =
          find.text('Preencher Cidadão Comum (Scout)');
      await tester.ensureVisible(fillCitizenBtn);
      await tester.pumpAndSettle();

      await tester.tap(fillCitizenBtn);
      await tester.pumpAndSettle();

      expect(find.text('cidadao@caminholivre.com.br'), findsOneWidget);
    });
  });
}
