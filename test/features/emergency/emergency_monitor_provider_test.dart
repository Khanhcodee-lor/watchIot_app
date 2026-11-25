import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchiot/features/emergency/domain/entities/emergency_alert.dart';
import 'package:watchiot/features/emergency/domain/entities/emergency_call_status.dart';
import 'package:watchiot/features/emergency/domain/entities/emergency_settings.dart';
import 'package:watchiot/features/emergency/domain/entities/family_contact.dart';
import 'package:watchiot/features/emergency/domain/repositories/emergency_alert_repository.dart';
import 'package:watchiot/features/emergency/domain/repositories/emergency_settings_repository.dart';
import 'package:watchiot/features/emergency/domain/repositories/phone_dialer.dart';
import 'package:watchiot/features/emergency/presentation/providers/emergency_monitor_provider.dart';
import 'package:watchiot/features/monitoring/domain/repositories/alarm_controller.dart';

void main() {
  late _MemorySettingsRepository settings;
  late _FakeAlertRepository alerts;
  late _FakeDialer dialer;
  late _FakeAlarm alarm;
  late EmergencyMonitorProvider provider;

  const contact = FamilyContact(
    id: 'family-1',
    name: 'Người thân',
    phoneNumber: '+84901234567',
  );

  setUp(() {
    settings = _MemorySettingsRepository();
    alerts = _FakeAlertRepository();
    dialer = _FakeDialer();
    alarm = _FakeAlarm();
    provider = EmergencyMonitorProvider(
      alertRepository: alerts,
      settingsRepository: settings,
      phoneDialer: dialer,
      alarmController: alarm,
      defaultDatabaseUrl: 'https://watch-test-default-rtdb.firebaseio.com/',
      defaultDeviceUid: 'firmware-account-uid',
    );
  });

  tearDown(() async {
    await provider.disconnect();
    provider.dispose();
    await alerts.dispose();
  });

  test(
    'first confirmed snapshot on fresh install is marked historical',
    () async {
      await provider.connectForUser('app-user-uid');
      alerts.alerts.add(_alert('old-alert', EmergencyAlert.emergencyConfirmed));
      await _flushEvents();

      expect(provider.isCurrentAlertHistorical, isTrue);
      expect(provider.callStatus, EmergencyCallStatus.historicalRecord);
      expect(provider.showEmergencyOverlay, isTrue);
      expect(alarm.startCount, 0);
      expect(dialer.openedNumbers, isEmpty);
      expect(settings.processed.values.single, contains('old-alert'));

      alerts.alerts.add(_alert('old-alert', EmergencyAlert.emergencyConfirmed));
      await _flushEvents();
      expect(provider.isCurrentAlertHistorical, isTrue);
      expect(provider.callStatus, EmergencyCallStatus.historicalRecord);
      await provider.openDialerFor(contact);
      expect(dialer.openedNumbers, isEmpty);
    },
  );

  test(
    'only confirmed alerts start the flow and dialer needs a user action',
    () async {
      await provider.connectForUser('app-user-uid');
      alerts.alerts.add(null);
      await _flushEvents();
      await provider.updateContacts([contact]);
      expect(await provider.setAllowCallWhenConfirmed(true), isTrue);

      alerts.alerts.add(_alert('alert-2', EmergencyAlert.fallAlertStart));
      await _flushEvents();
      expect(provider.callStatus, EmergencyCallStatus.fallCheckInProgress);
      expect(alarm.startCount, 0);
      expect(dialer.openedNumbers, isEmpty);

      alerts.alerts.add(_alert('alert-2', EmergencyAlert.alertCancelledByUser));
      await _flushEvents();
      expect(provider.callStatus, EmergencyCallStatus.cancelled);
      expect(alarm.startCount, 0);
      expect(dialer.openedNumbers, isEmpty);

      alerts.alerts.add(_alert('alert-3', EmergencyAlert.emergencyConfirmed));
      await _flushEvents();
      expect(provider.callStatus, EmergencyCallStatus.waitingForUser);
      expect(alarm.startCount, 1);
      expect(dialer.openedNumbers, isEmpty);

      await provider.openDialerFor(contact);
      expect(dialer.openedNumbers, ['+84901234567']);
      expect(provider.callStatus, EmergencyCallStatus.dialerOpened);
    },
  );

  test(
    'saved firmware DEVICE_UID is not replaced by the app login UID',
    () async {
      const configuredUrl =
          'https://family-monitor-default-rtdb.firebaseio.com/';
      settings.accountSettings['app-user-uid'] = const EmergencySettings(
        databaseUrl: configuredUrl,
        deviceUid: 'esp32-firebase-uid',
        contacts: [],
        allowCallWhenConfirmed: false,
      );

      await provider.connectForUser(
        'app-user-uid',
        legacyDeviceUid: 'app-user-uid',
      );

      expect(provider.settings.deviceUid, 'esp32-firebase-uid');
      expect(alerts.subscribedDatabaseUrl, configuredUrl);
      expect(alerts.subscribedDeviceUid, 'esp32-firebase-uid');
    },
  );

  test(
    'same alert id cannot open the phone dialer twice, including reconnect',
    () async {
      await provider.connectForUser('app-user-uid');
      alerts.alerts.add(null);
      await _flushEvents();
      await provider.updateContacts([contact]);
      await provider.setAllowCallWhenConfirmed(true);
      alerts.alerts.add(
        _alert('alert-unique', EmergencyAlert.emergencyConfirmed),
      );
      await _flushEvents();
      await provider.openDialerFor(contact);
      expect(dialer.openedNumbers, ['+84901234567']);

      await provider.disconnect();
      await provider.connectForUser('app-user-uid');
      alerts.alerts.add(
        _alert('alert-unique', EmergencyAlert.emergencyConfirmed),
      );
      await _flushEvents();

      expect(provider.callStatus, EmergencyCallStatus.dialerOpened);
      expect(alarm.startCount, 1);
      expect(dialer.openedNumbers, ['+84901234567']);
      await provider.openDialerFor(contact);
      expect(dialer.openedNumbers, ['+84901234567']);
    },
  );

  test(
    'notify_family false and dismissed statuses never start the call flow',
    () async {
      await provider.connectForUser('app-user-uid');
      alerts.alerts.add(null);
      await _flushEvents();

      alerts.alerts.add(
        _alert(
          'no-family-notification',
          EmergencyAlert.emergencyConfirmed,
          notifyFamily: false,
        ),
      );
      await _flushEvents();
      expect(provider.callStatus, EmergencyCallStatus.notNotifyingFamily);
      expect(alarm.startCount, 0);
      expect(dialer.openedNumbers, isEmpty);

      alerts.alerts.add(_alert('dismissed', EmergencyAlert.emergencyDismissed));
      await _flushEvents();
      expect(provider.callStatus, EmergencyCallStatus.cancelled);
      expect(alarm.startCount, 0);
      expect(dialer.openedNumbers, isEmpty);
    },
  );

  test('Firebase permission error is shown as a readable error', () async {
    await provider.connectForUser('app-user-uid');
    alerts.alerts.addError(
      FirebaseException(plugin: 'firebase_database', code: 'permission-denied'),
    );
    await _flushEvents();

    expect(provider.databaseError, contains('từ chối quyền đọc'));
    expect(
      provider.databaseError,
      contains('/devices/firmware-account-uid/alerts/latest'),
    );
  });
}

