import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../models/barrier_category.dart';
import '../models/barrier_model.dart';
import '../services/barrier_management_service.dart';
import '../services/preferences_service.dart';
import '../utils/app_constants.dart';
import '../widgets/priority_score_badge.dart';
import '../widgets/severity_indicator.dart';
import '../widgets/xp_feedback_banner.dart';

/// Tela Principal 3 — Relato Rápido em 3 Toques (Requisitos 3, 5 e 6).
/// Permite cadastrar um novo obstáculo selecionando:
/// (1) Categoria, (2) Gravidade de 1 a 5 e (3) Proximidade de serviço essencial,
/// exibindo feedback visual de +50 XP para o Guardião e retornando o novo BarrierModel.
class ReportBarrierScreen extends StatefulWidget {
  final PreferencesService? preferencesService;

  const ReportBarrierScreen({
    super.key,
    this.preferencesService,
  });

  @override
  State<ReportBarrierScreen> createState() => _ReportBarrierScreenState();
}

class _ReportBarrierScreenState extends State<ReportBarrierScreen> {
  final TextEditingController _addressController = TextEditingController(
    text: 'Av. Paulista, 1106 - Bela Vista, São Paulo/SP',
  );

  late final PreferencesService _preferencesService;

  BarrierCategory? _selectedCategory = BarrierCategory.ausenciaRampa;
  int _selectedSeverity = 5;
  double _selectedProximityFactor = AppConstants.proximityUbsHospital;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _preferencesService = widget.preferencesService ?? PreferencesService();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  double get _previewScore {
    return BarrierManagementService.calculatePreviewScore(
      severity: _selectedSeverity,
      proximityFactor: _selectedProximityFactor,
    );
  }

  Future<void> _submitReport() async {
    final BarrierCategory? category = _selectedCategory;
    if (category == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    await _preferencesService.addGuardianXp(AppConstants.xpPerNewReport);

    final BarrierModel newBarrier =
        BarrierManagementService.createReportedBarrier(
      category: category,
      severity: _selectedSeverity,
      proximityFactor: _selectedProximityFactor,
      rawAddress: _addressController.text,
    );

    if (!mounted) return;
    Navigator.pop(context, newBarrier);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relato em 3 Toques (Guardião)'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const XpFeedbackBanner(
                xpGained: AppConstants.xpPerNewReport,
                title: 'Missão Guardiões da Calçada (+50 XP)',
                subtitle:
                    'Fotos têm rostos e placas borrados localmente (On-Device LGPD) antes do envio.',
              ),
              const SizedBox(height: 16),

              // TOQUE 1: Categoria do Obstáculo
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Toque 1 • Categoria da Barreira (Pré-classificada IA)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.highContrastText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Selecione o tipo de patologia urbana identificada na calçada:',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: BarrierCategory.values.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.35,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          final BarrierCategory category =
                              BarrierCategory.values[index];
                          final bool selected = _selectedCategory == category;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? category.color.withValues(alpha: 0.14)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? category.color
                                      : const Color(0xFFD0D5DD),
                                  width: selected ? 2.2 : 1.2,
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    category.icon,
                                    color: category.color,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      category.label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: selected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: AppTheme.highContrastText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // TOQUE 2: Nível de Gravidade (1 a 5)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Expanded(
                            child: Text(
                              'Toque 2 • Gravidade Técnica (1 a 5)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.highContrastText,
                              ),
                            ),
                          ),
                          SeverityIndicator(severity: _selectedSeverity),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: List<Widget>.generate(5, (int index) {
                          final int level = index + 1;
                          final bool selected = _selectedSeverity == level;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: level < 5 ? 8 : 0,
                              ),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: selected
                                      ? AppTheme.primaryNavy
                                      : Colors.white,
                                  foregroundColor: selected
                                      ? Colors.white
                                      : AppTheme.primaryNavy,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedSeverity = level;
                                  });
                                },
                                child: Text('$level'),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // TOQUE 3: Proximidade de Equipamento Público Essencial
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Toque 3 • Proximidade de Equipamento Público',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.highContrastText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Define o multiplicador espacial para priorização de obras B2G:',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProximityOptionTile(
                        title: 'Próximo a UBS / Hospital (< 100m)',
                        subtitle: 'Multiplicador máximo de urgência: 2,5x',
                        icon: Icons.local_hospital_outlined,
                        factor: AppConstants.proximityUbsHospital,
                        selectedFactor: _selectedProximityFactor,
                        onSelect: (double value) {
                          setState(() {
                            _selectedProximityFactor = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _ProximityOptionTile(
                        title: 'Próximo a Escola / Parada de Ônibus (< 200m)',
                        subtitle: 'Multiplicador prioritário: 2,0x',
                        icon: Icons.school_outlined,
                        factor: AppConstants.proximitySchoolTransport,
                        selectedFactor: _selectedProximityFactor,
                        onSelect: (double value) {
                          setState(() {
                            _selectedProximityFactor = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _ProximityOptionTile(
                        title: 'Rua Residencial / Comercial Comum',
                        subtitle: 'Multiplicador base padrão: 1,0x',
                        icon: Icons.signpost_outlined,
                        factor: AppConstants.proximityRegularStreet,
                        selectedFactor: _selectedProximityFactor,
                        onSelect: (double value) {
                          setState(() {
                            _selectedProximityFactor = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Endereço / Ponto de Referência GPS',
                          prefixIcon: Icon(Icons.my_location_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pré-visualização do Score B2G e envio
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Prévia de Impacto no Painel B2G da Prefeitura:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.highContrastText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      PriorityScoreBadge(score: _previewScore),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _selectedCategory == null || _isSubmitting
                              ? null
                              : _submitReport,
                          icon: const Icon(Icons.send_rounded),
                          label: const Text(
                            'Confirmar Relato em 3 Toques (+50 XP)',
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
    );
  }
}

class _ProximityOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final double factor;
  final double selectedFactor;
  final ValueChanged<double> onSelect;

  const _ProximityOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.factor,
    required this.selectedFactor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = (factor - selectedFactor).abs() < 0.01;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onSelect(factor),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryNavy.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? AppTheme.primaryNavy : const Color(0xFFD0D5DD),
            width: isSelected ? 2.0 : 1.2,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              color:
                  isSelected ? AppTheme.primaryNavy : AppTheme.secondaryText,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.highContrastText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color:
                  isSelected ? AppTheme.primaryNavy : const Color(0xFF98A2B3),
            ),
          ],
        ),
      ),
    );
  }
}

