import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/pet.dart';
import '../models/pet_passport.dart';
import '../repositories/pet_repository.dart';
import '../repositories/pet_passport_repository.dart';
import '../utils/validators.dart';
import '../widgets/entity_form.dart';

class PassportFormScreen extends StatefulWidget {
  final int? id;
  const PassportFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<PassportFormScreen> createState() => _PassportFormScreenState();
}

class _PassportFormScreenState extends State<PassportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _microchipCtrl = TextEditingController();
  final _issuedCtrl = TextEditingController();

  int? _petId;
  DateTime _issuedAt = DateTime.now();
  List<Pet> _pets = [];
  bool _loading = true;
  bool _saving = false;
  String? _numberUniqueError;
  String? _petUniqueError;

  @override
  void initState() {
    super.initState();
    _issuedCtrl.text = DateFormat('yyyy-MM-dd').format(_issuedAt);
    _load();
  }

  Future<void> _load() async {
    final petRepo = context.read<PetRepository>();
    final passportRepo = context.read<PetPassportRepository>();
    final allPets = await petRepo.findAllActive();

    if (widget.isEditing) {
      final passport = await passportRepo.findById(widget.id!);
      if (passport != null && mounted) {
        _numberCtrl.text = passport.number;
        _microchipCtrl.text = passport.microchip;
        _petId = passport.petId;
        _issuedAt = passport.issuedAt;
        _issuedCtrl.text = DateFormat('yyyy-MM-dd').format(_issuedAt);
      }
    }

    final taken = <int>{};
    for (final p in await passportRepo.findAllActive()) {
      if (p.id != widget.id) taken.add(p.petId);
    }
    _pets = allPets
        .where((pet) => !taken.contains(pet.id) || pet.id == _petId)
        .toList();

    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _save() async {
    setState(() {
      _numberUniqueError = null;
      _petUniqueError = null;
    });
    if (!_formKey.currentState!.validate()) return false;
    final parsedDate = DateTime.tryParse(_issuedCtrl.text.trim());
    if (parsedDate != null) _issuedAt = parsedDate;

    final repo = context.read<PetPassportRepository>();
    final unique = await repo.isNumberUnique(
      _numberCtrl.text.trim(),
      excludeId: widget.id,
    );
    if (!unique) {
      setState(() => _numberUniqueError = 'Номер паспорта уже используется');
      return false;
    }
    final petFree = await repo.isPetFree(_petId!, excludeId: widget.id);
    if (!petFree) {
      setState(() => _petUniqueError = 'У этого питомца уже есть паспорт');
      return false;
    }

    setState(() => _saving = true);
    final passport = PetPassport(
      id: widget.id ?? 0,
      petId: _petId!,
      number: _numberCtrl.text.trim(),
      microchip: _microchipCtrl.text.trim(),
      issuedAt: _issuedAt,
    );
    try {
      if (widget.isEditing) {
        await repo.update(passport);
      } else {
        await repo.create(passport);
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e'))); }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _microchipCtrl.dispose();
    _issuedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EntityFormScaffold(
      title: widget.isEditing ? 'Редактирование паспорта' : 'Новый паспорт',
      loading: _loading,
      saving: _saving,
      formKey: _formKey,
      submitLabel: widget.isEditing ? 'Сохранить' : 'Создать',
      onSave: _save,
      fields: [
        AppFieldSpec.dropdown(
          label: 'Питомец *',
          value: _petId,
          items: _pets
              .map(
                (p) => DropdownMenuItem<dynamic>(
                  value: p.id,
                  child: Text(
                    '${p.name} (${p.chipNumber})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _petId = v as int?),
          dropdownValidator: (v) => v == null
              ? (_petUniqueError ?? 'Выберите питомца')
              : _petUniqueError,
        ),
        AppFieldSpec.text(
          label: 'Номер паспорта *',
          controller: _numberCtrl,
          errorText: _numberUniqueError,
          validator: (v) => Validators.combine([
            () => Validators.required(v, field: 'Номер паспорта'),
            () => Validators.minLength(v, 4, field: 'Номер паспорта'),
            () => Validators.maxLength(v, 30, field: 'Номер паспорта'),
          ]),
        ),
        AppFieldSpec.text(
          label: 'Микрочип',
          controller: _microchipCtrl,
          validator: (v) => Validators.maxLength(v, 20, field: 'Микрочип'),
        ),
        AppFieldSpec.text(
          label: 'Дата выдачи *',
          controller: _issuedCtrl,
          validator: Validators.date,
        ),
      ],
    );
  }
}
