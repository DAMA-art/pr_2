import '../models/page_result.dart';
import '../models/pet.dart';
import '../models/pet_query.dart';

abstract interface class PetRepository {
  Future<PageResult<Pet>> find(PetQuery query);
  Future<Pet?> findById(int id);
  Future<List<Pet>> findAllActive();
  Future<Pet> create(Pet pet);
  Future<Pet> update(Pet pet);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<bool> isChipUnique(String chipNumber, {int? excludeId});
  Future<int> countByOwner(int ownerId);
  Future<int> countByClinic(int clinicId);
}
