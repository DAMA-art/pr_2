import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/role.dart';
import '../models/clinic.dart';
import '../models/service.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Услуги'),
        actions: [
          if (notifier.hasSelection)
            IconButton(
              icon: const Icon(Icons.delete), 
              onPressed: () => notifier.deleteSelected()
            ),
          if (context.watch<AuthNotifier>().has(Role.staff))
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
                    onChanged: (v) => notifier.applyQuery(notifier.query.copyWith(search: v, page: 1)),
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
                            const DropdownMenuItem(value: null, child: Text('Все')),
                            for (final c in _clinics)
                              DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name, overflow: TextOverflow.ellipsis),
                              ),
                          ],
                          onChanged: (v) =>
                              notifier.applyQuery(notifier.query.copyWith(clinicId: v, page: 1)),
                        ),
                      ),
                      FilterChip(
                        label: const Text('Показать удалённые'),
                        selected: notifier.query.includeDeleted,
                        onSelected: (v) =>
                            notifier.applyQuery(notifier.query.copyWith(includeDeleted: v, page: 1)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (notifier.loading) const LinearProgressIndicator(),
          Expanded(child: _buildBody(context, notifier)),
          if (notifier.status == LoadStatus.success)
            PaginationBar(
              result: notifier.result,
              currentSize: notifier.query.size,
              onPageChanged: (p) => notifier.applyQuery(notifier.query.copyWith(page: p)),
              onSizeChanged: (s) => notifier.applyQuery(notifier.query.copyWith(size: s, page: 1)),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ServiceListNotifier notifier) {
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
              FilledButton(onPressed: () => notifier.load(), child: const Text('Повторить')),
            ],
          ),
        );
      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          return const Center(child: Text('Нет услуг'));
        }
        return EntityTable<Service>(
          items: notifier.result.items,
          idOf: (s) => s.id,
          selected: notifier.selected,
          onToggleSelect: notifier.toggleSelection,
          sortField: notifier.query.sortField,
          sortAscending: notifier.query.sortAscending,
          isDeleted: (s) => s.isDeleted,
          onSort: (field) {
            final q = notifier.query;
            notifier.applyQuery(q.copyWith(
              sortField: field,
              sortAscending: field == q.sortField ? !q.sortAscending : true,
            ));
          },
          columns: [
            TableColumnSpec(label: 'Название', sortField: 'name', build: (s) => Text(s.name)),
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
            if (s.isDeleted)
              IconButton(
                icon: const Icon(Icons.restore, color: Colors.green),
                onPressed: () => notifier.restore(s.id),
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () => context.go('/services/${s.id}'),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final ok = await context.push('/services/${s.id}/edit');
                  if (ok == true) notifier.load();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, notifier, s),
              ),
            ],
          ],
        );
    }
  }

  Future<void> _delete(BuildContext context, ServiceListNotifier notifier, Service s) async {
    final hard = await confirmDeleteMode(context, title: 'Удаление услуги', body: 'Удалить «${s.name}»?');
    if (hard == null) return;
    if (hard) {
      await notifier.hardDelete(s.id);
    } else {
      await notifier.softDelete(s.id);
    }
  }
}
