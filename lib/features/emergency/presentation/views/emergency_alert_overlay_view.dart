import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watchiot/core/app_theme.dart';
import 'package:watchiot/features/emergency/domain/entities/emergency_call_status.dart';
import 'package:watchiot/features/emergency/domain/entities/family_contact.dart';
import 'package:watchiot/features/emergency/presentation/providers/emergency_monitor_provider.dart';

class EmergencyAlertOverlayView extends StatefulWidget {
  const EmergencyAlertOverlayView({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  State<EmergencyAlertOverlayView> createState() =>
      _EmergencyAlertOverlayViewState();
}

class _EmergencyAlertOverlayViewState extends State<EmergencyAlertOverlayView> {
  Timer? _pulseTimer;
  bool _pulse = false;

  @override
  void initState() {
    super.initState();
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (mounted) setState(() => _pulse = !_pulse);
    });
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    super.dispose();
  }

  Future<void> _startCallFlow() async {
    final provider = context.read<EmergencyMonitorProvider>();
    final contacts = provider.settings.contacts;
    if (contacts.isEmpty || !provider.settings.allowCallWhenConfirmed) {
      widget.onOpenSettings();
      return;
    }
    if (provider.isCurrentAlertHistorical) return;
    if (contacts.length == 1) {
      await provider.openDialerFor(contacts.first);
      return;
    }
    final selected = await showModalBottomSheet<FamilyContact>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn người thân cần gọi',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              for (final contact in contacts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.accentSoft,
                    child: Icon(Icons.person_rounded, color: AppColors.warning),
                  ),
                  title: Text(contact.name),
                  subtitle: Text(contact.phoneNumber),
                  trailing: const Icon(Icons.call_rounded),
                  onTap: () => Navigator.pop(sheetContext, contact),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      await context.read<EmergencyMonitorProvider>().openDialerFor(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmergencyMonitorProvider>();
    final alert = provider.currentAlert;
    if (alert == null) return const SizedBox.shrink();

    final historical = provider.isCurrentAlertHistorical;
    final configured =
        provider.settings.isReadyForCall &&
        provider.settings.allowCallWhenConfirmed;
    final canCall =
        configured &&
        !historical &&
        provider.callStatus != EmergencyCallStatus.openingDialer &&
        provider.callStatus != EmergencyCallStatus.dialerOpened;
    final status = _statusDescription(provider.callStatus, historical);

    return Material(
      color: const Color(0xEE7B101B),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton.filledTonal(
                    tooltip: 'Ẩn cảnh báo trên điện thoại',
                    onPressed: provider.dismissEmergencyOnPhone,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  width: 104,
                  height: 104,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _pulse ? Colors.white : const Color(0xFFFFD9D9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(
                          alpha: _pulse ? .30 : .1,
                        ),
                        blurRadius: _pulse ? 34 : 18,
                        spreadRadius: _pulse ? 5 : 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.health_and_safety_rounded,
                    size: 56,
                    color: _pulse ? const Color(0xFF9A1722) : AppColors.danger,
                  ),
                ),
                const Text(
                  'CẢNH BÁO KHẨN CẤP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFD5D5),
                    fontSize: 13,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Đã xác nhận té ngã — cần liên hệ người thân',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (alert.message.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    alert.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFE8E8),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 21),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (provider.alarmError != null) ...[
                  const SizedBox(height: 9),
                  Text(
                    provider.alarmError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFE8E8),
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 64,
                  child: FilledButton.icon(
                    onPressed: canCall
                        ? _startCallFlow
                        : historical
                        ? null
                        : configured
                        ? null
                        : widget.onOpenSettings,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF8E101D),
                      disabledBackgroundColor: Colors.white.withValues(
                        alpha: .55,
                      ),
                      disabledForegroundColor: const Color(0xFF8E101D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(19),
                      ),
                    ),
                    icon: Icon(
                      configured ? Icons.call_rounded : Icons.settings_rounded,
                      size: 25,
                    ),
                    label: Text(
                      historical
                          ? 'CẢNH BÁO CŨ — KHÔNG GỌI'
                          : configured
                          ? provider.callStatus ==
                                    EmergencyCallStatus.openingDialer
                                ? 'ĐANG MỞ TRÌNH GỌI…'
                                : provider.callStatus ==
                                      EmergencyCallStatus.dialerOpened
                                ? 'ĐÃ MỞ TRÌNH GỌI'
                                : 'GỌI NGƯỜI THÂN NGAY'
                          : 'THIẾT LẬP SỐ NGƯỜI THÂN',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        letterSpacing: .3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'App chỉ mở trình gọi. Hãy xác nhận cuộc gọi trên màn hình điện thoại.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFE8E8),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: provider.dismissEmergencyOnPhone,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.visibility_off_rounded, size: 18),
                  label: const Text('Ẩn cảnh báo trên ứng dụng này'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusDescription(EmergencyCallStatus status, bool historical) {
    if (historical || status == EmergencyCallStatus.historicalRecord) {
      return 'Bản ghi này đã có trước lần đầu app kết nối. App đã bỏ qua quy trình báo gọi.';
    }
    return switch (status) {
      EmergencyCallStatus.waitingForUser =>
        'Đang chờ bạn xác nhận gọi người thân. Chưa có cuộc gọi nào được thực hiện.',
      EmergencyCallStatus.openingDialer => 'Đang mở trình gọi điện…',
      EmergencyCallStatus.dialerOpened =>
        'Đã mở trình gọi. App không thể biết bạn đã xác nhận cuộc gọi hay chưa.',
      EmergencyCallStatus.cancelled =>
        'Bạn đã ẩn cảnh báo trên ứng dụng này. Trạng thái trên đồng hồ không bị thay đổi.',
      EmergencyCallStatus.cannotCall =>
        'Không thể mở trình gọi. Hãy kiểm tra thiết bị hoặc gọi số khẩn cấp bằng điện thoại.',
      EmergencyCallStatus.callsDisabled =>
        'Gọi người thân đang tắt. Bật quyền gọi trong Cài đặt an toàn nếu muốn.',
      EmergencyCallStatus.fallCheckInProgress =>
        'Đồng hồ đang trong thời gian chờ xác nhận té ngã.',
      EmergencyCallStatus.notNotifyingFamily =>
        'Cảnh báo này không yêu cầu thông báo người thân.',
      EmergencyCallStatus.idle =>
        'Cảnh báo đã được nhận. Hãy chọn gọi người thân nếu cần hỗ trợ.',
      EmergencyCallStatus.historicalRecord =>
        'Bản ghi cũ đã được bỏ qua để không tạo cuộc gọi ngoài ý muốn.',
    };
  }
}
