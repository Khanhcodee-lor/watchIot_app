import 'package:flutter/material.dart';

import 'package:watchiot/core/app_theme.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.email,
    required this.accountUid,
    required this.deviceUid,
    required this.onSignOut,
    required this.onOpenSettings,
  });

  final String email;
  final String accountUid;
  final String deviceUid;
  final VoidCallback onSignOut;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final initial = email.isEmpty ? 'U' : email.substring(0, 1).toUpperCase();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          Text(
            'Hồ sơ',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 5),
          const Text(
            'Tài khoản và thiết bị đang theo dõi',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.surface, AppColors.surfaceRaised],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.outline),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.accentSoft,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  email.isEmpty ? 'Tài khoản người thân' : email,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                const Text(
                  'Người giám sát',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ProfileInfoCard(
            icon: Icons.person_outline_rounded,
            title: 'UID tài khoản ứng dụng',
            value: accountUid,
            color: AppColors.blue,
          ),
          const SizedBox(height: 11),
          _ProfileInfoCard(
            icon: Icons.watch_rounded,
            title: 'UID đồng hồ đang theo dõi',
            value: deviceUid.length <= 10
                ? deviceUid
                : '${deviceUid.substring(0, 5)}…${deviceUid.substring(deviceUid.length - 5)}',
            color: AppColors.warning,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.health_and_safety_rounded),
            label: const Text('Cài đặt Firebase và người thân'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.accentSoft,
              foregroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.25)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Smartwatch Fall & Health Monitor',
              style: TextStyle(color: AppColors.muted, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
