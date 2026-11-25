import '../entities/emergency_settings.dart';

abstract interface class EmergencySettingsRepository {
  Future<EmergencySettings?> loadSettings(String accountUid);

  Future<void> saveSettings(String accountUid, EmergencySettings settings);

  Future<Set<String>> loadProcessedAlertIds(String deviceUid);

  Future<void> saveProcessedAlertIds(String deviceUid, Set<String> alertIds);

  Future<bool> hasSeenInitialSnapshot(String deviceUid);

  Future<void> markInitialSnapshotSeen(String deviceUid);

  Future<Set<String>> loadHistoricalAlertIds(String deviceUid);

  Future<void> saveHistoricalAlertIds(String deviceUid, Set<String> alertIds);

  Future<Set<String>> loadOpenedDialerAlertIds(String accountUid);

  Future<void> saveOpenedDialerAlertIds(
    String accountUid,
    Set<String> alertIds,
  );
}
