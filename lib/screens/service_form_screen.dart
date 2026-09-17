import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/service.dart';
import '../models/clinic.dart';
import '../api/app_exceptions.dart';
import '../repositories/service_repository.dart';
import '../repositories/clinic_repository.dart';
import '../utils/validators.dart';
import '../widgets/entity_form.dart';

class ServiceFormScreen extends StatefulWidget {
  final int? id;
  const ServiceFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  int? _clinicId;
  List<Clinic> _clinics = [];
  bool _loading = true;
  bool _saving = false;
  String? _nameUniqueError;
  String? _priceError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final clinicRepo = context.read<ClinicRepository>();
    final serviceRepo = context.read<ServiceRepository>();
    _clinics = await clinicRepo.findAllActive();
    if (widget.isEditing) {
      final service = await serviceRepo.findById(widget.id!);
      if (service != null && mounted) {
        _nameCtrl.text = service.name;
        _descCtrl.text = service.description;
        _priceCtrl.text = service.price.toString();
        _clinicId = service.clinicId;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _save() async {
    setState(() {
      _nameUniqueError = null;
      _priceError = null;
    });
    if (!_formKey.currentState!.validate()) return false;

    final repo = context.read<ServiceRepository>();
    final unique = await repo.isNameUnique(
      _nameCtrl.text.trim(),
      excludeId: widget.id,
    );
    if (!unique) {
      setState(() => _nameUniqueError = 'Услуга с таким названием уже есть');
      return false;
    }

    setState(() => _saving = true);
    final service = Service(
      id: widget.id ?? 0,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.replaceAll(',', '.')),
      clinicId: _clinicId!,
    );
    try {
      if (widget.isEditing) {
        await repo.update(service);
      } else {
        await repo.create(service);
      }
      return true;
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() {
          _nameUniqueError = e.errorFor(['name']);
          _priceError = e.errorFor(['price']);
        });
        if (_nameUniqueError == null && _priceError == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
      return false;
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
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EntityFormScaffold(
      title: widget.isEditing ? 'Редактирование услуги' : 'Новая услуга',
      loading: _loading,
      saving: _saving,
      formKey: _formKey,
      submitLabel: widget.isEditing ? 'Сохранить' : 'Создать',
      onSave: _save,
      fields: [
        AppFieldSpec.text(
          label: 'Название *',
          controller: _nameCtrl,
          errorText: _nameUniqueError,
          validator: (v) => Validators.combine([
            () => Validators.required(v, field: 'Название'),
            () => Validators.maxLength(v, 100, field: 'Название'),
          ]),
        ),
        AppFieldSpec.text(
          label: 'Описание',
          controller: _descCtrl,
          maxLines: 3,
          maxLength: 400,
        ),
        AppFieldSpec.text(
          label: 'Цена (₽) *',
          controller: _priceCtrl,
          errorText: _priceError,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) => Validators.positiveDouble(v, field: 'Цена'),
        ),
        AppFieldSpec.dropdown(
          label: 'Филиал *',
          value: _clinicId,
          items: _clinics
              .map(
                (c) => DropdownMenuItem<dynamic>(
                  value: c.id,
                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _clinicId = v as int?),
          dropdownValidator: (v) => v == null ? 'Выберите филиал' : null,
        ),
      ],
    );
  }
}
