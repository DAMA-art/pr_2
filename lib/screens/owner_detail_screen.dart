import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/owner.dart';
import '../repositories/owner_repository.dart';
import '../repositories/pet_repository.dart';
import '../widgets/confirm_delete.dart';

class OwnerDetailScreen extends StatefulWidget {
  final int id;
  const OwnerDetailScreen({super.key, required this.id});

  @override
  State<OwnerDetailScreen> createState() => _OwnerDetailScreenState();
}

class _OwnerDetailScreenState extends State<OwnerDetailScreen> {
  Owner? _owner;
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
      final owner = await context.read<OwnerRepository>().findById(widget.id);
      setState(() {
        _owner = owner;
        _loading = false;
        if (owner == null) _error = 'Владелец не найден';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _delete() async {
    final owner = _owner;
    if (owner == null) return;
    final count = await context.read<PetRepository>().countByOwner(owner.id);
    if (!mounted) return;
    if (count > 0) {
      await showBlockedDelete(
        context,
        title: 'Невозможно удалить',
        body:
            'Владелец «${owner.fullName}» связан с $count питомцами.\n'
            'Сначала удалите или переназначьте питомцев.',
      );
      return;
    }
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить?'),
        content: Text('Удалить владельца «${owner.fullName}»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Нет'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Да'),
          ),
        ],
      ),
    );
    if (conf == true && mounted) {
      await context.read<OwnerRepository>().softDelete(owner.id);
      if (mounted) context.go('/owners');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_owner?.fullName ?? 'Владелец'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/owners'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final ok = await context.push('/owners/${widget.id}/edit');
              if (ok == true && mounted) _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _owner == null || _owner!.isDeleted ? null : _delete,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _owner == null
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
                        _owner!.fullName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text('Телефон: ${_owner!.phone}'),
                      Text('Email: ${_owner!.email}'),
                      Text('Город: ${_owner!.city}'),
                      Text('Страна: ${_owner!.country}'),
                      if (_owner!.isDeleted)
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
}
