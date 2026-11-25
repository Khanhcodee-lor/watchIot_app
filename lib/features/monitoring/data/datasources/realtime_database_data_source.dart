import 'package:firebase_database/firebase_database.dart';

class RealtimeDatabaseDataSource {
  RealtimeDatabaseDataSource(this._database);

  final FirebaseDatabase _database;

  DatabaseReference _deviceRef(String deviceUid) =>
      _database.ref('devices/$deviceUid');

  Stream<Object?> watchLatest(String deviceUid) {
    final ref = _deviceRef(deviceUid).child('latest');
    ref.keepSynced(true);
    return ref.onValue.map((event) => event.snapshot.value);
  }

  Stream<Object?> watchEvents(String deviceUid) => _deviceRef(
    deviceUid,
  ).child('events').limitToLast(30).onValue.map((event) => event.snapshot.value);

  Stream<bool> watchConnection() => _database
      .ref('.info/connected')
      .onValue
      .map((event) => event.snapshot.value == true);
}
