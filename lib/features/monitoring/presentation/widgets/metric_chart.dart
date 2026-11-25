import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:watchiot/core/app_theme.dart';
import 'package:watchiot/features/monitoring/domain/entities/metric_point.dart';

class MetricChart extends StatelessWidget {
  const MetricChart({
    super.key,
    required this.title,
    required this.unit,
    required this.points,
    required this.color,
    required this.icon,
    required this.fallbackMin,
    required this.fallbackMax,
  });

  final String title;
  final String unit;
  final List<MetricPoint> points;
  final Color color;
  final IconData icon;
  final double fallbackMin;
  final double fallbackMax;

  @override
  Widget build(BuildContext context) {
    final values = points.map((point) => point.value).toList();
    final minValue = values.isEmpty
        ? fallbackMin
        : values.reduce((a, b) => math.min(a, b).toDouble());
    final maxValue = values.isEmpty
        ? fallbackMax
        : values.reduce((a, b) => math.max(a, b).toDouble());
    final spread = math.max(maxValue - minValue, 4).toDouble();
    final minY = math.max(0.0, minValue - spread * 0.25).toDouble();
    final maxY = maxValue + spread * 0.25;
    final maxX = math.max(points.length - 1, 1).toDouble();
    final interval = math.max((maxY - minY) / 3, 1).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 9),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                unit,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 160,
            child: points.length < 2
                ? Center(
                    child: Text(
                      points.isEmpty
                          ? 'Đang chờ dữ liệu...'
                          : 'Cần thêm dữ liệu để vẽ biểu đồ',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: maxX,
                      minY: minY,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: interval,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.white.withValues(alpha: 0.07),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 37,
                            interval: interval,
                            getTitlesWidget: (value, meta) => Text(
                              value.round().toString(),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            interval: math.max(points.length / 3, 1).toDouble(),
                            getTitlesWidget: (value, meta) {
                              final index = value.round();
                              if (index < 0 || index >= points.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  DateFormat(
                                    'HH:mm',
                                  ).format(points[index].time),
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < points.length; i++)
                              FlSpot(i.toDouble(), points[i].value),
                          ],
                          isCurved: true,
                          curveSmoothness: 0.28,
                          color: color,
                          barWidth: 2.7,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 260),
                  ),
          ),
        ],
      ),
    );
  }
}
