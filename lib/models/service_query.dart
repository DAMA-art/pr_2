class ServiceQuery {
  final String search;
  final int? clinicId;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const ServiceQuery({
    this.search = '',
    this.clinicId,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  ServiceQuery copyWith({
    String? search,
    Object? clinicId = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return ServiceQuery(
      search: search ?? this.search,
      clinicId: clinicId == _unset ? this.clinicId : clinicId as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();
}
