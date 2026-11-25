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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: AppColors.outline, strokeWidth: 1),
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

enum _HealthMetric { heartRate, oxygen }

class HealthTrendChart extends StatefulWidget {
  const HealthTrendChart({
    super.key,
    required this.heartRatePoints,
    required this.spo2Points,
  });

  final List<MetricPoint> heartRatePoints;
  final List<MetricPoint> spo2Points;

  @override
  State<HealthTrendChart> createState() => _HealthTrendChartState();
}

class _HealthTrendChartState extends State<HealthTrendChart> {
  _HealthMetric _selected = _HealthMetric.heartRate;

  @override
  Widget build(BuildContext context) {
    final isHeartRate = _selected == _HealthMetric.heartRate;
    final points = isHeartRate ? widget.heartRatePoints : widget.spo2Points;
    final color = isHeartRate ? AppColors.danger : AppColors.blue;
    final unit = isHeartRate ? 'BPM' : '%';
    final latest = points.isEmpty ? null : points.last.value;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(23),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: AppColors.warning,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diễn biến sức khỏe',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '20 lần đo gần nhất',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: AppColors.success, size: 7),
                    SizedBox(width: 5),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MetricToggle(
                label: 'Nhịp tim',
                icon: Icons.favorite_rounded,
                color: AppColors.danger,
                selected: isHeartRate,
                onTap: () =>
                    setState(() => _selected = _HealthMetric.heartRate),
              ),
              const SizedBox(width: 8),
              _MetricToggle(
                label: 'SpO₂',
                icon: Icons.water_drop_rounded,
                color: AppColors.blue,
                selected: !isHeartRate,
                onTap: () => setState(() => _selected = _HealthMetric.oxygen),
              ),
              const Spacer(),
              Text(
                latest == null
                    ? '-- $unit'
                    : '${latest.toStringAsFixed(0)} $unit',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          SizedBox(
            height: 148,
            child: _TrendPlot(
              points: points,
              color: color,
              minValue: isHeartRate ? 50 : 90,
              maxValue: isHeartRate ? 120 : 100,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricToggle extends StatelessWidget {
  const _MetricToggle({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.11) : AppColors.background,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? color : AppColors.muted, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendPlot extends StatelessWidget {
  const _TrendPlot({
    required this.points,
    required this.color,
    required this.minValue,
    required this.maxValue,
  });

  final List<MetricPoint> points;
  final Color color;
  final double minValue;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final values = points.map((point) => point.value).toList();
    final dataMin = values.isEmpty
        ? minValue
        : values.reduce((a, b) => math.min(a, b).toDouble());
    final dataMax = values.isEmpty
        ? maxValue
        : values.reduce((a, b) => math.max(a, b).toDouble());
    final spread = math.max(dataMax - dataMin, 4).toDouble();
    final chartMin = math.min(minValue, dataMin - spread * 0.2).toDouble();
    final chartMax = math.max(maxValue, dataMax + spread * 0.2).toDouble();
    final interval = math.max((chartMax - chartMin) / 3, 1).toDouble();
    final maxX = math.max(points.length - 1, 4).toDouble();

    return Stack(
      alignment: Alignment.center,
      children: [
        LineChart(
          LineChartData(
            minX: 0,
            maxX: maxX,
            minY: chartMin,
            maxY: chartMax,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.outline.withValues(alpha: 0.9),
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
                  reservedSize: 31,
                  interval: interval,
                  getTitlesWidget: (value, meta) {
                    final nearEdge =
                        value <= chartMin + interval * 0.25 ||
                        value >= chartMax - interval * 0.25;
                    if (nearEdge) return const SizedBox.shrink();
                    return Text(
                      value.round().toString(),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: points.length > 1,
                  reservedSize: 22,
                  interval: math.max(points.length / 3, 1).toDouble(),
                  getTitlesWidget: (value, meta) {
                    final index = value.round();
                    if (index < 0 || index >= points.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat('HH:mm').format(points[index].time),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 8,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: points.isEmpty
                ? const []
                : [
                    LineChartBarData(
                      spots: [
                        for (var index = 0; index < points.length; index++)
                          FlSpot(index.toDouble(), points[index].value),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.24,
                      color: color,
                      barWidth: 2.8,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: points.length == 1),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
          ),
          duration: const Duration(milliseconds: 240),
        ),
        if (points.isEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _EmptyTrendGridPainter()),
            ),
          ),
        if (points.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors_rounded, color: AppColors.muted, size: 15),
                SizedBox(width: 6),
                Text(
                  'Đang chờ số đo hợp lệ',
                  style: TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyTrendGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const left = 35.0;
    const top = 7.0;
    const rightInset = 7.0;
    const bottomInset = 22.0;
    final right = size.width - rightInset;
    final bottom = size.height - bottomInset;
    final paint = Paint()
      ..color = const Color(0xFFE2E8EF)
      ..strokeWidth = 1;

    for (var row = 0; row <= 4; row++) {
      final y = top + (bottom - top) * row / 4;
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
    }
    for (var column = 0; column <= 4; column++) {
      final x = left + (right - left) * column / 4;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
