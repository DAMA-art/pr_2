import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/app_exceptions.dart';
import '../api/dio_client.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;
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
      final res = await dio.get<Map<String, dynamic>>('/stats');
      _stats = Map<String, dynamic>.from(res.data ?? {});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
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
                      _card('Питомцы', _stats?['pets']),
                      _card('Владельцы', _stats?['owners']),
                      _card('Филиалы', _stats?['clinics']),
                      _card('Услуги', _stats?['services']),
                      _card('Активные заселения', _stats?['visitsActive']),
                      _card('Пользователи', _stats?['users']),
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