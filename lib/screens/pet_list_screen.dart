import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/pet.dart';
import '../models/pet_query.dart';
import '../models/clinic.dart';
import '../repositories/clinic_repository.dart';
import '../repositories/pet_passport_repository.dart';
import '../state/load_status.dart';
import '../state/pet_list_notifier.dart';
import '../utils/species.dart';
import '../widgets/confirm_delete.dart';
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
                  child: Text('Выбрано: ${notifier.selected.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Создать',
            onPressed: () async {
              final ok = await context.push('/pets/new');
              if (ok == true && context.mounted) {
                context.read<PetListNotifier>().load();
              }
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
              FilledButton(onPressed: () => notifier.load(), child: const Text('Повторить')),
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
                  sortAscending: field == notifier.query.sortField ? !notifier.query.sortAscending : true,
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
                    style: TextStyle(decoration: p.isDeleted ? TextDecoration.lineThrough : null),
                  ),
                ),
                TableColumnSpec(label: 'Чип', sortField: 'chipNumber', build: (p) => Text(p.chipNumber)),
                TableColumnSpec(label: 'Вид', sortField: 'species', build: (p) => Text(speciesLabel(p.species))),
                TableColumnSpec(label: 'Порода', build: (p) => Text(p.breed)),
                TableColumnSpec(
                  label: 'Возраст (мес.)',
                  sortField: 'ageMonths',
                  numeric: true,
                  build: (p) => Text('${p.ageMonths}'),
                ),
              ],
              actions: (p) => [
                if (p.isDeleted)
                  IconButton(
                    icon: const Icon(Icons.restore, color: Colors.green),
                    onPressed: () => notifier.restore(p.id),
                  )
                else ...[
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/pets/${p.id}')),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
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
    if (q.clinicId != null) params['clinicId'] = '${q.clinicId}';
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

  Future<void> _confirmDelete(BuildContext context, PetListNotifier notifier, Pet pet) async {
    final hard = await confirmDeleteMode(
      context,
      title: 'Удаление питомца',
      body: 'Удалить «${pet.name}»?',
    );
    if (hard == null) return;
    if (!context.mounted) return;
    final passportRepo = context.read<PetPassportRepository>();
    final passport = await passportRepo.findByPetId(pet.id);
    if (hard) {
      if (passport != null) await passportRepo.hardDelete(passport.id);
      await notifier.hardDelete(pet.id);
    } else {
      if (passport != null) await passportRepo.softDelete(passport.id);
      await notifier.softDelete(pet.id);
    }
  }

  Future<void> _confirmBulkDelete(BuildContext context, PetListNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление выбранных'),
        content: Text('Удалить логически ${notifier.selected.length} записей?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirmed == true) await notifier.deleteSelected();
  }
}

class _FiltersPanel extends StatefulWidget {
  final PetListNotifier notifier;
  const _FiltersPanel({required this.notifier});

  @override
  State<_FiltersPanel> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<_FiltersPanel> {
  List<Clinic> _clinics = [];

  @override
  void initState() {
    super.initState();
    context.read<ClinicRepository>().findAllActive().then((v) {
      if (mounted) setState(() => _clinics = v);
    });
  }

  void _apply(PetQuery next) {
    widget.notifier.applyQuery(next);
    final params = <String, String>{};
    if (next.search.isNotEmpty) params['search'] = next.search;
    if (next.species != null) params['species'] = next.species!;
    if (next.ownerId != null) params['ownerId'] = '${next.ownerId}';
    if (next.clinicId != null) params['clinicId'] = '${next.clinicId}';
    if (next.ageFrom != null) params['ageFrom'] = '${next.ageFrom}';
    if (next.ageTo != null) params['ageTo'] = '${next.ageTo}';
    if (next.sortField != 'name' || !next.sortAscending) {
      params['sort'] = '${next.sortField},${next.sortAscending ? 'asc' : 'desc'}';
    }
    if (next.page != 1) params['page'] = '${next.page}';
    if (next.size != 10) params['size'] = '${next.size}';
    if (next.includeDeleted) params['includeDeleted'] = 'true';
    context.go(Uri(path: '/pets', queryParameters: params.isEmpty ? null : params).toString());
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.notifier.query;
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchField(
              initialValue: q.search,
              hintText: 'Поиск по кличке, породе или чипу...',
              onChanged: (v) => _apply(q.copyWith(search: v, page: 1)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: q.species,
                    decoration: const InputDecoration(
                      labelText: 'Вид',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все')),
                      for (final item in speciesItems)
                        DropdownMenuItem(value: item.$1, child: Text(item.$2)),
                    ],
                    onChanged: (v) => _apply(q.copyWith(species: v, page: 1)),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<int?>(
                    isExpanded: true,
                    initialValue: q.clinicId,
                    decoration: const InputDecoration(
                      labelText: 'Филиал',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все')),
                      for (final c in _clinics)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => _apply(q.copyWith(clinicId: v, page: 1)),
                  ),
                ),
                FilterChip(
                  label: const Text('Показать удалённые'),
                  selected: q.includeDeleted,
                  onSelected: (v) => _apply(q.copyWith(includeDeleted: v, page: 1)),
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
            subtitle: Text('${speciesLabel(p.species)} · ${p.breed}\nЧип: ${p.chipNumber}'),
            isThreeLine: true,
            trailing: p.isDeleted
                ? IconButton(
                    icon: const Icon(Icons.restore, color: Colors.green),
                    onPressed: () => notifier.restore(p.id),
                  )
                : PopupMenuButton(
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'view', child: Text('Карточка')),
                      PopupMenuItem(value: 'soft', child: Text('Удалить логически')),
                      PopupMenuItem(value: 'hard', child: Text('Удалить физически')),
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
