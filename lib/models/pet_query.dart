class PetQuery {
  final String search;
  final String? species;
  final int? ownerId;
  final int? ageFrom;
  final int? ageTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const PetQuery({
    this.search = '',
    this.species,
    this.ownerId,
    this.ageFrom,
    this.ageTo,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  PetQuery copyWith({
    String? search,
    Object? species = _unset,
    Object? ownerId = _unset,
    Object? ageFrom = _unset,
    Object? ageTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return PetQuery(
      search: search ?? this.search,
      species: species == _unset ? this.species : species as String?,
      ownerId: ownerId == _unset ? this.ownerId : ownerId as int?,
      ageFrom: ageFrom == _unset ? this.ageFrom : ageFrom as int?,
      ageTo: ageTo == _unset ? this.ageTo : ageTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1, // при смене фильтров — на первую страницу
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();
}