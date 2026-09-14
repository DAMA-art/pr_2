import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_strategy/url_strategy.dart';

import 'api/auth_api.dart';
import 'api/dio_client.dart';
import 'api/directory_cache.dart';
import 'models/clinic_query.dart';
import 'models/owner_query.dart';
import 'models/pet_passport_query.dart';
import 'models/pet_query.dart';
import 'models/role.dart';
import 'models/service_query.dart';
import 'repositories/api_clinic_repository.dart';
import 'repositories/api_owner_repository.dart';
import 'repositories/api_pet_passport_repository.dart';
import 'repositories/api_pet_repository.dart';
import 'repositories/api_service_repository.dart';
import 'repositories/clinic_repository.dart';
import 'repositories/owner_repository.dart';
import 'repositories/pet_passport_repository.dart';
import 'repositories/pet_repository.dart';
import 'repositories/service_repository.dart';
import 'repositories/visit_repository.dart';
import 'screens/clinic_detail_screen.dart';
import 'screens/clinic_form_screen.dart';
import 'screens/clinic_list_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/login_screen.dart';
import 'screens/owner_detail_screen.dart';
import 'screens/owner_form_screen.dart';
import 'screens/owner_list_screen.dart';
import 'screens/passport_detail_screen.dart';
import 'screens/passport_form_screen.dart';
import 'screens/passport_list_screen.dart';
import 'screens/pet_detail_screen.dart';
import 'screens/pet_form_screen.dart';
import 'screens/pet_list_screen.dart';
import 'screens/register_screen.dart';
import 'screens/service_detail_screen.dart';
import 'screens/service_form_screen.dart';
import 'screens/service_list_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/users_screen.dart';
import 'screens/visits_screen.dart';
import 'state/auth_notifier.dart';
import 'state/clinic_list_notifier.dart';
import 'state/owner_list_notifier.dart';
import 'state/passport_list_notifier.dart';
import 'state/pet_list_notifier.dart';
import 'state/service_list_notifier.dart';
import 'widgets/inactivity_watcher.dart';

final _messengerKey = GlobalKey<ScaffoldMessengerState>();

const _maxSessionDuration = Duration(hours: 8);
const _inactivityTimeout = Duration(minutes: 3);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  final dio = createDio();
  final cache = DirectoryCache();
  final authApi = AuthApi(dio);
  final auth = AuthNotifier(prefs, authApi);

  bindAuthToDio(
    tokenProvider: () => auth.accessToken,
    refresher: () => auth.refreshTokens(),
    onRefreshFailed: () => auth.logout(),
  );

  await auth.restore();

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>.value(value: dio),
        Provider<DirectoryCache>.value(value: cache),
        Provider<AuthApi>.value(value: authApi),
        ChangeNotifierProvider<AuthNotifier>.value(value: auth),
        Provider<PetRepository>(create: (_) => ApiPetRepository(dio)),
        Provider<OwnerRepository>(create: (_) => ApiOwnerRepository(dio, cache)),
        Provider<ServiceRepository>(create: (_) => ApiServiceRepository(dio, cache)),
        Provider<ClinicRepository>(create: (_) => ApiClinicRepository(dio, cache)),
        Provider<PetPassportRepository>(create: (_) => ApiPetPassportRepository(dio)),
        Provider(create: (_) => VisitRepository(dio)),
        ChangeNotifierProvider(create: (c) => PetListNotifier(c.read<PetRepository>())..load()),
        ChangeNotifierProvider(create: (c) => OwnerListNotifier(c.read<OwnerRepository>())..load()),
        ChangeNotifierProvider(create: (c) => ServiceListNotifier(c.read<ServiceRepository>())..load()),
        ChangeNotifierProvider(create: (c) => ClinicListNotifier(c.read<ClinicRepository>())..load()),
        ChangeNotifierProvider(create: (c) => PassportListNotifier(c.read<PetPassportRepository>())..load()),
      ],
      child: ZooSalonApp(auth: auth),
    ),
  );
}

class ZooSalonApp extends StatefulWidget {
  final AuthNotifier auth;
  const ZooSalonApp({super.key, required this.auth});

  @override
  State<ZooSalonApp> createState() => _ZooSalonAppState();
}

