import '../models/page_result.dart';
import '../models/clinic.dart';
import '../models/clinic_query.dart';

abstract interface class ClinicRepository {
  Future<PageResult<Clinic>> find(ClinicQuery query);
  Future<Clinic?> findById(int id);
  Future<List<Clinic>> findAllActive();
  Future<Clinic> create(Clinic clinic);
  Future<Clinic> update(Clinic clinic);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<bool> isNameUnique(String name, {int? excludeId});
  Future<List<String>> distinctCities();
}
