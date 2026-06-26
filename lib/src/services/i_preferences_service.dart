/// Abstraction over key-value persistence (Dependency Inversion Principle).
///
/// ViewModels depend on this interface, never on `SharedPreferences` directly,
/// so storage can be swapped (e.g. for tests or a secure backend) without
/// touching the rest of the app.
abstract interface class IPreferencesService {
  int? getInt(String key);
  Future<void> setInt(String key, int value);

  double? getDouble(String key);
  Future<void> setDouble(String key, double value);

  bool? getBool(String key);
  Future<void> setBool(String key, bool value);

  String? getString(String key);
  Future<void> setString(String key, String value);

  Future<void> remove(String key);
}
