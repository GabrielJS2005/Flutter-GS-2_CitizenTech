import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../app/app_theme.dart';
import '../models/barrier_model.dart';
import '../models/mobility_profile.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import 'guardian_b2g_screen.dart';

/// Argumentos para a tela de Login do Painel.
class LoginScreenArgs {
  final List<BarrierModel> barriers;
  final MobilityProfile activeProfile;

  const LoginScreenArgs({
    required this.barriers,
    required this.activeProfile,
  });
}

/// Tela de Autenticação e Controle de Acesso (Login).
/// Diferencia o Cidadão Comum (apenas visão Guardião Scout)
/// do Gestor Público Especializado (visão da Fila de Obras B2G + Guardião Scout).
class LoginScreen extends StatefulWidget {
  final LoginScreenArgs args;
  final PreferencesService? preferencesService;

  const LoginScreen({
    super.key,
    required this.args,
    this.preferencesService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final PreferencesService _preferencesService;

  bool _obscurePassword = true;
  String? _errorMessage;
  AppUser? _currentLoggedUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _preferencesService = widget.preferencesService ?? PreferencesService();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    final AppUser? saved = await _preferencesService.getLoggedUser();
    if (!mounted) return;
    setState(() {
      _currentLoggedUser = saved;
      _isLoading = false;
    });
  }

  Future<void> _proceedWithUser(AppUser user) async {
    await _preferencesService.saveLoggedUser(user);
    if (!mounted) return;

    final Object? updatedBarriers = await Navigator.pushNamed(
      context,
      AppRoutes.guardianB2G,
      arguments: GuardianB2GArgs(
        barriers: widget.args.barriers,
        activeProfile: widget.args.activeProfile,
        currentUser: user,
      ),
    );

    if (!mounted) return;
    Navigator.pop(context, updatedBarriers);
  }

  void _submitLogin() {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final AppUser? user = AuthService.authenticate(
      login: _loginController.text,
      password: _passwordController.text,
    );

    if (user != null) {
      _proceedWithUser(user);
    } else {
      setState(() {
        _errorMessage =
            'Credenciais inválidas. Verifique o login e a senha ou utilize um dos perfis de teste rápidos abaixo.';
      });
    }
  }

  void _fillCitizenProfile() {
    setState(() {
      _loginController.text = AuthService.citizenUser.email;
      _passwordController.text = AuthService.citizenPassword;
      _errorMessage = null;
    });
  }

  void _fillManagerProfile() {
    setState(() {
      _loginController.text = AuthService.managerUser.email;
      _passwordController.text = AuthService.managerPassword;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acesso ao Painel • Controle de Perfil'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Cabeçalho institucional
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            size: 46,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Autenticação de Acesso ao Painel',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.highContrastText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Por regras de governança municipal, a "Fila de Obras B2G" é restrita a gestores públicos credenciados. Usuários comuns acessam a visão Guardião Scout.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.secondaryText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Card de sessão existente (se houver)
                      if (_currentLoggedUser != null) ...<Widget>[
                        Card(
                          margin: EdgeInsets.zero,
                          color: _currentLoggedUser!.role.isGestor
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFE3F2FD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _currentLoggedUser!.role.isGestor
                                  ? const Color(0xFF2E7D32)
                                  : AppTheme.primaryNavy,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Icon(
                                      _currentLoggedUser!.role.isGestor
                                          ? Icons.verified_user_rounded
                                          : Icons.person_rounded,
                                      color: _currentLoggedUser!.role.isGestor
                                          ? const Color(0xFF2E7D32)
                                          : AppTheme.primaryNavy,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Sessão Ativa: ${_currentLoggedUser!.name}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Perfil: ${_currentLoggedUser!.role.label} (${_currentLoggedUser!.department})',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _currentLoggedUser!.role.isGestor
                                              ? const Color(0xFF2E7D32)
                                              : AppTheme.primaryNavy,
                                    ),
                                    onPressed: () =>
                                        _proceedWithUser(_currentLoggedUser!),
                                    icon: const Icon(Icons.arrow_forward_rounded),
                                    label: const Text('Continuar com Esta Conta'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Row(
                          children: <Widget>[
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'Ou entre com outro perfil',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.secondaryText,
                                ),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Mensagem de erro
                      if (_errorMessage != null) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.criticalRed.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.criticalRed,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppTheme.criticalRed,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppTheme.criticalRed,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Campo de Login / E-mail
                      TextFormField(
                        controller: _loginController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail ou Usuário',
                          hintText: 'cidadao@caminholivre.com.br ou gestor@sp.gov.br',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o e-mail ou usuário.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Campo de Senha
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a senha de acesso.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Botão de Login
                      ElevatedButton.icon(
                        onPressed: _submitLogin,
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Entrar no Painel'),
                      ),
                      const SizedBox(height: 24),

                      // Seção de Atalhos Rápidos para Teste
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.science_outlined,
                                    color: AppTheme.accentAmber,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Atalhos de Teste para Avaliação:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppTheme.highContrastText,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Toque em um dos botões abaixo para preencher automaticamente as credenciais:',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: _fillCitizenProfile,
                                icon: const Icon(Icons.person_rounded),
                                label: const Text(
                                  'Preencher Cidadão Comum (Scout)',
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 36, top: 4, bottom: 8),
                                child: Text(
                                  'Login: cidadao@caminholivre.com.br • Senha: 123456\n(Visão: apenas Guardião Scout / XP)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.secondaryText,
                                  ),
                                ),
                              ),
                              const Divider(height: 18),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFF2E7D32),
                                    width: 1.8,
                                  ),
                                  foregroundColor: const Color(0xFF2E7D32),
                                ),
                                onPressed: _fillManagerProfile,
                                icon: const Icon(Icons.admin_panel_settings_rounded),
                                label: const Text(
                                  'Preencher Gestor Público B2G',
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 36, top: 4),
                                child: Text(
                                  'Login: gestor@sp.gov.br • Senha: gestor123\n(Visão: Fila de Obras B2G + Guardião Scout)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.secondaryText,
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

