import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watchiot/core/app_theme.dart';
import 'package:watchiot/features/auth/presentation/providers/auth_provider.dart';
import 'package:watchiot/features/chatbot/presentation/views/chatbot_view.dart';
import 'package:watchiot/features/monitoring/presentation/providers/watch_data_provider.dart';
import 'package:watchiot/features/monitoring/presentation/views/alert_overlay_view.dart';
import 'package:watchiot/features/monitoring/presentation/views/dashboard_view.dart';
import 'package:watchiot/features/monitoring/presentation/views/history_view.dart';
import 'package:watchiot/features/profile/presentation/views/profile_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.onDeviceUidChanged});

  final Future<bool> Function(String deviceUid) onDeviceUidChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<WatchDataProvider>();
    final auth = context.watch<AuthProvider>();
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
        if (watch.showAlertOverlay)
          Positioned.fill(
            child: AlertOverlayView(
              emergency: watch.alert?.isEmergency ?? false,
              message: watch.alert?.message ?? '',
              probability: watch.alert?.probability ?? 0,
              secondsRemaining: watch.alertSecondsRemaining,
              isSendingCancel: watch.isSendingCancel,
              onCancel: () async {
                final userUid = auth.user?.uid;
                if (userUid == null) return;
                final success = await watch.requestCancelAlert(userUid);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Đã gửi yêu cầu xác nhận an toàn tới đồng hồ.'
                          : watch.errorMessage ?? 'Không gửi được yêu cầu.',
                    ),
                  ),
                );
              },
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
}
