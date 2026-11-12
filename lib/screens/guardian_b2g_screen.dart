import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../app/app_theme.dart';
import '../models/barrier_model.dart';
import '../models/barrier_status.dart';
import '../models/guardian_progress.dart';
import '../models/mobility_profile.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/barrier_management_service.dart';
import '../services/guardian_service.dart';
import '../services/preferences_service.dart';
import '../widgets/badge_tile.dart';
import '../widgets/priority_score_badge.dart';
import 'barrier_detail_screen.dart';

/// Argumentos tipados enviados para a GuardianB2GScreen (Requisito 3).
class GuardianB2GArgs {
  final List<BarrierModel> barriers;
  final MobilityProfile activeProfile;
  final AppUser? currentUser;

  const GuardianB2GArgs({
    required this.barriers,
    required this.activeProfile,
    this.currentUser,
  });
}

/// Tela Principal 4 — Painel do Guardião & Priorização B2G (Requisitos 3, 5 e 6).
/// Implementa controle de visibilidade baseado em perfil (RBAC):
/// - Cidadão Comum: acessa ESTRITAMENTE a aba gamificada do Guardião Scout (XP, insígnias, nível).
/// - Gestor Público B2G: tem acesso completo à Fila de Obras ordenada por Score B2G e ao Guardião Scout.
class GuardianB2GScreen extends StatefulWidget {
  final GuardianB2GArgs args;
  final PreferencesService? preferencesService;

  const GuardianB2GScreen({
    super.key,
    required this.args,
    this.preferencesService,
  });

  @override
  State<GuardianB2GScreen> createState() => _GuardianB2GScreenState();
}

class _GuardianB2GScreenState extends State<GuardianB2GScreen> {
  late final PreferencesService _preferencesService;
  late List<BarrierModel> _barriers;

