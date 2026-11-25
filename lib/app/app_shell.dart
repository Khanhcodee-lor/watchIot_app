import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watchiot/core/app_theme.dart';
import 'package:watchiot/features/auth/presentation/providers/auth_provider.dart';
import 'package:watchiot/features/chatbot/presentation/views/chatbot_view.dart';
import 'package:watchiot/features/emergency/presentation/providers/emergency_monitor_provider.dart';
import 'package:watchiot/features/emergency/presentation/views/emergency_alert_overlay_view.dart';
import 'package:watchiot/features/emergency/presentation/views/emergency_settings_view.dart';
import 'package:watchiot/features/monitoring/presentation/providers/watch_data_provider.dart';
import 'package:watchiot/features/monitoring/presentation/views/dashboard_view.dart';
import 'package:watchiot/features/monitoring/presentation/views/history_view.dart';
import 'package:watchiot/features/profile/presentation/views/profile_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.onDeviceUidChanged,
    required this.onTargetChanged,
  });

  final Future<bool> Function(String deviceUid) onDeviceUidChanged;
  final Future<bool> Function(String databaseUrl, String deviceUid)
  onTargetChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<WatchDataProvider>();
    final auth = context.watch<AuthProvider>();
    final emergency = context.watch<EmergencyMonitorProvider>();
    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              DashboardView(
                email: auth.user?.email ?? '',
                onDeviceUidChanged: widget.onDeviceUidChanged,
              ),
              const HistoryView(),
              ProfileView(
                email: auth.user?.email ?? '',
                accountUid: auth.user?.uid ?? '',
                deviceUid: watch.deviceUid,
                onSignOut: auth.signOut,
                onOpenSettings: _openEmergencySettings,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.small(
            heroTag: 'open-chatbot',
            onPressed: _openChatbot,
            tooltip: 'Mở Chatbot',
            backgroundColor: AppColors.accentSoft,
            foregroundColor: AppColors.warning,
            elevation: 3,
            child: const Icon(Icons.smart_toy_rounded, size: 21),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard_rounded),
                label: 'Tổng quan',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_rounded),
                selectedIcon: Icon(Icons.manage_history_rounded),
                label: 'Lịch sử',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Hồ sơ',
              ),
            ],
          ),
        ),
        if (emergency.showEmergencyOverlay)
          Positioned.fill(
            child: EmergencyAlertOverlayView(
              onOpenSettings: _openEmergencySettings,
            ),
          ),
        if (emergency.showEmergencyStatusBanner)
          Positioned(
            left: 14,
            right: 14,
            bottom: 88,
            child: Material(
              color: AppColors.surface,
              elevation: 8,
              borderRadius: BorderRadius.circular(17),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 11, 6, 11),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        emergency.emergencyStatusBannerMessage,
                        style: const TextStyle(fontSize: 11, height: 1.35),
                      ),
                    ),
                    if (emergency.canRestoreEmergencyOverlay)
                      TextButton(
                        onPressed: emergency.restoreEmergencyOverlay,
                        child: const Text('Xem lại'),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openChatbot() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (chatContext) => Scaffold(
          backgroundColor: AppColors.background,
          body: ChatbotView(onClose: () => Navigator.of(chatContext).pop()),
        ),
      ),
    );
  }

  void _openEmergencySettings() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            EmergencySettingsView(onTargetChanged: widget.onTargetChanged),
      ),
    );
  }
}
