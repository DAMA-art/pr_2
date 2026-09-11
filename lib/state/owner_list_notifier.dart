import 'package:flutter/foundation.dart';

import '../api/app_exceptions.dart';
import '../models/owner.dart';
import '../models/owner_query.dart';
import '../models/page_result.dart';
import '../repositories/owner_repository.dart';
import 'load_status.dart';

class OwnerListNotifier extends ChangeNotifier {
  final OwnerRepository _repository;

  OwnerListNotifier(this._repository);

  OwnerQuery _query = const OwnerQuery();
  PageResult<Owner> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  List<String> cities = const [];

  OwnerQuery get query => _query;
  PageResult<Owner> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repository.find(_query);
      cities = await _repository.distinctCities();
      _status = LoadStatus.success;
    } on CancelledException {
      return;
    } catch (e) {
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(OwnerQuery next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
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
