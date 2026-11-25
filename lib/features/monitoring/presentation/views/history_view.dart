import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:watchiot/core/app_theme.dart';
import 'package:watchiot/features/monitoring/domain/entities/watch_event.dart';
import 'package:watchiot/features/monitoring/presentation/providers/watch_data_provider.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final watch = context.watch<WatchDataProvider>();
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: const Icon(
                        Icons.event_note_rounded,
                        color: AppColors.warning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        'Lịch sử sự kiện',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(fontSize: 24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Các lần phát hiện té ngã và xác nhận an toàn từ đồng hồ.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                if (watch.errorMessage != null) ...[
                  _HistoryErrorCard(message: watch.errorMessage!),
                  const SizedBox(height: 12),
                ],
                if (watch.events.isEmpty)
                  _EmptyHistory(isLoading: watch.isLoading)
                else
                  ...watch.events.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _EventCard(event: event),
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Thời gian chính xác cần được thiết bị ghi kèm timestamp (Unix milliseconds) hoặc dùng khóa push của Firebase.',
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
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isLoading
                ? Icons.hourglass_empty_rounded
                : Icons.event_note_rounded,
            color: AppColors.warning,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            isLoading ? 'Đang tải sự kiện...' : 'Chưa có sự kiện nào',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          const Text(
            'Sự kiện mới sẽ xuất hiện tại đây.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _HistoryErrorCard extends StatelessWidget {
  const _HistoryErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final WatchEvent event;

  @override
  Widget build(BuildContext context) {
    final cancelled = event.status == 'ALERT_CANCELLED_BY_USER';
    final confirmed = event.status == 'EMERGENCY_CONFIRMED';
    final color = confirmed
        ? AppColors.danger
        : cancelled
        ? AppColors.success
        : AppColors.warning;
    final icon = confirmed
        ? Icons.emergency_rounded
        : cancelled
        ? Icons.verified_user_rounded
        : Icons.warning_amber_rounded;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _eventTitle(event),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (event.message.isNotEmpty &&
                    event.message != _eventTitle(event)) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.message,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  event.occurredAt == null
                      ? 'Chưa có thời gian'
                      : DateFormat(
                          'dd/MM/yyyy · HH:mm:ss',
                        ).format(event.occurredAt!.toLocal()),
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (event.probability != null)
            Text(
              '${(event.probability! * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
        ],
      ),
    );
  }
}

String _eventTitle(WatchEvent event) {
  switch (event.status) {
    case 'FALL_ALERT_START':
      return 'Phát hiện dấu hiệu té ngã';
    case 'EMERGENCY_CONFIRMED':
      return 'Đã xác nhận tình huống khẩn cấp';
    case 'ALERT_CANCELLED_BY_USER':
      return 'Người thân đã xác nhận an toàn';
    default:
      return event.message.isEmpty ? event.status : event.message;
  }
}
