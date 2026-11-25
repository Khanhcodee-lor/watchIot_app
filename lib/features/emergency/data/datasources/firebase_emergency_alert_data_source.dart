import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../domain/entities/emergency_alert.dart';

class FirebaseEmergencyAlertDataSource {
  FirebaseDatabase _databaseFor(String databaseUrl) {
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseUrl.trim(),
    );
  }

  Stream<EmergencyAlert?> watchLatestAlert({
    required String databaseUrl,
    required String deviceUid,
  }) {
    final ref = _databaseFor(databaseUrl)
        .ref('devices/${deviceUid.trim()}/alerts/latest');
    ref.keepSynced(true);
    return ref.onValue
        .map((event) => EmergencyAlert.fromRealtimeValue(event.snapshot.value));
  }

  Stream<bool> watchConnection(String databaseUrl) {
    return _databaseFor(databaseUrl)
        .ref('.info/connected')
        .onValue
        .map((event) => event.snapshot.value == true);
  }
}
