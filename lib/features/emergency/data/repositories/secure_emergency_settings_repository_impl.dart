import '../../domain/entities/emergency_settings.dart';
import '../../domain/repositories/emergency_settings_repository.dart';
import '../datasources/secure_emergency_settings_data_source.dart';

class SecureEmergencySettingsRepositoryImpl
    implements EmergencySettingsRepository {
  SecureEmergencySettingsRepositoryImpl(this._dataSource);

  final SecureEmergencySettingsDataSource _dataSource;

  @override
  Future<EmergencySettings?> loadSettings(String accountUid) =>
      _dataSource.loadSettings(accountUid);

  @override
  Future<void> saveSettings(String accountUid, EmergencySettings settings) =>
      _dataSource.saveSettings(accountUid, settings);

  @override
  Future<Set<String>> loadProcessedAlertIds(String deviceUid) =>
      _dataSource.loadProcessedAlertIds(deviceUid);

  @override
  Future<void> saveProcessedAlertIds(String deviceUid, Set<String> alertIds) =>
      _dataSource.saveProcessedAlertIds(deviceUid, alertIds);

  @override
  Future<bool> hasSeenInitialSnapshot(String deviceUid) =>
      _dataSource.hasSeenInitialSnapshot(deviceUid);

  @override
  Future<void> markInitialSnapshotSeen(String deviceUid) =>
      _dataSource.markInitialSnapshotSeen(deviceUid);

  @override
  Future<Set<String>> loadHistoricalAlertIds(String deviceUid) =>
      _dataSource.loadHistoricalAlertIds(deviceUid);

  @override
  Future<void> saveHistoricalAlertIds(String deviceUid, Set<String> alertIds) =>
      _dataSource.saveHistoricalAlertIds(deviceUid, alertIds);

  @override
  Future<Set<String>> loadOpenedDialerAlertIds(String accountUid) =>
      _dataSource.loadOpenedDialerAlertIds(accountUid);

  @override
  Future<void> saveOpenedDialerAlertIds(
    String accountUid,
    Set<String> alertIds,
  ) => _dataSource.saveOpenedDialerAlertIds(accountUid, alertIds);
}