class _ZooSalonAppState extends State<ZooSalonApp> {
  late final GoRouter _router;
  bool _sessionExpiredShown = false;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter(widget.auth);
    widget.auth.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    final started = widget.auth.sessionStartedAt;
    if (widget.auth.isAuthenticated && started != null) {
      if (DateTime.now().difference(started) > _maxSessionDuration) {
        _forceLogout('Сессия истекла по времени (макс. ${_maxSessionDuration.inHours} ч).');
      }
    }
  }

  Future<void> _forceLogout(String message) async {
    if (_sessionExpiredShown) return;
    _sessionExpiredShown = true;
    await widget.auth.logout();
    _messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
    _sessionExpiredShown = false;
  }

  @override
  void dispose() {
    widget.auth.removeListener(_onAuthChanged);
    super.dispose();
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
      builder: (context, child) {
        final auth = context.watch<AuthNotifier>();
        if (!auth.isAuthenticated) {
          return child ?? const SizedBox.shrink();
        }
        return InactivityWatcher(
          timeout: _inactivityTimeout,
          warningBefore: const Duration(seconds: 30),
          onWarning: () {
            _messengerKey.currentState?.showSnackBar(
              const SnackBar(
                content: Text('Сессия завершится через 30 секунд из‑за неактивности'),
                duration: Duration(seconds: 25),
              ),
            );
          },
          onTimeout: () {
            _forceLogout('Сессия завершена из‑за неактивности.');
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

GoRouter _buildRouter(AuthNotifier auth) {
  return GoRouter(
    initialLocation: '/pets',
    refreshListenable: auth,
    redirect: (context, state) {
      if (auth.isRestoring) return null;

      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (loggedIn && isPublic) return '/pets';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forbidden', builder: (_, __) => const ForbiddenScreen()),
      ShellRoute(
        builder: (context, state, child) {
          final auth = context.watch<AuthNotifier>();
          final path = state.uri.path;
          final isStaff = auth.has(Role.staff);

          final paths = <String>['/pets', '/services', '/clinics', '/visits'];
          if (isStaff) {
            paths.insert(1, '/owners');
            paths.insert(4, '/passports');
          }
          int selected = 0;
          for (var i = 0; i < paths.length; i++) {
            if (path.startsWith(paths[i])) selected = i;
          }

          final destinations = <NavigationDestination>[
            const NavigationDestination(icon: Icon(Icons.pets), label: 'Питомцы'),
            if (isStaff)
              const NavigationDestination(icon: Icon(Icons.people), label: 'Владельцы'),
            const NavigationDestination(icon: Icon(Icons.medical_services), label: 'Услуги'),
            const NavigationDestination(icon: Icon(Icons.local_hospital), label: 'Филиалы'),
            if (isStaff)
              const NavigationDestination(icon: Icon(Icons.badge_outlined), label: 'Паспорта'),
            const NavigationDestination(icon: Icon(Icons.hotel), label: 'Заселения'),
          ];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Зоосалон'),
              actions: [
                if (auth.has(Role.admin)) ...[
                  IconButton(
                    tooltip: 'Статистика',
                    onPressed: () => context.go('/admin/stats'),
                    icon: const Icon(Icons.bar_chart),
                  ),
                  IconButton(
                    tooltip: 'Пользователи',
                    onPressed: () => context.go('/admin/users'),
                    icon: const Icon(Icons.manage_accounts),
                  ),
                ],
                if (auth.user != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: Text(
                        '${auth.user!.fullName} (${auth.user!.role.title})',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: 'Выйти',
                  onPressed: () async {
                    await auth.logout();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selected.clamp(0, destinations.length - 1),
              onDestinationSelected: (i) {
                if (i >= 0 && i < paths.length) context.go(paths[i]);
              },
              destinations: destinations,
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
              GoRoute(
                path: 'new',
                redirect: (c, s) =>
                    c.read<AuthNotifier>().has(Role.staff) ? null : '/forbidden',
                builder: (_, __) => const PetFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (c, s) {
                  final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
                  return PetDetailScreen(id: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    redirect: (c, s) =>
                        c.read<AuthNotifier>().has(Role.staff) ? null : '/forbidden',
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
            redirect: (c, s) =>
                c.read<AuthNotifier>().has(Role.staff) ? null : '/forbidden',
            builder: (context, state) {
              final q = _parseOwnerQuery(state.uri.queryParameters);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final n = context.read<OwnerListNotifier>();
                if (_ownerQueryChanged(n.query, q)) n.applyQuery(q);
              });
              return const OwnerListScreen();
            },
            routes: [
              GoRoute(path: 'new', builder: (_, __) => const OwnerFormScreen()),
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
              GoRoute(
                path: 'new',
                redirect: (c, s) =>
                    c.read<AuthNotifier>().has(Role.staff) ? null : '/forbidden',
                builder: (_, __) => const ServiceFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (c, s) {
                  final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
                  return ServiceDetailScreen(id: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    redirect: (c, s) =>
                        c.read<AuthNotifier>().has(Role.staff) ? null : '/forbidden',
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
              GoRoute(
                path: 'new',
                redirect: (c, s) =>
                    c.read<AuthNotifier>().has(Role.staff) ? null : '/forbidden',
                builder: (_, __) => const ClinicFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (c, s) {
                  final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
                  return ClinicDetailScreen(id: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    redirect: (c, s) =>
                        c.read<AuthNotifier>().has(Role.staff) ? null : '/forbidden',
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
            redirect: (c, s) =>
                c.read<AuthNotifier>().has(Role.staff) ? null : '/forbidden',
            builder: (context, state) {
              final q = _parsePassportQuery(state.uri.queryParameters);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final n = context.read<PassportListNotifier>();
                if (_passportQueryChanged(n.query, q)) n.applyQuery(q);
              });
              return const PassportListScreen();
            },
            routes: [
              GoRoute(path: 'new', builder: (_, __) => const PassportFormScreen()),
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
          GoRoute(path: '/visits', builder: (_, __) => const VisitsScreen()),
          GoRoute(
            path: '/admin/users',
            redirect: (c, s) =>
                c.read<AuthNotifier>().has(Role.admin) ? null : '/forbidden',
            builder: (_, __) => const UsersScreen(),
          ),
          GoRoute(
            path: '/admin/stats',
            redirect: (c, s) =>
                c.read<AuthNotifier>().has(Role.admin) ? null : '/forbidden',
            builder: (_, __) => const StatsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (c, s) => Scaffold(
      appBar: AppBar(title: const Text('Не найдено')),
      body: Center(child: Text('Страница ${s.uri} не существует')),
    ),
  );
}

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