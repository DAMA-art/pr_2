import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/app_exceptions.dart';
import '../api/auth_api.dart';
import '../models/app_user.dart';
import '../models/role.dart';

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kSessionStarted = 'auth_session_started';
  static const _kLastActivity = 'auth_last_activity';

  final SharedPreferences _prefs;
  final AuthApi _api;

  AuthNotifier(this._prefs, this._api);

  AppUser? _user;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _sessionStartedAt;
  bool _restoring = true;

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _user != null && _accessToken != null;
  bool get isRestoring => _restoring;
  DateTime? get sessionStartedAt => _sessionStartedAt;

  bool has(Role role) => _user != null && _user!.role.atLeast(role);

  Future<void> restore() async {
    _restoring = true;
    notifyListeners();
    try {
      final access = _prefs.getString(_kAccess);
      final refresh = _prefs.getString(_kRefresh);
      final startedMs = _prefs.getInt(_kSessionStarted);
      if (startedMs != null) {
        _sessionStartedAt = DateTime.fromMillisecondsSinceEpoch(startedMs);
      }

      if (access == null || access.isEmpty) return;

      _accessToken = access;
      _refreshToken = refresh;

      try {
        _user = await _api.me();
      } on UnauthorizedException {
        if (refresh != null && refresh.isNotEmpty) {
          try {
            await _refreshWith(refresh);
          } catch (_) {
            await logout(silent: true);
          }
        } else {
          await logout(silent: true);
        }
      } catch (_) {
      }
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    final result = await _api.login(username, password);
    await _applyLogin(result);
  }

  Future<void> register({
    required String username,
    required String password,
    required String fullName,
    String email = '',
  }) async {
    final result = await _api.register(
      username: username,
      password: password,
      fullName: fullName,
      email: email,
    );
    await _applyLogin(result);
  }

  Future<void> _applyLogin(LoginResult result) async {
    _accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    _user = result.user;
    _sessionStartedAt = DateTime.now();
    await _prefs.setString(_kAccess, result.accessToken);
    await _prefs.setString(_kRefresh, result.refreshToken);
    await _prefs.setInt(_kSessionStarted, _sessionStartedAt!.millisecondsSinceEpoch);
    await _prefs.setInt(_kLastActivity, DateTime.now().millisecondsSinceEpoch);
    notifyListeners();
  }

  Future<void> refreshTokens() async {
    final refresh = _refreshToken ?? _prefs.getString(_kRefresh);
    if (refresh == null || refresh.isEmpty) {
      throw const UnauthorizedException('Нет токена обновления');
    }
    await _refreshWith(refresh);
  }

  Future<void> _refreshWith(String refresh) async {
    final result = await _api.refresh(refresh);
    _accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    _user = result.user;
    await _prefs.setString(_kAccess, result.accessToken);
    await _prefs.setString(_kRefresh, result.refreshToken);
    notifyListeners();
  }

  Future<void> logout({bool silent = false}) async {
    final refresh = _refreshToken;
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _sessionStartedAt = null;
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kSessionStarted);
    await _prefs.remove(_kLastActivity);
    if (!silent) {
      try {
        await _api.logout(refresh);
      } catch (_) {}
    }
    notifyListeners();
  }

  void touchActivity() {
    _prefs.setInt(_kLastActivity, DateTime.now().millisecondsSinceEpoch);
  }

  DateTime? lastActivityAt() {
    final ms = _prefs.getInt(_kLastActivity);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
}