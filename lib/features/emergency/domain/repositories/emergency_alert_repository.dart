import '../entities/emergency_alert.dart';

abstract interface class EmergencyAlertRepository {
  Stream<EmergencyAlert?> watchLatestAlert({
    required String databaseUrl,
    required String deviceUid,
  });

  Stream<bool> watchConnection(String databaseUrl);
}
