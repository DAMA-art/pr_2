import '../models/page_result.dart';
import '../models/groomer.dart';
import '../models/groomer_query.dart';

abstract interface class GroomerRepository {
  Future<PageResult<Groomer>> find(GroomerQuery query);
  Future<Groomer?> findById(int id);
  Future<List<Groomer>> findAllActive();
  Future<List<Groomer>> findByClinic(int clinicId);
  Future<Groomer> create(Groomer groomer);
  Future<Groomer> update(Groomer groomer);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
