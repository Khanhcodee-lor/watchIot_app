import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watchiot/features/auth/presentation/providers/auth_provider.dart';
import 'package:watchiot/features/auth/presentation/views/login_view.dart';
import 'package:watchiot/features/monitoring/domain/repositories/alarm_controller.dart';
import 'package:watchiot/features/monitoring/presentation/providers/watch_data_provider.dart';
import 'package:watchiot/app/app_shell.dart';
import 'package:watchiot/features/monitoring/domain/usecases/monitoring_use_cases.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        if (user == null) return const LoginView();
        return _WatchSession(key: ValueKey(user.uid), deviceUid: user.uid);
      },
    );
  }
}

class _WatchSession extends StatefulWidget {
  const _WatchSession({super.key, required this.deviceUid});

  final String deviceUid;

  @override
  State<_WatchSession> createState() => _WatchSessionState();
}

class _WatchSessionState extends State<_WatchSession> {
  late final WatchDataProvider _watchProvider;

  @override
  void initState() {
    super.initState();
    _watchProvider = WatchDataProvider(
      watchLatestUseCase: context.read<WatchLatestUseCase>(),
      watchEventsUseCase: context.read<WatchEventsUseCase>(),
      watchConnectionUseCase: context.read<WatchConnectionUseCase>(),
      requestCancelAlertUseCase: context.read<RequestCancelAlertUseCase>(),
      alarmController: context.read<AlarmController>(),
      deviceUid: widget.deviceUid,
    );
  }

  @override
  void dispose() {
    _watchProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WatchDataProvider>.value(
      value: _watchProvider,
      child: const AppShell(),
    );
  }
}
