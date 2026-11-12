import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../app/app_theme.dart';
import '../models/barrier_model.dart';
import '../models/mobility_profile.dart';
import '../services/barrier_api_service.dart';
import '../services/barrier_management_service.dart';
import '../services/preferences_service.dart';
import '../utils/request_state.dart';
import '../widgets/barrier_card.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/initial_state_widget.dart';
import '../widgets/loading_state_widget.dart';
import '../widgets/profile_selector_bar.dart';
import 'barrier_detail_screen.dart';
import 'login_screen.dart';

/// Tela Principal 1 — Radar de Barreiras e Perfil (Requisitos 3, 4, 5 e 6).
/// Controla os 4 estados da requisição HTTP (initial, loading, success, error) com setState,
/// filtra obstáculos por Perfil Biomecânico, busca por rua/título e gerencia favoritos.
class HomeRadarScreen extends StatefulWidget {
  final BarrierApiService? apiService;
  final PreferencesService? preferencesService;
  final bool autoFetchOnInit;

  const HomeRadarScreen({
    super.key,
    this.apiService,
    this.preferencesService,
    this.autoFetchOnInit = false,
  });

  @override
  State<HomeRadarScreen> createState() => _HomeRadarScreenState();
}

class _HomeRadarScreenState extends State<HomeRadarScreen> {
  final TextEditingController _searchController = TextEditingController();

  late final BarrierApiService _apiService;
  late final PreferencesService _preferencesService;

  RequestState _state = RequestState.initial;
  String _errorMessage = '';

  List<BarrierModel> _barriers = <BarrierModel>[];
  MobilityProfile _activeProfile = MobilityProfile.cadeirante;
  Set<String> _monitoredIds = <String>{};
  int _guardianXp = 120;

