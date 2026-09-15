import 'package:flutter_test/flutter_test.dart';
import 'package:pr_2/models/app_user.dart';
import 'package:pr_2/models/role.dart';

void main() {
  group('Role hierarchy', () {
    test('client level is 1', () {
      expect(Role.client.level, 1);
    });

    test('staff is at least client but not admin', () {
      expect(Role.staff.atLeast(Role.client), isTrue);
      expect(Role.staff.atLeast(Role.staff), isTrue);
      expect(Role.staff.atLeast(Role.admin), isFalse);
    });

    test('admin is at least all roles', () {
      expect(Role.admin.atLeast(Role.client), isTrue);
      expect(Role.admin.atLeast(Role.staff), isTrue);
      expect(Role.admin.atLeast(Role.admin), isTrue);
    });

    test('fromCode maps known codes', () {
      expect(Role.fromCode('admin'), Role.admin);
      expect(Role.fromCode('staff'), Role.staff);
      expect(Role.fromCode('client'), Role.client);
      expect(Role.fromCode('unknown'), Role.client);
    });
  });

  group('AppUser role and operation availability', () {
    AppUser user(Role role) => AppUser(
      id: 1,
      username: 'u',
      fullName: 'User',
      email: 'u@zoo.local',
      role: role,
    );

    bool canManageEntities(AppUser u) => u.role.atLeast(Role.staff);
    bool canManageUsers(AppUser u) => u.role.atLeast(Role.admin);
    bool canViewCatalog(AppUser u) => u.role.atLeast(Role.client);
    bool canHardDelete(AppUser u) => u.role.atLeast(Role.admin);
    bool canExtendVisit(AppUser u) => u.role.atLeast(Role.client);

    test('client: view catalog and extend visit, no manage', () {
      final u = user(Role.client);
      expect(canViewCatalog(u), isTrue);
      expect(canExtendVisit(u), isTrue);
      expect(canManageEntities(u), isFalse);
      expect(canManageUsers(u), isFalse);
      expect(canHardDelete(u), isFalse);
    });

    test('staff: manage entities, not users/hard delete', () {
      final u = user(Role.staff);
      expect(canViewCatalog(u), isTrue);
      expect(canManageEntities(u), isTrue);
      expect(canManageUsers(u), isFalse);
      expect(canHardDelete(u), isFalse);
    });

    test('admin: all operations available', () {
      final u = user(Role.admin);
      expect(canViewCatalog(u), isTrue);
      expect(canManageEntities(u), isTrue);
      expect(canManageUsers(u), isTrue);
      expect(canHardDelete(u), isTrue);
      expect(canExtendVisit(u), isTrue);
    });
  });
}
