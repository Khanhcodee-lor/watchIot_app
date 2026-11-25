import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:watchiot/features/monitoring/domain/entities/fall_alert.dart';
import 'package:watchiot/features/monitoring/domain/entities/health_reading.dart';
import 'package:watchiot/features/monitoring/domain/entities/metric_point.dart';
import 'package:watchiot/features/monitoring/domain/entities/sensor_reading.dart';
import 'package:watchiot/features/monitoring/domain/entities/watch_event.dart';
import 'package:watchiot/features/monitoring/domain/entities/watch_snapshot.dart';
import 'package:watchiot/features/monitoring/domain/repositories/alarm_controller.dart';
import 'package:watchiot/features/monitoring/domain/usecases/monitoring_use_cases.dart';

class WatchDataProvider extends ChangeNotifier {
  WatchDataProvider({
    required this.watchLatestUseCase,
    required this.watchEventsUseCase,
    required this.watchConnectionUseCase,
    required this.requestCancelAlertUseCase,
    required this.alarmController,
    required this.deviceUid,
  }) {
    _start();
  }

  static const onlineTimeout = Duration(seconds: 30);
  static const alertCountdown = Duration(seconds: 15);

  final WatchLatestUseCase watchLatestUseCase;
  final WatchEventsUseCase watchEventsUseCase;
  final WatchConnectionUseCase watchConnectionUseCase;
  final RequestCancelAlertUseCase requestCancelAlertUseCase;
  final AlarmController alarmController;
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
  DateTime? _localAlertStartedAt;
  DateTime? _alertSnapshotReceivedAt;
  bool? firebaseConnected;
  bool isLoading = true;
  bool isSendingCancel = false;
  bool isAlertLocallyDismissed = false;
  String? errorMessage;
  DateTime _now = DateTime.now();
  String? _lastAlertStatus;
  String? _lastHealthSignature;
  String? _lastAlertSignature;

  List<MetricPoint> get heartRatePoints => List.unmodifiable(_heartRatePoints);
  List<MetricPoint> get spo2Points => List.unmodifiable(_spo2Points);

  DateTime? get alertStartedAt => alert?.startedAt ?? _localAlertStartedAt;

  bool get isOnline {
    if (firebaseConnected != true || lastDataReceivedAt == null) return false;
    return _now.difference(lastDataReceivedAt!) <= onlineTimeout;
  }

  bool get showAlertOverlay {
    final current = alert;
    if (current == null || !current.isActive) return false;
    if (current.isEmergency) return true;
    return !isAlertLocallyDismissed;
  }

  int get alertSecondsRemaining {
    final current = alert;
    if (current == null) return 0;
    if (current.remainingMs != null) {
      final received = _alertSnapshotReceivedAt ?? _now;
      final elapsed = _now.difference(received).inMilliseconds;
      return ((current.remainingMs! - elapsed).clamp(0, 15000) / 1000).ceil();
    }
    final started = alertStartedAt;
    if (started == null) return alertCountdown.inSeconds;
    final elapsed = _now.difference(started).inSeconds;
    return (alertCountdown.inSeconds - elapsed).clamp(
      0,
      alertCountdown.inSeconds,
    );
  }

  void _start() {
    _connectionSubscription = watchConnectionUseCase().listen(
      (connected) {
        firebaseConnected = connected;
        errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        firebaseConnected = false;
        errorMessage = 'Không thể kết nối Firebase Realtime Database.';
        notifyListeners();
      },
    );

    _latestSubscription = watchLatestUseCase(deviceUid).listen(
      _handleLatest,
      onError: (Object error) {
        isLoading = false;
        errorMessage =
            'Không đọc được dữ liệu đồng hồ. Hãy kiểm tra quyền Firebase.';
        notifyListeners();
      },
    );

    _eventsSubscription = watchEventsUseCase(deviceUid).listen(
      (nextEvents) {
        events = nextEvents;
        notifyListeners();
      },
      onError: (Object error) {
        errorMessage = 'Không đọc được lịch sử sự kiện.';
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
      final signature = [
        nextAlert.status,
        nextAlert.startedAt?.millisecondsSinceEpoch,
        nextAlert.remainingMs,
      ].join('|');
      if (signature != _lastAlertSignature) {
        _lastAlertSignature = signature;
        _alertSnapshotReceivedAt = receivedAt;
      }
      if (nextAlert.status != _lastAlertStatus) {
        isAlertLocallyDismissed = false;
        _localAlertStartedAt = nextAlert.status == FallAlert.fallAlertStart
            ? receivedAt
            : null;
        _lastAlertStatus = nextAlert.status;
      }
      alert = nextAlert;
      if (nextAlert.isEmergency ||
          (nextAlert.status == FallAlert.fallAlertStart &&
              !isAlertLocallyDismissed)) {
        unawaited(alarmController.start().catchError((Object _) {}));
      } else {
        unawaited(alarmController.stop().catchError((Object _) {}));
      }
    }

    lastDataReceivedAt = snapshot.isEmpty
        ? null
        : snapshot.updatedAt ?? receivedAt;
    isLoading = false;
    errorMessage = null;
    _now = DateTime.now();
    notifyListeners();
  }

  Future<bool> requestCancelAlert(String requestedBy) async {
    isSendingCancel = true;
    notifyListeners();
    try {
      await requestCancelAlertUseCase(
        deviceUid: deviceUid,
        requestedBy: requestedBy,
      );
      isAlertLocallyDismissed = true;
      unawaited(alarmController.stop().catchError((Object _) {}));
      errorMessage = null;
      return true;
    } catch (_) {
      errorMessage =
          'Không gửi được yêu cầu hủy. Kiểm tra quyền ghi vào commands.';
      return false;
    } finally {
      isSendingCancel = false;
      notifyListeners();
    }
  }

  void _addPoint(List<MetricPoint> points, double value, DateTime at) {
    if (value <= 0) return;
    points.add(MetricPoint(at, value));
    if (points.length > 20) points.removeAt(0);
  }

  @override
  void dispose() {
    _latestSubscription?.cancel();
    _eventsSubscription?.cancel();
    _connectionSubscription?.cancel();
    _clock?.cancel();
    unawaited(alarmController.stop().catchError((Object _) {}));
    super.dispose();
  }
}
