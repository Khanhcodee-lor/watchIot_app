import 'package:firebase_database/firebase_database.dart';

class RealtimeDatabaseDataSource {
  RealtimeDatabaseDataSource(this._database);

  final FirebaseDatabase _database;

  DatabaseReference _deviceRef(String deviceUid) =>
      _database.ref('devices/$deviceUid');

  Stream<Object?> watchLatest(String deviceUid) => _deviceRef(
    deviceUid,
  ).child('latest').onValue.map((event) => event.snapshot.value);

  Stream<Object?> watchEvents(String deviceUid) => _deviceRef(
    deviceUid,
  ).child('events').onValue.map((event) => event.snapshot.value);

  Stream<bool> watchConnection() => _database
      .ref('.info/connected')
      .onValue
      .map((event) => event.snapshot.value == true);

  Future<void> requestCancelAlert({
    required String deviceUid,
    required String requestedBy,
  }) {
    return _deviceRef(deviceUid).child('commands/cancel_alert').set({
      'status': 'REQUESTED',
      'requested_at': ServerValue.timestamp,
      'requested_by': requestedBy,
    });
  }
}
