import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../api/app_exceptions.dart';
import '../api/dio_client.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  List<Map<String, dynamic>> _items = [];
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
      final dio = context.read<Dio>();
      final res = await dio.get<Map<String, dynamic>>('/visits');
      final content = res.data?['content'];
      _items = content is List
          ? content.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : [];
    } catch (e) {
      try {
        mapDioError(e);
      } on AppException catch (ae) {
        _error = ae.message;
      } catch (_) {
        _error = e.toString();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _extend(int id) async {
    try {
      final dio = context.read<Dio>();
      await dio.post('/visits/$id/extend', data: {'days': 3});
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Срок продлён на 3 дня')));
      _load();
    } catch (e) {
      try {
        mapDioError(e);
      } on AppException catch (ae) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ae.message)));
      }
    }
  }

  Future<void> _returnVisit(int id) async {
    try {
      final dio = context.read<Dio>();
      await dio.post('/visits/$id/return');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Выписка оформлена')));
      _load();
    } catch (e) {
      try {
        mapDioError(e);
      } on AppException catch (ae) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ae.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final isStaff = auth.has(Role.staff);
    final fmt = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заселения / выдачи'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _items.isEmpty
          ? const Center(child: Text('Нет активных заселений'))
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final v = _items[i];
                final pet = v['pet'] is Map ? v['pet'] as Map : {};
                final clinic = v['clinic'] is Map ? v['clinic'] as Map : {};
                final due = DateTime.tryParse('${v['dueAt']}');
                return ListTile(
                  title: Text(
                    '${pet['name'] ?? 'Питомец'} → ${clinic['name'] ?? 'Филиал'}',
                  ),
                  subtitle: Text(
                    'До: ${due != null ? fmt.format(due.toLocal()) : '—'} · ${v['status']}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (v['returnedAt'] == null)
                        TextButton(
                          onPressed: () => _extend(v['id'] as int),
                          child: const Text('Продлить'),
                        ),
                      if (isStaff && v['returnedAt'] == null)
                        TextButton(
                          onPressed: () => _returnVisit(v['id'] as int),
                          child: const Text('Выписать'),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
