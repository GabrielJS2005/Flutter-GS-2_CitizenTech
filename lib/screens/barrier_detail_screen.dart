import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/barrier_model.dart';
import '../models/mobility_profile.dart';
import '../services/impact_calculator.dart';
import '../services/preferences_service.dart';
import '../utils/app_constants.dart';
import '../widgets/priority_score_badge.dart';
import '../widgets/severity_indicator.dart';
import '../widgets/xp_feedback_banner.dart';

/// Argumentos tipados enviados via Navigator para a BarrierDetailScreen (Requisito 3).
class BarrierDetailArgs {
  final BarrierModel barrier;
  final MobilityProfile activeProfile;

  const BarrierDetailArgs({
    required this.barrier,
    required this.activeProfile,
  });
}

/// Tela Principal 2 — Detalhes da Barreira e Validação Comunitária (Requisitos 3, 5 e 6).
/// Recebe o BarrierModel por parâmetro, exibe foto anonimizada (Image.network + Blur LGPD),
/// calcula Custo_Trecho e permite validar "Ainda está lá?" (+15 XP e recálculo de Score).
class BarrierDetailScreen extends StatefulWidget {
  final BarrierDetailArgs args;
  final PreferencesService? preferencesService;

  const BarrierDetailScreen({
    super.key,
    required this.args,
    this.preferencesService,
  });

  @override
  State<BarrierDetailScreen> createState() => _BarrierDetailScreenState();
}

class _BarrierDetailScreenState extends State<BarrierDetailScreen> {
  late BarrierModel _barrier;
  late MobilityProfile _selectedProfile;
  late final PreferencesService _preferencesService;

  bool _hasValidatedInSession = false;
  bool _applyLgpdBlur = true;
  int _sessionXpEarned = 0;

  @override
  void initState() {
    super.initState();
    _barrier = widget.args.barrier.copyWith();
    _selectedProfile = widget.args.activeProfile;
    _preferencesService = widget.preferencesService ?? PreferencesService();
  }

