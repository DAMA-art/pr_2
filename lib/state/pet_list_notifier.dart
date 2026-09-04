import 'package:flutter/foundation.dart';

import '../models/page_result.dart';
import '../models/pet.dart';
import '../models/pet_query.dart';
import '../repositories/pet_repository.dart';

enum LoadStatus { idle, loading, success, error }

class PetListNotifier extends ChangeNotifier {
  final PetRepository _repository;

  PetListNotifier(this._repository);

  PetQuery _query = const PetQuery();
  PageResult<Pet> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  PetQuery get query => _query;
  PageResult<Pet> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      //throw Exception('Сервер недоступен');
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(PetQuery next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  Future<void> deleteSelected({bool hard = false}) async {
    if (hard) {
      for (final id in _selected) {
        await _repository.hardDelete(id);
      }
    } else {
      await _repository.deleteMany(_selected.toList());
    }
    _selected.clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }
}