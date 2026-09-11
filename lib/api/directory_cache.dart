import 'package:dio/dio.dart';

class DirectoryCache {
  final Map<String, dynamic> _store = {};
  final Map<String, DateTime> _loadedAt = {};

  T? get<T>(String key) => _store[key] as T?;

  void set<T>(String key, T value) {
    _store[key] = value;
    _loadedAt[key] = DateTime.now();
  }

  bool has(String key) => _store.containsKey(key);

  void invalidate([String? key]) {
    if (key == null) {
      _store.clear();
      _loadedAt.clear();
    } else {
      _store.remove(key);
      _loadedAt.remove(key);
    }
  }
}

class SearchCancel {
  CancelToken? _token;

  CancelToken next() {
    _token?.cancel('superseded');
    _token = CancelToken();
    return _token!;
  }

  void dispose() {
    _token?.cancel('dispose');
    _token = null;
  }
}
