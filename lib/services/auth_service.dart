import '../models/user_role.dart';

/// Serviço de autenticação e controle de perfis de usuário do Caminho Livre.
/// Define os perfis de teste exigidos para diferenciação entre Cidadão Comum e Gestor Público.
class AuthService {
  const AuthService._();

  /// Credenciais oficiais do Perfil 1: Cidadão Comum (Scout da Calçada)
  static const AppUser citizenUser = AppUser(
    email: 'cidadao@caminholivre.com.br',
    name: 'Ana Cidadã (Scout da Calçada)',
    role: UserRole.cidadao,
    department: 'Auditoria Comunitária & Engajamento Cívico',
  );
  static const String citizenPassword = '123456';

  /// Credenciais oficiais do Perfil 2: Gestor Público Especializado B2G
  static const AppUser managerUser = AppUser(
    email: 'gestor@sp.gov.br',
    name: 'Dr. Carlos Mendes (Engenheiro B2G)',
    role: UserRole.gestor,
    department: 'Secretaria Municipal de Obras e Mobilidade Urbana - SP',
  );
  static const String managerPassword = 'gestor123';
  static const String managerPasswordAlt = 'admin123';

  /// Valida as credenciais fornecidas na tela de login.
  /// Retorna o [AppUser] autenticado caso as credenciais sejam válidas, ou null em caso de erro.
  static AppUser? authenticate({
    required String login,
    required String password,
  }) {
    final String cleanLogin = login.trim().toLowerCase();
    final String cleanPassword = password.trim();

    // 1. Verificação do Perfil Cidadão
    if ((cleanLogin == citizenUser.email || cleanLogin == 'cidadao') &&
        cleanPassword == citizenPassword) {
      return citizenUser;
    }

    // 2. Verificação do Perfil Gestor Público
    if ((cleanLogin == managerUser.email || cleanLogin == 'gestor') &&
        (cleanPassword == managerPassword || cleanPassword == managerPasswordAlt)) {
      return managerUser;
    }

    return null;
  }
}

