import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/role.dart';
import '../state/auth_notifier.dart';
import '../models/pet.dart';
import '../models/pet_passport.dart';
import '../models/pet_passport_query.dart';
import '../repositories/pet_repository.dart';
import '../state/load_status.dart';
import '../state/passport_list_notifier.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/search_field.dart';

class PassportListScreen extends StatefulWidget {
  const PassportListScreen({super.key});

  @override
  State<PassportListScreen> createState() => _PassportListScreenState();
}

class _PassportListScreenState extends State<PassportListScreen> {
  List<Pet> _pets = [];

  @override
  void initState() {
    super.initState();
    context.read<PetRepository>().findAllActive().then((v) {
      if (mounted) setState(() => _pets = v);
    });
  }

  String _petName(int id) {
    for (final p in _pets) {
      if (p.id == id) return p.name;
    }
    return '#$id';
  }

  void _syncPassport(BuildContext context, PetPassportQuery q) {
    final params = <String, String>{};
    if (q.search.isNotEmpty) params['search'] = q.search;
    if (q.petId != null) params['petId'] = '${q.petId}';
    if (q.hasMicrochip == true) params['hasMicrochip'] = 'true';
    if (q.page != 1) params['page'] = '${q.page}';
    if (q.size != 10) params['size'] = '${q.size}';
    if (q.includeDeleted) params['includeDeleted'] = 'true';
    context.go(
      Uri(path: '/passports', queryParameters: params.isEmpty ? null : params)
          .toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PassportListNotifier>();
    final fmt = DateFormat('dd.MM.yyyy');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Паспорта'),
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
                final ok = await context.push('/passports/new');
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
                    hintText: 'Поиск по номеру или микрочипу...',
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
                        width: 240,
                        child: DropdownButtonFormField<int?>(
                          isExpanded: true,
                          initialValue: notifier.query.petId,
                          decoration: const InputDecoration(
                            labelText: 'Питомец',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Все'),
                            ),
                            for (final p in _pets)
                              DropdownMenuItem(
                                value: p.id,
                                child: Text(p.name),
                              ),
                          ],
                          onChanged: (v) {
                            final next =
                                notifier.query.copyWith(petId: v, page: 1);
                            notifier.applyQuery(next);
                            _syncPassport(context, next);
                          },
                        ),
                      ),
                      FilterChip(
                        label: const Text('Только с микрочипом'),
                        selected: notifier.query.hasMicrochip == true,
                        onSelected: (v) {
                          final next = notifier.query.copyWith(
                            hasMicrochip: v ? true : null,
                            page: 1,
                          );
                          notifier.applyQuery(next);
                          _syncPassport(context, next);
                        },
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
          Expanded(child: _buildBody(context, notifier, fmt)),
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

  Widget _buildBody(
    BuildContext context,
    PassportListNotifier notifier,
    DateFormat fmt,
  ) {
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
        if (notifier.result.items.isEmpty) {
          return const Center(child: Text('Нет паспортов'));
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: notifier.result.items.length,
                itemBuilder: (context, index) {
                  final p = notifier.result.items[index];
                  return Card(
                    color: p.isDeleted
                        ? Colors.red.withValues(alpha: 0.08)
                        : null,
                    child: ListTile(
                      leading: Checkbox(
                        value: notifier.selected.contains(p.id),
                        onChanged: (_) => notifier.toggleSelection(p.id),
                      ),
                      title: Text(
                        p.number,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          decoration: p.isDeleted
                              ? TextDecoration.lineThrough
                              : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${_petName(p.petId)} · ${p.microchip}\n${fmt.format(p.issuedAt)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: p.isDeleted
                          ? IconButton(
                              tooltip: 'Восстановить',
                              icon: const Icon(
                                Icons.restore,
                                color: Colors.green,
                              ),
                              onPressed: () => notifier.restore(p.id),
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
                                if (v == 'view') {
                                  context.go('/passports/${p.id}'); }
                                if (v == 'edit') {
                                  final ok = await context.push(
                                    '/passports/${p.id}/edit',
                                  );
                                  if (ok == true) notifier.load();
                                }
                                if (!context.mounted) return;
                                if (v == 'del') {
                                  await _delete(context, notifier, p);
                                }
                              },
                            ),
                    ),
                  );
                },
              );
            }
            return EntityTable<PetPassport>(
              items: notifier.result.items,
              idOf: (p) => p.id,
              selected: notifier.selected,
              onToggleSelect: notifier.toggleSelection,
              sortField: notifier.query.sortField,
              sortAscending: notifier.query.sortAscending,
              isDeleted: (p) => p.isDeleted,
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
                  label: 'Номер',
                  sortField: 'number',
                  build: (p) => Text(p.number),
                ),
                TableColumnSpec(
                  label: 'Питомец',
                  build: (p) => Text(_petName(p.petId)),
                ),
                TableColumnSpec(
                  label: 'Микрочип',
                  sortField: 'microchip',
                  build: (p) => Text(p.microchip),
                ),
                TableColumnSpec(
                  label: 'Выдан',
                  sortField: 'issuedAt',
                  build: (p) => Text(fmt.format(p.issuedAt)),
                ),
              ],
              actions: (p) => [
                if (p.isDeleted)
                  IconButton(
                    icon: const Icon(Icons.restore, color: Colors.green),
                    onPressed: () => notifier.restore(p.id),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () => context.go('/passports/${p.id}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final ok = await context.push('/passports/${p.id}/edit');
                      if (ok == true) notifier.load();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(context, notifier, p),
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
    PassportListNotifier notifier,
    PetPassport p,
  ) async {
    final hard = await confirmDeleteMode(
      context,
      title: 'Удаление паспорта',
      body: 'Удалить «${p.number}»?',
    );
    if (hard == null) return;
    if (hard) {
      await notifier.hardDelete(p.id);
    } else {
      await notifier.softDelete(p.id);
    }
  }
}
