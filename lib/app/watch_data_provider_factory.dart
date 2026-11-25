import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:watchiot/features/monitoring/data/datasources/realtime_database_data_source.dart';
import 'package:watchiot/features/monitoring/data/repositories/monitoring_repository_impl.dart';
import 'package:watchiot/features/monitoring/domain/usecases/monitoring_use_cases.dart';
import 'package:watchiot/features/monitoring/presentation/providers/watch_data_provider.dart';

/// Composition helper that keeps health and alert listeners on the configured
/// Realtime Database instance when the user changes the Firebase URL.
class WatchDataProviderFactory {
  WatchDataProvider create({
    required String databaseUrl,
    required String deviceUid,
  }) {
    final database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseUrl,
    );
    final repository = MonitoringRepositoryImpl(
      RealtimeDatabaseDataSource(database),
    );
    return WatchDataProvider(
      watchLatestUseCase: WatchLatestUseCase(repository),
      watchEventsUseCase: WatchEventsUseCase(repository),
      watchConnectionUseCase: WatchConnectionUseCase(repository),
      deviceUid: deviceUid,
    );
  }
}
