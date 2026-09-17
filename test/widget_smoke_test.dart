import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pr_2/models/page_result.dart';
import 'package:pr_2/screens/forbidden_screen.dart';
import 'package:pr_2/screens/login_screen.dart';
import 'package:pr_2/state/auth_notifier.dart';
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

  testWidgets('Индикатор загрузки виден', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Пустой результат — текст', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Ничего не найдено'))),
      ),
    );
    expect(find.text('Ничего не найдено'), findsOneWidget);
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
}
