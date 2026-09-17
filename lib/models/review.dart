class Review {
  final int id;
  final int? visitId;
  final String authorId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime? deletedAt;

  const Review({
    required this.id,
    this.visitId,
    required this.authorId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
}
