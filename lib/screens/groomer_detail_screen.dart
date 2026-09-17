import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/groomer.dart';
import '../models/role.dart';
import '../repositories/groomer_repository.dart';
import '../state/auth_notifier.dart';
import '../widgets/confirm_delete.dart';

class GroomerDetailScreen extends StatefulWidget {
  final int id;
  const GroomerDetailScreen({super.key, required this.id});

  @override
  State<GroomerDetailScreen> createState() => _GroomerDetailScreenState();
}

class _GroomerDetailScreenState extends State<GroomerDetailScreen> {
  Groomer? _item;
  bool _loading = true;
  String? _error;

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
      final g = await context.read<GroomerRepository>().findById(widget.id);
      setState(() {
        _item = g;
        _loading = false;
        if (g == null) _error = 'Мастер не найден';
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = context.watch<AuthNotifier>().has(Role.staff);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Мастер')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Мастер')),
        body: Center(child: Text(_error ?? 'Нет данных')),
      );
    }
    final g = _item!;
    return Scaffold(
      appBar: AppBar(
        title: Text(g.fullName),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final ok = await context.push('/groomers/${g.id}/edit');
                if (ok == true) _load();
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
                if (hard == null || !context.mounted) return;
                final repo = context.read<GroomerRepository>();
                if (hard) {
                  await repo.hardDelete(g.id);
                } else {
                  await repo.softDelete(g.id);
                }
                if (context.mounted) context.go('/groomers');
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(title: const Text('Телефон'), subtitle: Text(g.phone)),
          ListTile(
            title: const Text('Специализация'),
            subtitle: Text(g.specializationLabel),
          ),
          ListTile(
            title: const Text('Филиал'),
            subtitle: Text(g.clinicName ?? '—'),
          ),
          ListTile(
            title: const Text('Стаж'),
            subtitle: Text('${g.experienceYears} лет'),
          ),
        ],
      ),
    );
  }
}
