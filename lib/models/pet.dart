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
  final String? clinicName;
  final List<int> ownerIds;
  final List<String> ownerNames;
  final List<int> serviceIds;
  final List<String> serviceNames;
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
    this.clinicName,
    required this.ownerIds,
    this.ownerNames = const [],
    required this.serviceIds,
    this.serviceNames = const [],
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
    String? clinicName,
    List<int>? ownerIds,
    List<String>? ownerNames,
    List<int>? serviceIds,
    List<String>? serviceNames,
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
      clinicName: clinicName ?? this.clinicName,
      ownerIds: ownerIds ?? this.ownerIds,
      ownerNames: ownerNames ?? this.ownerNames,
      serviceIds: serviceIds ?? this.serviceIds,
      serviceNames: serviceNames ?? this.serviceNames,
      notes: notes ?? this.notes,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
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
      };

  factory Pet.fromJson(Map<String, dynamic>? json) {
    final map = JsonHelpers.asMap(json);
    final clinic = JsonHelpers.asMap(map['clinic']);
    var ownerIds = JsonHelpers.asIntList(map['ownerIds']);
    var ownerNames = <String>[];
    final owners = map['owners'];
    if (owners is List) {
      ownerIds = [
        for (final o in owners) JsonHelpers.asInt(JsonHelpers.asMap(o)['id']),
      ];
      ownerNames = [
        for (final o in owners)
          JsonHelpers.asString(
            JsonHelpers.asMap(o)['fullName'].toString().isEmpty
                ? '${JsonHelpers.asMap(o)['lastName']} ${JsonHelpers.asMap(o)['firstName']}'
                : JsonHelpers.asMap(o)['fullName'],
          ),
      ];
    }
    if (ownerIds.isEmpty) {
      final single = JsonHelpers.asInt(map['ownerId']);
      if (single > 0) ownerIds = [single];
    }

    var serviceIds = JsonHelpers.asIntList(map['serviceIds']);
    var serviceNames = <String>[];
    final services = map['services'];
    if (services is List) {
      serviceIds = [
        for (final s in services) JsonHelpers.asInt(JsonHelpers.asMap(s)['id']),
      ];
      serviceNames = [
        for (final s in services) JsonHelpers.asString(JsonHelpers.asMap(s)['name']),
      ];
    }

    return Pet(
      id: JsonHelpers.asInt(map['id']),
      name: JsonHelpers.asString(map['name']),
      species: JsonHelpers.asString(map['species'], 'cat'),
      breed: JsonHelpers.asString(map['breed']),
      chipNumber: JsonHelpers.asString(map['chipNumber']),
      ageMonths: JsonHelpers.asInt(map['ageMonths']),
      weightKg: JsonHelpers.asDouble(map['weightKg']),
      clinicId: clinic.isNotEmpty
          ? JsonHelpers.asInt(clinic['id'])
          : JsonHelpers.asInt(map['clinicId']),
      clinicName: clinic.isNotEmpty ? JsonHelpers.asString(clinic['name']) : null,
      ownerIds: ownerIds,
      ownerNames: ownerNames,
      serviceIds: serviceIds,
      serviceNames: serviceNames,
      notes: JsonHelpers.asString(map['notes']),
      deletedAt: JsonHelpers.asDateTime(map['deletedAt']),
    );
  }
}
