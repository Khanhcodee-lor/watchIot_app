import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:watchiot/core/app_theme.dart';
import 'package:watchiot/core/app_config.dart';
import 'package:watchiot/features/monitoring/domain/entities/fall_alert.dart';
import 'package:watchiot/features/monitoring/presentation/providers/watch_data_provider.dart';
import 'package:watchiot/features/monitoring/presentation/widgets/health_card.dart';
import 'package:watchiot/features/monitoring/presentation/widgets/metric_chart.dart';

String _maskedDeviceUid(String uid) {
  if (uid.length <= 10) return uid;
  return '${uid.substring(0, 5)}…${uid.substring(uid.length - 5)}';
}

class DashboardView extends StatelessWidget {
  const DashboardView({
    super.key,
    required this.email,
    required this.onDeviceUidChanged,
  });

  final String email;
  final Future<bool> Function(String deviceUid) onDeviceUidChanged;

  Future<void> _editDeviceUid(BuildContext context, String currentUid) async {
    final nextUid = await showDialog<String>(
      context: context,
      builder: (_) => _DeviceUidDialog(initialUid: currentUid),
    );
    if (nextUid == null || nextUid.trim().isEmpty || !context.mounted) return;

    final saved = await onDeviceUidChanged(nextUid.trim());
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Đã đổi thiết bị đang theo dõi.'
              : 'Không lưu được UID thiết bị. Hãy thử lại.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<WatchDataProvider>();
    final health = watch.health;
    final sensor = watch.sensor;
    final alert = watch.alert;
    final heartRate = health?.heartRate ?? 0;
    final spo2 = health?.spo2 ?? 0;
    final probability = alert?.probability;
    final isHeartRateWarning =
        health != null &&
        health.fingerDetected &&
        heartRate > 0 &&
        (heartRate < 50 || heartRate > 120);
    final isSpo2Warning =
        health != null && health.fingerDetected && spo2 > 0 && spo2 < 95;
    final aiStatus = _alertLabel(alert);
    final aiColor = alert == null
        ? AppColors.muted
        : alert.status == FallAlert.emergencyConfirmed
        ? AppColors.danger
        : alert.status == FallAlert.fallAlertStart || (probability ?? 0) >= 0.4
        ? AppColors.warning
        : AppColors.success;

    return SafeArea(
      top: true,
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 760 ? 30.0 : 16.0;
          final contentWidth = constraints.maxWidth - horizontalPadding * 2;
          final wide = constraints.maxWidth >= 760;
          final cardWidth = wide
              ? (contentWidth - 14) / 2
              : (contentWidth - 12) / 2;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  30,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.24),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.monitor_heart_rounded,
                            color: AppColors.warning,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SMARTWATCH  ·  THEO DÕI SỨC KHỎE',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.warning,
                                      letterSpacing: 0.65,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Sức khỏe người thân',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(fontSize: 18),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email.isEmpty
                                    ? 'Đang theo dõi thiết bị'
                                    : email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _ConnectionCard(
                      isOnline: watch.isOnline,
                      firebaseConnected: watch.firebaseConnected,
                      lastUpdated: watch.lastDataReceivedAt,
                      deviceUid: watch.deviceUid,
                      onEditDeviceUid: () =>
                          _editDeviceUid(context, watch.deviceUid),
                    ),
                    if (watch.firebaseConnected == true &&
                        !watch.isLoading &&
                        watch.lastDataReceivedAt == null &&
                        watch.errorMessage == null) ...[
                      const SizedBox(height: 12),
                      _NoDeviceDataCard(deviceUid: watch.deviceUid),
                    ],
                    if (watch.errorMessage != null) ...[
                      const SizedBox(height: 14),
                      _ErrorBanner(message: watch.errorMessage!),
                    ],
                    const SizedBox(height: 20),
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
                      ],
                    ),
                    const SizedBox(height: 22),
                    HealthTrendChart(
                      heartRatePoints: watch.heartRatePoints,
                      spo2Points: watch.spo2Points,
                    ),
                    const SizedBox(height: 12),
                    _FingerCard(
                      detected: health?.fingerDetected ?? false,
                      hasReading: health != null,
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
                    const SizedBox(height: 16),
                    const Text(
                      'Chỉ số hiển thị theo dữ liệu đồng hồ gửi lên; thông tin trong app không thay thế đánh giá y tế.',
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
      ),
    );
  }
}

class _DeviceUidDialog extends StatefulWidget {
  const _DeviceUidDialog({required this.initialUid});

