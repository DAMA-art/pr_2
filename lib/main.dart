import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';

import 'models/owner_query.dart';
import 'models/pet_query.dart';
import 'repositories/in_memory_owner_repository.dart';
import 'repositories/in_memory_pet_repository.dart';
import 'repositories/owner_repository.dart';
import 'repositories/pet_repository.dart';
import 'screens/owner_detail_screen.dart';
import 'screens/owner_list_screen.dart';
import 'screens/pet_detail_screen.dart';
import 'screens/pet_list_screen.dart';
import 'state/owner_list_notifier.dart';
import 'state/pet_list_notifier.dart';

void main() {
  setPathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        Provider<PetRepository>(create: (_) => InMemoryPetRepository()),
        Provider<OwnerRepository>(create: (_) => InMemoryOwnerRepository()),
        ChangeNotifierProvider(
          create: (context) =>
              PetListNotifier(context.read<PetRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              OwnerListNotifier(context.read<OwnerRepository>())..load(),
        ),
      ],
      child: const ZooSalonApp(),
    ),
  );
}

class ZooSalonApp extends StatelessWidget {
  const ZooSalonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Зоосалон',
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
        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.uri.path.startsWith('/owners') ? 1 : 0,
            onDestinationSelected: (i) {
              if (i == 0) {
                context.go('/pets');
              } else {
                context.go('/owners');
              }
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.pets), label: 'Питомцы'),
              NavigationDestination(icon: Icon(Icons.people), label: 'Владельцы'),
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
              final notifier = context.read<PetListNotifier>();
              if (_petQueryChanged(notifier.query, q)) {
                notifier.applyQuery(q);
              }
            });
            return const PetListScreen();
          },
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                return PetDetailScreen(id: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/owners',
          builder: (context, state) {
            final q = _parseOwnerQuery(state.uri.queryParameters);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final notifier = context.read<OwnerListNotifier>();
              if (_ownerQueryChanged(notifier.query, q)) {
                notifier.applyQuery(q);
              }
            });
            return const OwnerListScreen();
          },
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                return OwnerDetailScreen(id: id);
              },
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

bool _petQueryChanged(PetQuery a, PetQuery b) {
  return a.search != b.search ||
      a.species != b.species ||
      a.ownerId != b.ownerId ||
      a.ageFrom != b.ageFrom ||
      a.ageTo != b.ageTo ||
      a.sortField != b.sortField ||
      a.sortAscending != b.sortAscending ||
      a.page != b.page ||
      a.size != b.size ||
      a.includeDeleted != b.includeDeleted;
}

bool _ownerQueryChanged(OwnerQuery a, OwnerQuery b) {
  return a.search != b.search ||
      a.city != b.city ||
      a.country != b.country ||
      a.sortField != b.sortField ||
      a.sortAscending != b.sortAscending ||
      a.page != b.page ||
      a.size != b.size ||
      a.includeDeleted != b.includeDeleted;
}