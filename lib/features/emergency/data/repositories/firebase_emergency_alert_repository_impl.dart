import '../../domain/entities/emergency_alert.dart';
import '../../domain/repositories/emergency_alert_repository.dart';
import '../datasources/firebase_emergency_alert_data_source.dart';

class FirebaseEmergencyAlertRepositoryImpl implements EmergencyAlertRepository {
  FirebaseEmergencyAlertRepositoryImpl(this._dataSource);

  final FirebaseEmergencyAlertDataSource _dataSource;

  @override
  Stream<EmergencyAlert?> watchLatestAlert({
    required String databaseUrl,
    required String deviceUid,
  }) {
    return _dataSource.watchLatestAlert(
      databaseUrl: databaseUrl,
      deviceUid: deviceUid,
    );
  }

  @override
  Stream<bool> watchConnection(String databaseUrl) =>
      _dataSource.watchConnection(databaseUrl);
}
