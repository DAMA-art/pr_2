import 'package:flutter/foundation.dart';
import '../models/page_result.dart';
import '../models/pet_passport.dart';
import '../models/pet_passport_query.dart';
import '../repositories/pet_passport_repository.dart';
import 'load_status.dart';

class PassportListNotifier extends ChangeNotifier {
  final PetPassportRepository _repo;
  PetPassportQuery _query = const PetPassportQuery();
  PageResult<PetPassport> _result = PageResult.empty();
  LoadStatus status = LoadStatus.idle;
  String? error;
  final Set<int> selected = {};

  PassportListNotifier(this._repo);

  PetPassportQuery get query => _query;
  PageResult<PetPassport> get result => _result;
  bool get loading => status == LoadStatus.loading;
  bool get hasSelection => selected.isNotEmpty;

  Future<void> load() async {
    status = LoadStatus.loading;
    error = null;
    notifyListeners();
    try {
      _result = await _repo.find(_query);
      status = LoadStatus.success;
    } catch (e) {
      error = e.toString();
      status = LoadStatus.error;
    }
    notifyListeners();
  }

  void applyQuery(PetPassportQuery q) {
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
