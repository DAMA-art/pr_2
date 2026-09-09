import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/pet.dart';
import '../models/pet_passport.dart';
import '../repositories/pet_repository.dart';
import '../repositories/pet_passport_repository.dart';

class PassportDetailScreen extends StatefulWidget {
  final int id;
  const PassportDetailScreen({super.key, required this.id});

  @override
  State<PassportDetailScreen> createState() => _PassportDetailScreenState();
}

class _PassportDetailScreenState extends State<PassportDetailScreen> {
  PetPassport? _passport;
  Pet? _pet;
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
      final passportRepo = context.read<PetPassportRepository>();
      final petRepo = context.read<PetRepository>();
      final passport = await passportRepo.findById(widget.id);
      Pet? pet;
      if (passport != null) {
        pet = await petRepo.findById(passport.petId);
      }
      setState(() {
        _passport = passport;
        _pet = pet;
        _loading = false;
        if (passport == null) _error = 'Паспорт не найден';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _delete() async {
    final passport = _passport;
    if (passport == null) return;
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить?'),
        content: Text('Удалить паспорт «${passport.number}»?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Нет')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Да')),
        ],
      ),
    );
    if (conf == true && mounted) {
      await context.read<PetPassportRepository>().softDelete(passport.id);
      if (mounted) context.go('/passports');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy');
    return Scaffold(
      appBar: AppBar(
        title: Text(_passport?.number ?? 'Паспорт'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/passports')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final ok = await context.push('/passports/${widget.id}/edit');
              if (ok == true && mounted) _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _passport == null || _passport!.isDeleted ? null : _delete,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _passport == null
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
                              Text(_passport!.number, style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 12),
                              Text('Питомец: ${_pet?.name ?? _passport!.petId}'),
                              Text('Микрочип: ${_passport!.microchip}'),
                              Text('Выдан: ${fmt.format(_passport!.issuedAt)}'),
                              if (_passport!.isDeleted)
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
