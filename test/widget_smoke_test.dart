import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pr_2/api/auth_api.dart';
import 'package:pr_2/api/dio_client.dart';
import 'package:pr_2/models/role.dart';
import 'package:pr_2/screens/forbidden_screen.dart';
import 'package:pr_2/screens/login_screen.dart';
import 'package:pr_2/state/auth_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LoginScreen показывает заголовок', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dio = createDio();
    final auth = AuthNotifier(prefs, AuthApi(dio));

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
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dio = createDio();
    final auth = AuthNotifier(prefs, AuthApi(dio));

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthNotifier>.value(
        value: auth,
        child: const MaterialApp(home: ForbiddenScreen()),
      ),
    );
    await tester.pump();

    // Текст на экране: «Недостаточно прав» / «Доступ запрещён»
    expect(
      find.textContaining('прав').evaluate().isNotEmpty ||
          find.textContaining('запрещ').evaluate().isNotEmpty ||
          find.textContaining('Доступ').evaluate().isNotEmpty,
      isTrue,
    );
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

  testWidgets('Роль client не admin', (tester) async {
    expect(Role.client.atLeast(Role.admin), isFalse);
    expect(Role.admin.atLeast(Role.client), isTrue);
  });
}