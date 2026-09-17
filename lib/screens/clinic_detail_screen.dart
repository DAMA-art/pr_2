import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/clinic.dart';
import '../models/role.dart';
import '../repositories/clinic_repository.dart';
import '../state/auth_notifier.dart';
import '../repositories/pet_repository.dart';
import '../repositories/service_repository.dart';
import '../widgets/confirm_delete.dart';

class ClinicDetailScreen extends StatefulWidget {
  final int id;
  const ClinicDetailScreen({super.key, required this.id});

  @override
  State<ClinicDetailScreen> createState() => _ClinicDetailScreenState();
}

class _ClinicDetailScreenState extends State<ClinicDetailScreen> {
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
      final clinic = await context.read<ClinicRepository>().findById(widget.id);
      setState(() {
        _clinic = clinic;
        _loading = false;
        if (clinic == null) _error = 'Филиал не найден';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _delete() async {
    final clinic = _clinic;
    if (clinic == null) return;
    final serviceRepo = context.read<ServiceRepository>();
    final petRepo = context.read<PetRepository>();
    final serviceCount = await serviceRepo.countByClinic(clinic.id);
    final petCount = await petRepo.countByClinic(clinic.id);
    if (!mounted) return;
    if (serviceCount > 0 || petCount > 0) {
      await showBlockedDelete(
        context,
        title: 'Невозможно удалить',
        body:
            'Филиал «${clinic.name}» связан с $serviceCount услугами и $petCount питомцами.',
      );
      return;
    }
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить?'),
        content: Text('Удалить филиал «${clinic.name}»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Нет'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Да'),
          ),
        ],
      ),
    );
    if (conf == true && mounted) {
      await context.read<ClinicRepository>().softDelete(clinic.id);
      if (mounted) context.go('/clinics');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_clinic?.name ?? 'Филиал'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/clinics'),
        ),
        actions: [
          if (context.watch<AuthNotifier>().has(Role.staff)) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final ok = await context.push('/clinics/${widget.id}/edit');
                if (ok == true && mounted) _load();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _clinic == null || _clinic!.isDeleted ? null : _delete,
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _clinic == null
          ? const Center(child: Text('Не найден'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _clinic!.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text('Адрес: ${_clinic!.address}'),
                      Text('Телефон: ${_clinic!.phone}'),
                      Text('Город: ${_clinic!.city}'),
                      if (_clinic!.isDeleted)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'УДАЛЁН',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
