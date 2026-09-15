import 'package:flutter/foundation.dart';

import '../api/app_exceptions.dart';
import '../models/page_result.dart';
import '../models/service.dart';
import '../models/service_query.dart';
import '../repositories/service_repository.dart';
import 'load_status.dart';

class ServiceListNotifier extends ChangeNotifier {
  final ServiceRepository _repo;
  ServiceQuery _query = const ServiceQuery();
  PageResult<Service> _result = PageResult.empty();
  LoadStatus status = LoadStatus.idle;
  String? error;
  final Set<int> selected = {};

  ServiceListNotifier(this._repo);

  ServiceQuery get query => _query;
  PageResult<Service> get result => _result;
  bool get loading => status == LoadStatus.loading;
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

  void applyQuery(ServiceQuery q) {
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
