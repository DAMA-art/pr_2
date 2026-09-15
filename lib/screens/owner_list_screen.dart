import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/role.dart';
import '../state/auth_notifier.dart';
import '../models/owner.dart';
import '../repositories/pet_repository.dart';
import '../state/load_status.dart';
import '../state/owner_list_notifier.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/search_field.dart';

class OwnerListScreen extends StatelessWidget {
  const OwnerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Владельцы — Зоосалон'),
        actions: [
          Consumer<OwnerListNotifier>(
            builder: (context, notifier, _) {
              if (!notifier.hasSelection) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Text(
                    'Выбрано: ${notifier.selected.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
          Consumer<OwnerListNotifier>(
            builder: (context, notifier, _) {
              if (!notifier.hasSelection) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Удалить выбранные',
                onPressed: () => _confirmBulkDelete(context, notifier),
              );
            },
          ),
          if (context.watch<AuthNotifier>().has(Role.staff))
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Создать',
              onPressed: () async {
                final ok = await context.push('/owners/new');
                if (ok == true && context.mounted) {
                  context.read<OwnerListNotifier>().load();
                }
              },
            ),
        ],
      ),
      body: Consumer<OwnerListNotifier>(
        builder: (context, notifier, _) {
          return Column(
            children: [
              _FiltersPanel(notifier: notifier),
              Expanded(child: _buildBody(context, notifier)),
              if (notifier.status == LoadStatus.success)
                PaginationBar(
                  result: notifier.result,
                  currentSize: notifier.query.size,
                  onPageChanged: (page) {
                    notifier.applyQuery(notifier.query.copyWith(page: page));
                  },
                  onSizeChanged: (size) {
                    notifier.applyQuery(
                      notifier.query.copyWith(size: size, page: 1),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, OwnerListNotifier notifier) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(notifier.error ?? 'Ошибка', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => notifier.load(),
                child: const Text('Повторить'),
              ),
            ],
          ),
        );
      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Ничего не найдено', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Попробуйте изменить условия поиска или фильтры'),
              ],
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return _OwnerCardsList(notifier: notifier);
            }
            return EntityTable<Owner>(
              items: notifier.result.items,
              idOf: (o) => o.id,
              selected: notifier.selected,
              onToggleSelect: notifier.toggleSelection,
              sortField: notifier.query.sortField,
              sortAscending: notifier.query.sortAscending,
              isDeleted: (o) => o.isDeleted,
              onSort: (field) {
                final next = notifier.query.copyWith(
                  sortField: field,
                  sortAscending: field == notifier.query.sortField
                      ? !notifier.query.sortAscending
                      : true,
                );
                notifier.applyQuery(next);
              },
              columns: [
                TableColumnSpec(
                  label: 'Фамилия',
                  sortField: 'lastName',
                  build: (o) => Text(
                    o.lastName,
                    style: TextStyle(
                      decoration: o.isDeleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                TableColumnSpec(
                  label: 'Имя',
                  sortField: 'firstName',
                  build: (o) => Text(o.firstName),
                ),
                TableColumnSpec(label: 'Телефон', build: (o) => Text(o.phone)),
                TableColumnSpec(
                  label: 'Город',
                  sortField: 'city',
                  build: (o) => Text(o.city),
                ),
                TableColumnSpec(
                  label: 'Страна',
                  sortField: 'country',
                  build: (o) => Text(o.country),
                ),
              ],
              actions: (o) => [
                if (o.isDeleted)
                  IconButton(
                    icon: const Icon(Icons.restore, color: Colors.green),
                    tooltip: 'Восстановить',
                    onPressed: () => notifier.restore(o.id),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Карточка',
                    onPressed: () => context.go('/owners/${o.id}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Удалить',
                    onPressed: () => _confirmDelete(context, notifier, o),
                  ),
                ],
              ],
            );
          },
        );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    OwnerListNotifier notifier,
    Owner owner,
  ) async {
    final count = await context.read<PetRepository>().countByOwner(owner.id);
    if (!context.mounted) return;
    if (count > 0) {
      await showBlockedDelete(
        context,
        title: 'Невозможно удалить',
        body:
            'Владелец «${owner.fullName}» связан с $count питомцами. '
            'Сначала удалите или переназначьте питомцев.',
      );
      return;
    }
    final hard = await confirmDeleteMode(
      context,
      title: 'Удаление владельца',
      body: 'Удалить «${owner.fullName}»?',
    );
    if (hard == null) return;
    if (hard) {
      await notifier.hardDelete(owner.id);
    } else {
      await notifier.softDelete(owner.id);
    }
  }

  Future<void> _confirmBulkDelete(
    BuildContext context,
    OwnerListNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление выбранных'),
        content: Text('Удалить логически ${notifier.selected.length} записей?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await notifier.deleteSelected();
    }
  }
}

class _FiltersPanel extends StatelessWidget {
  final OwnerListNotifier notifier;

  const _FiltersPanel({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final q = notifier.query;
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchField(
              initialValue: q.search,
              hintText: 'Поиск по фамилии, имени, телефону или стране...',
              onChanged: (v) => notifier.applyQuery(q.copyWith(search: v)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: q.city,
                    decoration: const InputDecoration(
                      labelText: 'Город',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все')),
                      for (final city in notifier.cities)
                        DropdownMenuItem(value: city, child: Text(city)),
                    ],
                    onChanged: (v) => notifier.applyQuery(q.copyWith(city: v)),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: q.country,
                    decoration: const InputDecoration(
                      labelText: 'Страна',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Все')),
                      DropdownMenuItem(value: 'Россия', child: Text('Россия')),
                    ],
                    onChanged: (v) =>
                        notifier.applyQuery(q.copyWith(country: v)),
                  ),
                ),
                FilterChip(
                  label: const Text('Показать удалённые'),
                  selected: q.includeDeleted,
                  onSelected: (v) =>
                      notifier.applyQuery(q.copyWith(includeDeleted: v)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerCardsList extends StatelessWidget {
  final OwnerListNotifier notifier;

  const _OwnerCardsList({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: notifier.result.items.length,
      itemBuilder: (context, index) {
        final o = notifier.result.items[index];
        return Card(
          color: o.isDeleted ? Colors.red.withValues(alpha: 0.08) : null,
          child: ListTile(
            leading: Checkbox(
              value: notifier.selected.contains(o.id),
              onChanged: (_) => notifier.toggleSelection(o.id),
            ),
            title: Text(
              o.fullName,
              style: TextStyle(
                decoration: o.isDeleted ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text('${o.phone}\n${o.city}, ${o.country}'),
            isThreeLine: true,
            trailing: o.isDeleted
                ? IconButton(
                    icon: const Icon(Icons.restore, color: Colors.green),
                    onPressed: () => notifier.restore(o.id),
                  )
                : PopupMenuButton(
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Text('Карточка'),
                      ),
                      const PopupMenuItem(
                        value: 'soft',
                        child: Text('Удалить логически'),
                      ),
                      const PopupMenuItem(
                        value: 'hard',
                        child: Text('Удалить физически'),
                      ),
                    ],
                    onSelected: (v) {
                      if (v == 'view') context.go('/owners/${o.id}');
                      if (v == 'soft') notifier.softDelete(o.id);
                      if (v == 'hard') notifier.hardDelete(o.id);
                    },
                  ),
          ),
        );
      },
    );
  }
}
