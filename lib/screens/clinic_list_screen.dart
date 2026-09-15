import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/role.dart';
import '../state/auth_notifier.dart';
import '../models/clinic.dart';
import '../repositories/pet_repository.dart';
import '../repositories/service_repository.dart';
import '../state/clinic_list_notifier.dart';
import '../state/load_status.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/search_field.dart';

class ClinicListScreen extends StatelessWidget {
  const ClinicListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClinicListNotifier>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Филиалы'),
        actions: [
          if (notifier.hasSelection)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => notifier.deleteSelected(),
            ),
          if (context.watch<AuthNotifier>().has(Role.staff))
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final ok = await context.push('/clinics/new');
                if (ok == true) notifier.load();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SearchField(
                    initialValue: notifier.query.search,
                    hintText: 'Поиск по названию, адресу, городу...',
                    onChanged: (v) => notifier.applyQuery(
                      notifier.query.copyWith(search: v, page: 1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String?>(
                          isExpanded: true,
                          initialValue: notifier.query.city,
                          decoration: const InputDecoration(
                            labelText: 'Город',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Все'),
                            ),
                            for (final city in notifier.cities)
                              DropdownMenuItem(value: city, child: Text(city)),
                          ],
                          onChanged: (v) => notifier.applyQuery(
                            notifier.query.copyWith(city: v, page: 1),
                          ),
                        ),
                      ),
                      FilterChip(
                        label: const Text('Показать удалённые'),
                        selected: notifier.query.includeDeleted,
                        onSelected: (v) => notifier.applyQuery(
                          notifier.query.copyWith(includeDeleted: v, page: 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (notifier.loading) const LinearProgressIndicator(),
          Expanded(child: _body(context, notifier)),
          if (notifier.status == LoadStatus.success)
            PaginationBar(
              result: notifier.result,
              currentSize: notifier.query.size,
              onPageChanged: (p) =>
                  notifier.applyQuery(notifier.query.copyWith(page: p)),
              onSizeChanged: (s) => notifier.applyQuery(
                notifier.query.copyWith(size: s, page: 1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, ClinicListNotifier notifier) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notifier.error ?? 'Ошибка', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => notifier.load(),
                child: const Text('Повторить'),
              ),
            ],
          ),
        );
      case LoadStatus.success:
        final items = notifier.result.items;
        if (items.isEmpty) return const Center(child: Text('Нет филиалов'));
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final c = items[index];
                  return Card(
                    color: c.isDeleted
                        ? Colors.red.withValues(alpha: 0.08)
                        : null,
                    child: ListTile(
                      leading: Checkbox(
                        value: notifier.selected.contains(c.id),
                        onChanged: (_) => notifier.toggleSelection(c.id),
                      ),
                      title: Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          decoration: c.isDeleted
                              ? TextDecoration.lineThrough
                              : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${c.city}\n${c.address}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: c.isDeleted
                          ? IconButton(
                              tooltip: 'Восстановить',
                              icon: const Icon(
                                Icons.restore,
                                color: Colors.green,
                              ),
                              onPressed: () => notifier.restore(c.id),
                            )
                          : PopupMenuButton<String>(
                              tooltip: 'Действия',
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'view',
                                  child: Text('Открыть'),
                                ),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Изменить'),
                                ),
                                PopupMenuItem(
                                  value: 'del',
                                  child: Text('Удалить'),
                                ),
                              ],
                              onSelected: (v) async {
                                if (v == 'view') context.go('/clinics/${c.id}');
                                if (v == 'edit') {
                                  final ok = await context.push(
                                    '/clinics/${c.id}/edit',
                                  );
                                  if (ok == true) notifier.load();
                                }
                                if (!context.mounted) return;
                                if (v == 'del') {
                                  await _delete(context, notifier, c);
                                  
                                }
                              },
                            ),
                    ),
                  );
                },
              );
            }
            return EntityTable<Clinic>(
              items: items,
              idOf: (c) => c.id,
              selected: notifier.selected,
              onToggleSelect: notifier.toggleSelection,
              sortField: notifier.query.sortField,
              sortAscending: notifier.query.sortAscending,
              isDeleted: (c) => c.isDeleted,
              onSort: (field) {
                final q = notifier.query;
                notifier.applyQuery(
                  q.copyWith(
                    sortField: field,
                    sortAscending: field == q.sortField
                        ? !q.sortAscending
                        : true,
                  ),
                );
              },
              columns: [
                TableColumnSpec(
                  label: 'Название',
                  sortField: 'name',
                  build: (c) => Text(c.name),
                ),
                TableColumnSpec(
                  label: 'Город',
                  sortField: 'city',
                  build: (c) => Text(c.city),
                ),
                TableColumnSpec(
                  label: 'Адрес',
                  sortField: 'address',
                  build: (c) => Text(c.address),
                ),
                TableColumnSpec(label: 'Телефон', build: (c) => Text(c.phone)),
              ],
              actions: (c) => [
                if (c.isDeleted)
                  IconButton(
                    icon: const Icon(Icons.restore, color: Colors.green),
                    onPressed: () => notifier.restore(c.id),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () => context.go('/clinics/${c.id}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final ok = await context.push('/clinics/${c.id}/edit');
                      if (ok == true) notifier.load();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(context, notifier, c),
                  ),
                ],
              ],
            );
          },
        );
    }
  }

  Future<void> _delete(
    BuildContext context,
    ClinicListNotifier notifier,
    Clinic c,
  ) async {
    final serviceRepo = context.read<ServiceRepository>();
    final petRepo = context.read<PetRepository>();
    final serviceCount = await serviceRepo.countByClinic(c.id);
    final petCount = await petRepo.countByClinic(c.id);
    if (!context.mounted) return;
    if (serviceCount > 0 || petCount > 0) {
      await showBlockedDelete(
        context,
        title: 'Невозможно удалить',
        body:
            'Филиал «${c.name}» связан с $serviceCount услугами и $petCount питомцами. '
            'Удалите или переназначьте связанные записи.',
      );
      return;
    }
    final hard = await confirmDeleteMode(
      context,
      title: 'Удаление филиала',
      body: 'Удалить «${c.name}»?',
    );
    if (hard == null) return;
    if (hard) {
      await notifier.hardDelete(c.id);
    } else {
      await notifier.softDelete(c.id);
    }
  }
}
