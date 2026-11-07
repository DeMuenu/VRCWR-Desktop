import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Custom cookie_jar Storage that saves directly to Windows Credential Manager / Linux libsecret
class SecureStorage implements Storage {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const _prefix = 'vrcwr_cookie_';

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) async {
    return await _secureStorage.read(key: '$_prefix$key');
  }

  @override
  Future<void> write(String key, String value) async {
    await _secureStorage.write(key: '$_prefix$key', value: value);
  }

  @override
  Future<void> delete(String key) async {
    await _secureStorage.delete(key: '$_prefix$key');
  }

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      await delete(key);
    }
  }
}