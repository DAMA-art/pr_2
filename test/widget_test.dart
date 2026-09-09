import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pr_2/main.dart';
import 'package:pr_2/repositories/clinic_repository.dart';
import 'package:pr_2/repositories/owner_repository.dart';
import 'package:pr_2/repositories/pet_passport_repository.dart';
import 'package:pr_2/repositories/pet_repository.dart';
import 'package:pr_2/repositories/persistent_clinic_repository.dart';
import 'package:pr_2/repositories/persistent_owner_repository.dart';
import 'package:pr_2/repositories/persistent_pet_passport_repository.dart';
import 'package:pr_2/repositories/persistent_pet_repository.dart';
import 'package:pr_2/repositories/persistent_service_repository.dart';
import 'package:pr_2/repositories/service_repository.dart';
import 'package:pr_2/state/clinic_list_notifier.dart';
import 'package:pr_2/state/owner_list_notifier.dart';
import 'package:pr_2/state/passport_list_notifier.dart';
import 'package:pr_2/state/pet_list_notifier.dart';
import 'package:pr_2/state/service_list_notifier.dart';

void main() {
  testWidgets('Zoo salon app starts', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PetRepository>(create: (_) => PersistentPetRepository(prefs)),
          Provider<OwnerRepository>(create: (_) => PersistentOwnerRepository(prefs)),
          Provider<ServiceRepository>(create: (_) => PersistentServiceRepository(prefs)),
          Provider<ClinicRepository>(create: (_) => PersistentClinicRepository(prefs)),
          Provider<PetPassportRepository>(create: (_) => PersistentPetPassportRepository(prefs)),
          ChangeNotifierProvider(create: (c) => PetListNotifier(c.read<PetRepository>())..load()),
          ChangeNotifierProvider(create: (c) => OwnerListNotifier(c.read<OwnerRepository>())..load()),
          ChangeNotifierProvider(create: (c) => ServiceListNotifier(c.read<ServiceRepository>())..load()),
          ChangeNotifierProvider(create: (c) => ClinicListNotifier(c.read<ClinicRepository>())..load()),
          ChangeNotifierProvider(create: (c) => PassportListNotifier(c.read<PetPassportRepository>())..load()),
        ],
        child: const ZooSalonApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(ZooSalonApp), findsOneWidget);
  });
}
