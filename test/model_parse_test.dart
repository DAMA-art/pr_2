import 'package:flutter_test/flutter_test.dart';
import 'package:pr_2/models/pet.dart';
import 'package:pr_2/models/role.dart';

void main() {
  test('Pet.fromJson с минимальными полями не падает', () {
    final pet = Pet.fromJson({'id': 1, 'name': 'Барсик'});
    expect(pet.id, 1);
    expect(pet.name, 'Барсик');
  });

  test('Role.fromCode', () {
    expect(Role.fromCode('admin'), Role.admin);
    expect(Role.fromCode('staff'), Role.staff);
    expect(Role.fromCode('client'), Role.client);
  });
}
