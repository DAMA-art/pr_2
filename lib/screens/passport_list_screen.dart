import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/pet.dart';
import '../models/pet_passport.dart';
import '../repositories/pet_repository.dart';
import '../state/passport_list_notifier.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/search_field.dart';

class PassportListScreen extends StatefulWidget {
  const PassportListScreen({super.key});

  @override
  State<PassportListScreen> createState() => _PassportListScreenState();
}

class _PassportListScreenState extends State<PassportListScreen> {
  List<Pet> _pets = [];

  @override
  void initState() {
    super.initState();
    context.read<PetRepository>().findAllActive().then((v) {
      if (mounted) setState(() => _pets = v);
    });
  }

  String _petName(int id) {
    for (final p in _pets) {
      if (p.id == id) return p.name;
    }
    return '#$id';
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PassportListNotifier>();
    final fmt = DateFormat('dd.MM.yyyy');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Паспорта'),
        actions: [
          if (notifier.hasSelection)
            IconButton(icon: const Icon(Icons.delete), onPressed: () => notifier.deleteSelected()),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final ok = await context.push('/passports/new');
              if (ok == true) notifier.load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SearchField(
                    initialValue: notifier.query.search,
                    hintText: 'Поиск по номеру или микрочипу...',
                    onChanged: (v) => notifier.applyQuery(notifier.query.copyWith(search: v, page: 1)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: 240,
                        child: DropdownButtonFormField<int?>(
                          isExpanded: true,
                          initialValue: notifier.query.petId,
                          decoration: const InputDecoration(
                            labelText: 'Питомец',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Все')),
                            for (final p in _pets)
                              DropdownMenuItem(value: p.id, child: Text(p.name)),
                          ],
                          onChanged: (v) =>
                              notifier.applyQuery(notifier.query.copyWith(petId: v, page: 1)),
                        ),
                      ),
                      FilterChip(
                        label: const Text('Показать удалённые'),
                        selected: notifier.query.includeDeleted,
                        onSelected: (v) =>
                            notifier.applyQuery(notifier.query.copyWith(includeDeleted: v, page: 1)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (notifier.loading) const LinearProgressIndicator(),
          Expanded(
            child: notifier.result.items.isEmpty
                ? const Center(child: Text('Нет паспортов'))
                : EntityTable<PetPassport>(
                    items: notifier.result.items,
                    idOf: (p) => p.id,
                    selected: notifier.selected,
                    onToggleSelect: notifier.toggleSelection,
                    sortField: notifier.query.sortField,
                    sortAscending: notifier.query.sortAscending,
                    isDeleted: (p) => p.isDeleted,
                    onSort: (field) {
                      final q = notifier.query;
                      notifier.applyQuery(q.copyWith(
                        sortField: field,
                        sortAscending: field == q.sortField ? !q.sortAscending : true,
                      ));
                    },
                    columns: [
                      TableColumnSpec(label: 'Номер', sortField: 'number', build: (p) => Text(p.number)),
                      TableColumnSpec(label: 'Питомец', build: (p) => Text(_petName(p.petId))),
                      TableColumnSpec(label: 'Микрочип', sortField: 'microchip', build: (p) => Text(p.microchip)),
                      TableColumnSpec(
                        label: 'Выдан',
                        sortField: 'issuedAt',
                        build: (p) => Text(fmt.format(p.issuedAt)),
                      ),
                    ],
                    actions: (p) => [
                      if (p.isDeleted)
                        IconButton(
                          icon: const Icon(Icons.restore, color: Colors.green),
                          onPressed: () => notifier.restore(p.id),
                        )
                      else ...[
                        IconButton(
                          icon: const Icon(Icons.visibility),
                          onPressed: () => context.go('/passports/${p.id}'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final ok = await context.push('/passports/${p.id}/edit');
                            if (ok == true) notifier.load();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(context, notifier, p),
                        ),
                      ],
                    ],
                  ),
          ),
          PaginationBar(
            result: notifier.result,
            currentSize: notifier.query.size,
            onPageChanged: (p) => notifier.applyQuery(notifier.query.copyWith(page: p)),
            onSizeChanged: (s) => notifier.applyQuery(notifier.query.copyWith(size: s, page: 1)),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, PassportListNotifier notifier, PetPassport p) async {
    final hard = await confirmDeleteMode(context, title: 'Удаление паспорта', body: 'Удалить «${p.number}»?');
    if (hard == null) return;
    if (hard) {
      await notifier.hardDelete(p.id);
    } else {
      await notifier.softDelete(p.id);
    }
  }
}
