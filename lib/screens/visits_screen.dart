import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../api/app_exceptions.dart';
import '../models/role.dart';
import '../models/visit.dart';
import '../repositories/visit_repository.dart';
import '../state/auth_notifier.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  List<Visit> _items = [];
  bool _loading = true;
  String? _error;
  bool _includeDeleted = false;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await context.read<VisitRepository>().list(
            includeDeleted: _includeDeleted,
          );
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
          Padding(
            padding: const EdgeInsets.all(8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Показать удалённые'),
                selected: _includeDeleted,
                onSelected: (v) {
                  setState(() => _includeDeleted = v);
                  _load();
                },
              ),
            ),
          ),
          Expanded(child: _body(fmt, isStaff)),
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
    if (_items.isEmpty) {
      return const Center(child: Text('Нет записей на груминг'));
    }
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final v = _items[i];
        return ListTile(
          leading: Checkbox(
            value: _selected.contains(v.id),
            onChanged: isStaff
                ? (_) => setState(() {
                      _selected.contains(v.id)
                          ? _selected.remove(v.id)
                          : _selected.add(v.id);
                    })
                : null,
          ),
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
              ? IconButton(
                  icon: const Icon(Icons.restore, color: Colors.green),
                  onPressed: () async {
                    await context.read<VisitRepository>().restore(v.id);
                    _load();
                  },
                )
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
                      final hard = value == 'hard';
                      if (hard) {
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
