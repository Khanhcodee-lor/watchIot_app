class EmergencyAlert {
  const EmergencyAlert({
    required this.type,
    required this.status,
    required this.alertId,
    required this.notifyFamily,
    required this.message,
    required this.fallProbability,
    required this.uptimeMs,
  });

  static const typeAlert = 'alert';
  static const fallAlertStart = 'FALL_ALERT_START';
  static const emergencyConfirmed = 'EMERGENCY_CONFIRMED';
  static const alertCancelledByUser = 'ALERT_CANCELLED_BY_USER';
  static const emergencyDismissed = 'EMERGENCY_DISMISSED';

  final String type;
  final String status;
  final String alertId;
  final bool notifyFamily;
  final String message;
  final double fallProbability;
  final int? uptimeMs;

  bool get isEmergencyConfirmed => status == emergencyConfirmed;

  bool get requestsFamilyNotification =>
      type == typeAlert &&
      isEmergencyConfirmed &&
      notifyFamily &&
      alertId.trim().isNotEmpty;

  bool get isCancelled =>
      status == alertCancelledByUser || status == emergencyDismissed;

  static EmergencyAlert? fromRealtimeValue(Object? value) {
    if (value == null) return null;
    if (value is! Map) {
      throw const FormatException('Alert payload must be an object.');
    }

    final map = Map<Object?, Object?>.from(value);
    final type = map['type']?.toString() ?? '';
    if (type != typeAlert) {
      throw const FormatException('Alert payload type must be "alert".');
    }
    final status = map['status']?.toString() ?? '';
    if (status.isEmpty) {
      throw const FormatException('Alert payload is missing status.');
    }

    final probabilityValue = map['p_fall'];
    final probability = probabilityValue is num
        ? probabilityValue.toDouble()
        : double.tryParse(probabilityValue?.toString() ?? '') ?? 0;
    final uptimeValue = map['uptime_ms'];

    return EmergencyAlert(
      type: type,
      status: status,
      alertId: map['alert_id']?.toString() ?? '',
      notifyFamily: map['notify_family'] == true,
      message: map['message']?.toString() ?? '',
      fallProbability: probability.isFinite
          ? probability.clamp(0, 1).toDouble()
          : 0,
      uptimeMs: uptimeValue is num
          ? uptimeValue.toInt()
          : int.tryParse(uptimeValue?.toString() ?? ''),
    );
  }
}
