import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/owner_query.dart';
import 'models/pet_query.dart';
import 'models/service_query.dart';
import 'models/clinic_query.dart';
import 'models/pet_passport_query.dart';
import 'repositories/persistent_owner_repository.dart';
import 'repositories/persistent_pet_repository.dart';
import 'repositories/persistent_service_repository.dart';
import 'repositories/persistent_clinic_repository.dart';
import 'repositories/persistent_pet_passport_repository.dart';
import 'repositories/owner_repository.dart';
import 'repositories/pet_repository.dart';
import 'repositories/service_repository.dart';
import 'repositories/clinic_repository.dart';
import 'repositories/pet_passport_repository.dart';
import 'screens/owner_detail_screen.dart';
import 'screens/owner_list_screen.dart';
import 'screens/owner_form_screen.dart';
import 'screens/pet_detail_screen.dart';
import 'screens/pet_list_screen.dart';
import 'screens/pet_form_screen.dart';
import 'screens/service_form_screen.dart';
import 'screens/clinic_form_screen.dart';
import 'screens/service_list_screen.dart';
import 'screens/clinic_list_screen.dart';
import 'screens/service_detail_screen.dart';
import 'screens/clinic_detail_screen.dart';
import 'screens/passport_list_screen.dart';
import 'screens/passport_form_screen.dart';
import 'screens/passport_detail_screen.dart';
import 'state/owner_list_notifier.dart';
import 'state/pet_list_notifier.dart';
import 'state/service_list_notifier.dart';
import 'state/clinic_list_notifier.dart';
import 'state/passport_list_notifier.dart';
import 'utils/schema_migration.dart';

final _messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();
  final migrationMessage = await SchemaMigration.migrate(prefs);
  runApp(
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
      child: ZooSalonApp(migrationMessage: migrationMessage),
    ),
  );
}

class ZooSalonApp extends StatefulWidget {
  final String? migrationMessage;
  const ZooSalonApp({super.key, this.migrationMessage});

  @override
  State<ZooSalonApp> createState() => _ZooSalonAppState();
}

