import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:watchiot/core/app_theme.dart';
import 'package:watchiot/features/monitoring/domain/entities/fall_alert.dart';
import 'package:watchiot/features/monitoring/presentation/providers/watch_data_provider.dart';
import 'package:watchiot/features/monitoring/presentation/widgets/health_card.dart';
import 'package:watchiot/features/monitoring/presentation/widgets/metric_chart.dart';
import 'package:watchiot/features/monitoring/presentation/widgets/status_pill.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({
    super.key,
    required this.email,
    required this.onSignOut,
  });

  final String email;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<WatchDataProvider>();
    final health = watch.health;
    final sensor = watch.sensor;
    final alert = watch.alert;
    final heartRate = health?.heartRate ?? 0;
    final spo2 = health?.spo2 ?? 0;
    final probability = alert?.probability ?? 0;
    final isHeartRateWarning =
        health != null &&
        health.fingerDetected &&
        heartRate > 0 &&
        (heartRate < 50 || heartRate > 120);
    final isSpo2Warning =
        health != null && health.fingerDetected && spo2 > 0 && spo2 < 95;
    final aiStatus = _alertLabel(alert);
    final aiColor = alert?.status == FallAlert.emergencyConfirmed
        ? AppColors.danger
        : alert?.status == FallAlert.fallAlertStart || probability >= 0.4
        ? AppColors.warning
        : AppColors.accent;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final contentWidth = constraints.maxWidth;
        final cardWidth = wide
            ? (contentWidth - 14) / 2
            : (contentWidth - 12) / 2;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                wide ? 32 : 20,
                24,
                wide ? 32 : 20,
                30,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SMARTWATCH MONITOR',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sức khỏe hôm nay',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontSize: 27),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              email.isEmpty ? 'Đang theo dõi thiết bị' : email,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Đăng xuất',
                        onPressed: onSignOut,
                        icon: const Icon(Icons.logout_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _ConnectionCard(
                    isOnline: watch.isOnline,
                    firebaseConnected: watch.firebaseConnected,
                    lastUpdated: watch.lastDataReceivedAt,
                    deviceUid: watch.deviceUid,
                  ),
                  if (watch.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    _ErrorBanner(message: watch.errorMessage!),
                  ],
                  const SizedBox(height: 27),
                  _SectionHeading(
                    title: 'Chỉ số sức khỏe',
                    subtitle: 'Dữ liệu mới nhất từ cảm biến MAX30102',
                    icon: Icons.favorite_rounded,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: HealthCard(
                          title: 'Nhịp tim',
                          value:
                              health == null ||
                                  !health.fingerDetected ||
                                  heartRate <= 0
                              ? '--'
                              : heartRate.toStringAsFixed(0),
                          unit: 'BPM',
                          icon: Icons.favorite_rounded,
                          color: AppColors.danger,
                          warning: isHeartRateWarning,
                          caption: health == null
                              ? 'Chưa có dữ liệu'
                              : !health.fingerDetected
                              ? 'Đặt ngón tay lên cảm biến để đo'
                              : isHeartRateWarning
                              ? 'Ngoài ngưỡng hiển thị 50–120 BPM'
                              : 'Nhịp tim đang được theo dõi',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: HealthCard(
                          title: 'Nồng độ SpO₂',
                          value:
                              health == null ||
                                  !health.fingerDetected ||
                                  spo2 <= 0
                              ? '--'
                              : spo2.toStringAsFixed(0),
                          unit: '%',
                          icon: Icons.water_drop_rounded,
                          color: AppColors.blue,
                          warning: isSpo2Warning,
                          caption: health == null
                              ? 'Chưa có dữ liệu'
                              : !health.fingerDetected
                              ? 'Đặt ngón tay lên cảm biến để đo'
                              : isSpo2Warning
                              ? 'Thấp hơn ngưỡng cảnh báo 95%'
                              : 'Nồng độ oxy trong máu',
                        ),
                      ),
                      SizedBox(
                        width: contentWidth,
                        child: _FingerCard(
                          detected: health?.fingerDetected ?? false,
                          hasReading: health != null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 27),
                  _SectionHeading(
                    title: 'AI chuyển động & té ngã',
                    subtitle: 'Phân tích từ cảm biến MPU-6050',
                    icon: Icons.sensors_rounded,
                  ),
                  const SizedBox(height: 14),
                  _MotionCard(
                    acceleration: sensor?.accelerationMagnitude,
                    status: aiStatus,
                    color: aiColor,
                    probability: probability,
                    isActive: alert?.isActive ?? false,
                  ),
                  const SizedBox(height: 27),
                  _SectionHeading(
                    title: 'Diễn biến sức khỏe',
                    subtitle: '20 mẫu gần nhất nhận được khi ứng dụng đang mở',
                    icon: Icons.show_chart_rounded,
                  ),
                  const SizedBox(height: 14),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: MetricChart(
                            title: 'Nhịp tim',
                            unit: 'BPM',
                            points: watch.heartRatePoints,
                            color: AppColors.danger,
                            icon: Icons.favorite_rounded,
                            fallbackMin: 50,
                            fallbackMax: 120,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: MetricChart(
                            title: 'SpO₂',
                            unit: '%',
                            points: watch.spo2Points,
                            color: AppColors.blue,
                            icon: Icons.water_drop_rounded,
                            fallbackMin: 90,
                            fallbackMax: 100,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    MetricChart(
                      title: 'Nhịp tim',
                      unit: 'BPM',
                      points: watch.heartRatePoints,
                      color: AppColors.danger,
                      icon: Icons.favorite_rounded,
                      fallbackMin: 50,
                      fallbackMax: 120,
                    ),
                    const SizedBox(height: 12),
                    MetricChart(
                      title: 'SpO₂',
                      unit: '%',
                      points: watch.spo2Points,
                      color: AppColors.blue,
                      icon: Icons.water_drop_rounded,
                      fallbackMin: 90,
                      fallbackMax: 100,
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Text(
                    'Ngưỡng màu là thiết lập giao diện tham khảo, không thay thế đánh giá y tế. Gia tốc được hiển thị theo đơn vị thiết bị gửi lên.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _alertLabel(FallAlert? alert) {
  if (alert == null) return 'Đang chờ dữ liệu';
  switch (alert.status) {
    case FallAlert.fallAlertStart:
      return 'Nghi ngờ ngã';
    case FallAlert.emergencyConfirmed:
      return 'CẢNH BÁO TÉ NGÃ!';
    case FallAlert.cancelledByUser:
      return 'Đã xác nhận an toàn';
    default:
      return alert.probability >= 0.4
          ? 'Đang theo dõi chuyển động'
          : 'Bình thường';
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.isOnline,
    required this.firebaseConnected,
    required this.lastUpdated,
    required this.deviceUid,
  });

  final bool isOnline;
  final bool? firebaseConnected;
  final DateTime? lastUpdated;
  final String deviceUid;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppColors.accent : AppColors.warning;
    final status = firebaseConnected == false
        ? 'Mất kết nối Firebase'
        : lastUpdated == null
        ? 'Đang chờ dữ liệu'
        : isOnline
        ? 'Đồng hồ đang trực tuyến'
        : 'Đồng hồ ngoại tuyến';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceRaised,
            AppColors.surface.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.watch_rounded, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill(
                  label: status,
                  color: color,
                  icon: isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                ),
                const SizedBox(height: 8),
                Text(
                  lastUpdated == null
                      ? 'Thiết bị: $deviceUid'
                      : 'Cập nhật lúc ${TimeOfDay.fromDateTime(lastUpdated!).format(context)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 21),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FingerCard extends StatelessWidget {
  const _FingerCard({required this.detected, required this.hasReading});

  final bool detected;
  final bool hasReading;

  @override
  Widget build(BuildContext context) {
    final color = detected ? AppColors.accent : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app_rounded, color: color, size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trạng thái chạm tay',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  !hasReading
                      ? 'Đang chờ dữ liệu'
                      : detected
                      ? 'Đang đo'
                      : 'Chưa chạm ngón tay',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Icon(
            detected ? Icons.check_circle_rounded : Icons.more_horiz_rounded,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _MotionCard extends StatelessWidget {
  const _MotionCard({
    required this.acceleration,
    required this.status,
    required this.color,
    required this.probability,
    required this.isActive,
  });

  final double? acceleration;
  final String status;
  final Color color;
  final double probability;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: isActive ? 0.42 : 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.accessibility_new_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trạng thái AI',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                const Icon(
                  Icons.crisis_alert_rounded,
                  color: AppColors.danger,
                  size: 25,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: AppColors.blue, size: 18),
              const SizedBox(width: 7),
              const Text(
                'Độ lớn gia tốc',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const Spacer(),
              Text(
                acceleration == null
                    ? '-- m/s²'
                    : '${acceleration!.toStringAsFixed(2)} m/s²',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Xác suất té ngã',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
              Text(
                '${(probability * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: probability,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Xác suất do mô hình AI trên đồng hồ cung cấp.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
