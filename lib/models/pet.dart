import '../utils/json_helpers.dart';

class Pet {
  final int id;
  final String name;
  final String species;
  final String breed;
  final String chipNumber;
  final int ageMonths;
  final double weightKg;
  final int clinicId;
  final List<int> ownerIds;
  final List<int> serviceIds;
  final String notes;
  final DateTime? deletedAt;

  const Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.chipNumber,
    required this.ageMonths,
    required this.weightKg,
    required this.clinicId,
    required this.ownerIds,
    required this.serviceIds,
    this.notes = '',
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Pet copyWith({
    String? name,
    String? species,
    String? breed,
    String? chipNumber,
    int? ageMonths,
    double? weightKg,
    int? clinicId,
    List<int>? ownerIds,
    List<int>? serviceIds,
    String? notes,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Pet(
      id: id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      chipNumber: chipNumber ?? this.chipNumber,
      ageMonths: ageMonths ?? this.ageMonths,
      weightKg: weightKg ?? this.weightKg,
      clinicId: clinicId ?? this.clinicId,
      ownerIds: ownerIds ?? this.ownerIds,
      serviceIds: serviceIds ?? this.serviceIds,
      notes: notes ?? this.notes,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'species': species,
        'breed': breed,
        'chipNumber': chipNumber,
        'ageMonths': ageMonths,
        'weightKg': weightKg,
        'clinicId': clinicId,
        'ownerIds': ownerIds,
        'serviceIds': serviceIds,
        'notes': notes,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Pet.fromJson(Map<String, dynamic>? json) {
    final map = JsonHelpers.asMap(json);
    var ownerIds = JsonHelpers.asIntList(map['ownerIds']);
    if (ownerIds.isEmpty) {
      final single = JsonHelpers.asInt(map['ownerId']);
      if (single > 0) ownerIds = [single];
    }
    return Pet(
      id: JsonHelpers.asInt(map['id']),
      name: JsonHelpers.asString(map['name']),
      species: JsonHelpers.asString(map['species'], 'cat'),
      breed: JsonHelpers.asString(map['breed']),
      chipNumber: JsonHelpers.asString(map['chipNumber']),
      ageMonths: JsonHelpers.asInt(map['ageMonths']),
      weightKg: JsonHelpers.asDouble(map['weightKg']),
      clinicId: JsonHelpers.asInt(map['clinicId']),
      ownerIds: ownerIds,
      serviceIds: JsonHelpers.asIntList(map['serviceIds']),
      notes: JsonHelpers.asString(map['notes']),
      deletedAt: JsonHelpers.asDateTime(map['deletedAt']),
    );
  }
}
