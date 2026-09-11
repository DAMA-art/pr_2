import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../api/app_exceptions.dart';
import '../models/pet.dart';
import '../models/owner.dart';
import '../models/service.dart';
import '../models/clinic.dart';
import '../models/pet_passport.dart';
import '../repositories/pet_repository.dart';
import '../repositories/owner_repository.dart';
import '../repositories/service_repository.dart';
import '../repositories/clinic_repository.dart';
import '../repositories/pet_passport_repository.dart';
import '../repositories/visit_repository.dart';
import '../utils/species.dart';

class PetDetailScreen extends StatefulWidget {
  final int id;
  const PetDetailScreen({super.key, required this.id});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  Pet? _pet;
  Clinic? _clinic;
  List<Owner> _owners = [];
  List<Service> _services = [];
  PetPassport? _passport;
  bool _loading = true;
  bool _boarding = false;
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
      final petRepo = context.read<PetRepository>();
      final clinicRepo = context.read<ClinicRepository>();
      final ownerRepo = context.read<OwnerRepository>();
      final serviceRepo = context.read<ServiceRepository>();
      final passportRepo = context.read<PetPassportRepository>();
      final pet = await petRepo.findById(widget.id);
      if (pet == null) {
        setState(() {
          _pet = null;
          _loading = false;
          _error = 'Питомец не найден';
        });
        return;
      }
      final clinic = await clinicRepo.findById(pet.clinicId);
      final owners = <Owner>[];
      for (final id in pet.ownerIds) {
        final o = await ownerRepo.findById(id);
        if (o != null) owners.add(o);
      }
      final services = <Service>[];
      for (final id in pet.serviceIds) {
        final s = await serviceRepo.findById(id);
        if (s != null) services.add(s);
      }
      final passport = await passportRepo.findByPetId(pet.id);
      setState(() {
        _pet = pet;
        _clinic = clinic;
        _owners = owners;
        _services = services;
        _passport = passport;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _boardAtClinic() async {
    final pet = _pet;
    if (pet == null || _boarding) return;
    setState(() => _boarding = true);
    try {
      await context.read<VisitRepository>().create(
            petId: pet.id,
            clinicId: pet.clinicId,
            days: 3,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Питомец заселён в филиал')),
      );
      await _load();
    } on ConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _boarding = false);
    }
  }

  Future<void> _delete() async {
    final pet = _pet;
    if (pet == null) return;
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить?'),
        content: Text('Удалить питомца «${pet.name}»?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Нет')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Да')),
        ],
      ),
    );
    if (conf == true && mounted) {
      final passportRepo = context.read<PetPassportRepository>();
      final petRepo = context.read<PetRepository>();
      if (_passport != null) {
        await passportRepo.softDelete(_passport!.id);
      }
      await petRepo.softDelete(pet.id);
      if (mounted) context.go('/pets');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pet?.name ?? 'Питомец'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/pets')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final ok = await context.push('/pets/${widget.id}/edit');
              if (ok == true && mounted) _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _pet == null || _pet!.isDeleted ? null : _delete,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('Повторить')),
                    ],
                  ),
                )
              : _pet == null
                  ? const Center(child: Text('Не найден'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_pet!.name, style: Theme.of(context).textTheme.headlineSmall),
                                const SizedBox(height: 12),
                                Text('Чип: ${_pet!.chipNumber}'),
                                Text('Вид: ${speciesLabel(_pet!.species)}'),
                                Text('Порода: ${_pet!.breed}'),
                                Text('Возраст: ${_pet!.ageMonths} мес.'),
                                Text('Вес: ${_pet!.weightKg} кг'),
                                Text(
                                  'Филиал: ${_clinic?.name ?? _pet!.clinicId}'
                                  '${_clinic != null ? ' (мест: ${_clinic!.slotsAvailable}/${_clinic!.slotsTotal})' : ''}',
                                ),
                                Text(
                                  'Владельцы: ${_owners.isEmpty ? '—' : _owners.map((o) => o.fullName).join(', ')}',
                                ),
                                Text(
                                  'Услуги: ${_services.isEmpty ? '—' : _services.map((s) => s.name).join(', ')}',
                                ),
                                if (_pet!.notes.isNotEmpty) Text('Заметки: ${_pet!.notes}'),
                                if (_pet!.isDeleted)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: Text(
                                      'УДАЛЁН',
                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: _pet!.isDeleted || _boarding ? null : _boardAtClinic,
                                  icon: _boarding
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.hotel),
                                  label: Text(_boarding ? 'Заселение…' : 'Заселить в филиал'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_passport != null)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Паспорт', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 8),
                                  Text('Номер: ${_passport!.number}'),
                                  Text('Микрочип: ${_passport!.microchip}'),
                                  Text('Выдан: ${_passport!.issuedAt.toIso8601String().split('T').first}'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }
}
