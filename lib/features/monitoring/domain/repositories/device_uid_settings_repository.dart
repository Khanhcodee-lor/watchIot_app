abstract interface class DeviceUidSettingsRepository {
  Future<String?> getDeviceUid(String accountUid);

  Future<void> saveDeviceUid({
    required String accountUid,
    required String deviceUid,
  });
}
