import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:watchiot/features/emergency/domain/entities/emergency_alert.dart';
import 'package:watchiot/features/emergency/domain/entities/emergency_call_status.dart';
import 'package:watchiot/features/emergency/domain/entities/emergency_settings.dart';
import 'package:watchiot/features/emergency/domain/entities/family_contact.dart';
import 'package:watchiot/features/emergency/domain/repositories/emergency_alert_repository.dart';
import 'package:watchiot/features/emergency/domain/repositories/emergency_settings_repository.dart';
import 'package:watchiot/features/emergency/domain/repositories/phone_dialer.dart';
import 'package:watchiot/features/monitoring/domain/repositories/alarm_controller.dart';

class EmergencyMonitorProvider extends ChangeNotifier {
  EmergencyMonitorProvider({
    required this.alertRepository,
    required this.settingsRepository,
    required this.phoneDialer,
    required this.alarmController,
    required this.defaultDatabaseUrl,
    required this.defaultDeviceUid,
  });

  static const _maxProcessedIds = 500;

  final EmergencyAlertRepository alertRepository;
  final EmergencySettingsRepository settingsRepository;
  final PhoneDialer phoneDialer;
  final AlarmController alarmController;
  final String defaultDatabaseUrl;
  final String defaultDeviceUid;

  EmergencySettings _settings = const EmergencySettings(
    databaseUrl: '',
    deviceUid: '',
    contacts: [],
    allowCallWhenConfirmed: false,
  );
  EmergencySettings get settings => _settings;

  EmergencyAlert? currentAlert;
  DateTime? alertReceivedAt;
  bool isSettingsLoading = true;
  bool isAlertLoading = false;
  bool? isFirebaseConnected;
  String? settingsError;
  String? databaseError;
  String? alarmError;
  EmergencyCallStatus callStatus = EmergencyCallStatus.idle;

  String? _accountUid;
  String? _activeAlertId;
  String? _dismissedAlertId;
  bool _initialSnapshotReceived = false;
  bool _baselineInitialized = false;
  bool _initialRecordIsHistorical = false;
  bool _isLaunchingDialer = false;
  int _generation = 0;
  Set<String> _processedAlertIds = <String>{};
  Set<String> _historicalAlertIds = <String>{};
  Set<String> _openedDialerAlertIds = <String>{};
  StreamSubscription<EmergencyAlert?>? _alertSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  Future<void> _eventQueue = Future<void>.value();

  bool get hasUser => _accountUid != null;

  bool get isConfigured =>
      _settings.hasValidDatabaseUrl && _settings.hasValidDeviceUid;

  bool get canEnableCalls => _settings.isReadyForCall;

  bool get showEmergencyOverlay {
    final alert = currentAlert;
    return alert != null &&
        alert.requestsFamilyNotification &&
        _dismissedAlertId != alert.alertId;
  }

  bool get showEmergencyStatusBanner {
    final alert = currentAlert;
    if (alert == null || showEmergencyOverlay) return false;
    return alert.isCancelled || _dismissedAlertId == alert.alertId;
  }

  bool get canRestoreEmergencyOverlay {
    final alert = currentAlert;
    return alert != null &&
        alert.requestsFamilyNotification &&
        _dismissedAlertId == alert.alertId;
  }

  String get emergencyStatusBannerMessage {
    if (currentAlert?.isCancelled == true) {
      return 'Cảnh báo đã được hủy hoặc tắt trên đồng hồ. App không gọi người thân.';
    }
    return 'Bạn đã ẩn cảnh báo trên điện thoại. Trạng thái đồng hồ không thay đổi.';
  }

  void restoreEmergencyOverlay() {
    final alert = currentAlert;
    if (alert == null || !alert.requestsFamilyNotification) return;
    _dismissedAlertId = null;
    if (_openedDialerAlertIds.contains(alert.alertId)) {
      callStatus = EmergencyCallStatus.dialerOpened;
    } else if (_historicalAlertIds.contains(alert.alertId)) {
      callStatus = EmergencyCallStatus.historicalRecord;
      _initialRecordIsHistorical = true;
    } else {
      callStatus = _settings.allowCallWhenConfirmed && canEnableCalls
          ? EmergencyCallStatus.waitingForUser
          : EmergencyCallStatus.callsDisabled;
    }
    notifyListeners();
  }

