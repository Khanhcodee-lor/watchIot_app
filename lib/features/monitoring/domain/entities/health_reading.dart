class HealthReading {
  const HealthReading({
    required this.fingerDetected,
    required this.heartRate,
    required this.spo2,
    this.uptimeMs,
    this.updatedAt,
  });

  final bool fingerDetected;
  final double heartRate;
  final double spo2;
  final int? uptimeMs;
  final DateTime? updatedAt;
}
