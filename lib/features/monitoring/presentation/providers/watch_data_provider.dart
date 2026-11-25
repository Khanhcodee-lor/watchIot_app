import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:watchiot/features/monitoring/domain/entities/fall_alert.dart';
import 'package:watchiot/features/monitoring/domain/entities/health_reading.dart';
import 'package:watchiot/features/monitoring/domain/entities/metric_point.dart';
import 'package:watchiot/features/monitoring/domain/entities/sensor_reading.dart';
import 'package:watchiot/features/monitoring/domain/entities/watch_event.dart';
import 'package:watchiot/features/monitoring/domain/entities/watch_snapshot.dart';
import 'package:watchiot/features/monitoring/domain/usecases/monitoring_use_cases.dart';

class WatchDataProvider extends ChangeNotifier {
  WatchDataProvider({
    required this.watchLatestUseCase,
    required this.watchEventsUseCase,
    required this.watchConnectionUseCase,
    required this.deviceUid,
  }) {
    _start();
  }

  static const onlineTimeout = Duration(seconds: 30);
  final WatchLatestUseCase watchLatestUseCase;
  final WatchEventsUseCase watchEventsUseCase;
  final WatchConnectionUseCase watchConnectionUseCase;
  final String deviceUid;

  StreamSubscription<WatchSnapshot>? _latestSubscription;
  StreamSubscription<List<WatchEvent>>? _eventsSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  Timer? _clock;

  HealthReading? health;
  SensorReading? sensor;
  FallAlert? alert;
  List<WatchEvent> events = const [];
  final List<MetricPoint> _heartRatePoints = [];
  final List<MetricPoint> _spo2Points = [];
  DateTime? lastDataReceivedAt;
  bool? firebaseConnected;
  bool isLoading = true;
  String? _connectionErrorMessage;
  String? _latestErrorMessage;
  String? _eventsErrorMessage;
  DateTime _now = DateTime.now();
  String? _lastHealthSignature;

  List<MetricPoint> get heartRatePoints => List.unmodifiable(_heartRatePoints);
  List<MetricPoint> get spo2Points => List.unmodifiable(_spo2Points);
  String? get errorMessage =>
      _latestErrorMessage ?? _eventsErrorMessage ?? _connectionErrorMessage;

  bool get isOnline {
    if (firebaseConnected != true || lastDataReceivedAt == null) return false;
    return _now.difference(lastDataReceivedAt!) <= onlineTimeout;
  }

  void _start() {
    _connectionSubscription = watchConnectionUseCase().listen(
      (connected) {
        firebaseConnected = connected;
        if (connected) _connectionErrorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        firebaseConnected = false;
        _connectionErrorMessage =
            'Không thể kết nối Firebase Realtime Database.';
        notifyListeners();
      },
    );

    _latestSubscription = watchLatestUseCase(deviceUid).listen(
      _handleLatest,
      onError: (Object error) {
        isLoading = false;
        _latestErrorMessage = _readErrorMessage(
          error,
          '/devices/$deviceUid/latest',
        );
        notifyListeners();
      },
    );

    _eventsSubscription = watchEventsUseCase(deviceUid).listen(
      (nextEvents) {
        events = nextEvents;
        _eventsErrorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _eventsErrorMessage = _readErrorMessage(
          error,
          '/devices/$deviceUid/events',
        );
        notifyListeners();
      },
    );

    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = DateTime.now();
      notifyListeners();
    });
  }

  void _handleLatest(WatchSnapshot snapshot) {
    final receivedAt = DateTime.now();

    final nextHealth = snapshot.health;
    if (nextHealth != null) {
      health = nextHealth;
      final signature = [
        nextHealth.uptimeMs,
        nextHealth.updatedAt?.millisecondsSinceEpoch,
        nextHealth.fingerDetected,
        nextHealth.heartRate,
        nextHealth.spo2,
      ].join('|');
      if (signature != _lastHealthSignature) {
        _lastHealthSignature = signature;
        _addPoint(_heartRatePoints, nextHealth.heartRate, receivedAt);
        _addPoint(_spo2Points, nextHealth.spo2, receivedAt);
      }
    }

    if (snapshot.sensor != null) sensor = snapshot.sensor;
    final nextAlert = snapshot.alert;
    if (nextAlert != null) {
      alert = nextAlert;
    }

    lastDataReceivedAt = snapshot.isEmpty
        ? null
        : snapshot.updatedAt ?? receivedAt;
    isLoading = false;
    _latestErrorMessage = null;
    _now = DateTime.now();
    notifyListeners();
  }

  void _addPoint(List<MetricPoint> points, double value, DateTime at) {
    if (value <= 0) return;
    points.add(MetricPoint(at, value));
    if (points.length > 20) points.removeAt(0);
  }

  String _readErrorMessage(Object error, String path) {
    final firebaseError = error is FirebaseException ? error : null;
    final details = [
      error.toString(),
      firebaseError?.code ?? '',
      firebaseError?.message ?? '',
    ].join(' ').toLowerCase();
    if (details.contains('permission_denied') ||
        details.contains('permission-denied') ||
        details.contains('permission denied') ||
        details.contains('insufficient permission')) {
      return 'Tài khoản app chưa được RTDB Rules cấp quyền đọc $path.';
    }
    if (firebaseError != null) {
      final message = firebaseError.message;
      return 'Lỗi Firebase (${firebaseError.code}) khi đọc $path${message == null || message.isEmpty ? '.' : ': $message'}';
    }
    return 'Không đọc được $path. Hãy kiểm tra kết nối Firebase và UID thiết bị.';
  }

  @override
  void dispose() {
    _latestSubscription?.cancel();
    _eventsSubscription?.cancel();
    _connectionSubscription?.cancel();
    _clock?.cancel();
    super.dispose();
  }
}
