import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/app_exceptions.dart';
import '../models/clinic.dart';
import '../repositories/clinic_repository.dart';
import '../utils/validators.dart';
import '../widgets/entity_form.dart';

class ClinicFormScreen extends StatefulWidget {
  final int? id;
  const ClinicFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<ClinicFormScreen> createState() => _ClinicFormScreenState();
}

class _ClinicFormScreenState extends State<ClinicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _slotsCtrl = TextEditingController(text: '5');

  bool _loading = true;
  bool _saving = false;
  String? _nameUniqueError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.isEditing) {
      try {
        final clinic = await context.read<ClinicRepository>().findById(widget.id!);
        if (clinic != null && mounted) {
          _nameCtrl.text = clinic.name;
          _addressCtrl.text = clinic.address;
          _phoneCtrl.text = clinic.phone;
          _cityCtrl.text = clinic.city;
          _slotsCtrl.text = clinic.slotsTotal.toString();
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _save() async {
    setState(() => _nameUniqueError = null);
    if (!_formKey.currentState!.validate()) return false;

    final repo = context.read<ClinicRepository>();
    setState(() => _saving = true);
    final clinic = Clinic(
      id: widget.id ?? 0,
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      slotsTotal: int.parse(_slotsCtrl.text),
    );
    try {
      if (widget.isEditing) {
        await repo.update(clinic);
      } else {
        await repo.create(clinic);
      }
      return true;
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() => _nameUniqueError = e.fieldErrors['name']);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return false;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _slotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EntityFormScaffold(
      title: widget.isEditing ? 'Редактирование филиала' : 'Новый филиал',
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
          label: 'Адрес *',
          controller: _addressCtrl,
          validator: (v) => Validators.combine([
            () => Validators.required(v, field: 'Адрес'),
            () => Validators.maxLength(v, 200, field: 'Адрес'),
          ]),
        ),
        AppFieldSpec.text(
          label: 'Телефон *',
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          validator: Validators.phone,
        ),
        AppFieldSpec.text(
          label: 'Город *',
          controller: _cityCtrl,
          validator: (v) => Validators.combine([
            () => Validators.required(v, field: 'Город'),
            () => Validators.maxLength(v, 80, field: 'Город'),
          ]),
        ),
        AppFieldSpec.text(
          label: 'Мест стационара *',
          controller: _slotsCtrl,
          keyboardType: TextInputType.number,
          validator: (v) => Validators.nonNegativeInt(v, field: 'Число мест'),
        ),
      ],
    );
  }
}
