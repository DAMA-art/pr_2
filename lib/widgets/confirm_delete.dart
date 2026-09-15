import 'package:flutter/material.dart';

Future<bool?> confirmDeleteMode(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Логически'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Физически'),
        ),
      ],
    ),
  );
}

Future<void> showBlockedDelete(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Понятно'),
        ),
      ],
    ),
  );
}
