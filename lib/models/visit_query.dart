class VisitQuery {
  final String search;
  final int? clinicId;
  final String? status;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const VisitQuery({
    this.search = '',
    this.clinicId,
    this.status,
    this.sortField = 'issued_at',
    this.sortAscending = false,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  VisitQuery copyWith({
    String? search,
    Object? clinicId = _unset,
    Object? status = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return VisitQuery(
      search: search ?? this.search,
      clinicId: clinicId == _unset ? this.clinicId : clinicId as int?,
      status: status == _unset ? this.status : status as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();
}
