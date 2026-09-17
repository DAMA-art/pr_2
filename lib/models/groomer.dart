class Groomer {
  final int id;
  final String fullName;
  final String phone;
  final String specialization;
  final int clinicId;
  final String? clinicName;
  final int experienceYears;
  final DateTime? deletedAt;

  const Groomer({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.specialization,
    required this.clinicId,
    this.clinicName,
    this.experienceYears = 0,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  String get specializationLabel => switch (specialization) {
        'dogs' => 'Собаки',
        'cats' => 'Кошки',
        'horse' => 'Лошади',
        _ => 'Все виды',
      };
}
