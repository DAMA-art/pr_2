import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pr_2/models/page_result.dart';
import 'package:pr_2/screens/forbidden_screen.dart';
import 'package:pr_2/screens/login_screen.dart';
import 'package:pr_2/state/auth_notifier.dart';
import 'package:pr_2/widgets/confirm_delete.dart';
import 'package:pr_2/widgets/entity_form.dart';
import 'package:pr_2/widgets/entity_table.dart';
import 'package:pr_2/widgets/pagination_bar.dart';
import 'package:pr_2/widgets/search_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LoginScreen показывает заголовок', (tester) async {
    final auth = AuthNotifier();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthNotifier>.value(
        value: auth,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Вход'), findsWidgets);
  });

  testWidgets('ForbiddenScreen показывает отказ', (tester) async {
    final auth = AuthNotifier();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthNotifier>.value(
        value: auth,
        child: const MaterialApp(home: ForbiddenScreen()),
      ),
    );
    await tester.pump();
    expect(find.textContaining('прав'), findsWidgets);
  });

  testWidgets('PaginationBar показывает номер страницы', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaginationBar(
            result: const PageResult<int>(
              items: [1, 2],
              page: 1,
              size: 10,
              total: 12,
            ),
            currentSize: 10,
            onPageChanged: (_) {},
            onSizeChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.textContaining('Стр. 1'), findsOneWidget);
    expect(find.textContaining('Всего: 12'), findsOneWidget);
  });

  testWidgets('SearchField отображает подсказку', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchField(
            hintText: 'Поиск по кличке',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Поиск по кличке'), findsOneWidget);
  });

  testWidgets('EntityFormScaffold показывает ошибку обязательного поля', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: EntityFormScaffold(
          title: 'Новый питомец',
          formKey: formKey,
          fields: [
            AppFieldSpec.text(
              label: 'Кличка *',
              controller: controller,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Кличка обязательна' : null,
            ),
          ],
          onSave: () async => formKey.currentState?.validate() ?? false,
        ),
      ),
    );
    await tester.tap(find.text('Сохранить'));
    await tester.pump();
    expect(find.text('Кличка обязательна'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('EntityTable без onToggleSelect не рисует чекбоксы', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EntityTable<String>(
            items: const ['Барсик'],
            idOf: (_) => 1,
            columns: [
              TableColumnSpec(label: 'Имя', build: (v) => Text(v)),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Барсик'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('confirmDeleteMode предлагает логическое и физическое удаление', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => confirmDeleteMode(
                context,
                title: 'Удаление питомца',
                body: 'Удалить «Барсик»?',
              ),
              child: const Text('Удалить'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    expect(find.text('Логически'), findsOneWidget);
    expect(find.text('Физически'), findsOneWidget);
  });
}
