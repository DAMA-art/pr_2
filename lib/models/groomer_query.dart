class GroomerQuery {
  final String search;
  final int? clinicId;
  final String? specialization;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const GroomerQuery({
    this.search = '',
    this.clinicId,
    this.specialization,
    this.sortField = 'full_name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  GroomerQuery copyWith({
    String? search,
    Object? clinicId = _unset,
    Object? specialization = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return GroomerQuery(
      search: search ?? this.search,
      clinicId: clinicId == _unset ? this.clinicId : clinicId as int?,
      specialization: specialization == _unset
          ? this.specialization
          : specialization as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();
}