  bool get isCurrentAlertHistorical => _initialRecordIsHistorical;

  String get alertPath => '/devices/${_settings.deviceUid}/alerts/latest';

  String get _deviceStorageKey =>
      '${_settings.databaseUrl.trim()}|${_settings.deviceUid.trim()}';

  Future<String> connectForUser(
    String accountUid, {
    String? legacyDeviceUid,
  }) async {
    await _stopSubscriptions();
    await _stopAlarm();
    _generation++;
    final generation = _generation;
    _accountUid = accountUid;
    isSettingsLoading = true;
    isAlertLoading = true;
    currentAlert = null;
    alertReceivedAt = null;
    databaseError = null;
    settingsError = null;
    callStatus = EmergencyCallStatus.idle;
    _dismissedAlertId = null;
    notifyListeners();

    try {
      final stored = await settingsRepository.loadSettings(accountUid);
      var next =
          stored ??
          EmergencySettings(
            databaseUrl: defaultDatabaseUrl,
            deviceUid: defaultDeviceUid,
            contacts: const [],
            allowCallWhenConfirmed: false,
          );
      final migratedUid = legacyDeviceUid?.trim();
      if (stored == null && migratedUid != null && migratedUid.isNotEmpty) {
        next = next.copyWith(deviceUid: migratedUid);
      }
      if (next.allowCallWhenConfirmed && !next.isReadyForCall) {
        next = next.copyWith(allowCallWhenConfirmed: false);
      }
      await settingsRepository.saveSettings(accountUid, next);
      if (generation != _generation) return next.deviceUid;

      _settings = next;
      _initialSnapshotReceived = false;
      _initialRecordIsHistorical = false;
      _activeAlertId = null;
      _processedAlertIds = await settingsRepository.loadProcessedAlertIds(
        _deviceStorageKey,
      );
      _historicalAlertIds = await settingsRepository.loadHistoricalAlertIds(
        _deviceStorageKey,
      );
      _openedDialerAlertIds = await settingsRepository.loadOpenedDialerAlertIds(
        _deviceStorageKey,
      );
      _baselineInitialized = await settingsRepository.hasSeenInitialSnapshot(
        _deviceStorageKey,
      );
      if (generation != _generation) return next.deviceUid;

      isSettingsLoading = false;
      isAlertLoading = true;
      _startSubscriptions(generation);
      notifyListeners();
      return next.deviceUid;
    } catch (_) {
      if (generation == _generation) {
        _settings = EmergencySettings(
          databaseUrl: defaultDatabaseUrl,
          deviceUid: defaultDeviceUid,
          contacts: const [],
          allowCallWhenConfirmed: false,
        );
        isSettingsLoading = false;
        isAlertLoading = false;
        settingsError =
            'Không đọc được cài đặt bảo mật trên thiết bị. Hãy khởi động lại app rồi thử lại.';
        notifyListeners();
      }
      return defaultDeviceUid;
    }
  }

  Future<void> disconnect() async {
    _accountUid = null;
    _generation++;
    await _stopSubscriptions();
    currentAlert = null;
    alertReceivedAt = null;
    isFirebaseConnected = null;
    isAlertLoading = false;
    _dismissedAlertId = null;
    callStatus = EmergencyCallStatus.idle;
    await _stopAlarm();
    notifyListeners();
  }

  Future<bool> updateDeviceUid(String value) async {
    return updateTarget(databaseUrl: _settings.databaseUrl, deviceUid: value);
  }

  Future<bool> updateDatabaseUrl(String value) async {
    return updateTarget(databaseUrl: value, deviceUid: _settings.deviceUid);
  }

