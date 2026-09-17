import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/role.dart';
import '../state/auth_notifier.dart';
import '../utils/breakpoints.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const ResponsiveScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final isStaff = auth.has(Role.staff);
    final isClientOnly = auth.isExactly(Role.client);
    final isStaffOnly = auth.isExactly(Role.staff);
    final width = MediaQuery.sizeOf(context).width;

    final paths = <String>['/pets', '/services', '/clinics', '/visits'];
    if (isStaff) {
      paths.insert(1, '/owners');
      paths.add('/groomers');
    }
    if (isStaffOnly) {
      paths.add('/passports');
    }
    if (isClientOnly) {
      paths.add('/reviews');
    }

    int selected = 0;
    for (var i = 0; i < paths.length; i++) {
      if (currentPath.startsWith(paths[i])) selected = i;
    }

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.pets_outlined),
        selectedIcon: Icon(Icons.pets),
        label: 'Питомцы',
      ),
      if (isStaff)
        const NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Владельцы',
        ),
      const NavigationDestination(
        icon: Icon(Icons.spa_outlined),
        selectedIcon: Icon(Icons.spa),
        label: 'Услуги',
      ),
      const NavigationDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront),
        label: 'Филиалы',
      ),
      const NavigationDestination(
        icon: Icon(Icons.event_outlined),
        selectedIcon: Icon(Icons.event),
        label: 'Записи',
      ),
      if (isStaff)
        const NavigationDestination(
          icon: Icon(Icons.content_cut_outlined),
          selectedIcon: Icon(Icons.content_cut),
          label: 'Мастера',
        ),
      if (isStaffOnly)
        const NavigationDestination(
          icon: Icon(Icons.badge_outlined),
          selectedIcon: Icon(Icons.badge),
          label: 'Паспорта',
        ),
      if (isClientOnly)
        const NavigationDestination(
          icon: Icon(Icons.reviews_outlined),
          selectedIcon: Icon(Icons.reviews),
          label: 'Отзывы',
        ),
    ];

    void goIndex(int i) {
      if (i >= 0 && i < paths.length) context.go(paths[i]);
    }

    final appBar = AppBar(
      title: const Text('Зоосалон'),
      actions: [
        if (auth.isExactly(Role.admin)) ...[
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
        if (auth.user != null && width >= Breakpoints.phone)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                '${auth.user!.fullName} (${auth.user!.role.title})',
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
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
    );

    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.contentMax),
        child: child,
      ),
    );

    if (Breakpoints.isPhone(width)) {
      return Scaffold(
        appBar: appBar,
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected.clamp(0, destinations.length - 1),
          onDestinationSelected: goIndex,
          destinations: destinations,
        ),
      );
    }

    final extended = width >= Breakpoints.desktop;
    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selected.clamp(0, destinations.length - 1),
            onDestinationSelected: goIndex,
            extended: extended,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon ?? d.icon,
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
