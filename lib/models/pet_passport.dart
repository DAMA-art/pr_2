import '../utils/json_helpers.dart';

class PetPassport {
  final int id;
  final int petId;
  final String number;
  final String microchip;
  final DateTime issuedAt;
  final DateTime? deletedAt;

  const PetPassport({
    required this.id,
    required this.petId,
    required this.number,
    required this.microchip,
    required this.issuedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  PetPassport copyWith({
    int? petId,
    String? number,
    String? microchip,
    DateTime? issuedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return PetPassport(
      id: id,
      petId: petId ?? this.petId,
      number: number ?? this.number,
      microchip: microchip ?? this.microchip,
      issuedAt: issuedAt ?? this.issuedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'petId': petId,
    'number': number,
    'microchip': microchip,
    'issuedAt': issuedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory PetPassport.fromJson(Map<String, dynamic>? json) {
    final map = JsonHelpers.asMap(json);
    return PetPassport(
      id: JsonHelpers.asInt(map['id']),
      petId: JsonHelpers.asInt(map['petId']),
      number: JsonHelpers.asString(map['number']),
      microchip: JsonHelpers.asString(map['microchip']),
      issuedAt: JsonHelpers.asDateTime(map['issuedAt']) ?? DateTime.now(),
      deletedAt: JsonHelpers.asDateTime(map['deletedAt']),
    );
  }
}
