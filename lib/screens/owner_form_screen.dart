import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/app_exceptions.dart';
import '../models/owner.dart';
import '../repositories/owner_repository.dart';
import '../utils/validators.dart';
import '../widgets/entity_form.dart';

class OwnerFormScreen extends StatefulWidget {
  final int? id;
  const OwnerFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<OwnerFormScreen> createState() => _OwnerFormScreenState();
}

class _OwnerFormScreenState extends State<OwnerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _emailUniqueError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.isEditing) {
      final owner = await context.read<OwnerRepository>().findById(widget.id!);
      if (owner != null && mounted) {
        _lastNameCtrl.text = owner.lastName;
        _firstNameCtrl.text = owner.firstName;
        _phoneCtrl.text = owner.phone;
        _emailCtrl.text = owner.email;
        _cityCtrl.text = owner.city;
        _countryCtrl.text = owner.country;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _save() async {
    setState(() => _emailUniqueError = null);
    if (!_formKey.currentState!.validate()) return false;

    final ownerRepo = context.read<OwnerRepository>();
    setState(() => _saving = true);
    try {
      final owner = Owner(
        id: widget.id ?? 0,
        lastName: _lastNameCtrl.text.trim(),
        firstName: _firstNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
      );
      if (widget.isEditing) {
        await ownerRepo.update(owner);
      } else {
        await ownerRepo.create(owner);
      }
      return true;
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() => _emailUniqueError = e.fieldErrors['email']);
        if (_emailUniqueError == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EntityFormScaffold(
      title: widget.isEditing ? 'Редактирование владельца' : 'Новый владелец',
      loading: _loading,
      saving: _saving,
      formKey: _formKey,
      submitLabel: widget.isEditing ? 'Сохранить' : 'Создать',
      onSave: _save,
      fields: [
        AppFieldSpec.text(
          label: 'Фамилия *',
          controller: _lastNameCtrl,
          validator: (v) => Validators.combine([
            () => Validators.required(v, field: 'Фамилия'),
            () => Validators.maxLength(v, 50, field: 'Фамилия'),
          ]),
        ),
        AppFieldSpec.text(
          label: 'Имя *',
          controller: _firstNameCtrl,
          validator: (v) => Validators.combine([
            () => Validators.required(v, field: 'Имя'),
            () => Validators.maxLength(v, 50, field: 'Имя'),
          ]),
        ),
        AppFieldSpec.text(
          label: 'Телефон *',
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          validator: Validators.phone,
        ),
        AppFieldSpec.text(
          label: 'Email *',
          controller: _emailCtrl,
          errorText: _emailUniqueError,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
          onTextChanged: (_) {
            if (_emailUniqueError != null){
              setState(() => _emailUniqueError = null);}
          },
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
          label: 'Страна *',
          controller: _countryCtrl,
          validator: (v) => Validators.combine([
            () => Validators.required(v, field: 'Страна'),
            () => Validators.maxLength(v, 80, field: 'Страна'),
          ]),
        ),
      ],
    );
  }
}
