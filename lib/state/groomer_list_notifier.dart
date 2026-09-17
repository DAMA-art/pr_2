import 'package:flutter/foundation.dart';

import '../api/app_exceptions.dart';
import '../models/groomer.dart';
import '../models/groomer_query.dart';
import '../models/page_result.dart';
import '../repositories/groomer_repository.dart';
import 'load_status.dart';

class GroomerListNotifier extends ChangeNotifier {
  final GroomerRepository _repo;
  GroomerQuery _query = const GroomerQuery();
  PageResult<Groomer> _result = PageResult.empty();
  LoadStatus status = LoadStatus.idle;
  String? error;
  final Set<int> selected = {};

  GroomerListNotifier(this._repo);

  GroomerQuery get query => _query;
  PageResult<Groomer> get result => _result;
  bool get hasSelection => selected.isNotEmpty;

  Future<void> load() async {
    status = LoadStatus.loading;
    error = null;
    notifyListeners();
    try {
      _result = await _repo.find(_query);
      status = LoadStatus.success;
    } on CancelledException {
      return;
    } catch (e) {
      error = e.toString();
      status = LoadStatus.error;
    }
    notifyListeners();
  }

  void applyQuery(GroomerQuery q) {
    _query = q;
    selected.clear();
    load();
  }

  void toggleSelection(int id) {
    selected.contains(id) ? selected.remove(id) : selected.add(id);
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    await _repo.deleteMany(selected.toList());
    selected.clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repo.softDelete(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repo.hardDelete(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repo.restore(id);
    await load();
  }
}
