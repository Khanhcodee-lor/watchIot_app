import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watchiot/app/auth_gate.dart';
import 'package:watchiot/app/watch_data_provider_factory.dart';
import 'package:watchiot/core/app_theme.dart';
import 'package:watchiot/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:watchiot/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:watchiot/features/auth/domain/repositories/auth_repository.dart';
import 'package:watchiot/features/auth/domain/usecases/auth_use_cases.dart';
import 'package:watchiot/features/auth/presentation/providers/auth_provider.dart';
import 'package:watchiot/features/emergency/data/datasources/firebase_emergency_alert_data_source.dart';
import 'package:watchiot/features/emergency/data/datasources/secure_emergency_settings_data_source.dart';
import 'package:watchiot/features/emergency/data/repositories/firebase_emergency_alert_repository_impl.dart';
import 'package:watchiot/features/emergency/data/repositories/secure_emergency_settings_repository_impl.dart';
import 'package:watchiot/features/emergency/data/services/external_phone_dialer.dart';
import 'package:watchiot/features/emergency/domain/repositories/emergency_alert_repository.dart';
import 'package:watchiot/features/emergency/domain/repositories/emergency_settings_repository.dart';
import 'package:watchiot/features/emergency/domain/repositories/phone_dialer.dart';
import 'package:watchiot/features/emergency/presentation/providers/emergency_monitor_provider.dart';
import 'package:watchiot/core/app_config.dart';
import 'package:watchiot/features/monitoring/data/datasources/device_uid_local_data_source.dart';
import 'package:watchiot/features/monitoring/data/repositories/device_uid_settings_repository_impl.dart';
import 'package:watchiot/features/monitoring/data/services/audio_alarm_controller.dart';
import 'package:watchiot/features/monitoring/domain/repositories/alarm_controller.dart';
import 'package:watchiot/features/monitoring/domain/repositories/device_uid_settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final authRepository = AuthRepositoryImpl(
    FirebaseAuthDataSource(FirebaseAuth.instance),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<WatchDataProviderFactory>(
          create: (_) => WatchDataProviderFactory(),
        ),
        Provider<DeviceUidSettingsRepository>(
          create: (_) => DeviceUidSettingsRepositoryImpl(
            DeviceUidLocalDataSource(SharedPreferencesAsync()),
          ),
        ),
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
        Provider<RegisterUseCase>(
          create: (context) => RegisterUseCase(context.read<AuthRepository>()),
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
            registerUseCase: context.read<RegisterUseCase>(),
            sendPasswordResetUseCase: context.read<SendPasswordResetUseCase>(),
            signOutUseCase: context.read<SignOutUseCase>(),
          ),
        ),
        Provider<AlarmController>(
          create: (_) => AudioAlarmController(),
          dispose: (_, controller) => controller.dispose(),
        ),
        Provider<EmergencyAlertRepository>(
          create: (_) => FirebaseEmergencyAlertRepositoryImpl(
            FirebaseEmergencyAlertDataSource(),
          ),
        ),
        Provider<EmergencySettingsRepository>(
          create: (_) => SecureEmergencySettingsRepositoryImpl(
            SecureEmergencySettingsDataSource(const FlutterSecureStorage()),
          ),
        ),
        Provider<PhoneDialer>(create: (_) => ExternalPhoneDialer()),
        ChangeNotifierProvider<EmergencyMonitorProvider>(
          create: (context) => EmergencyMonitorProvider(
            alertRepository: context.read<EmergencyAlertRepository>(),
            settingsRepository: context.read<EmergencySettingsRepository>(),
            phoneDialer: context.read<PhoneDialer>(),
            alarmController: context.read<AlarmController>(),
            defaultDatabaseUrl: defaultFirebaseDatabaseUrl,
            defaultDeviceUid: defaultWatchDeviceUid,
          ),
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