  AppUser? _currentUser;
  int _totalXp = 120;
  BarrierStatus? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    _preferencesService = widget.preferencesService ?? PreferencesService();
    _barriers = widget.args.barriers
        .map((BarrierModel item) => item.copyWith())
        .toList();
    _currentUser = widget.args.currentUser;
    _initUserAndXp();
  }

  Future<void> _initUserAndXp() async {
    final int xp = await _preferencesService.getGuardianXp();
    AppUser? user = _currentUser;
    user ??= await _preferencesService.getLoggedUser();
    user ??= AuthService.citizenUser;

    if (!mounted) return;
    setState(() {
      _totalXp = xp;
      _currentUser = user;
    });
  }

  List<BarrierModel> get _sortedAndFilteredBarriers {
    return BarrierManagementService.rankAndFilterB2GQueue(
      barriers: _barriers,
      statusFilter: _selectedStatusFilter,
    );
  }

  void _cycleBarrierStatus(BarrierModel target) {
    // Apenas gestores podem alterar status de obras
    if (_currentUser?.role.isGestor != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ação restrita a funcionários públicos e gestores municipais.',
          ),
          backgroundColor: AppTheme.criticalRed,
        ),
      );
      return;
    }

    final BarrierStatus nextStatus =
        BarrierManagementService.nextLifecycleStatus(target.statusEnum);

    setState(() {
      final int idx =
          _barriers.indexWhere((BarrierModel b) => b.id == target.id);
      if (idx != -1) {
        _barriers[idx] = _barriers[idx].copyWith(status: nextStatus.label);
      }
    });

    final String feedbackMessage = nextStatus == BarrierStatus.resolvido
        ? 'Obra concluída! Notificação enviada aos cidadãos que monitoram a barreira.'
        : 'Status municipal atualizado para "${nextStatus.label}".';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: nextStatus.color,
        content: Text(
          feedbackMessage,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _openBarrierDetail(BarrierModel barrier) async {
    final Object? updated = await Navigator.pushNamed(
      context,
      AppRoutes.barrierDetail,
      arguments: BarrierDetailArgs(
        barrier: barrier,
        activeProfile: widget.args.activeProfile,
      ),
    );

    final int xp = await _preferencesService.getGuardianXp();
    if (!mounted) return;

    setState(() {
      _totalXp = xp;
      if (updated is BarrierModel) {
        final int index =
            _barriers.indexWhere((BarrierModel b) => b.id == updated.id);
        if (index != -1) {
          _barriers[index] = updated;
        }
      }
    });
  }

  void _popWithUpdatedList() {
    Navigator.pop(context, _barriers);
  }

  Future<void> _logoutAndExit() async {
    await _preferencesService.clearLoggedUser();
    if (!mounted) return;
    _popWithUpdatedList();
  }

  @override
  Widget build(BuildContext context) {
    final GuardianProgress progress = GuardianService.buildProgress(_totalXp);
    final List<BarrierModel> rankedList = _sortedAndFilteredBarriers;
    final bool isGestor = _currentUser?.role.isGestor ?? false;

    return PopScope<List<BarrierModel>>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, List<BarrierModel>? result) {
        if (didPop) return;
        _popWithUpdatedList();
      },
      child: isGestor
          ? _buildManagerScaffold(progress, rankedList)
          : _buildCitizenScaffold(progress),
    );
  }

  /// Visão do Gestor Público: TabBar completa com Guardião Scout e Fila de Obras B2G
  Widget _buildManagerScaffold(
    GuardianProgress progress,
    List<BarrierModel> rankedList,
  ) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Voltar ao Radar',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _popWithUpdatedList,
          ),
          title: const Text('Painel B2G • Gestão Pública'),
          actions: <Widget>[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.admin_panel_settings_rounded,
                      size: 15, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Gestor B2G',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Trocar Usuário / Sair',
              icon: const Icon(Icons.logout_rounded),
              onPressed: _logoutAndExit,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3.5,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFD0D5DD),
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            tabs: <Widget>[
              Tab(
                icon: Icon(Icons.shield_outlined),
                text: 'Guardião Scout (XP)',
              ),
              Tab(
                icon: Icon(Icons.account_balance_outlined),
                text: 'Fila de Obras B2G',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _buildGuardianTab(progress),
            _buildPublicManagerB2GTab(rankedList),
          ],
        ),
      ),
    );
  }

  /// Visão do Cidadão Comum: SEM TABBAR, com acesso EXCLUSIVO à página Guardião Scout
  Widget _buildCitizenScaffold(GuardianProgress progress) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar ao Radar',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _popWithUpdatedList,
        ),
        title: const Text('Painel Guardião Scout'),
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 1.2),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.person_rounded, size: 15, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Cidadão Scout',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Trocar Usuário / Sair',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logoutAndExit,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Aviso explicativo de controle de acesso
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFEFF8FF),
            child: const Row(
              children: <Widget>[
                Icon(Icons.info_outline_rounded,
                    color: AppTheme.primaryNavy, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Visão Cidadão Comum: Acesso focado em auditorias, XP e insígnias. A "Fila de Obras B2G" é de acesso restrito a gestores públicos.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildGuardianTab(progress),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianTab(GuardianProgress progress) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Card(
            margin: EdgeInsets.zero,
            color: AppTheme.primaryNavy,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Nível ${progress.level} • ${progress.rankTitle}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${progress.totalXp} XP acumulados em auditorias comunitárias',
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFFE0EAFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.levelProgress,
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00E5B8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Progresso para o Nível ${progress.level + 1}: '
                    '${progress.xpIntoCurrentLevel}/${progress.xpForNextLevel} XP',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Contador de empatia tangível (Solução do Grupo - Seção 4.1)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      color: AppTheme.secondaryTeal,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Contador de Empatia Tangível',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.highContrastText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Suas auditorias protegeram cerca de '
                          '${progress.protectedCitizensEstimate} cadeirantes, idosos e '
                          'pessoas com deficiência visual nesta semana.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.secondaryText,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Insígnias de Impacto Social (GridView)',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.highContrastText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Valide barreiras ("Ainda está lá?") ou registre relatos em 3 toques para desbloquear:',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: progress.badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (BuildContext context, int index) {
              return BadgeTile(badge: progress.badges[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPublicManagerB2GTab(List<BarrierModel> rankedList) {
    return Column(
      children: <Widget>[
        Container(
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
              const Text(
                'Fila de Obras Ordenada por Score Matemático B2G:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.highContrastText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Score = Gravidade × (1 + Confirmações) × Fator_Proximidade × Decaimento_Idade',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    ChoiceChip(
                      showCheckmark: false,
                      label: Text('Todos (${_barriers.length})'),
                      selected: _selectedStatusFilter == null,
                      onSelected: (_) {
                        setState(() {
                          _selectedStatusFilter = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ...BarrierStatus.values.map((BarrierStatus status) {
                      final int count = _barriers
                          .where((BarrierModel b) => b.statusEnum == status)
                          .length;
                      final bool selected = _selectedStatusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          showCheckmark: false,
                          avatar: Icon(
                            status.icon,
                            size: 16,
                            color: selected ? Colors.white : status.color,
                          ),
                          label: Text('${status.label} ($count)'),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedStatusFilter = status;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: rankedList.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhuma barreira encontrada no status selecionado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: rankedList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final BarrierModel item = rankedList[index];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openBarrierDetail(item),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryNavy,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '#${index + 1} Prioridade',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: PriorityScoreBadge(
                                      score: item.priorityScore,
                                      compact: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.highContrastText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.address} • ${item.proximityDescription}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.statusEnum.color
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Icon(
                                          item.statusEnum.icon,
                                          size: 15,
                                          color: item.statusEnum.color,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          item.status,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: item.statusEnum.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(44, 38),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                    ),
                                    onPressed: () => _cycleBarrierStatus(item),
                                    icon: const Icon(
                                      Icons.sync_alt_rounded,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Avançar Status B2G',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
