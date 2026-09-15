import 'package:flutter/foundation.dart';

import '../api/app_exceptions.dart';
import '../models/page_result.dart';
import '../models/clinic.dart';
import '../models/clinic_query.dart';
import '../repositories/clinic_repository.dart';
import 'load_status.dart';

class ClinicListNotifier extends ChangeNotifier {
  final ClinicRepository _repo;
  ClinicQuery _query = const ClinicQuery();
  PageResult<Clinic> _result = PageResult.empty();
  LoadStatus status = LoadStatus.idle;
  String? error;
  final Set<int> selected = {};
  List<String> cities = const [];

  ClinicListNotifier(this._repo);

  ClinicQuery get query => _query;
  PageResult<Clinic> get result => _result;
  bool get loading => status == LoadStatus.loading;
  bool get hasSelection => selected.isNotEmpty;

  Future<void> load() async {
    status = LoadStatus.loading;
    error = null;
    notifyListeners();
    try {
      _result = await _repo.find(_query);
      cities = await _repo.distinctCities();
      status = LoadStatus.success;
    } on CancelledException {
      return;
    } catch (e) {
      error = e.toString();
      status = LoadStatus.error;
    }
    notifyListeners();
  }

  void applyQuery(ClinicQuery q) {
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
