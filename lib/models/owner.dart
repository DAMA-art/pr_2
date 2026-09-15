import '../utils/json_helpers.dart';

class Owner {
  final int id;
  final String lastName;
  final String firstName;
  final String phone;
  final String email;
  final String city;
  final String country;
  final DateTime? deletedAt;

  const Owner({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.phone,
    required this.email,
    required this.city,
    required this.country,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  String get fullName => '$lastName $firstName';

  Owner copyWith({
    String? lastName,
    String? firstName,
    String? phone,
    String? email,
    String? city,
    String? country,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Owner(
      id: id,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      city: city ?? this.city,
      country: country ?? this.country,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'lastName': lastName,
    'firstName': firstName,
    'phone': phone,
    'email': email,
    'city': city,
    'country': country,
  };

  factory Owner.fromJson(Map<String, dynamic>? json) {
    final map = JsonHelpers.asMap(json);
    return Owner(
      id: JsonHelpers.asInt(map['id']),
      lastName: JsonHelpers.asString(map['lastName']),
      firstName: JsonHelpers.asString(map['firstName']),
      phone: JsonHelpers.asString(map['phone']),
      email: JsonHelpers.asString(map['email']),
      city: JsonHelpers.asString(map['city']),
      country: JsonHelpers.asString(map['country']),
      deletedAt: JsonHelpers.asDateTime(map['deletedAt']),
    );
  }
}
