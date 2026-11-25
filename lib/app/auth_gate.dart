import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watchiot/app/app_shell.dart';
import 'package:watchiot/app/watch_data_provider_factory.dart';
import 'package:watchiot/features/auth/presentation/providers/auth_provider.dart';
import 'package:watchiot/features/auth/presentation/views/login_view.dart';
import 'package:watchiot/features/emergency/presentation/providers/emergency_monitor_provider.dart';
import 'package:watchiot/features/monitoring/domain/repositories/device_uid_settings_repository.dart';
import 'package:watchiot/features/monitoring/presentation/providers/watch_data_provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        if (user == null) return const LoginView();
        return _WatchSession(key: ValueKey(user.uid), accountUid: user.uid);
      },
    );
  }
}

class _WatchSession extends StatefulWidget {
  const _WatchSession({super.key, required this.accountUid});

  final String accountUid;

  @override
  State<_WatchSession> createState() => _WatchSessionState();
}

class _WatchSessionState extends State<_WatchSession> {
  WatchDataProvider? _watchProvider;
  String? _deviceUid;
  late final EmergencyMonitorProvider _emergencyMonitor;

  @override
  void initState() {
    super.initState();
    _emergencyMonitor = context.read<EmergencyMonitorProvider>();
    _loadDeviceUid();
  }

  Future<void> _loadDeviceUid() async {
    String? savedUid;
    try {
      final repository = context.read<DeviceUidSettingsRepository>();
      savedUid = await repository.getDeviceUid(widget.accountUid);
    } catch (_) {
      // Use the configured device UID if local preferences are unavailable.
    }
    if (!mounted) return;

    final uid = await _emergencyMonitor.connectForUser(
      widget.accountUid,
      legacyDeviceUid: savedUid,
    );
    if (!mounted) return;
    setState(() {
      _deviceUid = uid;
      _watchProvider = _createWatchProvider(uid);
    });
  }

  WatchDataProvider _createWatchProvider(String deviceUid) {
    return context.read<WatchDataProviderFactory>().create(
      databaseUrl: _emergencyMonitor.settings.databaseUrl,
      deviceUid: deviceUid,
    );
  }

  Future<bool> _changeDeviceUid(String nextUid) async {
    return _changeTarget(_emergencyMonitor.settings.databaseUrl, nextUid);
  }

  Future<bool> _changeTarget(String databaseUrl, String nextUid) async {
    final normalizedUid = nextUid.trim();
    if (normalizedUid.isEmpty) return false;
    final uidSettingsRepository = context.read<DeviceUidSettingsRepository>();
    final targetSaved = await _emergencyMonitor.updateTarget(
      databaseUrl: databaseUrl,
      deviceUid: normalizedUid,
    );
    if (!targetSaved) return false;
    try {
      await uidSettingsRepository.saveDeviceUid(
        accountUid: widget.accountUid,
        deviceUid: normalizedUid,
      );
    } catch (_) {}
    if (!mounted) return false;

    final replacement = _createWatchProvider(normalizedUid);
    final previous = _watchProvider;
    setState(() {
      _deviceUid = normalizedUid;
      _watchProvider = replacement;
    });
    previous?.dispose();
    return true;
  }

  @override
  void dispose() {
    _watchProvider?.dispose();
    unawaited(_emergencyMonitor.disconnect());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watchProvider = _watchProvider;
    if (watchProvider == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ChangeNotifierProvider<WatchDataProvider>.value(
      key: ValueKey(_deviceUid),
      value: watchProvider,
      child: AppShell(
        onDeviceUidChanged: _changeDeviceUid,
        onTargetChanged: _changeTarget,
      ),
    );
  }
}