  final String initialUid;

  @override
  State<_DeviceUidDialog> createState() => _DeviceUidDialogState();
}

class _DeviceUidDialogState extends State<_DeviceUidDialog> {
  late final TextEditingController _controller;
  var _obscureUid = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUid);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      scrollable: true,
      icon: const Icon(Icons.watch_rounded, color: AppColors.warning),
      title: const Text('Chọn đồng hồ cần theo dõi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhập UID nằm sau devices/ trong Firebase Realtime Database.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: _obscureUid,
            enableSuggestions: false,
            autocorrect: false,
            enableIMEPersonalizedLearning: false,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'UID thiết bị',
              hintText: 'Nhập UID thiết bị',
              prefixIcon: const Icon(Icons.devices_rounded),
              suffixIconConstraints: const BoxConstraints.tightFor(
                width: 40,
                height: 40,
              ),
              suffixIcon: IconButton(
                tooltip: _obscureUid ? 'Hiện UID' : 'Ẩn UID',
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                onPressed: () => setState(() => _obscureUid = !_obscureUid),
                icon: Icon(
                  _obscureUid
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đường dẫn đọc: /devices/<UID>/latest',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context, defaultWatchDeviceUid),
          icon: const Icon(Icons.restore_rounded, size: 17),
          label: const Text('UID mặc định'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Lưu UID'),
        ),
      ],
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
    required this.onEditDeviceUid,
  });

  final bool isOnline;
  final bool? firebaseConnected;
  final DateTime? lastUpdated;
  final String deviceUid;
  final VoidCallback onEditDeviceUid;

  @override
  Widget build(BuildContext context) {
    final firebaseColor = firebaseConnected == true
        ? AppColors.success
        : firebaseConnected == false
        ? AppColors.danger
        : AppColors.warning;
    final firebaseLabel = firebaseConnected == true
        ? 'Đã kết nối'
        : firebaseConnected == false
        ? 'Mất kết nối'
        : 'Đang kiểm tra';
    final deviceColor = isOnline
        ? AppColors.success
        : lastUpdated == null
        ? AppColors.muted
        : AppColors.warning;
    final deviceLabel = isOnline
        ? 'Trực tuyến'
        : lastUpdated == null
        ? 'Chưa có dữ liệu'
        : 'Ngoại tuyến';
    final deviceIcon = isOnline
        ? Icons.wifi_rounded
        : lastUpdated == null
        ? Icons.hourglass_empty_rounded
        : Icons.wifi_off_rounded;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.cloud_done_rounded,
                  color: AppColors.warning,
                  size: 19,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Realtime Database',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 9,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _ConnectionBadge(
                label: firebaseLabel,
                color: firebaseColor,
                icon: firebaseConnected == true
                    ? Icons.check_rounded
                    : firebaseConnected == false
                    ? Icons.cloud_off_rounded
                    : Icons.sync_rounded,
              ),
              const SizedBox(width: 4),
              Material(
                color: AppColors.surfaceRaised,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: onEditDeviceUid,
                  tooltip: 'Đổi UID thiết bị',
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.edit_rounded,
                    size: 15,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppColors.outline),
          ),
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: deviceColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.watch_rounded, size: 18, color: deviceColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đồng hồ',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 9,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      deviceLabel,
                      style: TextStyle(
                        color: deviceColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(deviceIcon, size: 17, color: deviceColor),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 12,
                color: AppColors.muted.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 4),
              Text(
                lastUpdated == null
                    ? 'Chưa cập nhật'
                    : TimeOfDay.fromDateTime(lastUpdated!).format(context),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.fingerprint_rounded,
                size: 12,
                color: AppColors.muted.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Tooltip(
                  message: 'UID được ẩn một phần; mở sửa UID để xem đầy đủ.',
                  child: Text(
                    'UID: ${_maskedDeviceUid(deviceUid)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoDeviceDataCard extends StatelessWidget {
  const _NoDeviceDataCard({required this.deviceUid});

  final String deviceUid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chưa có dữ liệu từ đồng hồ',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '/devices/${_maskedDeviceUid(deviceUid)}/latest · kiểm tra UID và RTDB Rules',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
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
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.outline),
          ),
          child: Icon(icon, color: AppColors.warning, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
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
    final color = detected ? AppColors.success : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.outline),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
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
  final double? probability;
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
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
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
                probability == null
                    ? '--'
                    : '${(probability! * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: probability ?? 0,
              minHeight: 9,
              backgroundColor: AppColors.outline,
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
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
