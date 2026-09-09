const speciesItems = <(String value, String label)>[
  ('cat', 'Кошка'),
  ('dog', 'Собака'),
  ('rabbit', 'Кролик'),
  ('bird', 'Птица'),
];

String speciesLabel(String value) {
  for (final item in speciesItems) {
    if (item.$1 == value) return item.$2;
  }
  return value;
}
