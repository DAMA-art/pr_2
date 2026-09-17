import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/clinic.dart';
import '../models/groomer.dart';
import '../models/groomer_query.dart';
import '../models/role.dart';
import '../repositories/clinic_repository.dart';
import '../state/auth_notifier.dart';
import '../state/groomer_list_notifier.dart';
import '../state/load_status.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/search_field.dart';

class GroomerListScreen extends StatefulWidget {
  const GroomerListScreen({super.key});

  @override
  State<GroomerListScreen> createState() => _GroomerListScreenState();
}

class _GroomerListScreenState extends State<GroomerListScreen> {
  List<Clinic> _clinics = [];

  @override
  void initState() {
    super.initState();
    context.read<ClinicRepository>().findAllActive().then((v) {
      if (mounted) setState(() => _clinics = v);
    });
  }

  void _sync(GroomerQuery q) {
    final params = <String, String>{};
    if (q.search.isNotEmpty) params['search'] = q.search;
    if (q.clinicId != null) params['clinicId'] = '${q.clinicId}';
    if (q.specialization != null) params['spec'] = q.specialization!;
    if (q.page != 1) params['page'] = '${q.page}';
    if (q.size != 10) params['size'] = '${q.size}';
    if (q.includeDeleted) params['includeDeleted'] = 'true';
    context.go(
      Uri(path: '/groomers', queryParameters: params.isEmpty ? null : params)
          .toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<GroomerListNotifier>();
    final canEdit = context.watch<AuthNotifier>().has(Role.staff);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мастера'),
        actions: [
          if (notifier.hasSelection)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => notifier.deleteSelected(),
            ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final ok = await context.push('/groomers/new');
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
                children: [
                  SearchField(
                    initialValue: notifier.query.search,
                    hintText: 'Поиск по имени или телефону...',
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
                        width: 220,
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
                              DropdownMenuItem(value: c.id, child: Text(c.name)),
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
                        child: DropdownButtonFormField<String?>(
                          isExpanded: true,
                          initialValue: notifier.query.specialization,
                          decoration: const InputDecoration(
                            labelText: 'Специализация',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Все')),
                            DropdownMenuItem(value: 'all', child: Text('Все виды')),
                            DropdownMenuItem(value: 'dogs', child: Text('Собаки')),
                            DropdownMenuItem(value: 'cats', child: Text('Кошки')),
                          ],
                          onChanged: (v) {
                            final next = notifier.query
                                .copyWith(specialization: v, page: 1);
                            notifier.applyQuery(next);
                            _sync(next);
                          },
                        ),
                      ),
                      FilterChip(
                        label: const Text('Показать удалённых'),
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
          Expanded(child: _body(context, notifier, canEdit)),
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

  Widget _body(
    BuildContext context,
    GroomerListNotifier notifier,
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
              Text(notifier.error ?? 'Ошибка'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: notifier.load,
                child: const Text('Повторить'),
              ),
            ],
          ),
        );
      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          return const Center(child: Text('Нет мастеров'));
        }
        return EntityTable<Groomer>(
          items: notifier.result.items,
          idOf: (g) => g.id,
          selected: notifier.selected,
          onToggleSelect: notifier.toggleSelection,
          sortField: notifier.query.sortField,
          sortAscending: notifier.query.sortAscending,
          isDeleted: (g) => g.isDeleted,
          onSort: (field) {
            final q = notifier.query;
            final next = q.copyWith(
              sortField: field,
              sortAscending: field == q.sortField ? !q.sortAscending : true,
            );
            notifier.applyQuery(next);
            _sync(next);
          },
          columns: [
            TableColumnSpec(
              label: 'ФИО',
              sortField: 'full_name',
              build: (g) => Text(g.fullName),
            ),
            TableColumnSpec(
              label: 'Специализация',
              build: (g) => Text(g.specializationLabel),
            ),
            TableColumnSpec(
              label: 'Филиал',
              build: (g) => Text(g.clinicName ?? '—'),
            ),
            TableColumnSpec(
              label: 'Стаж, лет',
              numeric: true,
              build: (g) => Text('${g.experienceYears}'),
            ),
          ],
          actions: (g) => [
            if (g.isDeleted)
              IconButton(
                icon: const Icon(Icons.restore, color: Colors.green),
                onPressed: () => notifier.restore(g.id),
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () => context.go('/groomers/${g.id}'),
              ),
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final ok = await context.push('/groomers/${g.id}/edit');
                    if (ok == true) notifier.load();
                  },
                ),
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final hard = await confirmDeleteMode(
                      context,
                      title: 'Удаление мастера',
                      body: 'Удалить «${g.fullName}»?',
                    );
                    if (hard == null) return;
                    if (hard) {
                      await notifier.hardDelete(g.id);
                    } else {
                      await notifier.softDelete(g.id);
                    }
                  },
                ),
            ],
          ],
        );
    }
  }
}
