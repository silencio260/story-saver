import 'package:shared_preferences/shared_preferences.dart';

/// Local storage abstraction for StarterKit
abstract class LocalStorage {
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
  Future<void> setBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<void> setInt(String key, int value);
  Future<int?> getInt(String key);
  Future<void> setDouble(String key, double value);
  Future<double?> getDouble(String key);
  Future<void> setStringList(String key, List<String> value);
  Future<List<String>?> getStringList(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

/// SharedPreferences implementation of LocalStorage
class SharedPreferencesStorage implements LocalStorage {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<void> setString(String key, String value) async {
    final p = await prefs;
    await p.setString(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    final p = await prefs;
    return p.getString(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    final p = await prefs;
    await p.setBool(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    final p = await prefs;
    return p.getBool(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    final p = await prefs;
    await p.setInt(key, value);
  }

  @override
  Future<int?> getInt(String key) async {
    final p = await prefs;
    return p.getInt(key);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    final p = await prefs;
    await p.setDouble(key, value);
  }

  @override
  Future<double?> getDouble(String key) async {
    final p = await prefs;
    return p.getDouble(key);
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    final p = await prefs;
    await p.setStringList(key, value);
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    final p = await prefs;
    return p.getStringList(key);
  }

  @override
  Future<void> remove(String key) async {
    final p = await prefs;
    await p.remove(key);
  }

  @override
  Future<void> clear() async {
    final p = await prefs;
    await p.clear();
  }
}
