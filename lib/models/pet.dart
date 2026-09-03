class Pet {
  final int id;
  final String name;
  final String species;
  final String breed;
  final int ageMonths;
  final double weightKg;
  final int ownerId;
  final List<int> serviceIds;
  final String notes;
  final DateTime? deletedAt;

  const Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.ageMonths,
    required this.weightKg,
    required this.ownerId,
    required this.serviceIds,
    this.notes = '',
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Pet copyWith({
    String? name,
    String? species,
    String? breed,
    int? ageMonths,
    double? weightKg,
    int? ownerId,
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
      ageMonths: ageMonths ?? this.ageMonths,
      weightKg: weightKg ?? this.weightKg,
      ownerId: ownerId ?? this.ownerId,
      serviceIds: serviceIds ?? this.serviceIds,
      notes: notes ?? this.notes,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}