import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../api/app_exceptions.dart';
import '../models/clinic.dart';
import '../models/page_result.dart';
import '../models/role.dart';
import '../models/visit.dart';
import '../models/visit_query.dart';
import '../repositories/clinic_repository.dart';
import '../repositories/visit_repository.dart';
import '../state/auth_notifier.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/search_field.dart';

String visitUri(VisitQuery q) {
  final params = <String, String>{};
  if (q.search.isNotEmpty) params['search'] = q.search;
  if (q.clinicId != null) params['clinicId'] = '${q.clinicId}';
  if (q.status != null) params['status'] = q.status!;
  if (q.sortField != 'issued_at' || q.sortAscending) {
    params['sort'] = '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}';
  }
  if (q.page != 1) params['page'] = '${q.page}';
  if (q.size != 10) params['size'] = '${q.size}';
  if (q.includeDeleted) params['includeDeleted'] = 'true';
  return Uri(path: '/visits', queryParameters: params.isEmpty ? null : params)
      .toString();
}

class VisitsScreen extends StatefulWidget {
  final VisitQuery query;
  const VisitsScreen({super.key, required this.query});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  PageResult<Visit> _result = PageResult.empty();
  bool _loading = true;
  String? _error;
  final Set<int> _selected = {};
  List<Clinic> _clinics = [];

  VisitQuery get _query => widget.query;

  @override
  void initState() {
    super.initState();
    context.read<ClinicRepository>().findAllActive().then((v) {
      if (mounted) setState(() => _clinics = v);
    });
    _load();
  }

  @override
  void didUpdateWidget(covariant VisitsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_queryChanged(oldWidget.query, widget.query)) {
      _selected.clear();
      _load();
    }
  }

  bool _queryChanged(VisitQuery a, VisitQuery b) =>
      a.search != b.search ||
      a.clinicId != b.clinicId ||
      a.status != b.status ||
      a.sortField != b.sortField ||
      a.sortAscending != b.sortAscending ||
      a.page != b.page ||
      a.size != b.size ||
      a.includeDeleted != b.includeDeleted;

  void _go(VisitQuery next) => context.go(visitUri(next));

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _result = await context.read<VisitRepository>().find(_query);
    } on AppException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final isStaff = auth.has(Role.staff);
    final fmt = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Записи на груминг'),
        actions: [
          if (_selected.isNotEmpty && isStaff)
            IconButton(
              tooltip: 'Удалить выбранные',
              onPressed: () async {
                await context
                    .read<VisitRepository>()
                    .deleteMany(_selected.toList());
                _selected.clear();
                _load();
              },
              icon: const Icon(Icons.delete),
            ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(
            tooltip: 'Новая запись',
            onPressed: () async {
              final ok = await context.push('/visits/new');
              if (ok == true) _load();
            },
            icon: const Icon(Icons.add),
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
                    initialValue: _query.search,
                    hintText: 'Поиск по кличке питомца...',
                    onChanged: (v) => _go(_query.copyWith(search: v, page: 1)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<int?>(
                          key: ValueKey('visit-clinic-${_query.clinicId}'),
                          isExpanded: true,
                          initialValue: _query.clinicId,
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
                                child: Text(c.name),
                              ),
                          ],
                          onChanged: (v) =>
                              _go(_query.copyWith(clinicId: v, page: 1)),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String?>(
                          key: ValueKey('visit-status-${_query.status}'),
                          isExpanded: true,
                          initialValue: _query.status,
                          decoration: const InputDecoration(
                            labelText: 'Статус',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Все')),
                            DropdownMenuItem(
                              value: 'scheduled',
                              child: Text('Запись'),
                            ),
                            DropdownMenuItem(
                              value: 'done',
                              child: Text('Завершена'),
                            ),
                            DropdownMenuItem(
                              value: 'cancelled',
                              child: Text('Отменена'),
                            ),
                          ],
                          onChanged: (v) =>
                              _go(_query.copyWith(status: v, page: 1)),
                        ),
                      ),
                      if (isStaff)
                        FilterChip(
                          label: const Text('Показать удалённые'),
                          selected: _query.includeDeleted,
                          onSelected: (v) => _go(
                            _query.copyWith(includeDeleted: v, page: 1),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _body(fmt, isStaff)),
          if (!_loading && _error == null)
            PaginationBar(
              result: _result,
              currentSize: _query.size,
              onPageChanged: (p) => _go(_query.copyWith(page: p)),
              onSizeChanged: (s) => _go(_query.copyWith(size: s, page: 1)),
            ),
        ],
      ),
    );
  }

  Widget _body(DateFormat fmt, bool isStaff) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }
    if (_result.items.isEmpty) {
      return const Center(child: Text('Нет записей на груминг'));
    }
    return ListView.separated(
      itemCount: _result.items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final v = _result.items[i];
        return ListTile(
          leading: isStaff
              ? Checkbox(
                  value: _selected.contains(v.id),
                  onChanged: (_) => setState(() {
                    _selected.contains(v.id)
                        ? _selected.remove(v.id)
                        : _selected.add(v.id);
                  }),
                )
              : CircleAvatar(child: Text(v.totalPrice.toStringAsFixed(0))),
          title: Text(
            '${v.petName ?? 'Питомец'} · ${v.clinicName ?? 'Филиал'}',
            style: TextStyle(
              decoration: v.isDeleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            '${fmt.format(v.issuedAt.toLocal())} — ${fmt.format(v.dueAt.toLocal())}\n'
            '${v.groomerName ?? 'Мастер не указан'} · ${v.statusLabel} · ${v.totalPrice.toStringAsFixed(0)} ₽',
          ),
          isThreeLine: true,
          trailing: v.isDeleted
              ? (isStaff
                    ? IconButton(
                        icon: const Icon(Icons.restore, color: Colors.green),
                        onPressed: () async {
                          await context.read<VisitRepository>().restore(v.id);
                          _load();
                        },
                      )
                    : null)
              : PopupMenuButton<String>(
                  onSelected: (value) async {
                    final repo = context.read<VisitRepository>();
                    if (value == 'edit') {
                      final ok = await context.push('/visits/${v.id}/edit');
                      if (ok == true) _load();
                    } else if (value == 'extend') {
                      await repo.extend(v.id);
                      _load();
                    } else if (value == 'done') {
                      await repo.complete(v.id);
                      _load();
                    } else if (value == 'soft' || value == 'hard') {
                      if (value == 'hard') {
                        await repo.hardDelete(v.id);
                      } else {
                        await repo.softDelete(v.id);
                      }
                      _load();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Изменить')),
                    if (v.isActive)
                      const PopupMenuItem(
                        value: 'extend',
                        child: Text('Продлить на 30 мин'),
                      ),
                    if (isStaff && v.isActive)
                      const PopupMenuItem(
                        value: 'done',
                        child: Text('Завершить'),
                      ),
                    if (isStaff)
                      const PopupMenuItem(
                        value: 'soft',
                        child: Text('Удалить логически'),
                      ),
                    if (isStaff)
                      const PopupMenuItem(
                        value: 'hard',
                        child: Text('Удалить физически'),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
