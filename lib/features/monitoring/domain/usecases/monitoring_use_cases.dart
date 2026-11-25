import 'package:watchiot/features/monitoring/domain/entities/watch_event.dart';
import 'package:watchiot/features/monitoring/domain/entities/watch_snapshot.dart';
import 'package:watchiot/features/monitoring/domain/repositories/monitoring_repository.dart';

class WatchLatestUseCase {
  const WatchLatestUseCase(this._repository);

  final MonitoringRepository _repository;

  Stream<WatchSnapshot> call(String deviceUid) =>
      _repository.watchLatest(deviceUid);
}

class WatchEventsUseCase {
  const WatchEventsUseCase(this._repository);

  final MonitoringRepository _repository;

  Stream<List<WatchEvent>> call(String deviceUid) =>
      _repository.watchEvents(deviceUid);
}

class WatchConnectionUseCase {
  const WatchConnectionUseCase(this._repository);

  final MonitoringRepository _repository;

  Stream<bool> call() => _repository.watchConnection();
}

class RequestCancelAlertUseCase {
  const RequestCancelAlertUseCase(this._repository);

  final MonitoringRepository _repository;

  Future<void> call({required String deviceUid, required String requestedBy}) {
    return _repository.requestCancelAlert(
      deviceUid: deviceUid,
      requestedBy: requestedBy,
    );
  }
}
