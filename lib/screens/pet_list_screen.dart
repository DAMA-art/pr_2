import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/pet.dart';
import '../models/pet_query.dart';
import '../state/pet_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/search_field.dart';

class PetListScreen extends StatelessWidget {
  const PetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Питомцы — Зоосалон'),
        actions: [
          Consumer<PetListNotifier>(
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
          Consumer<PetListNotifier>(
            builder: (context, notifier, _) {
              if (!notifier.hasSelection) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Удалить выбранные',
                onPressed: () => _confirmBulkDelete(context, notifier),
              );
            },
          ),
        ],
      ),
      body: Consumer<PetListNotifier>(
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
                    final next = notifier.query.copyWith(page: page);
                    notifier.applyQuery(next);
                    _syncUrl(context, next);
                  },
                  onSizeChanged: (size) {
                    final next = notifier.query.copyWith(size: size, page: 1);
                    notifier.applyQuery(next);
                    _syncUrl(context, next);
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, PetListNotifier notifier) {
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
              return _PetCardsList(notifier: notifier);
            }
            return EntityTable<Pet>(
              items: notifier.result.items,
              idOf: (p) => p.id,
              selected: notifier.selected,
              onToggleSelect: notifier.toggleSelection,
              sortField: notifier.query.sortField,
              sortAscending: notifier.query.sortAscending,
              isDeleted: (p) => p.isDeleted,
              onSort: (field) {
                final next = notifier.query.copyWith(
                  sortField: field,
                  sortAscending: field == notifier.query.sortField
                      ? !notifier.query.sortAscending
                      : true,
                );
                notifier.applyQuery(next);
                _syncUrl(context, next);
              },
              columns: [
                TableColumnSpec(
                  label: 'Имя',
                  sortField: 'name',
                  build: (p) => Text(
                    p.name,
                    style: TextStyle(
                      decoration: p.isDeleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                TableColumnSpec(
                  label: 'Вид',
                  sortField: 'species',
                  build: (p) => Text(_speciesLabel(p.species)),
                ),
                TableColumnSpec(
                  label: 'Порода',
                  build: (p) => Text(p.breed),
                ),
                TableColumnSpec(
                  label: 'Возраст (мес.)',
                  sortField: 'ageMonths',
                  numeric: true,
                  build: (p) => Text('${p.ageMonths}'),
                ),
                TableColumnSpec(
                  label: 'Вес (кг)',
                  sortField: 'weightKg',
                  numeric: true,
                  build: (p) => Text(p.weightKg.toStringAsFixed(1)),
                ),
              ],
              actions: (p) => [
                if (p.isDeleted)
                  IconButton(
                    icon: const Icon(Icons.restore, color: Colors.green),
                    tooltip: 'Восстановить',
                    onPressed: () => notifier.restore(p.id),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Карточка',
                    onPressed: () => context.go('/pets/${p.id}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Удалить',
                    onPressed: () => _confirmDelete(context, notifier, p),
                  ),
                ],
              ],
            );
          },
        );
    }
  }

  void _syncUrl(BuildContext context, PetQuery q) {
    final params = <String, String>{};
    if (q.search.isNotEmpty) params['search'] = q.search;
    if (q.species != null) params['species'] = q.species!;
    if (q.ownerId != null) params['ownerId'] = '${q.ownerId}';
    if (q.ageFrom != null) params['ageFrom'] = '${q.ageFrom}';
    if (q.ageTo != null) params['ageTo'] = '${q.ageTo}';
    if (q.sortField != 'name' || !q.sortAscending) {
      params['sort'] = '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}';
    }
    if (q.page != 1) params['page'] = '${q.page}';
    if (q.size != 10) params['size'] = '${q.size}';
    if (q.includeDeleted) params['includeDeleted'] = 'true';

    final uri = Uri(path: '/pets', queryParameters: params.isEmpty ? null : params);
    context.go(uri.toString());
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PetListNotifier notifier,
    Pet pet,
  ) async {
    final hard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление питомца'),
        content: Text('Удалить «${pet.name}»?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Логически'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Физически'),
          ),
        ],
      ),
    );
    if (hard == null) return;
    if (hard) {
      await notifier.hardDelete(pet.id);
    } else {
      await notifier.softDelete(pet.id);
    }
  }

  Future<void> _confirmBulkDelete(
    BuildContext context,
    PetListNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление выбранных'),
        content: Text('Удалить логически ${notifier.selected.length} записей?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
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

  static String _speciesLabel(String s) {
    return switch (s) {
      'dog' => 'Собака',
      'cat' => 'Кошка',
      'rabbit' => 'Кролик',
      'bird' => 'Птица',
      _ => s,
    };
  }
}

class _FiltersPanel extends StatelessWidget {
  final PetListNotifier notifier;

  const _FiltersPanel({required this.notifier});

  void _apply(BuildContext context, PetQuery next) {
    notifier.applyQuery(next);
    final params = <String, String>{};
    if (next.search.isNotEmpty) params['search'] = next.search;
    if (next.species != null) params['species'] = next.species!;
    if (next.ownerId != null) params['ownerId'] = '${next.ownerId}';
    if (next.ageFrom != null) params['ageFrom'] = '${next.ageFrom}';
    if (next.ageTo != null) params['ageTo'] = '${next.ageTo}';
    if (next.sortField != 'name' || !next.sortAscending) {
      params['sort'] = '${next.sortField},${next.sortAscending ? 'asc' : 'desc'}';
    }
    if (next.page != 1) params['page'] = '${next.page}';
    if (next.size != 10) params['size'] = '${next.size}';
    if (next.includeDeleted) params['includeDeleted'] = 'true';
    final uri = Uri(path: '/pets', queryParameters: params.isEmpty ? null : params);
    context.go(uri.toString());
  }

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
              hintText: 'Поиск по имени или породе...',
              onChanged: (v) => _apply(context, q.copyWith(search: v)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String?>(
                    initialValue: q.species,
                    decoration: const InputDecoration(
                      labelText: 'Вид',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Все')),
                      DropdownMenuItem(value: 'dog', child: Text('Собака')),
                      DropdownMenuItem(value: 'cat', child: Text('Кошка')),
                      DropdownMenuItem(value: 'rabbit', child: Text('Кролик')),
                      DropdownMenuItem(value: 'bird', child: Text('Птица')),
                    ],
                    onChanged: (v) => _apply(context, q.copyWith(species: v)),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    initialValue: q.ageFrom?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Возраст от',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      _apply(context, q.copyWith(ageFrom: n));
                    },
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    initialValue: q.ageTo?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Возраст до',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      _apply(context, q.copyWith(ageTo: n));
                    },
                  ),
                ),
                FilterChip(
                  label: const Text('Показать удалённые'),
                  selected: q.includeDeleted,
                  onSelected: (v) => _apply(context, q.copyWith(includeDeleted: v)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PetCardsList extends StatelessWidget {
  final PetListNotifier notifier;

  const _PetCardsList({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: notifier.result.items.length,
      itemBuilder: (context, index) {
        final p = notifier.result.items[index];
        return Card(
          color: p.isDeleted ? Colors.red.withValues(alpha: 0.08) : null,
          child: ListTile(
            leading: Checkbox(
              value: notifier.selected.contains(p.id),
              onChanged: (_) => notifier.toggleSelection(p.id),
            ),
            title: Text(
              p.name,
              style: TextStyle(
                decoration: p.isDeleted ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${PetListScreen._speciesLabel(p.species)} · ${p.breed}\n'
              'Возраст: ${p.ageMonths} мес. · Вес: ${p.weightKg} кг',
            ),
            isThreeLine: true,
            trailing: p.isDeleted
                ? IconButton(
                    icon: const Icon(Icons.restore, color: Colors.green),
                    onPressed: () => notifier.restore(p.id),
                  )
                : PopupMenuButton(
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'view', child: Text('Карточка')),
                      const PopupMenuItem(value: 'soft', child: Text('Удалить логически')),
                      const PopupMenuItem(value: 'hard', child: Text('Удалить физически')),
                    ],
                    onSelected: (v) {
                      if (v == 'view') context.go('/pets/${p.id}');
                      if (v == 'soft') notifier.softDelete(p.id);
                      if (v == 'hard') notifier.hardDelete(p.id);
                    },
                  ),
          ),
        );
      },
    );
  }
}