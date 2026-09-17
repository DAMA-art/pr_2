import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/app_exceptions.dart';
import '../models/review.dart';
import '../models/visit.dart';
import '../repositories/review_repository.dart';
import '../repositories/visit_repository.dart';
import '../utils/validators.dart';

class ReviewListScreen extends StatefulWidget {
  const ReviewListScreen({super.key});

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  final _repo = ReviewRepository();
  List<Review> _items = [];
  List<Visit> _visits = [];
  bool _loading = true;
  String? _error;
  bool _includeDeleted = false;
  final Set<int> _selected = {};

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
      final visitRepo = context.read<VisitRepository>();
      _items = await _repo.listMine(includeDeleted: _includeDeleted);
      _visits = await visitRepo.list();
    } on AppException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({Review? existing}) async {
    final ratingCtrl = TextEditingController(
      text: existing == null ? '5' : '${existing.rating}',
    );
    final commentCtrl = TextEditingController(text: existing?.comment ?? '');
    int? visitId = existing?.visitId;
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Новый отзыв' : 'Изменить отзыв'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int?>(
                  initialValue: visitId,
                  decoration: const InputDecoration(
                    labelText: 'Запись (необязательно)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Без записи')),
                    for (final v in _visits)
                      DropdownMenuItem(
                        value: v.id,
                        child: Text('${v.petName ?? 'Питомец'} · ${v.statusLabel}'),
                      ),
                  ],
                  onChanged: (v) => visitId = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ratingCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Оценка 1–5 *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => Validators.rangeInt(v, 1, 5, field: 'Оценка'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: commentCtrl,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Комментарий *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => Validators.combine([
                    () => Validators.required(v, field: 'Комментарий'),
                    () => Validators.minLength(v, 5, field: 'Комментарий'),
                    () => Validators.maxLength(v, 1000, field: 'Комментарий'),
                  ]),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    try {
      if (existing == null) {
        await _repo.create(
          rating: int.parse(ratingCtrl.text),
          comment: commentCtrl.text.trim(),
          visitId: visitId,
        );
      } else {
        await _repo.update(
          Review(
            id: existing.id,
            visitId: visitId,
            authorId: existing.authorId,
            rating: int.parse(ratingCtrl.text),
            comment: commentCtrl.text.trim(),
            createdAt: existing.createdAt,
          ),
        );
      }
      _load();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои отзывы'),
        actions: [
          if (_selected.isNotEmpty)
            IconButton(
              tooltip: 'Удалить выбранные',
              onPressed: () async {
                await _repo.deleteMany(_selected.toList());
                _selected.clear();
                _load();
              },
              icon: const Icon(Icons.delete),
            ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Показать удалённые'),
                selected: _includeDeleted,
                onSelected: (v) {
                  setState(() {
                    _includeDeleted = v;
                    _selected.clear();
                  });
                  _load();
                },
              ),
            ),
          ),
          Expanded(child: _listBody()),
        ],
      ),
    );
  }

  Widget _listBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Вы ещё не оставляли отзывов'));
    }
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final r = _items[i];
        return ListTile(
          leading: Checkbox(
            value: _selected.contains(r.id),
            onChanged: (_) => setState(() {
              _selected.contains(r.id)
                  ? _selected.remove(r.id)
                  : _selected.add(r.id);
            }),
          ),
          title: Text(
            r.comment,
            style: TextStyle(
              decoration: r.isDeleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text('${r.createdAt.toLocal()}'.split('.').first),
          trailing: r.isDeleted
              ? IconButton(
                  icon: const Icon(Icons.restore, color: Colors.green),
                  onPressed: () async {
                    await _repo.restore(r.id);
                    _load();
                  },
                )
              : PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') _openForm(existing: r);
                    if (v == 'soft') {
                      await _repo.softDelete(r.id);
                      _load();
                    }
                    if (v == 'hard') {
                      await _repo.hardDelete(r.id);
                      _load();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Изменить')),
                    PopupMenuItem(
                      value: 'soft',
                      child: Text('Удалить логически'),
                    ),
                    PopupMenuItem(
                      value: 'hard',
                      child: Text('Удалить физически'),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
