import '../utils/json_helpers.dart';

class Clinic {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String city;
  final int slotsTotal;
  final int slotsAvailable;
  final DateTime? deletedAt;

  const Clinic({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.city,
    this.slotsTotal = 0,
    this.slotsAvailable = 0,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Clinic copyWith({
    String? name,
    String? address,
    String? phone,
    String? city,
    int? slotsTotal,
    int? slotsAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Clinic(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      slotsTotal: slotsTotal ?? this.slotsTotal,
      slotsAvailable: slotsAvailable ?? this.slotsAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'phone': phone,
    'city': city,
    'slotsTotal': slotsTotal,
  };

  factory Clinic.fromJson(Map<String, dynamic>? json) {
    final map = JsonHelpers.asMap(json);
    final slots = JsonHelpers.asInt(map['slotsTotal']);
    return Clinic(
      id: JsonHelpers.asInt(map['id']),
      name: JsonHelpers.asString(map['name']),
      address: JsonHelpers.asString(map['address']),
      phone: JsonHelpers.asString(map['phone']),
      city: JsonHelpers.asString(map['city']),
      slotsTotal: slots,
      slotsAvailable: JsonHelpers.asInt(map['slotsAvailable'], slots),
      deletedAt: JsonHelpers.asDateTime(map['deletedAt']),
    );
  }
}
