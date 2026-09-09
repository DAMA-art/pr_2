class PetPassportQuery {
  final String search;
  final int? petId;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const PetPassportQuery({
    this.search = '',
    this.petId,
    this.sortField = 'number',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  PetPassportQuery copyWith({
    String? search,
    Object? petId = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return PetPassportQuery(
      search: search ?? this.search,
      petId: petId == _unset ? this.petId : petId as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();
}
