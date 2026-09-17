import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/app_exceptions.dart';
import '../models/clinic.dart';
import '../models/groomer.dart';
import '../repositories/clinic_repository.dart';
import '../repositories/groomer_repository.dart';
import '../utils/validators.dart';
import '../widgets/entity_form.dart';

class GroomerFormScreen extends StatefulWidget {
  final int? id;
  const GroomerFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<GroomerFormScreen> createState() => _GroomerFormScreenState();
}

class _GroomerFormScreenState extends State<GroomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _expCtrl = TextEditingController(text: '1');
  String _spec = 'all';
  int? _clinicId;
  bool _loading = true;
  bool _saving = false;
  List<Clinic> _clinics = [];
  String? _nameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final clinicRepo = context.read<ClinicRepository>();
    final groomerRepo = context.read<GroomerRepository>();
    _clinics = await clinicRepo.findAllActive();
    if (widget.isEditing) {
      final g = await groomerRepo.findById(widget.id!);
      if (g != null && mounted) {
        _nameCtrl.text = g.fullName;
        _phoneCtrl.text = g.phone;
        _expCtrl.text = '${g.experienceYears}';
        _spec = g.specialization;
        _clinicId = g.clinicId == 0 ? null : g.clinicId;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _save() async {
    setState(() {
      _nameError = null;
      _phoneError = null;
    });
    if (!_formKey.currentState!.validate()) return false;
    setState(() => _saving = true);
    final g = Groomer(
      id: widget.id ?? 0,
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      specialization: _spec,
      clinicId: _clinicId ?? 0,
      experienceYears: int.parse(_expCtrl.text),
    );
    try {
      final repo = context.read<GroomerRepository>();
      if (widget.isEditing) {
        await repo.update(g);
      } else {
        await repo.create(g);
      }
      return true;
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() {
          _nameError = e.errorFor(['full_name', 'fullName', 'name']);
          _phoneError = e.errorFor(['phone']);
        });
        if (_nameError == null && _phoneError == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
      return false;
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EntityFormScaffold(
      title: widget.isEditing ? 'Редактирование мастера' : 'Новый мастер',
      loading: _loading,
      saving: _saving,
      formKey: _formKey,
      onSave: _save,
      fields: [
        AppFieldSpec.text(
          label: 'ФИО *',
          controller: _nameCtrl,
          errorText: _nameError,
          validator: (v) => Validators.combine([
            () => Validators.required(v, field: 'ФИО'),
            () => Validators.maxLength(v, 100, field: 'ФИО'),
          ]),
        ),
        AppFieldSpec.text(
          label: 'Телефон *',
          controller: _phoneCtrl,
          errorText: _phoneError,
          keyboardType: TextInputType.phone,
          validator: Validators.phone,
        ),
        AppFieldSpec.dropdown(
          label: 'Специализация *',
          value: _spec,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Все виды')),
            DropdownMenuItem(value: 'dogs', child: Text('Собаки')),
            DropdownMenuItem(value: 'cats', child: Text('Кошки')),
          ],
          onChanged: (v) => setState(() => _spec = v as String),
        ),
        AppFieldSpec.dropdown(
          label: 'Филиал *',
          value: _clinicId,
          items: [
            for (final c in _clinics)
              DropdownMenuItem<dynamic>(value: c.id, child: Text(c.name)),
          ],
          onChanged: (v) => setState(() => _clinicId = v as int?),
          dropdownValidator: (v) => v == null ? 'Выберите филиал' : null,
        ),
        AppFieldSpec.text(
          label: 'Стаж (лет) *',
          controller: _expCtrl,
          keyboardType: TextInputType.number,
          validator: (v) => Validators.rangeInt(v, 0, 50, field: 'Стаж'),
        ),
      ],
    );
  }
}
