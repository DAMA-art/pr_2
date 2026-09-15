import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;
  final bool Function(T item)? isDeleted;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
    this.isDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              child: DataTable(
                sortColumnIndex: _sortColumnIndex(),
                sortAscending: sortAscending,
                columns: [
                  if (onToggleSelect != null) const DataColumn(label: Text('')),
                  ...columns.map((col) {
                    return DataColumn(
                      label: Text(col.label),
                      numeric: col.numeric,
                      onSort: col.sortField != null && onSort != null
                          ? (columnIndex, ascending) => onSort!(col.sortField!)
                          : null,
                    );
                  }),
                  if (actions != null)
                    const DataColumn(label: Text('Действия')),
                ],
                rows: items.map((item) {
                  final id = idOf(item);
                  final deleted = isDeleted?.call(item) ?? false;
                  return DataRow(
                    selected: selected.contains(id),
                    onSelectChanged: onToggleSelect != null
                        ? (_) => onToggleSelect!(id)
                        : null,
                    color: deleted
                        ? WidgetStateProperty.all(
                            Colors.red.withValues(alpha: 0.08),
                          )
                        : null,
                    cells: [
                      if (onToggleSelect != null)
                        DataCell(
                          Checkbox(
                            value: selected.contains(id),
                            onChanged: (_) => onToggleSelect!(id),
                          ),
                        ),
                      ...columns.map((col) => DataCell(col.build(item))),
                      if (actions != null)
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: actions!(item),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  int? _sortColumnIndex() {
    if (sortField == null) return null;
    int offset = onToggleSelect != null ? 1 : 0;
    for (var i = 0; i < columns.length; i++) {
      if (columns[i].sortField == sortField) return i + offset;
    }
    return null;
  }
}
