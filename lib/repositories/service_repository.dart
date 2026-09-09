import '../models/page_result.dart';
import '../models/service.dart';
import '../models/service_query.dart';

abstract interface class ServiceRepository {
  Future<PageResult<Service>> find(ServiceQuery query);
  Future<Service?> findById(int id);
  Future<List<Service>> findAllActive();
  Future<Service> create(Service service);
  Future<Service> update(Service service);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<bool> isNameUnique(String name, {int? excludeId});
  Future<int> countByClinic(int clinicId);
}