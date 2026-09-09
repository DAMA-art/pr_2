import '../utils/json_helpers.dart';

class Service {
  final int id;
  final String name;
  final String description;
  final double price;
  final int clinicId;
  final DateTime? deletedAt;

  const Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.clinicId,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Service copyWith({
    String? name,
    String? description,
    double? price,
    int? clinicId,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Service(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      clinicId: clinicId ?? this.clinicId,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'clinicId': clinicId,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Service.fromJson(Map<String, dynamic>? json) {
    final map = JsonHelpers.asMap(json);
    return Service(
      id: JsonHelpers.asInt(map['id']),
      name: JsonHelpers.asString(map['name']),
      description: JsonHelpers.asString(map['description']),
      price: JsonHelpers.asDouble(map['price']),
      clinicId: JsonHelpers.asInt(map['clinicId']),
      deletedAt: JsonHelpers.asDateTime(map['deletedAt']),
    );
  }
}
