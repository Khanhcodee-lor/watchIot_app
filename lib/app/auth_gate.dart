import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watchiot/app/app_shell.dart';
import 'package:watchiot/core/app_config.dart';
import 'package:watchiot/features/auth/presentation/providers/auth_provider.dart';
import 'package:watchiot/features/auth/presentation/views/login_view.dart';
import 'package:watchiot/features/monitoring/domain/repositories/alarm_controller.dart';
import 'package:watchiot/features/monitoring/domain/repositories/device_uid_settings_repository.dart';
import 'package:watchiot/features/monitoring/domain/usecases/monitoring_use_cases.dart';
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

  @override
  void initState() {
    super.initState();
    _loadDeviceUid();
  }

  Future<void> _loadDeviceUid() async {
    String? savedUid;
    try {
      savedUid = await context.read<DeviceUidSettingsRepository>().getDeviceUid(
        widget.accountUid,
      );
    } catch (_) {
      // Use the configured device UID if local preferences are unavailable.
    }
    if (!mounted) return;

    final uid = savedUid?.trim().isNotEmpty == true
        ? savedUid!.trim()
        : defaultWatchDeviceUid;
    setState(() {
      _deviceUid = uid;
      _watchProvider = _createWatchProvider(uid);
    });
  }

  WatchDataProvider _createWatchProvider(String deviceUid) {
    return WatchDataProvider(
      watchLatestUseCase: context.read<WatchLatestUseCase>(),
      watchEventsUseCase: context.read<WatchEventsUseCase>(),
      watchConnectionUseCase: context.read<WatchConnectionUseCase>(),
      requestCancelAlertUseCase: context.read<RequestCancelAlertUseCase>(),
      alarmController: context.read<AlarmController>(),
      deviceUid: deviceUid,
    );
  }

  Future<bool> _changeDeviceUid(String nextUid) async {
    final normalizedUid = nextUid.trim();
    if (normalizedUid.isEmpty) return false;

    try {
      await context.read<DeviceUidSettingsRepository>().saveDeviceUid(
        accountUid: widget.accountUid,
        deviceUid: normalizedUid,
      );
    } catch (_) {
      return false;
    }
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
      child: AppShell(onDeviceUidChanged: _changeDeviceUid),
    );
  }
}
