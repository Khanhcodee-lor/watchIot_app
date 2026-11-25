import 'package:watchiot/features/monitoring/domain/entities/watch_event.dart';
import 'package:watchiot/features/monitoring/domain/entities/watch_snapshot.dart';

abstract interface class MonitoringRepository {
  Stream<WatchSnapshot> watchLatest(String deviceUid);
  Stream<List<WatchEvent>> watchEvents(String deviceUid);
  Stream<bool> watchConnection();
  Future<void> requestCancelAlert({
    required String deviceUid,
    required String requestedBy,
  });
}
