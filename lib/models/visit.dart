import '../utils/json_helpers.dart';

class Visit {
  final int id;
  final int petId;
  final String? petName;
  final int clinicId;
  final String? clinicName;
  final int? groomerId;
  final String? groomerName;
  final DateTime issuedAt;
  final DateTime dueAt;
  final DateTime? returnedAt;
  final String status;
  final double totalPrice;
  final List<int> serviceIds;
  final DateTime? deletedAt;

  const Visit({
    required this.id,
    required this.petId,
    this.petName,
    required this.clinicId,
    this.clinicName,
    this.groomerId,
    this.groomerName,
    required this.issuedAt,
    required this.dueAt,
    this.returnedAt,
    this.status = 'scheduled',
    this.totalPrice = 0,
    this.serviceIds = const [],
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get isActive =>
      returnedAt == null &&
      status != 'returned' &&
      status != 'done' &&
      status != 'cancelled';

  String get statusLabel => switch (status) {
        'scheduled' => 'Запись',
        'active' => 'В работе',
        'done' => 'Завершена',
        'returned' => 'Завершена',
        'cancelled' => 'Отменена',
        _ => status,
      };

  factory Visit.fromJson(Map<String, dynamic>? json) {
    final map = JsonHelpers.asMap(json);
    final pet = JsonHelpers.asMap(map['pet']);
    final clinic = JsonHelpers.asMap(map['clinic']);
    final groomer = JsonHelpers.asMap(map['groomer']);
    return Visit(
      id: JsonHelpers.asInt(map['id']),
      petId: pet.isNotEmpty
          ? JsonHelpers.asInt(pet['id'])
          : JsonHelpers.asInt(map['petId'] ?? map['pet_id']),
      petName: pet.isNotEmpty ? JsonHelpers.asString(pet['name']) : null,
      clinicId: clinic.isNotEmpty
          ? JsonHelpers.asInt(clinic['id'])
          : JsonHelpers.asInt(map['clinicId'] ?? map['clinic_id']),
      clinicName: clinic.isNotEmpty ? JsonHelpers.asString(clinic['name']) : null,
      groomerId: groomer.isNotEmpty
          ? JsonHelpers.asInt(groomer['id'])
          : (map['groomer_id'] == null && map['groomerId'] == null
              ? null
              : JsonHelpers.asInt(map['groomerId'] ?? map['groomer_id'])),
      groomerName: groomer.isNotEmpty
          ? JsonHelpers.asString(groomer['full_name'] ?? groomer['fullName'])
          : null,
      issuedAt: JsonHelpers.asDateTime(map['issuedAt'] ?? map['issued_at']) ??
          DateTime.now(),
      dueAt:
          JsonHelpers.asDateTime(map['dueAt'] ?? map['due_at']) ?? DateTime.now(),
      returnedAt:
          JsonHelpers.asDateTime(map['returnedAt'] ?? map['returned_at']),
      status: JsonHelpers.asString(map['status'], 'scheduled'),
      totalPrice: JsonHelpers.asDouble(map['totalPrice'] ?? map['total_price']),
      serviceIds: JsonHelpers.asIntList(map['serviceIds'] ?? map['service_ids']),
      deletedAt: JsonHelpers.asDateTime(map['deletedAt'] ?? map['deleted_at']),
    );
  }
}