  Future<void> _confirmBarrierStillThere() async {
    if (_hasValidatedInSession) return;

    await _preferencesService.addGuardianXp(AppConstants.xpPerValidation);

    if (!mounted) return;
    late final bool wasReopened;
    setState(() {
      wasReopened = _barrier.registerCommunityValidation();
      _hasValidatedInSession = true;
      _sessionXpEarned += AppConstants.xpPerValidation;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            wasReopened ? AppTheme.criticalRed : AppTheme.secondaryTeal,
        behavior: SnackBarBehavior.floating,
        content: Text(
          wasReopened
              ? 'Chamado reaberto para "Aberto"! +${AppConstants.xpPerValidation} XP '
                '• Novo Score B2G: ${_barrier.priorityScore.toStringAsFixed(1)}'
              : 'Validação registrada! +${AppConstants.xpPerValidation} XP '
                '• Novo Score B2G: ${_barrier.priorityScore.toStringAsFixed(1)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _toggleMonitor() async {
    final Set<String> monitoredIds =
        await _preferencesService.toggleMonitoredBarrier(_barrier.id);

    if (!mounted) return;
    setState(() {
      _barrier.isMonitored = monitoredIds.contains(_barrier.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          _barrier.isMonitored
              ? 'Barreira adicionada ao monitoramento de obras municipais.'
              : 'Monitoramento removido para esta barreira.',
        ),
      ),
    );
  }

  void _popWithUpdatedBarrier() {
    Navigator.pop(context, _barrier);
  }

  @override
  Widget build(BuildContext context) {
    final ProfileImpactResult impactResult = ImpactCalculator.evaluate(
      category: _barrier.category,
      profile: _selectedProfile,
      severity: _barrier.severity,
    );

    return PopScope<BarrierModel>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, BarrierModel? result) {
        if (didPop) return;
        _popWithUpdatedBarrier();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Voltar ao Radar',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _popWithUpdatedBarrier,
          ),
          title: const Text('Auditoria & Detalhes'),
          actions: <Widget>[
            IconButton(
              tooltip: _barrier.isMonitored
                  ? 'Monitorando reparo municipal'
                  : 'Monitorar reparo municipal',
              onPressed: _toggleMonitor,
              icon: Icon(
                _barrier.isMonitored
                    ? Icons.notifications_active
                    : Icons.notifications_none_outlined,
                color: _barrier.isMonitored
                    ? const Color(0xFFFFD54F)
                    : Colors.white,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Imagem da barreira via Image.network com camada de desfoque LGPD
                Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Stack(
                        children: <Widget>[
                          SizedBox(
                            width: double.infinity,
                            height: 210,
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: _applyLgpdBlur ? 2.4 : 0.0,
                                sigmaY: _applyLgpdBlur ? 2.4 : 0.0,
                              ),
                              child: Image.network(
                                _barrier.imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: const Color(0xFFE4E7EC),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                                errorBuilder: (BuildContext context,
                                    Object error, StackTrace? stackTrace) {
                                  return Container(
                                    color: const Color(0xFFE4E7EC),
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Icon(
                                          _barrier.category.icon,
                                          size: 48,
                                          color: _barrier.category.color,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Registro Fotográfico Georreferenciado (Modo Offline)',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(
                                    Icons.privacy_tip_outlined,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _applyLgpdBlur
                                        ? 'LGPD Edge Blur Ativo (Rostos/Placas)'
                                        : 'Inspeção Visual Técnica',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.78),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(44, 40),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _applyLgpdBlur = !_applyLgpdBlur;
                                });
                              },
                              icon: Icon(
                                _applyLgpdBlur
                                    ? Icons.blur_off_rounded
                                    : Icons.blur_on_rounded,
                                size: 18,
                              ),
                              label: Text(
                                _applyLgpdBlur
                                    ? 'Inspecionar Piso'
                                    : 'Ativar Blur LGPD',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _barrier.category.color
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _barrier.category.color,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(
                                        _barrier.category.icon,
                                        size: 16,
                                        color: _barrier.category.color,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _barrier.category.label,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: _barrier.category.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _barrier.statusEnum.color
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(
                                        _barrier.statusEnum.icon,
                                        size: 15,
                                        color: _barrier.statusEnum.color,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Status B2G: ${_barrier.status}',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: _barrier.statusEnum.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _barrier.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.highContrastText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.place_outlined,
                                  size: 18,
                                  color: AppTheme.secondaryText,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _barrier.address,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.secondaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SeverityIndicator(severity: _barrier.severity),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_sessionXpEarned > 0) ...<Widget>[
                  XpFeedbackBanner(
                    xpGained: _sessionXpEarned,
                    title: 'Auditoria Comunitária Confirmada!',
                    subtitle:
                        'O consenso comunitário foi atualizado e o Score B2G da prefeitura subiu.',
                  ),
                  const SizedBox(height: 16),
                ],

                // Seção de Impacto no Cálculo de Rota (Custo_Trecho) por Perfil Biomecânico
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: impactResult.isPhysicalBlock
                          ? AppTheme.criticalRed
                          : AppTheme.primaryNavy,
                      width: 1.8,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              _selectedProfile.icon,
                              color: impactResult.isPhysicalBlock
                                  ? AppTheme.criticalRed
                                  : AppTheme.primaryNavy,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Impacto Biomecânico: ${_selectedProfile.label}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.highContrastText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: impactResult.isPhysicalBlock
                                ? AppTheme.criticalRed.withValues(alpha: 0.12)
                                : AppTheme.primaryNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                impactResult.summaryLabel,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  color: impactResult.isPhysicalBlock
                                      ? AppTheme.criticalRed
                                      : AppTheme.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                impactResult.routeCostDisplay,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.highContrastText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                impactResult.technicalExplanation,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.secondaryText,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Simular impacto em outro perfil biomecânico:',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: MobilityProfile.values
                                .map((MobilityProfile profile) {
                              final bool selected = profile == _selectedProfile;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  showCheckmark: false,
                                  avatar: Icon(
                                    profile.icon,
                                    size: 16,
                                    color: selected
                                        ? Colors.white
                                        : AppTheme.primaryNavy,
                                  ),
                                  label: Text(profile.label),
                                  selected: selected,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedProfile = profile;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Seção de Validação Comunitária ("Guardiões da Calçada")
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.verified_user_rounded,
                              color: AppTheme.secondaryTeal,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Validação Comunitária ("Guardiões da Calçada")',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.highContrastText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        PriorityScoreBadge(score: _barrier.priorityScore),
                        const SizedBox(height: 12),
                        const Text(
                          'Você passou por este local recentemente? Confirme se o '
                          'obstáculo permanece ativo para atualizar a priorização de '
                          'zeladoria urbana da prefeitura e ganhar +15 XP.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppTheme.secondaryText,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasValidatedInSession
                                  ? AppTheme.secondaryTeal
                                  : AppTheme.primaryNavy,
                            ),
                            onPressed: _hasValidatedInSession
                                ? null
                                : _confirmBarrierStillThere,
                            icon: Icon(
                              _hasValidatedInSession
                                  ? Icons.verified_rounded
                                  : Icons.thumb_up_alt_outlined,
                            ),
                            label: Text(
                              _hasValidatedInSession
                                  ? 'Confirmado nesta sessão (+15 XP ganhos)'
                                  : 'Ainda está lá? (+15 XP • Validar Barreira)',
                            ),
                          ),
                        ),
                      ],
                    ),
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