class _ZooSalonAppState extends State<ZooSalonApp> {
  @override
  void initState() {
    super.initState();
    final msg = widget.migrationMessage;
    if (msg != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 8)),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Зоосалон',
      scaffoldMessengerKey: _messengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/pets',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        int idx = 0;
        final path = state.uri.path;
        if (path.startsWith('/owners')) {
          idx = 1;
        } else if (path.startsWith('/services')) {
          idx = 2;
        } else if (path.startsWith('/clinics')) {
          idx = 3;
        } else if (path.startsWith('/passports')) {
          idx = 4;
        }

        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: idx,
            onDestinationSelected: (i) {
              switch (i) {
                case 0:
                  context.go('/pets');
                case 1:
                  context.go('/owners');
                case 2:
                  context.go('/services');
                case 3:
                  context.go('/clinics');
                case 4:
                  context.go('/passports');
              }
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.pets), label: 'Питомцы'),
              NavigationDestination(icon: Icon(Icons.people), label: 'Владельцы'),
              NavigationDestination(icon: Icon(Icons.medical_services), label: 'Услуги'),
              NavigationDestination(icon: Icon(Icons.local_hospital), label: 'Филиалы'),
              NavigationDestination(icon: Icon(Icons.badge_outlined), label: 'Паспорта'),
            ],
          ),
        );
      },
      routes: [
        GoRoute(
          path: '/pets',
          builder: (context, state) {
            final q = _parsePetQuery(state.uri.queryParameters);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final n = context.read<PetListNotifier>();
              if (_petQueryChanged(n.query, q)) n.applyQuery(q);
            });
            return const PetListScreen();
          },
          routes: [
            GoRoute(path: 'new', builder: (_, _) => const PetFormScreen()),
            GoRoute(
              path: ':id',
              builder: (c, s) {
                final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
                return PetDetailScreen(id: id);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (c, s) {
                    final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
                    return PetFormScreen(id: id);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/owners',
          builder: (context, state) {
            final q = _parseOwnerQuery(state.uri.queryParameters);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final n = context.read<OwnerListNotifier>();
              if (_ownerQueryChanged(n.query, q)) n.applyQuery(q);
            });
            return const OwnerListScreen();
          },
          routes: [
            GoRoute(path: 'new', builder: (_, _) => const OwnerFormScreen()),
            GoRoute(
              path: ':id',
              builder: (c, s) {
                final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
                return OwnerDetailScreen(id: id);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (c, s) {
                    final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
                    return OwnerFormScreen(id: id);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/services',
          builder: (context, state) {
            final q = _parseServiceQuery(state.uri.queryParameters);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final n = context.read<ServiceListNotifier>();
              if (_serviceQueryChanged(n.query, q)) n.applyQuery(q);
            });
            return const ServiceListScreen();
          },
          routes: [
            GoRoute(path: 'new', builder: (_, _) => const ServiceFormScreen()),
            GoRoute(
              path: ':id',
              builder: (c, s) {
                final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
                return ServiceDetailScreen(id: id);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (c, s) {
                    final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
                    return ServiceFormScreen(id: id);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/clinics',
          builder: (context, state) {
            final q = _parseClinicQuery(state.uri.queryParameters);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final n = context.read<ClinicListNotifier>();
              if (_clinicQueryChanged(n.query, q)) n.applyQuery(q);
            });
            return const ClinicListScreen();
          },
          routes: [
            GoRoute(path: 'new', builder: (_, _) => const ClinicFormScreen()),
            GoRoute(
              path: ':id',
              builder: (c, s) {
                final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
                return ClinicDetailScreen(id: id);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (c, s) {
                    final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
                    return ClinicFormScreen(id: id);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/passports',
          builder: (context, state) {
            final q = _parsePassportQuery(state.uri.queryParameters);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final n = context.read<PassportListNotifier>();
              if (_passportQueryChanged(n.query, q)) n.applyQuery(q);
            });
            return const PassportListScreen();
          },
          routes: [
            GoRoute(path: 'new', builder: (_, _) => const PassportFormScreen()),
            GoRoute(
              path: ':id',
              builder: (c, s) {
                final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
                return PassportDetailScreen(id: id);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (c, s) {
                    final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
                    return PassportFormScreen(id: id);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

PetQuery _parsePetQuery(Map<String, String> params) {
  String sortField = 'name';
  bool sortAsc = true;
  if (params.containsKey('sort')) {
    final parts = params['sort']!.split(',');
    sortField = parts[0];
    if (parts.length > 1) sortAsc = parts[1] != 'desc';
  }
  return PetQuery(
    search: params['search'] ?? '',
    species: params['species'],
    ownerId: int.tryParse(params['ownerId'] ?? ''),
    clinicId: int.tryParse(params['clinicId'] ?? ''),
    ageFrom: int.tryParse(params['ageFrom'] ?? ''),
    ageTo: int.tryParse(params['ageTo'] ?? ''),
    sortField: sortField,
    sortAscending: sortAsc,
    page: int.tryParse(params['page'] ?? '1') ?? 1,
    size: int.tryParse(params['size'] ?? '10') ?? 10,
    includeDeleted: params['includeDeleted'] == 'true',
  );
}

OwnerQuery _parseOwnerQuery(Map<String, String> params) {
  String sortField = 'lastName';
  bool sortAsc = true;
  if (params.containsKey('sort')) {
    final parts = params['sort']!.split(',');
    sortField = parts[0];
    if (parts.length > 1) sortAsc = parts[1] != 'desc';
  }
  return OwnerQuery(
    search: params['search'] ?? '',
    city: params['city'],
    country: params['country'],
    sortField: sortField,
    sortAscending: sortAsc,
    page: int.tryParse(params['page'] ?? '1') ?? 1,
    size: int.tryParse(params['size'] ?? '10') ?? 10,
    includeDeleted: params['includeDeleted'] == 'true',
  );
}

ServiceQuery _parseServiceQuery(Map<String, String> params) {
  String sortField = 'name';
  bool sortAsc = true;
  if (params.containsKey('sort')) {
    final parts = params['sort']!.split(',');
    sortField = parts[0];
    if (parts.length > 1) sortAsc = parts[1] != 'desc';
  }
  return ServiceQuery(
    search: params['search'] ?? '',
    clinicId: int.tryParse(params['clinicId'] ?? ''),
    sortField: sortField,
    sortAscending: sortAsc,
    page: int.tryParse(params['page'] ?? '1') ?? 1,
    size: int.tryParse(params['size'] ?? '10') ?? 10,
    includeDeleted: params['includeDeleted'] == 'true',
  );
}

ClinicQuery _parseClinicQuery(Map<String, String> params) {
  String sortField = 'name';
  bool sortAsc = true;
  if (params.containsKey('sort')) {
    final parts = params['sort']!.split(',');
    sortField = parts[0];
    if (parts.length > 1) sortAsc = parts[1] != 'desc';
  }
  return ClinicQuery(
    search: params['search'] ?? '',
    city: params['city'],
    sortField: sortField,
    sortAscending: sortAsc,
    page: int.tryParse(params['page'] ?? '1') ?? 1,
    size: int.tryParse(params['size'] ?? '10') ?? 10,
    includeDeleted: params['includeDeleted'] == 'true',
  );
}

PetPassportQuery _parsePassportQuery(Map<String, String> params) {
  String sortField = 'number';
  bool sortAsc = true;
  if (params.containsKey('sort')) {
    final parts = params['sort']!.split(',');
    sortField = parts[0];
    if (parts.length > 1) sortAsc = parts[1] != 'desc';
  }
  return PetPassportQuery(
    search: params['search'] ?? '',
    petId: int.tryParse(params['petId'] ?? ''),
    sortField: sortField,
    sortAscending: sortAsc,
    page: int.tryParse(params['page'] ?? '1') ?? 1,
    size: int.tryParse(params['size'] ?? '10') ?? 10,
    includeDeleted: params['includeDeleted'] == 'true',
  );
}

bool _petQueryChanged(PetQuery a, PetQuery b) =>
    a.search != b.search ||
    a.species != b.species ||
    a.ownerId != b.ownerId ||
    a.clinicId != b.clinicId ||
    a.ageFrom != b.ageFrom ||
    a.ageTo != b.ageTo ||
    a.sortField != b.sortField ||
    a.sortAscending != b.sortAscending ||
    a.page != b.page ||
    a.size != b.size ||
    a.includeDeleted != b.includeDeleted;

bool _ownerQueryChanged(OwnerQuery a, OwnerQuery b) =>
    a.search != b.search ||
    a.city != b.city ||
    a.country != b.country ||
    a.sortField != b.sortField ||
    a.sortAscending != b.sortAscending ||
    a.page != b.page ||
    a.size != b.size ||
    a.includeDeleted != b.includeDeleted;

bool _serviceQueryChanged(ServiceQuery a, ServiceQuery b) =>
    a.search != b.search ||
    a.clinicId != b.clinicId ||
    a.sortField != b.sortField ||
    a.sortAscending != b.sortAscending ||
    a.page != b.page ||
    a.size != b.size ||
    a.includeDeleted != b.includeDeleted;

bool _clinicQueryChanged(ClinicQuery a, ClinicQuery b) =>
    a.search != b.search ||
    a.city != b.city ||
    a.sortField != b.sortField ||
    a.sortAscending != b.sortAscending ||
    a.page != b.page ||
    a.size != b.size ||
    a.includeDeleted != b.includeDeleted;

bool _passportQueryChanged(PetPassportQuery a, PetPassportQuery b) =>
    a.search != b.search ||
    a.petId != b.petId ||
    a.sortField != b.sortField ||
    a.sortAscending != b.sortAscending ||
    a.page != b.page ||
    a.size != b.size ||
    a.includeDeleted != b.includeDeleted;
