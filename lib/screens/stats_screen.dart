import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/app_exceptions.dart';
import '../api/supabase_errors.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, int> _stats = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<int> _count(String table) async {
    final res = await Supabase.instance.client
        .from(table)
        .select('id')
        .isFilter('deleted_at', null)
        .count(CountOption.exact);
    return res.count;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pets = await _count('pets');
      final owners = await _count('owners');
      final clinics = await _count('clinics');
      final services = await _count('services');
      final groomers = await _count('groomers');
      final visits = await _count('visits');
      final reviews = await _count('reviews');
      final users = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .count(CountOption.exact);
      _stats = {
        'Питомцы': pets,
        'Владельцы': owners,
        'Филиалы': clinics,
        'Услуги': services,
        'Мастера': groomers,
        'Записи': visits,
        'Отзывы': reviews,
        'Пользователи': users.count,
      };
    } on AppException catch (e) {
      _error = e.message;
    } catch (e) {
      try {
        mapSupabaseError(e);
      } on AppException catch (ae) {
        _error = ae.message;
      } catch (_) {
        _error = '$e';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final e in _stats.entries) _card(e.key, e.value),
                    ],
                  ),
                ),
    );
  }

  Widget _card(String title, dynamic value) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('$value', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
