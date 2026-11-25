import 'package:flutter/material.dart';

import 'package:watchiot/core/app_theme.dart';

class HealthCard extends StatelessWidget {
  const HealthCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.caption,
    this.warning = false,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final String? caption;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final highlight = warning ? AppColors.warning : color;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlight.withValues(alpha: warning ? 0.42 : 0.12),
          width: warning ? 1.2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: highlight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 21, color: highlight),
              ),
              const Spacer(),
              if (warning)
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 19,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: warning ? AppColors.warning : Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 10),
            Text(
              caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: warning ? AppColors.warning : AppColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
