import '../models/owner.dart';
import '../models/owner_query.dart';
import '../models/page_result.dart';

abstract interface class OwnerRepository {
  Future<PageResult<Owner>> find(OwnerQuery query);
  Future<Owner?> findById(int id);
  Future<Owner> create(Owner owner);
  Future<Owner> update(Owner owner);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}