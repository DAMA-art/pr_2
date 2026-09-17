import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../api/app_exceptions.dart';
import '../models/clinic.dart';
import '../models/groomer.dart';
import '../models/pet.dart';
import '../models/service.dart';
import '../models/visit.dart';
import '../repositories/clinic_repository.dart';
import '../repositories/groomer_repository.dart';
import '../repositories/pet_repository.dart';
import '../repositories/service_repository.dart';
import '../repositories/visit_repository.dart';
import '../utils/grooming_quote.dart';
import '../utils/validators.dart';

class VisitFormScreen extends StatefulWidget {
  final int? id;
  const VisitFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<VisitFormScreen> createState() => _VisitFormScreenState();
}

class _VisitFormScreenState extends State<VisitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationCtrl = TextEditingController(text: '60');
  DateTime _start = DateTime.now().add(const Duration(hours: 1));
  int? _petId;
  int? _clinicId;
  int? _groomerId;
  List<int> _serviceIds = [];
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  String? _overlapError;

  List<Pet> _pets = [];
  List<Clinic> _clinics = [];
  List<Groomer> _groomers = [];
  List<Service> _services = [];
  GroomingQuoteResult? _quote;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final petRepo = context.read<PetRepository>();
    final clinicRepo = context.read<ClinicRepository>();
    final serviceRepo = context.read<ServiceRepository>();
    final groomerRepo = context.read<GroomerRepository>();
    final visitRepo = context.read<VisitRepository>();
    final pets = await petRepo.findAllActive();
    final clinics = await clinicRepo.findAllActive();
    final services = await serviceRepo.findAllActive();
    final groomers = await groomerRepo.findAllActive();
    _pets = pets;
    _clinics = clinics;
    _services = services;
    _groomers = groomers;

    if (widget.isEditing) {
      final visit = await visitRepo.findById(widget.id!);
      if (visit != null && mounted) {
        _petId = visit.petId;
        _clinicId = visit.clinicId;
        _groomerId = visit.groomerId;
        _serviceIds = List.from(visit.serviceIds);
        _start = visit.issuedAt;
        final mins = visit.dueAt.difference(visit.issuedAt).inMinutes;
        _durationCtrl.text = '${mins <= 0 ? 60 : mins}';
      }
    }
    await _recalc();
    if (mounted) setState(() => _loading = false);
  }

  List<Service> get _clinicServices => _services
      .where((s) => _clinicId != null && s.clinicId == _clinicId)
      .toList();

  List<Groomer> get _clinicGroomers => _groomers
      .where((g) => _clinicId != null && g.clinicId == _clinicId)
      .toList();

  Future<void> _recalc() async {
    final pet = _pets.where((p) => p.id == _petId).firstOrNull;
    final prices = _clinicServices
        .where((s) => _serviceIds.contains(s.id))
        .map((s) => s.price)
        .toList();
    var completed = 0;
    if (_petId != null) {
      final visitRepo = context.read<VisitRepository>();
      completed = await visitRepo.countCompletedByPet(_petId!);
    }
    if (!mounted) return;
    setState(() {
      _quote = GroomingQuote.calculate(
        servicePrices: prices,
        petWeightKg: pet?.weightKg ?? 0,
        species: pet?.species ?? 'cat',
        completedVisits: completed,
      );
    });
  }

  Future<void> _save() async {
    setState(() => _overlapError = null);
    if (!_formKey.currentState!.validate()) return;
    final minutes = int.parse(_durationCtrl.text);
    final end = _start.add(Duration(minutes: minutes));
    final repo = context.read<VisitRepository>();
    setState(() => _saving = true);
    try {
      if (_groomerId != null) {
        final clash = await repo.hasOverlap(
          groomerId: _groomerId!,
          start: _start,
          end: end,
          excludeId: widget.id,
        );
        if (clash) {
          setState(() =>
              _overlapError = 'Мастер уже занят в выбранный интервал');
          return;
        }
      }
      await _recalc();
      final total = _quote?.total ?? 0;
      if (widget.isEditing) {
        await repo.update(
          Visit(
            id: widget.id!,
            petId: _petId!,
            clinicId: _clinicId!,
            groomerId: _groomerId,
            issuedAt: _start,
            dueAt: end,
            status: 'scheduled',
            totalPrice: total,
            serviceIds: _serviceIds,
          ),
        );
      } else {
        await repo.create(
          petId: _petId!,
          clinicId: _clinicId!,
          groomerId: _groomerId,
          start: _start,
          end: end,
          serviceIds: _serviceIds,
          totalPrice: total,
        );
      }
      if (mounted) context.pop(true);
    } on ValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } on ConflictException catch (e) {
      setState(() => _overlapError = e.message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time == null) return;
    setState(() {
      _dirty = true;
      _start = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy HH:mm');
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Изменить запись' : 'Запись на груминг'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Изменить запись' : 'Запись на груминг'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _petId,
              decoration: const InputDecoration(
                labelText: 'Питомец *',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final p in _pets)
                  DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.name} (${p.weightKg} кг)'),
                  ),
              ],
              onChanged: (v) {
                setState(() {
                  _dirty = true;
                  _petId = v;
                });
                _recalc();
              },
              validator: (v) => v == null ? 'Выберите питомца' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _clinicId,
              decoration: const InputDecoration(
                labelText: 'Филиал *',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final c in _clinics)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) {
                setState(() {
                  _dirty = true;
                  _clinicId = v;
                  _groomerId = null;
                  _serviceIds = [];
                });
                _recalc();
              },
              validator: (v) => v == null ? 'Выберите филиал' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _groomerId,
              decoration: InputDecoration(
                labelText: 'Мастер *',
                border: const OutlineInputBorder(),
                errorText: _overlapError,
              ),
              items: [
                for (final g in _clinicGroomers)
                  DropdownMenuItem(value: g.id, child: Text(g.fullName)),
              ],
              onChanged: (v) => setState(() {
                _dirty = true;
                _groomerId = v;
                _overlapError = null;
              }),
              validator: (v) => v == null ? 'Выберите мастера' : null,
            ),
            const SizedBox(height: 12),
            FormField<List<int>>(
              initialValue: _serviceIds,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Выберите хотя бы одну услугу' : null,
              builder: (state) {
                return InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Услуги *',
                    border: const OutlineInputBorder(),
                    errorText: state.errorText,
                  ),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final s in _clinicServices)
                        FilterChip(
                          label: Text(
                            '${s.name} (${s.price.toStringAsFixed(0)} ₽)',
                          ),
                          selected: _serviceIds.contains(s.id),
                          onSelected: (_) {
                            setState(() {
                              _dirty = true;
                              _serviceIds.contains(s.id)
                                  ? _serviceIds.remove(s.id)
                                  : _serviceIds.add(s.id);
                            });
                            state.didChange(_serviceIds);
                            _recalc();
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationCtrl,
              decoration: const InputDecoration(
                labelText: 'Длительность (мин) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  Validators.rangeInt(v, 15, 480, field: 'Длительность'),
              onChanged: (_) => _dirty = true,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickStart,
              icon: const Icon(Icons.schedule),
              label: Text('Начало: ${fmt.format(_start)}'),
            ),
            if (_quote != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Расчёт стоимости',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('База: ${_quote!.base.toStringAsFixed(0)} ₽'),
                      if (_quote!.largeSurcharge > 0)
                        Text(
                          'Надбавка за крупного питомца (+30%): +${_quote!.largeSurcharge.toStringAsFixed(0)} ₽',
                        ),
                      if (_quote!.multiDiscount > 0)
                        Text(
                          'Скидка за комплекс из 3+ услуг (−10%): −${_quote!.multiDiscount.toStringAsFixed(0)} ₽',
                        ),
                      if (_quote!.loyalDiscount > 0)
                        Text(
                          'Скидка постоянного клиента (−15%): −${_quote!.loyalDiscount.toStringAsFixed(0)} ₽',
                        ),
                      Text(
                        'Итого: ${_quote!.total.toStringAsFixed(0)} ₽',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isEditing ? 'Сохранить' : 'Записать'),
            ),
            if (_dirty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Есть несохранённые изменения'),
              ),
          ],
        ),
      ),
    );
  }
}
