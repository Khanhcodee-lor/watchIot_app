import 'package:watchiot/features/monitoring/data/datasources/realtime_database_data_source.dart';
import 'package:watchiot/features/monitoring/data/mappers/realtime_watch_mapper.dart';
import 'package:watchiot/features/monitoring/domain/entities/watch_event.dart';
import 'package:watchiot/features/monitoring/domain/entities/watch_snapshot.dart';
import 'package:watchiot/features/monitoring/domain/repositories/monitoring_repository.dart';

class MonitoringRepositoryImpl implements MonitoringRepository {
  MonitoringRepositoryImpl(
    this._dataSource, {
    this.mapper = const RealtimeWatchMapper(),
  });

  final RealtimeDatabaseDataSource _dataSource;
  final RealtimeWatchMapper mapper;

  @override
  Stream<WatchSnapshot> watchLatest(String deviceUid) =>
      _dataSource.watchLatest(deviceUid).map(mapper.toSnapshot);

  @override
  Stream<List<WatchEvent>> watchEvents(String deviceUid) =>
      _dataSource.watchEvents(deviceUid).map(mapper.toEvents);

  @override
  Stream<bool> watchConnection() => _dataSource.watchConnection();
}
