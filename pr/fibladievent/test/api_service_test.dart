import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:p/services/api_service.dart';

class FakeSecureStorage {
  final Map<String, String> _store = {};

  Future<void> write({required String key, required String? value}) async {
    if (value == null) return;
    _store[key] = value;
  }

  Future<String?> read({required String key}) async {
    return _store[key];
  }

  Future<void> delete({required String key}) async {
    _store.remove(key);
  }
}

void main() {
  group('ApiService token storage', () {
    late FakeSecureStorage storage;
    late ApiService api;

    setUp(() {
      storage = FakeSecureStorage();
      api = ApiService(dio: Dio(), storage: storage);
    });

    test('saveToken and getToken work', () async {
      await api.saveToken('abc123');
      final token = await api.getToken();
      expect(token, 'abc123');
    });

    test('clearToken removes token', () async {
      await api.saveToken('abc123');
      await api.clearToken();
      final token = await api.getToken();
      expect(token, isNull);
    });
  });
}
