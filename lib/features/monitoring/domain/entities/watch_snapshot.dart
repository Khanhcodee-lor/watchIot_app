import 'package:watchiot/features/monitoring/domain/entities/fall_alert.dart';
import 'package:watchiot/features/monitoring/domain/entities/health_reading.dart';
import 'package:watchiot/features/monitoring/domain/entities/sensor_reading.dart';

class WatchSnapshot {
  const WatchSnapshot({this.health, this.sensor, this.alert, this.updatedAt});

  final HealthReading? health;
  final SensorReading? sensor;
  final FallAlert? alert;
  final DateTime? updatedAt;

  bool get isEmpty => health == null && sensor == null && alert == null;
}
