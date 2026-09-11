class AuthSession {
  static String? accessToken;
  static String? refreshToken;
  static Map<String, dynamic>? user;

  static bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;

  static void clear() {
    accessToken = null;
    refreshToken = null;
    user = null;
  }
}
