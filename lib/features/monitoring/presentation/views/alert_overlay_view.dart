import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:watchiot/core/app_theme.dart';
import 'package:watchiot/features/monitoring/presentation/widgets/sos_button.dart';

class AlertOverlayView extends StatefulWidget {
  const AlertOverlayView({
    super.key,
    required this.emergency,
    required this.message,
    required this.probability,
    required this.secondsRemaining,
    required this.isSendingCancel,
    required this.onCancel,
  });

  final bool emergency;
  final String message;
  final double probability;
  final int secondsRemaining;
  final bool isSendingCancel;
  final VoidCallback onCancel;

  @override
  State<AlertOverlayView> createState() => _AlertOverlayViewState();
}

class _AlertOverlayViewState extends State<AlertOverlayView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _callRelative() async {
    final controller = TextEditingController();
    final number = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Gọi người thân'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Nhập số điện thoại',
            prefixIcon: Icon(Icons.phone_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Tiếp tục gọi'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || number == null || number.isEmpty) return;
    final launched = await launchUrl(
      Uri(scheme: 'tel', path: number),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thiết bị không thể mở ứng dụng gọi điện.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmergency = widget.emergency;
    final color = isEmergency
        ? const Color(0xFFFF2538)
        : const Color(0xFFFF5D68);
    return Material(
      color: AppColors.background,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final opacity = isEmergency
              ? 0.22 + _pulseController.value * 0.25
              : 0.08 + _pulseController.value * 0.26;
          return Container(
            color: Color.lerp(AppColors.background, color, opacity),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [color.withValues(alpha: 0.16), Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.13),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withValues(alpha: 0.45),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              isEmergency
                                  ? Icons.emergency_rounded
                                  : Icons.warning_rounded,
                              color: color,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            isEmergency ? 'NGUY CẤP' : 'CẢNH BÁO TÉ NGÃ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: color,
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            isEmergency
                                ? 'Đồng hồ đã xác nhận tình huống khẩn cấp.'
                                : 'Đang chờ người đeo xác nhận an toàn.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              height: 1.5,
                            ),
                          ),
                          if (widget.message.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          if (!isEmergency)
                            Container(
                              width: 152,
                              height: 152,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surface,
                                border: Border.all(
                                  color: color.withValues(alpha: 0.45),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.12),
                                    blurRadius: 28,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.secondsRemaining.toString(),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 56,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'GIÂY',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                'Xác suất AI: ${(widget.probability * 100).toStringAsFixed(0)}%',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          const SizedBox(height: 28),
                          if (isEmergency) ...[
                            const SosButton(
                              label: 'GỌI CẤP CỨU 115',
                              phoneNumber: '115',
                            ),
                            const SizedBox(height: 11),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _callRelative,
                                icon: const Icon(Icons.family_restroom_rounded),
                                label: const Text('GỌI NGƯỜI THÂN'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(52),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: widget.isSendingCancel
                                    ? null
                                    : widget.onCancel,
                                icon: widget.isSendingCancel
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.verified_user_rounded),
                                label: const Text('HỦY BÁO ĐỘNG GIẢ'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: AppColors.background,
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Đồng hồ cần nhận lệnh tại devices/{uid}/commands/cancel_alert để xác nhận hủy.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
