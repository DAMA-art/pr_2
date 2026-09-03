import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/pet.dart';
import '../repositories/pet_repository.dart';

class PetDetailScreen extends StatefulWidget {
  final int id;

  const PetDetailScreen({super.key, required this.id});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
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
      final repo = context.read<PetRepository>();
      final pet = await repo.findById(widget.id);
      setState(() {
        _pet = pet;
        _loading = false;
        if (pet == null) _error = 'Питомец не найден';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pet?.name ?? 'Питомец'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/pets'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _pet == null
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
                                'Имя: ${_pet!.name}',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text('Вид: ${_speciesLabel(_pet!.species)}'),
                              Text('Порода: ${_pet!.breed}'),
                              Text('Возраст: ${_pet!.ageMonths} мес.'),
                              Text('Вес: ${_pet!.weightKg} кг'),
                              Text('ID владельца: ${_pet!.ownerId}'),
                              if (_pet!.notes.isNotEmpty) Text('Заметки: ${_pet!.notes}'),
                              if (_pet!.isDeleted)
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

  String _speciesLabel(String s) {
    return switch (s) {
      'dog' => 'Собака',
      'cat' => 'Кошка',
      'rabbit' => 'Кролик',
      'bird' => 'Птица',
      _ => s,
    };
  }
}