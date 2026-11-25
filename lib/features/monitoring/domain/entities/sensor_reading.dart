import 'dart:math' as math;

class SensorReading {
  const SensorReading({
    required this.accel,
    required this.gyro,
    this.uptimeMs,
    this.updatedAt,
  });

  final List<double> accel;
  final List<double> gyro;
  final int? uptimeMs;
  final DateTime? updatedAt;

  double get accelerationMagnitude =>
      math.sqrt(accel.fold<double>(0, (sum, value) => sum + value * value));
}
