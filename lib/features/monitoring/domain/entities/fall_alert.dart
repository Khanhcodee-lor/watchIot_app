class FallAlert {
  const FallAlert({
    required this.status,
    required this.message,
    required this.probability,
    this.uptimeMs,
    this.startedAt,
    this.remainingMs,
  });

  static const normal = 'NORMAL';
  static const fallAlertStart = 'FALL_ALERT_START';
  static const emergencyConfirmed = 'EMERGENCY_CONFIRMED';
  static const cancelledByUser = 'ALERT_CANCELLED_BY_USER';

  final String status;
  final String message;
  final double probability;
  final int? uptimeMs;
  final DateTime? startedAt;
  final int? remainingMs;

  bool get isActive => status == fallAlertStart || status == emergencyConfirmed;
  bool get isEmergency => status == emergencyConfirmed;
}
