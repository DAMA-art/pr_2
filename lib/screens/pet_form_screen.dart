import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pet.dart';
import '../models/pet_passport.dart';
import '../models/owner.dart';
import '../models/service.dart';
import '../models/clinic.dart';
import '../repositories/pet_repository.dart';
import '../repositories/owner_repository.dart';
import '../repositories/service_repository.dart';
import '../repositories/clinic_repository.dart';
import '../repositories/pet_passport_repository.dart';
import '../utils/validators.dart';
import '../utils/species.dart';
import '../widgets/entity_form.dart';

class PetFormScreen extends StatefulWidget {
  final int? id;
  const PetFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  final _chipCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _passportNumberCtrl = TextEditingController();
  final _microchipCtrl = TextEditingController();

  bool _hasPassport = false;
  int? _passportId;
  DateTime _passportIssuedAt = DateTime.now();

  String _species = 'cat';
  int? _clinicId;
  List<int> _ownerIds = [];
  List<int> _serviceIds = [];
  bool _loading = true;
  bool _saving = false;
  String? _chipUniqueError;
  String? _passportUniqueError;

  List<Owner> _owners = [];
  List<Service> _services = [];
  List<Clinic> _clinics = [];

  List<Service> get _clinicServices =>
      _services.where((s) => _clinicId != null && s.clinicId == _clinicId).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final petRepo = context.read<PetRepository>();
    final ownerRepo = context.read<OwnerRepository>();
    final serviceRepo = context.read<ServiceRepository>();
    final clinicRepo = context.read<ClinicRepository>();
    final passportRepo = context.read<PetPassportRepository>();

    _owners = await ownerRepo.findAllActive();
    _services = await serviceRepo.findAllActive();
    _clinics = await clinicRepo.findAllActive();

