import '../utils/json_helpers.dart';

class Clinic {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String city;
  final DateTime? deletedAt;

  const Clinic({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.city,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Clinic copyWith({
    String? name,
    String? address,
    String? phone,
    String? city,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Clinic(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'city': city,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Clinic.fromJson(Map<String, dynamic>? json) {
    final map = JsonHelpers.asMap(json);
    return Clinic(
      id: JsonHelpers.asInt(map['id']),
      name: JsonHelpers.asString(map['name']),
      address: JsonHelpers.asString(map['address']),
      phone: JsonHelpers.asString(map['phone']),
      city: JsonHelpers.asString(map['city']),
      deletedAt: JsonHelpers.asDateTime(map['deletedAt']),
    );
  }
}
