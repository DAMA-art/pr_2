import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/clinic.dart';
import '../models/service.dart';
import '../repositories/clinic_repository.dart';
import '../repositories/service_repository.dart';

class ServiceDetailScreen extends StatefulWidget {
  final int id;
  const ServiceDetailScreen({super.key, required this.id});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  Service? _service;
  Clinic? _clinic;
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
      final serviceRepo = context.read<ServiceRepository>();
      final clinicRepo = context.read<ClinicRepository>();
      final service = await serviceRepo.findById(widget.id);
      Clinic? clinic;
      if (service != null) {
        clinic = await clinicRepo.findById(service.clinicId);
      }
      setState(() {
        _service = service;
        _clinic = clinic;
        _loading = false;
        if (service == null) _error = 'Услуга не найдена';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _delete() async {
    final service = _service;
    if (service == null) return;
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить?'),
        content: Text('Удалить услугу «${service.name}»?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Нет')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Да')),
        ],
      ),
    );
    if (conf == true && mounted) {
      await context.read<ServiceRepository>().softDelete(service.id);
      if (mounted) context.go('/services');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_service?.name ?? 'Услуга'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/services')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final ok = await context.push('/services/${widget.id}/edit');
              if (ok == true && mounted) _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _service == null || _service!.isDeleted ? null : _delete,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _service == null
                  ? const Center(child: Text('Не найдена'))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_service!.name, style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 12),
                              Text('Цена: ${_service!.price.toStringAsFixed(0)} ₽'),
                              Text('Филиал: ${_clinic?.name ?? _service!.clinicId}'),
                              if (_service!.description.isNotEmpty) Text('Описание: ${_service!.description}'),
                              if (_service!.isDeleted)
                                const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Text('УДАЛЁН', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }
}