EmergencyAlert _alert(String id, String status, {bool notifyFamily = true}) =>
    EmergencyAlert(
      type: EmergencyAlert.typeAlert,
      status: status,
      alertId: id,
      notifyFamily: notifyFamily,
      message: 'Fall confirmed',
      fallProbability: 1,
      uptimeMs: 123456,
    );

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeAlertRepository implements EmergencyAlertRepository {
  final StreamController<EmergencyAlert?> alerts =
      StreamController<EmergencyAlert?>.broadcast(sync: true);
  final StreamController<bool> connection = StreamController<bool>.broadcast(
    sync: true,
  );
  String? subscribedDatabaseUrl;
  String? subscribedDeviceUid;

  @override
  Stream<bool> watchConnection(String databaseUrl) => connection.stream;

  @override
  Stream<EmergencyAlert?> watchLatestAlert({
    required String databaseUrl,
    required String deviceUid,
  }) {
    subscribedDatabaseUrl = databaseUrl;
    subscribedDeviceUid = deviceUid;
    return alerts.stream;
  }

  Future<void> dispose() async {
    await alerts.close();
    await connection.close();
  }
}

class _MemorySettingsRepository implements EmergencySettingsRepository {
  final Map<String, EmergencySettings> accountSettings = {};
  final Map<String, Set<String>> processed = {};
  final Set<String> initializedDevices = {};
  final Map<String, Set<String>> historical = {};
  final Map<String, Set<String>> opened = {};

  @override
  Future<EmergencySettings?> loadSettings(String accountUid) async =>
      accountSettings[accountUid];

  @override
  Future<void> saveSettings(
    String accountUid,
    EmergencySettings settings,
  ) async {
    accountSettings[accountUid] = settings;
  }

  @override
  Future<Set<String>> loadProcessedAlertIds(String deviceUid) async => {
    ...processed[deviceUid] ?? const <String>{},
  };

  @override
  Future<void> saveProcessedAlertIds(
    String deviceUid,
    Set<String> alertIds,
  ) async {
    processed[deviceUid] = {...alertIds};
  }

  @override
  Future<bool> hasSeenInitialSnapshot(String deviceUid) async =>
      initializedDevices.contains(deviceUid);

  @override
  Future<void> markInitialSnapshotSeen(String deviceUid) async {
    initializedDevices.add(deviceUid);
  }

  @override
  Future<Set<String>> loadHistoricalAlertIds(String deviceUid) async => {
    ...historical[deviceUid] ?? const <String>{},
  };

  @override
  Future<void> saveHistoricalAlertIds(
    String deviceUid,
    Set<String> alertIds,
  ) async {
    historical[deviceUid] = {...alertIds};
  }

  @override
  Future<Set<String>> loadOpenedDialerAlertIds(String accountUid) async => {
    ...opened[accountUid] ?? const <String>{},
  };

  @override
  Future<void> saveOpenedDialerAlertIds(
    String accountUid,
    Set<String> alertIds,
  ) async {
    opened[accountUid] = {...alertIds};
  }
}

class _FakeDialer implements PhoneDialer {
  final List<String> openedNumbers = [];

  @override
  Future<bool> openDialer(String phoneNumber) async {
    openedNumbers.add(phoneNumber);
    return true;
  }
}

class _FakeAlarm implements AlarmController {
  int startCount = 0;
  int stopCount = 0;

  @override
  Future<void> start() async {
    startCount++;
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> dispose() async {}
}