    if (widget.isEditing) {
      final pet = await petRepo.findById(widget.id!);
      if (pet != null && mounted) {
        _nameCtrl.text = pet.name;
        _breedCtrl.text = pet.breed;
        _chipCtrl.text = pet.chipNumber;
        _ageCtrl.text = pet.ageMonths.toString();
        _weightCtrl.text = pet.weightKg.toString();
        _notesCtrl.text = pet.notes;
        _species = pet.species;
        _clinicId = pet.clinicId == 0 ? null : pet.clinicId;
        _ownerIds = List.from(pet.ownerIds);
        _serviceIds = List.from(pet.serviceIds);

        final passport = await passportRepo.findByPetId(pet.id);
        if (passport != null) {
          _hasPassport = true;
          _passportId = passport.id;
          _passportNumberCtrl.text = passport.number;
          _microchipCtrl.text = passport.microchip;
          _passportIssuedAt = passport.issuedAt;
        }
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _save() async {
    setState(() {
      _chipUniqueError = null;
      _passportUniqueError = null;
    });
    if (!_formKey.currentState!.validate()) return false;

    final petRepo = context.read<PetRepository>();
    final unique = await petRepo.isChipUnique(_chipCtrl.text.trim(), excludeId: widget.id);
    if (!mounted) return false;
    if (!unique) {
      setState(() => _chipUniqueError = 'Номер чипа уже используется');
      return false;
    }

    final passportRepo = context.read<PetPassportRepository>();
    if (_hasPassport) {
      final numberUnique = await passportRepo.isNumberUnique(
        _passportNumberCtrl.text.trim(),
        excludeId: _passportId,
      );
      if (!mounted) return false;
      if (!numberUnique) {
        setState(() => _passportUniqueError = 'Номер паспорта уже используется');
        return false;
      }
    }

    setState(() => _saving = true);
    final pet = Pet(
      id: widget.id ?? 0,
      name: _nameCtrl.text.trim(),
      species: _species,
      breed: _breedCtrl.text.trim(),
      chipNumber: _chipCtrl.text.trim(),
      ageMonths: int.parse(_ageCtrl.text),
      weightKg: double.parse(_weightCtrl.text.replaceAll(',', '.')),
      clinicId: _clinicId!,
      ownerIds: List.from(_ownerIds),
      serviceIds: List.from(_serviceIds),
      notes: _notesCtrl.text.trim(),
    );

    try {
      final Pet saved = widget.isEditing ? await petRepo.update(pet) : await petRepo.create(pet);

      if (_hasPassport) {
        final number = _passportNumberCtrl.text.trim();
        final microchip = _microchipCtrl.text.trim();
        if (_passportId != null) {
          final existing = await passportRepo.findById(_passportId!);
          if (existing != null) {
            await passportRepo.update(existing.copyWith(
              petId: saved.id,
              number: number,
              microchip: microchip,
            ));
          }
        } else {
          await passportRepo.create(PetPassport(
            id: 0,
            petId: saved.id,
            number: number,
            microchip: microchip,
            issuedAt: _passportIssuedAt,
          ));
        }
      } else if (_passportId != null) {
        await passportRepo.softDelete(_passportId!);
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _chipCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    _passportNumberCtrl.dispose();
    _microchipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EntityFormScaffold(
      title: widget.isEditing ? 'Редактирование питомца' : 'Новый питомец',
      loading: _loading,
      saving: _saving,
      formKey: _formKey,
      submitLabel: widget.isEditing ? 'Сохранить' : 'Создать',
      onSave: _save,
      fields: [
        AppFieldSpec.text(
          label: 'Кличка *',
          controller: _nameCtrl,
          validator: (v) => Validators.combine([
            () => Validators.required(v, field: 'Кличка'),
            () => Validators.maxLength(v, 50, field: 'Кличка'),
          ]),
        ),
        AppFieldSpec.text(
          label: 'Номер чипа *',
          controller: _chipCtrl,
          errorText: _chipUniqueError,
          validator: Validators.chipNumber,
          onTextChanged: (_) {
            if (_chipUniqueError != null) setState(() => _chipUniqueError = null);
          },
        ),
        AppFieldSpec.dropdown(
          label: 'Вид *',
          value: _species,
          items: [
            for (final item in speciesItems)
              DropdownMenuItem(value: item.$1, child: Text(item.$2)),
          ],
          onChanged: (v) => setState(() => _species = v as String),
          dropdownValidator: (v) => v == null ? 'Выберите вид' : null,
        ),
        AppFieldSpec.text(
          label: 'Порода *',
          controller: _breedCtrl,
          validator: (v) => Validators.combine([
            () => Validators.required(v, field: 'Порода'),
            () => Validators.maxLength(v, 100, field: 'Порода'),
          ]),
        ),
        AppFieldSpec.text(
          label: 'Возраст (месяцы) *',
          controller: _ageCtrl,
          keyboardType: TextInputType.number,
          validator: (v) => Validators.rangeInt(v, 1, 360, field: 'Возраст'),
        ),
        AppFieldSpec.text(
          label: 'Вес (кг) *',
          controller: _weightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) => Validators.positiveDouble(v, field: 'Вес'),
        ),
        AppFieldSpec.dropdown(
          label: 'Филиал *',
          value: _clinicId,
          items: _clinics
              .map((c) => DropdownMenuItem<dynamic>(
                    value: c.id,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) {
            setState(() {
              _clinicId = v as int?;
              _serviceIds = _serviceIds.where((id) => _clinicServices.any((s) => s.id == id)).toList();
            });
          },
          dropdownValidator: (v) => v == null ? 'Выберите филиал' : null,
          helperText: 'От филиала зависит список доступных услуг',
        ),
        AppFieldSpec.multiSelect(
          label: 'Владельцы *',
          options: _owners.map((o) => SelectOption(id: o.id, label: o.fullName)).toList(),
          selectedIds: _ownerIds,
          onMultiChanged: (ids) => setState(() => _ownerIds = ids),
          multiValidator: (value) =>
              (value == null || value.isEmpty) ? 'Выберите хотя бы одного владельца' : null,
        ),
        AppFieldSpec.multiSelect(
          label: 'Услуги *',
          options: _clinicServices
              .map((s) => SelectOption(id: s.id, label: '${s.name} (${s.price.toStringAsFixed(0)} ₽)'))
              .toList(),
          selectedIds: _serviceIds,
          onMultiChanged: (ids) => setState(() => _serviceIds = ids),
          multiValidator: (value) =>
              (value == null || value.isEmpty) ? 'Выберите хотя бы одну услугу' : null,
          helperText: _clinicId == null ? 'Сначала выберите филиал' : null,
        ),
        AppFieldSpec.text(
          label: 'Заметки',
          controller: _notesCtrl,
          maxLines: 3,
          maxLength: 500,
        ),
        AppFieldSpec.nestedGroup(
          label: 'Паспорт питомца',
          nestedEnabled: _hasPassport,
          onNestedToggle: (v) => setState(() => _hasPassport = v),
          children: [
            AppFieldSpec.text(
              label: 'Номер паспорта *',
              controller: _passportNumberCtrl,
              errorText: _passportUniqueError,
              validator: (v) {
                if (!_hasPassport) return null;
                return Validators.combine([
                  () => Validators.required(v, field: 'Номер паспорта'),
                  () => Validators.minLength(v, 4, field: 'Номер паспорта'),
                  () => Validators.maxLength(v, 30, field: 'Номер паспорта'),
                ]);
              },
              onTextChanged: (_) {
                if (_passportUniqueError != null) setState(() => _passportUniqueError = null);
              },
            ),
            AppFieldSpec.text(
              label: 'Микрочип',
              controller: _microchipCtrl,
              validator: (v) {
                if (!_hasPassport || (v == null || v.trim().isEmpty)) return null;
                return Validators.maxLength(v, 20, field: 'Микрочип');
              },
            ),
          ],
        ),
      ],
    );
  }
}
