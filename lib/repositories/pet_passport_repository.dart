import '../models/page_result.dart';
import '../models/pet_passport.dart';
import '../models/pet_passport_query.dart';

abstract interface class PetPassportRepository {
  Future<PageResult<PetPassport>> find(PetPassportQuery query);
  Future<PetPassport?> findById(int id);
  Future<PetPassport?> findByPetId(int petId);
  Future<List<PetPassport>> findAllActive();
  Future<PetPassport> create(PetPassport passport);
  Future<PetPassport> update(PetPassport passport);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<bool> isNumberUnique(String number, {int? excludeId});
  Future<bool> isPetFree(int petId, {int? excludeId});
}
