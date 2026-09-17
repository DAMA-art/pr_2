class PetPassportQuery {
  final String search;
  final int? petId;
  final bool? hasMicrochip;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const PetPassportQuery({
    this.search = '',
    this.petId,
    this.hasMicrochip,
    this.sortField = 'number',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  PetPassportQuery copyWith({
    String? search,
    Object? petId = _unset,
    Object? hasMicrochip = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return PetPassportQuery(
      search: search ?? this.search,
      petId: petId == _unset ? this.petId : petId as int?,
      hasMicrochip:
          hasMicrochip == _unset ? this.hasMicrochip : hasMicrochip as bool?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();
}
