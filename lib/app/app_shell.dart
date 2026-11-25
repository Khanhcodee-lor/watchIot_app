import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watchiot/features/auth/presentation/providers/auth_provider.dart';
import 'package:watchiot/features/monitoring/presentation/providers/watch_data_provider.dart';
import 'package:watchiot/features/monitoring/presentation/views/alert_overlay_view.dart';
import 'package:watchiot/features/monitoring/presentation/views/dashboard_view.dart';
import 'package:watchiot/features/monitoring/presentation/views/history_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<WatchDataProvider>();
    final auth = context.read<AuthProvider>();
    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              DashboardView(
                email: auth.user?.email ?? '',
                onSignOut: auth.signOut,
              ),
              const HistoryView(),
            ],
          ),
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
}
