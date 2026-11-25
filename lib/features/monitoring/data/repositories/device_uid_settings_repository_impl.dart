import 'package:watchiot/features/monitoring/data/datasources/device_uid_local_data_source.dart';
import 'package:watchiot/features/monitoring/domain/repositories/device_uid_settings_repository.dart';

class DeviceUidSettingsRepositoryImpl implements DeviceUidSettingsRepository {
  DeviceUidSettingsRepositoryImpl(this._dataSource);

  final DeviceUidLocalDataSource _dataSource;

  @override
  Future<String?> getDeviceUid(String accountUid) =>
      _dataSource.getDeviceUid(accountUid);

  @override
  Future<void> saveDeviceUid({
    required String accountUid,
    required String deviceUid,
  }) => _dataSource.saveDeviceUid(accountUid: accountUid, deviceUid: deviceUid);
}
