import 'package:flutter/material.dart';
import '../models/page_result.dart';

class PaginationBar extends StatelessWidget {
  final PageResult result;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;
  final int currentSize;

  const PaginationBar({
    super.key,
    required this.result,
    required this.onPageChanged,
    required this.onSizeChanged,
    required this.currentSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Всего: ${result.total}', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: result.hasPrevious ? () => onPageChanged(1) : null,
            tooltip: 'Первая',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: result.hasPrevious ? () => onPageChanged(result.page - 1) : null,
            tooltip: 'Предыдущая',
          ),
          Text('Стр. ${result.page} из ${result.totalPages}'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: result.hasNext ? () => onPageChanged(result.page + 1) : null,
            tooltip: 'Следующая',
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: result.hasNext ? () => onPageChanged(result.totalPages) : null,
            tooltip: 'Последняя',
          ),
          const SizedBox(width: 16),
          const Text('На странице:'),
          DropdownButton<int>(
            value: currentSize,
            items: const [
              DropdownMenuItem(value: 10, child: Text('10')),
              DropdownMenuItem(value: 25, child: Text('25')),
              DropdownMenuItem(value: 50, child: Text('50')),
            ],
            onChanged: (v) {
              if (v != null) onSizeChanged(v);
            },
          ),
        ],
      ),
    );
  }
}