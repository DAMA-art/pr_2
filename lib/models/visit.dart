import '../utils/json_helpers.dart';

class Visit {
  final int id;
  final int petId;
  final String? petName;
  final int clinicId;
  final String? clinicName;
  final DateTime issuedAt;
  final DateTime dueAt;
  final DateTime? returnedAt;
  final String status;
  final DateTime? deletedAt;

  const Visit({
    required this.id,
    required this.petId,
    this.petName,
    required this.clinicId,
    this.clinicName,
    required this.issuedAt,
    required this.dueAt,
    this.returnedAt,
    this.status = 'active',
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get isActive => returnedAt == null && status != 'returned';

  factory Visit.fromJson(Map<String, dynamic>? json) {
    final map = JsonHelpers.asMap(json);
    final pet = JsonHelpers.asMap(map['pet']);
    final clinic = JsonHelpers.asMap(map['clinic']);
    return Visit(
      id: JsonHelpers.asInt(map['id']),
      petId: pet.isNotEmpty
          ? JsonHelpers.asInt(pet['id'])
          : JsonHelpers.asInt(map['petId']),
      petName: pet.isNotEmpty ? JsonHelpers.asString(pet['name']) : null,
      clinicId: clinic.isNotEmpty
          ? JsonHelpers.asInt(clinic['id'])
          : JsonHelpers.asInt(map['clinicId']),
      clinicName: clinic.isNotEmpty
          ? JsonHelpers.asString(clinic['name'])
          : null,
      issuedAt: JsonHelpers.asDateTime(map['issuedAt']) ?? DateTime.now(),
      dueAt: JsonHelpers.asDateTime(map['dueAt']) ?? DateTime.now(),
      returnedAt: JsonHelpers.asDateTime(map['returnedAt']),
      status: JsonHelpers.asString(map['status'], 'active'),
      deletedAt: JsonHelpers.asDateTime(map['deletedAt']),
    );
  }
}
