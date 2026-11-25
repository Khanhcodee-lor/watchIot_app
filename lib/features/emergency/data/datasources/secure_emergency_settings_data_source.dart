import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/emergency_settings.dart';

class SecureEmergencySettingsDataSource {
  SecureEmergencySettingsDataSource(this._storage);

  static const _settingsPrefix = 'smartwatch.emergency.settings.';
  static const _processedPrefix = 'smartwatch.emergency.processed.';
  static const _baselinePrefix = 'smartwatch.emergency.baseline.';
  static const _historicalPrefix = 'smartwatch.emergency.historical.';
  static const _openedDialerPrefix = 'smartwatch.emergency.dialer_opened.';

  final FlutterSecureStorage _storage;

  Future<EmergencySettings?> loadSettings(String accountUid) async {
    final raw = await _storage.read(key: '$_settingsPrefix$accountUid');
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return EmergencySettings.fromJson(Map<String, Object?>.from(decoded));
  }

  Future<void> saveSettings(
    String accountUid,
    EmergencySettings settings,
  ) async {
    await _storage.write(
      key: '$_settingsPrefix$accountUid',
      value: jsonEncode(settings.toJson()),
    );
  }

  Future<Set<String>> loadProcessedAlertIds(String deviceUid) async {
    return _readSet('$_processedPrefix$deviceUid');
  }

  Future<void> saveProcessedAlertIds(
    String deviceUid,
    Set<String> alertIds,
  ) async {
    await _writeSet('$_processedPrefix$deviceUid', alertIds);
  }

  Future<bool> hasSeenInitialSnapshot(String deviceUid) async {
    return await _storage.read(key: '$_baselinePrefix$deviceUid') == 'true';
  }

  Future<void> markInitialSnapshotSeen(String deviceUid) async {
    await _storage.write(key: '$_baselinePrefix$deviceUid', value: 'true');
  }

  Future<Set<String>> loadHistoricalAlertIds(String deviceUid) async {
    return _readSet('$_historicalPrefix$deviceUid');
  }

  Future<void> saveHistoricalAlertIds(
    String deviceUid,
    Set<String> alertIds,
  ) async {
    await _writeSet('$_historicalPrefix$deviceUid', alertIds);
  }

  Future<Set<String>> loadOpenedDialerAlertIds(String accountUid) async {
    return _readSet('$_openedDialerPrefix$accountUid');
  }

  Future<void> saveOpenedDialerAlertIds(
    String accountUid,
    Set<String> alertIds,
  ) async {
    await _writeSet('$_openedDialerPrefix$accountUid', alertIds);
  }

  Future<Set<String>> _readSet(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) return <String>{};
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <String>{};
    return decoded.map((item) => item.toString()).toSet();
  }

  Future<void> _writeSet(String key, Set<String> values) async {
    final sorted = values.toList()..sort();
    await _storage.write(key: key, value: jsonEncode(sorted));
  }
}
