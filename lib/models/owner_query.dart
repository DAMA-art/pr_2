class OwnerQuery {
  final String search;
  final String? city;
  final String? country;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const OwnerQuery({
    this.search = '',
    this.city,
    this.country,
    this.sortField = 'lastName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  OwnerQuery copyWith({
    String? search,
    Object? city = _unset,
    Object? country = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return OwnerQuery(
      search: search ?? this.search,
      city: city == _unset ? this.city : city as String?,
      country: country == _unset ? this.country : country as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();
}
