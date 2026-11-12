/// Níveis de acesso para controle de permissões no Caminho Livre.
enum UserRole {
  cidadao(
    label: 'Cidadão / Scout',
    description:
        'Acesso restrito ao Painel Guardião Scout (gamificação, missões de auditoria, XP e insígnias).',
  ),
  gestor(
    label: 'Gestor Público B2G',
    description:
        'Acesso irrestrito: Painel Guardião Scout e Fila de Obras da Prefeitura ordenada por Score B2G.',
  );

  const UserRole({
    required this.label,
    required this.description,
  });

  final String label;
  final String description;

  bool get isGestor => this == UserRole.gestor;
  bool get isCidadao => this == UserRole.cidadao;

  static UserRole fromName(String? name) {
    return UserRole.values.firstWhere(
      (role) => role.name == name,
      orElse: () => UserRole.cidadao,
    );
  }
}

/// Representa o usuário autenticado na sessão do aplicativo.
class AppUser {
  final String email;
  final String name;
  final UserRole role;
  final String department;

  const AppUser({
    required this.email,
    required this.name,
    required this.role,
    required this.department,
  });
}

