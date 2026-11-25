import 'package:watchiot/features/monitoring/domain/entities/fall_alert.dart';
import 'package:watchiot/features/monitoring/domain/entities/health_reading.dart';
import 'package:watchiot/features/monitoring/domain/entities/sensor_reading.dart';
import 'package:watchiot/features/monitoring/domain/entities/watch_event.dart';
import 'package:watchiot/features/monitoring/domain/entities/watch_snapshot.dart';

class RealtimeWatchMapper {
  const RealtimeWatchMapper();

  WatchSnapshot toSnapshot(Object? value) {
    final root = _asMap(value);
    final healthMap = _asMap(root['health']);
    final sensorMap = _asMap(root['sensor']);
    final alertMap = _asMap(root['alert']);
    // The current ESP32 firmware publishes the AI result under `inference`.
    // Keep supporting `alert` for firmware versions that use that name.
    final inferenceMap = _asMap(root['inference']);
    final resolvedAlertMap = alertMap.isNotEmpty ? alertMap : inferenceMap;

    return WatchSnapshot(
      health: healthMap.isEmpty ? null : _toHealth(healthMap),
      sensor: sensorMap.isEmpty ? null : _toSensor(sensorMap),
      alert: resolvedAlertMap.isEmpty ? null : _toAlert(resolvedAlertMap),
      updatedAt: _latestTimestamp(root, healthMap, sensorMap, resolvedAlertMap),
    );
  }

  List<WatchEvent> toEvents(Object? value) {
    final events = <WatchEvent>[];
    if (value is Map) {
      for (final entry in value.entries) {
        if (entry.value is Map) {
          events.add(_toEvent(entry.key.toString(), _asMap(entry.value)));
        }
      }
    } else if (value is List) {
      for (var index = 0; index < value.length; index++) {
        if (value[index] is Map) {
          events.add(_toEvent(index.toString(), _asMap(value[index])));
        }
      }
    }

    events.sort((a, b) {
      final aTime = a.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return events.length > 100 ? events.take(100).toList() : events;
  }

  HealthReading _toHealth(Map<Object?, Object?> map) {
    return HealthReading(
      fingerDetected: map['finger_detected'] == true,
      heartRate: _asDouble(map['heart_rate']),
      spo2: _asDouble(map['spo2']),
      uptimeMs: _asInt(map['uptime_ms']),
      updatedAt: _readTimestamp(map, const [
        'updated_at',
        'timestamp',
        'timestamp_ms',
        'last_seen',
      ]),
    );
  }

  SensorReading _toSensor(Map<Object?, Object?> map) {
    return SensorReading(
      accel: _readVector(map['accel']),
      gyro: _readVector(map['gyro']),
      uptimeMs: _asInt(map['uptime_ms']),
      updatedAt: _readTimestamp(map, const [
        'updated_at',
        'timestamp',
        'timestamp_ms',
        'last_seen',
      ]),
    );
  }

  FallAlert _toAlert(Map<Object?, Object?> map) {
    final probability = _asDouble(map['p_fall']);
    return FallAlert(
      status: map['status']?.toString() ?? FallAlert.normal,
      message: map['message']?.toString() ?? '',
      probability: probability.clamp(0, 1).toDouble(),
      uptimeMs: _asInt(map['uptime_ms']),
      startedAt: _readTimestamp(map, const [
        'started_at',
        'alert_started_at',
        'timestamp',
      ]),
      remainingMs: _asInt(map['countdown_remaining_ms']),
    );
  }

  WatchEvent _toEvent(String id, Map<Object?, Object?> map) {
    final probabilityValue = map['p_fall'];
    final probability = probabilityValue is num
        ? probabilityValue.toDouble()
        : double.tryParse(probabilityValue?.toString() ?? '');
    return WatchEvent(
      id: id,
      status: (map['status'] ?? map['type'] ?? 'EVENT').toString(),
      message: map['message']?.toString() ?? '',
      occurredAt:
          _readTimestamp(map, const [
            'timestamp',
            'timestamp_ms',
            'created_at',
            'occurred_at',
            'updated_at',
          ]) ??
          _dateFromPushId(id),
      probability: probability?.isFinite == true ? probability : null,
    );
  }

  DateTime? _latestTimestamp(
    Map<Object?, Object?> root,
    Map<Object?, Object?> health,
    Map<Object?, Object?> sensor,
    Map<Object?, Object?> alert,
  ) {
    final candidates = [
      _readTimestamp(root, const ['updated_at', 'timestamp', 'last_seen']),
      _readTimestamp(health, const [
        'updated_at',
        'timestamp',
        'timestamp_ms',
        'last_seen',
      ]),
      _readTimestamp(sensor, const [
        'updated_at',
        'timestamp',
        'timestamp_ms',
        'last_seen',
      ]),
      _readTimestamp(alert, const [
        'updated_at',
        'timestamp',
        'timestamp_ms',
        'last_seen',
      ]),
    ].whereType<DateTime>().toList();
    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.last;
  }

  DateTime? _readTimestamp(Map<Object?, Object?> map, List<String> keys) {
    for (final key in keys) {
      final millis = _asInt(map[key]);
      if (millis != null && millis > 0) {
        return DateTime.fromMillisecondsSinceEpoch(
          millis < 100000000000 ? millis * 1000 : millis,
        );
      }
    }
    return null;
  }

  DateTime? _dateFromPushId(String key) {
    const alphabet =
        '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
    if (key.length < 8) return null;
    var millis = 0;
    for (final codeUnit in key.substring(0, 8).codeUnits) {
      final digit = alphabet.indexOf(String.fromCharCode(codeUnit));
      if (digit < 0) return null;
      millis = millis * 64 + digit;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  List<double> _readVector(Object? value) {
    if (value is! List) return const [0, 0, 0];
    return List<double>.generate(3, (index) {
      if (index >= value.length) return 0;
      return _asDouble(value[index]);
    });
  }

  double _asDouble(Object? value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    return parsed.isFinite ? parsed : 0;
  }

  int? _asInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Map<Object?, Object?> _asMap(Object? value) {
    if (value is Map<Object?, Object?>) return value;
    if (value is Map) return Map<Object?, Object?>.from(value);
    return const {};
  }
}
