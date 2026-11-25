import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watchiot/app/auth_gate.dart';
import 'package:watchiot/core/app_theme.dart';
import 'package:watchiot/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:watchiot/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:watchiot/features/auth/domain/repositories/auth_repository.dart';
import 'package:watchiot/features/auth/domain/usecases/auth_use_cases.dart';
import 'package:watchiot/features/auth/presentation/providers/auth_provider.dart';
import 'package:watchiot/features/monitoring/data/datasources/realtime_database_data_source.dart';
import 'package:watchiot/features/monitoring/data/repositories/monitoring_repository_impl.dart';
import 'package:watchiot/features/monitoring/data/services/audio_alarm_controller.dart';
import 'package:watchiot/features/monitoring/domain/repositories/alarm_controller.dart';
import 'package:watchiot/features/monitoring/domain/repositories/monitoring_repository.dart';
import 'package:watchiot/features/monitoring/domain/usecases/monitoring_use_cases.dart';

const firebaseDatabaseUrl =
    'https://smartwatch-c1877-default-rtdb.firebaseio.com/';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: firebaseDatabaseUrl,
  );
  final authRepository = AuthRepositoryImpl(
    FirebaseAuthDataSource(FirebaseAuth.instance),
  );
  final monitoringRepository = MonitoringRepositoryImpl(
    RealtimeDatabaseDataSource(database),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<MonitoringRepository>.value(value: monitoringRepository),
        Provider<GetCurrentUserUseCase>(
          create: (context) =>
              GetCurrentUserUseCase(context.read<AuthRepository>()),
        ),
        Provider<WatchAuthStateUseCase>(
          create: (context) =>
              WatchAuthStateUseCase(context.read<AuthRepository>()),
        ),
        Provider<SignInUseCase>(
          create: (context) => SignInUseCase(context.read<AuthRepository>()),
        ),
        Provider<SendPasswordResetUseCase>(
          create: (context) =>
              SendPasswordResetUseCase(context.read<AuthRepository>()),
        ),
        Provider<SignOutUseCase>(
          create: (context) => SignOutUseCase(context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            getCurrentUserUseCase: context.read<GetCurrentUserUseCase>(),
            watchAuthStateUseCase: context.read<WatchAuthStateUseCase>(),
            signInUseCase: context.read<SignInUseCase>(),
            sendPasswordResetUseCase: context.read<SendPasswordResetUseCase>(),
            signOutUseCase: context.read<SignOutUseCase>(),
          ),
        ),
        Provider<WatchLatestUseCase>(
          create: (context) =>
              WatchLatestUseCase(context.read<MonitoringRepository>()),
        ),
        Provider<WatchEventsUseCase>(
          create: (context) =>
              WatchEventsUseCase(context.read<MonitoringRepository>()),
        ),
        Provider<WatchConnectionUseCase>(
          create: (context) =>
              WatchConnectionUseCase(context.read<MonitoringRepository>()),
        ),
        Provider<RequestCancelAlertUseCase>(
          create: (context) =>
              RequestCancelAlertUseCase(context.read<MonitoringRepository>()),
        ),
        Provider<AlarmController>(
          create: (_) => AudioAlarmController(),
          dispose: (_, controller) => controller.dispose(),
        ),
      ],
      child: const SmartwatchMonitorApp(),
    ),
  );
}

class SmartwatchMonitorApp extends StatelessWidget {
  const SmartwatchMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smartwatch Fall & Health Monitor',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}
