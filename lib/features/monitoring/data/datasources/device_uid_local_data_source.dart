import 'package:shared_preferences/shared_preferences.dart';

class DeviceUidLocalDataSource {
  DeviceUidLocalDataSource(this._preferences);

  static const _keyPrefix = 'smartwatch.device_uid.';

  final SharedPreferencesAsync _preferences;

  Future<String?> getDeviceUid(String accountUid) =>
      _preferences.getString('$_keyPrefix$accountUid');

  Future<void> saveDeviceUid({
    required String accountUid,
    required String deviceUid,
  }) => _preferences.setString('$_keyPrefix$accountUid', deviceUid);
}
