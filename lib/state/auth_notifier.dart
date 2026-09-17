import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../models/role.dart';

class AuthNotifier extends ChangeNotifier {
  AppUser? user;
  bool isRestoring = true;
  String? error;
  DateTime? sessionStartedAt;

  SupabaseClient get _sb => Supabase.instance.client;

  bool get isAuthenticated => user != null && _sb.auth.currentSession != null;

  String? get accessToken => _sb.auth.currentSession?.accessToken;

  bool has(Role r) => user != null && user!.role.atLeast(r);

  bool isExactly(Role r) => user?.role == r;

  Future<void> restore() async {
    isRestoring = true;
    notifyListeners();
    try {
      final u = _sb.auth.currentUser;
      if (u != null) {
        await _load(u);
        sessionStartedAt = DateTime.now();
      } else {
        user = null;
        sessionStartedAt = null;
      }
    } catch (e) {
      debugPrint('$e');
      user = null;
    }
    isRestoring = false;
    notifyListeners();
  }

  Future<void> _load(User u) async {
    final row = await _sb.from('profiles').select().eq('id', u.id).maybeSingle();
    user = AppUser(
      id: 0,
      username: u.email ?? '',
      fullName: '${row?['full_name'] ?? u.email ?? ''}',
      email: u.email ?? '',
      role: Role.fromCode('${row?['role'] ?? 'client'}'),
    );
  }

  Future<bool> login(String email, String password) async {
    error = null;
    notifyListeners();
    try {
      final res = await _sb.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (res.user == null) {
        error = 'Неверный логин или пароль';
        notifyListeners();
        return false;
      }
      await _load(res.user!);
      sessionStartedAt = DateTime.now();
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Нет соединения с сервером';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    error = null;
    notifyListeners();
    try {
      final res = await _sb.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName, 'role': 'client'},
      );
      if (res.user == null) {
        error = 'Ошибка регистрации';
        notifyListeners();
        return false;
      }
      if (res.session != null) {
        await _load(res.user!);
        sessionStartedAt = DateTime.now();
      }
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Нет соединения с сервером';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _sb.auth.signOut();
    user = null;
    error = null;
    sessionStartedAt = null;
    notifyListeners();
  }

  Future<bool> refreshTokens() async {
    try {
      final r = await _sb.auth.refreshSession();
      return r.session != null;
    } catch (_) {
      await logout();
      return false;
    }
  }
}
