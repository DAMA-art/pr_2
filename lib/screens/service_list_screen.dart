import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/role.dart';
import '../models/clinic.dart';
import '../models/service.dart';
import '../models/service_query.dart';
import '../repositories/clinic_repository.dart';
import '../state/load_status.dart';
import '../state/auth_notifier.dart';
import '../state/service_list_notifier.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/search_field.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  List<Clinic> _clinics = [];

  void _sync(ServiceQuery q) {
    final params = <String, String>{};
    if (q.search.isNotEmpty) params['search'] = q.search;
    if (q.clinicId != null) params['clinicId'] = '${q.clinicId}';
    if (q.maxPrice != null) params['maxPrice'] = '${q.maxPrice}';
    if (q.sortField != 'name' || !q.sortAscending) {
      params['sort'] = '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}';
    }
    if (q.page != 1) params['page'] = '${q.page}';
    if (q.size != 10) params['size'] = '${q.size}';
    if (q.includeDeleted) params['includeDeleted'] = 'true';
    context.go(
      Uri(path: '/services', queryParameters: params.isEmpty ? null : params)
          .toString(),
    );
  }

  @override
  void initState() {
    super.initState();
    context.read<ClinicRepository>().findAllActive().then((v) {
      if (mounted) setState(() => _clinics = v);
    });
  }

  String _clinicName(int id) {
    for (final c in _clinics) {
      if (c.id == id) return c.name;
    }
    return '#$id';
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ServiceListNotifier>();
    final canEdit = context.watch<AuthNotifier>().has(Role.staff);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Услуги'),
        actions: [
          if (canEdit && notifier.hasSelection)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => notifier.deleteSelected(),
            ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final ok = await context.push('/services/new');
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
                    hintText: 'Поиск по названию или описанию...',
                    onChanged: (v) {
                      final next = notifier.query.copyWith(search: v, page: 1);
                      notifier.applyQuery(next);
                      _sync(next);
                    },
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
                          initialValue: notifier.query.clinicId,
                          decoration: const InputDecoration(
                            labelText: 'Филиал',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Все'),
                            ),
                            for (final c in _clinics)
                              DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  c.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (v) {
                            final next =
                                notifier.query.copyWith(clinicId: v, page: 1);
                            notifier.applyQuery(next);
                            _sync(next);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<double?>(
                          isExpanded: true,
                          initialValue: notifier.query.maxPrice,
                          decoration: const InputDecoration(
                            labelText: 'Цена до',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Любая')),
                            DropdownMenuItem(value: 1000, child: Text('1 000 ₽')),
                            DropdownMenuItem(value: 2500, child: Text('2 500 ₽')),
                            DropdownMenuItem(value: 5000, child: Text('5 000 ₽')),
                          ],
                          onChanged: (v) {
                            final next =
                                notifier.query.copyWith(maxPrice: v, page: 1);
                            notifier.applyQuery(next);
                            _sync(next);
                          },
                        ),
                      ),
                      if (canEdit)
                        FilterChip(
                          label: const Text('Показать удалённые'),
                          selected: notifier.query.includeDeleted,
                          onSelected: (v) {
                            final next = notifier.query
                                .copyWith(includeDeleted: v, page: 1);
                            notifier.applyQuery(next);
                            _sync(next);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (notifier.loading) const LinearProgressIndicator(),
          Expanded(child: _buildBody(context, notifier, canEdit)),
          if (notifier.status == LoadStatus.success)
            PaginationBar(
              result: notifier.result,
              currentSize: notifier.query.size,
              onPageChanged: (p) {
                final next = notifier.query.copyWith(page: p);
                notifier.applyQuery(next);
                _sync(next);
              },
              onSizeChanged: (s) {
                final next = notifier.query.copyWith(size: s, page: 1);
                notifier.applyQuery(next);
                _sync(next);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ServiceListNotifier notifier,
    bool canEdit,
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
          return const Center(child: Text('Нет услуг'));
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: notifier.result.items.length,
                itemBuilder: (context, index) {
                  final s = notifier.result.items[index];
                  return Card(
                    color: s.isDeleted
                        ? Colors.red.withValues(alpha: 0.08)
                        : null,
                    child: ListTile(
                      leading: canEdit
                          ? Checkbox(
                              value: notifier.selected.contains(s.id),
                              onChanged: (_) => notifier.toggleSelection(s.id),
                            )
                          : const Icon(Icons.spa),
                      title: Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          decoration: s.isDeleted
                              ? TextDecoration.lineThrough
                              : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${s.price.toStringAsFixed(0)} ₽ · ${_clinicName(s.clinicId)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: s.isDeleted && canEdit
                          ? IconButton(
                              tooltip: 'Восстановить',
                              icon: const Icon(
                                Icons.restore,
                                color: Colors.green,
                              ),
                              onPressed: () => notifier.restore(s.id),
                            )
                          : PopupMenuButton<String>(
                              tooltip: 'Действия',
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Text('Открыть'),
                                ),
                                if (canEdit)
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Изменить'),
                                  ),
                                if (canEdit)
                                  const PopupMenuItem(
                                    value: 'del',
                                    child: Text('Удалить'),
                                  ),
                              ],
                              onSelected: (v) async {
                                if (v == 'view') {
                                  context.go('/services/${s.id}'); }
                                if (v == 'edit') {
                                  final ok = await context.push(
                                    '/services/${s.id}/edit',
                                  );
                                  if (ok == true) notifier.load();
                                }
                                if (!context.mounted) return;
                                if (v == 'del') {
                                  await _delete(context, notifier, s);
                                }
                              },
                            ),
                    ),
                  );
                },
              );
            }
            return EntityTable<Service>(
              items: notifier.result.items,
              idOf: (s) => s.id,
              selected: canEdit ? notifier.selected : const {},
              onToggleSelect: canEdit ? notifier.toggleSelection : null,
              sortField: notifier.query.sortField,
              sortAscending: notifier.query.sortAscending,
              isDeleted: (s) => s.isDeleted,
              onSort: (field) {
                final q = notifier.query;
                final next = q.copyWith(
                  sortField: field,
                  sortAscending:
                      field == q.sortField ? !q.sortAscending : true,
                );
                notifier.applyQuery(next);
                _sync(next);
              },
              columns: [
                TableColumnSpec(
                  label: 'Название',
                  sortField: 'name',
                  build: (s) => Text(s.name),
                ),
                TableColumnSpec(
                  label: 'Цена',
                  sortField: 'price',
                  numeric: true,
                  build: (s) => Text('${s.price.toStringAsFixed(0)} ₽'),
                ),
                TableColumnSpec(
                  label: 'Филиал',
                  sortField: 'clinicId',
                  build: (s) => Text(_clinicName(s.clinicId)),
                ),
              ],
              actions: (s) => [
                if (s.isDeleted && canEdit)
                  IconButton(
                    icon: const Icon(Icons.restore, color: Colors.green),
                    onPressed: () => notifier.restore(s.id),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () => context.go('/services/${s.id}'),
                  ),
                  if (canEdit)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final ok = await context.push('/services/${s.id}/edit');
                        if (ok == true) notifier.load();
                      },
                    ),
                  if (canEdit)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(context, notifier, s),
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
    ServiceListNotifier notifier,
    Service s,
  ) async {
    final hard = await confirmDeleteMode(
      context,
      title: 'Удаление услуги',
      body: 'Удалить «${s.name}»?',
    );
    if (hard == null) return;
    if (hard) {
      await notifier.hardDelete(s.id);
    } else {
      await notifier.softDelete(s.id);
    }
  }
}
