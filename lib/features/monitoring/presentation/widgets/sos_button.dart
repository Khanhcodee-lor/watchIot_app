import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:watchiot/core/app_theme.dart';

class SosButton extends StatelessWidget {
  const SosButton({
    super.key,
    required this.label,
    required this.phoneNumber,
    this.secondary = false,
  });

  final String label;
  final String phoneNumber;
  final bool secondary;

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thiết bị không thể mở ứng dụng gọi điện.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = secondary ? AppColors.surfaceRaised : AppColors.danger;
    final foreground = Colors.white;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _call(context),
        icon: const Icon(Icons.call_rounded),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }
}