  Future<bool> updateTarget({
    required String databaseUrl,
    required String deviceUid,
  }) async {
    final url = databaseUrl.trim();
    final uid = deviceUid.trim();
    final uri = Uri.tryParse(url);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty ||
        uid.isEmpty ||
        _accountUid == null) {
      settingsError = 'Nhập URL Realtime Database và DEVICE_UID hợp lệ.';
      notifyListeners();
      return false;
    }
    if (url == _settings.databaseUrl.trim() &&
        uid == _settings.deviceUid.trim()) {
      settingsError = null;
      notifyListeners();
      return true;
    }
    return _saveAndApplySettings(
      _settings.copyWith(
        databaseUrl: url,
        deviceUid: uid,
        allowCallWhenConfirmed:
            _settings.allowCallWhenConfirmed && _settings.hasValidContact,
      ),
      targetChanged: true,
    );
  }

  Future<bool> updateContacts(List<FamilyContact> contacts) async {
    if (_accountUid == null) return false;
    final cleaned = contacts
        .map(
          (contact) => contact.copyWith(
            name: contact.name.trim(),
            phoneNumber: normalizePhoneNumber(contact.phoneNumber),
          ),
        )
        .where(
          (contact) =>
              contact.id.isNotEmpty &&
              contact.name.isNotEmpty &&
              isValidPhoneNumber(contact.phoneNumber),
        )
        .toList(growable: false);
    var next = _settings.copyWith(contacts: cleaned);
    if (cleaned.isEmpty) {
      next = next.copyWith(allowCallWhenConfirmed: false);
    }
    return _saveAndApplySettings(next);
  }

  Future<bool> setAllowCallWhenConfirmed(bool enabled) async {
    if (_accountUid == null) return false;
    if (enabled && !canEnableCalls) {
      settingsError =
          'Cần URL Firebase, DEVICE_UID và ít nhất một số điện thoại hợp lệ trước khi bật.';
      notifyListeners();
      return false;
    }
    settingsError = null;
    return _saveAndApplySettings(
      _settings.copyWith(allowCallWhenConfirmed: enabled),
    );
  }

  Future<bool> _saveAndApplySettings(
    EmergencySettings next, {
    bool targetChanged = false,
  }) async {
    final accountUid = _accountUid;
    if (accountUid == null) return false;
    try {
      await settingsRepository.saveSettings(accountUid, next);
      _settings = next;
      settingsError = null;
      if (targetChanged) {
        await _restartSubscriptions();
      } else if (currentAlert?.requestsFamilyNotification == true &&
          callStatus != EmergencyCallStatus.dialerOpened) {
        callStatus = _settings.allowCallWhenConfirmed && canEnableCalls
            ? EmergencyCallStatus.waitingForUser
            : EmergencyCallStatus.callsDisabled;
      }
      notifyListeners();
      return true;
    } catch (_) {
      settingsError = 'Không thể lưu cài đặt an toàn trên thiết bị.';
      notifyListeners();
      return false;
    }
  }

  Future<void> _restartSubscriptions() async {
    final generation = ++_generation;
    await _stopSubscriptions();
    await _stopAlarm();
    currentAlert = null;
    alertReceivedAt = null;
    _initialSnapshotReceived = false;
    _initialRecordIsHistorical = false;
    _dismissedAlertId = null;
    _activeAlertId = null;
    callStatus = EmergencyCallStatus.idle;
    isFirebaseConnected = null;
    isAlertLoading = true;
    databaseError = null;
    try {
      _processedAlertIds = await settingsRepository.loadProcessedAlertIds(
        _deviceStorageKey,
      );
      _historicalAlertIds = await settingsRepository.loadHistoricalAlertIds(
        _deviceStorageKey,
      );
      _baselineInitialized = await settingsRepository.hasSeenInitialSnapshot(
        _deviceStorageKey,
      );
      if (_accountUid != null && generation == _generation) {
        _startSubscriptions(generation);
      }
    } catch (_) {
      isAlertLoading = false;
      settingsError = 'Không tải được trạng thái chống cảnh báo lặp.';
    }
    notifyListeners();
  }

  Future<void> _handleSnapshot(EmergencyAlert? alert, int generation) async {
    if (generation != _generation) return;
    final isFirstSnapshot = !_initialSnapshotReceived;
    _initialSnapshotReceived = true;
    final previousId = currentAlert?.alertId;
    currentAlert = alert;
    alertReceivedAt = DateTime.now();
    isAlertLoading = false;
    databaseError = null;
    if (previousId != alert?.alertId) {
      _dismissedAlertId = null;
      _initialRecordIsHistorical = false;
    }

    if (isFirstSnapshot && !_baselineInitialized) {
      try {
        if (alert?.requestsFamilyNotification == true) {
          await _rememberProcessedAlertId(alert!.alertId);
          await _rememberHistoricalAlertId(alert.alertId);
          _initialRecordIsHistorical = true;
          callStatus = EmergencyCallStatus.historicalRecord;
        } else {
          callStatus = _statusForNonEmergency(alert);
        }
        await settingsRepository.markInitialSnapshotSeen(_deviceStorageKey);
        _baselineInitialized = true;
      } catch (_) {
        settingsError =
            'Không lưu được trạng thái khởi tạo; chưa xử lý cảnh báo để tránh gọi lặp.';
        callStatus = EmergencyCallStatus.historicalRecord;
      }
      await _stopAlarm();
      if (generation == _generation) notifyListeners();
      return;
    }

    _initialRecordIsHistorical = false;
    if (alert == null) {
      callStatus = EmergencyCallStatus.idle;
      _activeAlertId = null;
      await _stopAlarm();
      if (generation == _generation) notifyListeners();
      return;
    }

    if (alert.status == EmergencyAlert.fallAlertStart) {
      callStatus = EmergencyCallStatus.fallCheckInProgress;
      _activeAlertId = alert.alertId;
      await _stopAlarm();
      if (generation == _generation) notifyListeners();
      return;
    }

    if (alert.isCancelled) {
      callStatus = EmergencyCallStatus.cancelled;
      _activeAlertId = alert.alertId;
      _dismissedAlertId = alert.alertId;
      await _stopAlarm();
      if (generation == _generation) notifyListeners();
      return;
    }

    if (!alert.isEmergencyConfirmed || !alert.notifyFamily) {
      callStatus = alert.isEmergencyConfirmed
          ? EmergencyCallStatus.notNotifyingFamily
          : EmergencyCallStatus.idle;
      _activeAlertId = alert.alertId;
      await _stopAlarm();
      if (generation == _generation) notifyListeners();
      return;
    }

    if (alert.alertId.trim().isEmpty) {
      callStatus = EmergencyCallStatus.cannotCall;
      databaseError = 'Cảnh báo thiếu alert_id; không thể chống xử lý lặp.';
      await _stopAlarm();
      if (generation == _generation) notifyListeners();
      return;
    }

    if (_historicalAlertIds.contains(alert.alertId)) {
      _activeAlertId = alert.alertId;
      _initialRecordIsHistorical = true;
      _dismissedAlertId = null;
      callStatus = EmergencyCallStatus.historicalRecord;
      await _stopAlarm();
      if (generation == _generation) notifyListeners();
      return;
    }

    final alreadyProcessed = _processedAlertIds.contains(alert.alertId);
    if (!alreadyProcessed) {
      try {
        await _rememberProcessedAlertId(alert.alertId);
      } catch (_) {
        settingsError =
            'Không lưu được alert_id đã xử lý; đã bỏ qua quy trình gọi để tránh lặp.';
        callStatus = EmergencyCallStatus.cannotCall;
        await _stopAlarm();
        if (generation == _generation) notifyListeners();
        return;
      }
      _activeAlertId = alert.alertId;
      _dismissedAlertId = null;
      callStatus = _settings.allowCallWhenConfirmed && canEnableCalls
          ? EmergencyCallStatus.waitingForUser
          : EmergencyCallStatus.callsDisabled;
      await _startAlarm();
    } else if (_activeAlertId != alert.alertId) {
      _activeAlertId = alert.alertId;
      _dismissedAlertId = null;
      if (_openedDialerAlertIds.contains(alert.alertId)) {
        callStatus = EmergencyCallStatus.dialerOpened;
      } else {
        callStatus = _settings.allowCallWhenConfirmed && canEnableCalls
            ? EmergencyCallStatus.waitingForUser
            : EmergencyCallStatus.callsDisabled;
      }
      await _stopAlarm();
    }

    if (generation == _generation) notifyListeners();
  }

  EmergencyCallStatus _statusForNonEmergency(EmergencyAlert? alert) {
    if (alert == null) return EmergencyCallStatus.idle;
    if (alert.isCancelled) return EmergencyCallStatus.cancelled;
    if (alert.status == EmergencyAlert.fallAlertStart) {
      return EmergencyCallStatus.fallCheckInProgress;
    }
    if (alert.isEmergencyConfirmed && !alert.notifyFamily) {
      return EmergencyCallStatus.notNotifyingFamily;
    }
    return EmergencyCallStatus.idle;
  }

  Future<void> _rememberProcessedAlertId(String alertId) async {
    final next = <String>{..._processedAlertIds, alertId};
    while (next.length > _maxProcessedIds) {
      next.remove(next.first);
    }
    await settingsRepository.saveProcessedAlertIds(_deviceStorageKey, next);
    _processedAlertIds = next;
  }

  Future<void> _rememberHistoricalAlertId(String alertId) async {
    final next = <String>{..._historicalAlertIds, alertId};
    while (next.length > _maxProcessedIds) {
      next.remove(next.first);
    }
    await settingsRepository.saveHistoricalAlertIds(_deviceStorageKey, next);
    _historicalAlertIds = next;
  }

  Future<void> _startAlarm() async {
    try {
      await alarmController.start();
      alarmError = null;
    } catch (_) {
      alarmError = 'Không thể phát âm báo hoặc rung trên thiết bị này.';
    }
  }

  Future<void> _stopAlarm() async {
    try {
      await alarmController.stop();
    } catch (_) {
      alarmError = 'Không thể dừng âm báo trên thiết bị này.';
    }
  }

  Future<void> openDialerFor(FamilyContact contact) async {
    final alert = currentAlert;
    if (alert == null ||
        !alert.requestsFamilyNotification ||
        _initialRecordIsHistorical ||
        _accountUid == null) {
      callStatus = EmergencyCallStatus.historicalRecord;
      notifyListeners();
      return;
    }
    if (!_settings.allowCallWhenConfirmed || !canEnableCalls) {
      callStatus = EmergencyCallStatus.callsDisabled;
      notifyListeners();
      return;
    }
    if (!isValidPhoneNumber(contact.phoneNumber)) {
      callStatus = EmergencyCallStatus.cannotCall;
      notifyListeners();
      return;
    }
    if (!_settings.contacts.any(
      (saved) =>
          saved.id == contact.id &&
          normalizePhoneNumber(saved.phoneNumber) ==
              normalizePhoneNumber(contact.phoneNumber),
    )) {
      callStatus = EmergencyCallStatus.cannotCall;
      notifyListeners();
      return;
    }
    if (_openedDialerAlertIds.contains(alert.alertId)) {
      callStatus = EmergencyCallStatus.dialerOpened;
      notifyListeners();
      return;
    }
    if (_isLaunchingDialer) return;

    _isLaunchingDialer = true;
    callStatus = EmergencyCallStatus.openingDialer;
    notifyListeners();
    try {
      final launched = await phoneDialer.openDialer(contact.phoneNumber);
      if (launched) {
        final next = <String>{..._openedDialerAlertIds, alert.alertId};
        _openedDialerAlertIds = next;
        callStatus = EmergencyCallStatus.dialerOpened;
        notifyListeners();
        try {
          await settingsRepository.saveOpenedDialerAlertIds(
            _deviceStorageKey,
            next,
          );
        } catch (_) {
          settingsError =
              'Trình gọi đã mở, nhưng không lưu được trạng thái chống mở lặp.';
        }
      } else {
        callStatus = EmergencyCallStatus.cannotCall;
      }
    } catch (_) {
      callStatus = EmergencyCallStatus.cannotCall;
    } finally {
      _isLaunchingDialer = false;
      notifyListeners();
    }
  }

  Future<void> dismissEmergencyOnPhone() async {
    final alert = currentAlert;
    if (alert == null || !alert.requestsFamilyNotification) return;
    _dismissedAlertId = alert.alertId;
    callStatus = EmergencyCallStatus.cancelled;
    await _stopAlarm();
    notifyListeners();
  }

  String _describeDatabaseError(Object error, String path) {
    if (error is FormatException) {
      return 'Dữ liệu cảnh báo tại $path không đúng định dạng.';
    }
    if (error is FirebaseException) {
      final code = error.code.toLowerCase();
      if (code.contains('permission-denied') ||
          code.contains('permission_denied')) {
        return 'Firebase từ chối quyền đọc $path. Hãy kiểm tra đăng nhập và RTDB Rules.';
      }
      if (code.contains('unauthenticated')) {
        return 'Phiên đăng nhập Firebase đã hết hạn. Hãy đăng nhập lại.';
      }
      if (code.contains('network')) {
        return 'Mất kết nối mạng khi đọc $path.';
      }
      return 'Lỗi Firebase (${error.code}) khi đọc $path.';
    }
    final text = error.toString().toLowerCase();
    if (text.contains('permission denied') ||
        text.contains('permission_denied')) {
      return 'Firebase từ chối quyền đọc $path. Hãy kiểm tra đăng nhập và RTDB Rules.';
    }
    return 'Không thể đọc $path. Kiểm tra mạng, Firebase và DEVICE_UID.';
  }

  void _startSubscriptions(int generation) {
    if (!_settings.hasValidDatabaseUrl || !_settings.hasValidDeviceUid) {
      isAlertLoading = false;
      databaseError = 'Cần cấu hình URL Firebase và DEVICE_UID.';
      notifyListeners();
      return;
    }

    try {
      _connectionSubscription = alertRepository
          .watchConnection(_settings.databaseUrl)
          .listen(
            (connected) {
              if (generation != _generation) return;
              isFirebaseConnected = connected;
              if (connected && databaseError?.contains('Mất kết nối') == true) {
                databaseError = null;
              }
              notifyListeners();
            },
            onError: (Object error) {
              if (generation != _generation) return;
              isFirebaseConnected = false;
              databaseError = _describeDatabaseError(error, '.info/connected');
              notifyListeners();
            },
          );
      _alertSubscription = alertRepository
          .watchLatestAlert(
            databaseUrl: _settings.databaseUrl,
            deviceUid: _settings.deviceUid,
          )
          .listen(
            (alert) {
              _eventQueue = _eventQueue
                  .then((_) => _handleSnapshot(alert, generation))
                  .catchError((Object error) {
                    if (generation == _generation) {
                      isAlertLoading = false;
                      databaseError = _describeDatabaseError(error, alertPath);
                      notifyListeners();
                    }
                  });
            },
            onError: (Object error) {
              if (generation != _generation) return;
              isAlertLoading = false;
              databaseError = _describeDatabaseError(error, alertPath);
              notifyListeners();
            },
          );
    } catch (error) {
      if (generation != _generation) return;
      isAlertLoading = false;
      databaseError = _describeDatabaseError(error, alertPath);
      notifyListeners();
    }
  }

  Future<void> _stopSubscriptions() async {
    await _alertSubscription?.cancel();
    await _connectionSubscription?.cancel();
    _alertSubscription = null;
    _connectionSubscription = null;
  }

  @override
  void dispose() {
    unawaited(_stopSubscriptions());
    unawaited(_stopAlarm());
    super.dispose();
  }
}
