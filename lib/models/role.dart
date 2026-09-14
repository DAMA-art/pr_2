enum Role {
  client(1, 'client', 'Клиент'),
  staff(2, 'staff', 'Сотрудник'),
  admin(3, 'admin', 'Администратор');

  final int level;
  final String code;
  final String title;

  const Role(this.level, this.code, this.title);

  static Role fromCode(String? code) {
    switch ((code ?? '').toLowerCase()) {
      case 'admin':
        return Role.admin;
      case 'staff':
        return Role.staff;
      case 'client':
      default:
        return Role.client;
    }
  }

  bool atLeast(Role other) => level >= other.level;
}