  String _searchQuery = '';
  bool _onlyMonitored = false;
  bool _onlyBlockingForProfile = false;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? BarrierApiService();
    _preferencesService = widget.preferencesService ?? PreferencesService();
    _loadPersistedPreferences();
    if (widget.autoFetchOnInit) {
      _fetchBarriers();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPersistedPreferences() async {
    final MobilityProfile savedProfile =
        await _preferencesService.getActiveProfile();
    final Set<String> monitored =
        await _preferencesService.getMonitoredBarrierIds();
    final int xp = await _preferencesService.getGuardianXp();

    if (!mounted) return;
    setState(() {
      _activeProfile = savedProfile;
      _monitoredIds = monitored;
      _guardianXp = xp;
    });
  }

  Future<void> _fetchBarriers() async {
    setState(() {
      _state = RequestState.loading;
      _errorMessage = '';
    });

    try {
      final List<BarrierModel> remoteBarriers =
          await _apiService.fetchBarriers();
      final Set<String> monitored =
          await _preferencesService.getMonitoredBarrierIds();

      for (final BarrierModel b in remoteBarriers) {
        b.isMonitored = monitored.contains(b.id);
      }

      if (!mounted) return;
      setState(() {
        _barriers = remoteBarriers;
        _monitoredIds = monitored;
        _state = RequestState.success;
      });
    } on BarrierApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _state = RequestState.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Falha inesperada ao consultar a API de barreiras urbanas de São Paulo.';
        _state = RequestState.error;
      });
    }
  }

  Future<void> _onSelectProfile(MobilityProfile profile) async {
    setState(() {
      _activeProfile = profile;
    });
    await _preferencesService.setActiveProfile(profile);
  }

  Future<void> _toggleMonitor(BarrierModel barrier) async {
    final Set<String> updatedSet =
        await _preferencesService.toggleMonitoredBarrier(barrier.id);

    if (!mounted) return;
    setState(() {
      _monitoredIds = updatedSet;
      barrier.isMonitored = _monitoredIds.contains(barrier.id);
    });
  }

  Future<void> _openBarrierDetail(BarrierModel barrier) async {
    final Object? result = await Navigator.pushNamed(
      context,
      AppRoutes.barrierDetail,
      arguments: BarrierDetailArgs(
        barrier: barrier,
        activeProfile: _activeProfile,
      ),
    );

    final int latestXp = await _preferencesService.getGuardianXp();
    final Set<String> monitored =
        await _preferencesService.getMonitoredBarrierIds();

    if (!mounted) return;
    setState(() {
      _guardianXp = latestXp;
      _monitoredIds = monitored;
      if (result is BarrierModel) {
        final int index =
            _barriers.indexWhere((BarrierModel b) => b.id == result.id);
        if (index != -1) {
          _barriers[index] = result;
        }
      }
    });
  }

  Future<void> _openReportBarrierScreen() async {
    final Object? result = await Navigator.pushNamed(
      context,
      AppRoutes.reportBarrier,
    );

    final int latestXp = await _preferencesService.getGuardianXp();
    if (!mounted) return;

    if (result is BarrierModel) {
      await _preferencesService.toggleMonitoredBarrier(result.id);
      final Set<String> monitored =
          await _preferencesService.getMonitoredBarrierIds();

      if (!mounted) return;
      setState(() {
        _guardianXp = latestXp;
        _monitoredIds = monitored;
        _barriers.insert(0, result);
        _state = RequestState.success;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.secondaryTeal,
          content: Text(
            'Relato em 3 toques registrado! +50 XP adicionados ao seu perfil Guardião.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    } else {
      setState(() {
        _guardianXp = latestXp;
      });
    }
  }

  Future<void> _openGuardianB2GScreen() async {
    final Object? result = await Navigator.pushNamed(
      context,
      AppRoutes.login,
      arguments: LoginScreenArgs(
        barriers: _barriers,
        activeProfile: _activeProfile,
      ),
    );

    final int latestXp = await _preferencesService.getGuardianXp();
    if (!mounted) return;

    setState(() {
      _guardianXp = latestXp;
      if (result is List<BarrierModel>) {
        _barriers = result;
      }
    });
  }

  List<BarrierModel> get _filteredBarriers {
    return BarrierManagementService.filterBarriers(
      barriers: _barriers,
      activeProfile: _activeProfile,
      searchQuery: _searchQuery,
      onlyMonitored: _onlyMonitored,
      onlyBlockingForProfile: _onlyBlockingForProfile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int blockingCount =
        BarrierManagementService.countBlockingForProfile(
      _barriers,
      _activeProfile,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caminho Livre • Radar'),
        actions: <Widget>[
          IconButton(
            tooltip: _onlyMonitored
                ? 'Mostrar todas as barreiras'
                : 'Filtrar apenas barreiras monitoradas',
            onPressed: () {
              setState(() {
                _onlyMonitored = !_onlyMonitored;
              });
            },
            icon: Icon(
              _onlyMonitored
                  ? Icons.notifications_active
                  : Icons.notifications_none_outlined,
              color:
                  _onlyMonitored ? const Color(0xFFFFD54F) : Colors.white,
            ),
          ),
          IconButton(
            tooltip: 'Painel do Guardião ($_guardianXp XP) & Fila B2G',
            onPressed: _openGuardianB2GScreen,
            icon: const Icon(Icons.shield_outlined),
          ),
          IconButton(
            tooltip: 'Sincronizar novamente com a API Caminho Livre',
            onPressed: _fetchBarriers,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Barra superior de seleção dinâmica de Perfil Biomecânico
            ProfileSelectorBar(
              selectedProfile: _activeProfile,
              onProfileSelected: _onSelectProfile,
            ),

            // Barra de busca e filtros rápidos quando já existem barreiras carregadas
            if (_state == RequestState.success)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: _searchController,
                      onChanged: (String value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Buscar por rua, bairro ou tipo de barreira...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                tooltip: 'Limpar busca',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                icon: const Icon(Icons.clear_rounded),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        FilterChip(
                          showCheckmark: false,
                          avatar: Icon(
                            Icons.block_flipped,
                            size: 16,
                            color: _onlyBlockingForProfile
                                ? Colors.white
                                : AppTheme.criticalRed,
                          ),
                          label: Text(
                            'Bloqueio Físico ($blockingCount)',
                          ),
                          selected: _onlyBlockingForProfile,
                          onSelected: (bool selected) {
                            setState(() {
                              _onlyBlockingForProfile = selected;
                            });
                          },
                        ),
                        FilterChip(
                          showCheckmark: false,
                          avatar: Icon(
                            Icons.notifications_active_outlined,
                            size: 16,
                            color: _onlyMonitored
                                ? Colors.white
                                : AppTheme.accentAmber,
                          ),
                          label: Text(
                            'Monitoradas (${_monitoredIds.length})',
                          ),
                          selected: _onlyMonitored,
                          onSelected: (bool selected) {
                            setState(() {
                              _onlyMonitored = selected;
                            });
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: AppTheme.secondaryTeal,
                          ),
                          label: Text('$_guardianXp XP • Fila B2G'),
                          onPressed: _openGuardianB2GScreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Corpo principal gerenciando os 4 estados obrigatórios (Requisito 4)
            Expanded(
              child: _buildBodyForState(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.secondaryTeal,
        foregroundColor: Colors.white,
        onPressed: _openReportBarrierScreen,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text(
          'Relatar em 3 Toques (+50 XP)',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildBodyForState() {
    switch (_state) {
      case RequestState.initial:
        return InitialStateWidget(onStartScan: _fetchBarriers);

      case RequestState.loading:
        return const LoadingStateWidget(
          message: 'Sincronizando malha de calçadas e barreiras...',
        );

      case RequestState.error:
        return ErrorStateWidget(
          errorMessage: _errorMessage,
          onRetry: _fetchBarriers,
        );

      case RequestState.success:
        final List<BarrierModel> visibleBarriers = _filteredBarriers;
        if (visibleBarriers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.filter_alt_off_outlined,
                    size: 48,
                    color: AppTheme.secondaryText,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nenhuma barreira corresponde aos filtros atuais.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.highContrastText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _onlyMonitored = false;
                        _onlyBlockingForProfile = false;
                      });
                    },
                    icon: const Icon(Icons.clear_all_rounded),
                    label: const Text('Limpar Filtros'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 6, bottom: 88),
          itemCount: visibleBarriers.length,
          itemBuilder: (BuildContext context, int index) {
            final BarrierModel barrier = visibleBarriers[index];
            return BarrierCard(
              barrier: barrier,
              activeProfile: _activeProfile,
              onTap: () => _openBarrierDetail(barrier),
              onToggleMonitor: () => _toggleMonitor(barrier),
            );
          },
        );
    }
  }
}

