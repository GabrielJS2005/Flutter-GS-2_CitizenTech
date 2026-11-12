import 'package:shared_preferences/shared_preferences.dart';

import '../models/mobility_profile.dart';
import '../models/user_role.dart';

/// Serviço de persistência local via SharedPreferences (Requisitos 1, 2 e 7).
/// Armazena o controle de Onboarding, o XP acumulado do Guardião,
/// o perfil biomecânico ativo, os IDs das barreiras monitoradas
/// e a sessão do usuário autenticado (Cidadão vs. Gestor Público).
class PreferencesService {
  static const String _keySkipOnboarding = 'skip_onboarding';
  static const String _keyGuardianXp = 'guardian_xp';
  static const String _keyMonitoredBarrierIds = 'monitored_barrier_ids';
  static const String _keyActiveProfile = 'active_profile';

  static const String _keyLoggedUserEmail = 'logged_user_email';
  static const String _keyLoggedUserRole = 'logged_user_role';
  static const String _keyLoggedUserName = 'logged_user_name';
  static const String _keyLoggedUserDept = 'logged_user_dept';

  static const int _initialDemoXp = 120;

  /// Verifica se o usuário marcou "Não mostrar novamente" no Onboarding.
  Future<bool> shouldSkipOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySkipOnboarding) ?? false;
  }

  /// Salva a preferência de pular ou exibir o Onboarding nas próximas aberturas.
  Future<void> setSkipOnboarding(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySkipOnboarding, value);
  }

  /// Lê o XP total acumulado pelo usuário na missão Guardiões da Calçada.
  Future<int> getGuardianXp() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyGuardianXp) ?? _initialDemoXp;
  }

  /// Incrementa o XP do usuário e retorna o novo total persistido.
  Future<int> addGuardianXp(int deltaXp) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int current = prefs.getInt(_keyGuardianXp) ?? _initialDemoXp;
    final int updated = current + deltaXp;
    await prefs.setInt(_keyGuardianXp, updated);
    return updated;
  }

  /// Lê o perfil biomecânico selecionado pelo usuário.
  Future<MobilityProfile> getActiveProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? name = prefs.getString(_keyActiveProfile);
    return MobilityProfile.fromName(name);
  }

  /// Persiste o perfil biomecânico selecionado.
  Future<void> setActiveProfile(MobilityProfile profile) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveProfile, profile.name);
  }

  /// Obtém o conjunto de IDs de barreiras monitoradas/favoritadas pelo cidadão.
  Future<Set<String>> getMonitoredBarrierIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> list =
        prefs.getStringList(_keyMonitoredBarrierIds) ?? const <String>[];
    return list.toSet();
  }

  /// Alterna o monitoramento de uma barreira e salva no SharedPreferences.
  Future<Set<String>> toggleMonitoredBarrier(String barrierId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Set<String> current =
        (prefs.getStringList(_keyMonitoredBarrierIds) ?? <String>[]).toSet();
    if (current.contains(barrierId)) {
      current.remove(barrierId);
    } else {
      current.add(barrierId);
    }
    await prefs.setStringList(_keyMonitoredBarrierIds, current.toList());
    return current;
  }

  /// Obtém o usuário atualmente autenticado na sessão local, ou null caso deslogado.
  Future<AppUser?> getLoggedUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString(_keyLoggedUserEmail);
    final String? roleName = prefs.getString(_keyLoggedUserRole);
    final String? name = prefs.getString(_keyLoggedUserName);
    final String? dept = prefs.getString(_keyLoggedUserDept);

    if (email == null || roleName == null) {
      return null;
    }

    return AppUser(
      email: email,
      name: name ?? email,
      role: UserRole.fromName(roleName),
      department: dept ?? 'Caminho Livre',
    );
  }

  /// Salva a sessão do usuário autenticado no SharedPreferences.
  Future<void> saveLoggedUser(AppUser user) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLoggedUserEmail, user.email);
    await prefs.setString(_keyLoggedUserRole, user.role.name);
    await prefs.setString(_keyLoggedUserName, user.name);
    await prefs.setString(_keyLoggedUserDept, user.department);
  }

  /// Remove a sessão do usuário ativo (Logout).
  Future<void> clearLoggedUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedUserEmail);
    await prefs.remove(_keyLoggedUserRole);
    await prefs.remove(_keyLoggedUserName);
    await prefs.remove(_keyLoggedUserDept);
  }
}
