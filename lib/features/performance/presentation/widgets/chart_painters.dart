import 'dart:math' as math;

import 'package:flutter/material.dart';

class ChartLine {
  const ChartLine({required this.values, required this.color});

  final List<double> values;
  final Color color;
}

// ─────────────────────────────────────────────────────────────────
//  Multi-line chart
// ─────────────────────────────────────────────────────────────────

class MultiLineChart extends StatelessWidget {
  const MultiLineChart({
    super.key,
    required this.lines,
    required this.height,
    this.percentMode = true,
  });

  final List<ChartLine> lines;
  final double height;
  final bool percentMode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _MultiLineChartPainter(lines: lines, percentMode: percentMode)),
    );
  }
}

class _MultiLineChartPainter extends CustomPainter {
  const _MultiLineChartPainter({required this.lines, required this.percentMode});

  final List<ChartLine> lines;
  final bool percentMode;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      canvas.drawLine(Offset(0, size.height * i / 4), Offset(size.width, size.height * i / 4), gridPaint);
    }

    final allValues = lines.expand((l) => l.values.isEmpty ? const <double>[0] : l.values).toList();
    final maxValue = allValues.isEmpty ? 1.0 : allValues.reduce(math.max);
    final safeMaxValue = percentMode ? 100.0 : (maxValue <= 0 ? 1.0 : maxValue);

    for (final line in lines) {
      final source = line.values.isEmpty ? const <double>[0] : line.values;
      final path = Path();
      for (var i = 0; i < source.length; i++) {
        final x = source.length == 1 ? size.width / 2 : size.width * i / (source.length - 1);
        final normalized = percentMode ? source[i].clamp(0, 100) / safeMaxValue : source[i] / safeMaxValue;
        final y = size.height - (normalized * (size.height - 8)) - 4;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = line.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MultiLineChartPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────
//  Mini line chart
// ─────────────────────────────────────────────────────────────────

class MiniLineChart extends StatelessWidget {
  const MiniLineChart({
    super.key,
    required this.values,
    required this.color,
    required this.height,
    this.fill = false,
  });

  final List<double> values;
  final Color color;
  final double height;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _MiniLineChartPainter(values: values, color: color, fill: fill)),
    );
  }
}

class _MiniLineChartPainter extends CustomPainter {
  const _MiniLineChartPainter({required this.values, required this.color, required this.fill});

  final List<double> values;
  final Color color;
  final bool fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      Paint()..color = color.withValues(alpha: 0.05)..style = PaintingStyle.fill,
    );

    final gridPaint = Paint()..color = color.withValues(alpha: 0.08)..strokeWidth = 1;
    for (var i = 1; i <= 2; i++) {
      canvas.drawLine(Offset(0, size.height * i / 3), Offset(size.width, size.height * i / 3), gridPaint);
    }

    final source = values.isEmpty ? const <double>[0] : values;
    final minValue = source.reduce(math.min);
    final maxValue = source.reduce(math.max);
    final range = (maxValue - minValue).abs() < 0.001 ? 1.0 : (maxValue - minValue);

    final path = Path();
    for (var i = 0; i < source.length; i++) {
      final x = source.length == 1 ? size.width / 2 : size.width * i / (source.length - 1);
      final y = size.height - ((source[i] - minValue) / range * (size.height - 10)) - 5;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(fillPath, Paint()..color = color.withValues(alpha: 0.14)..style = PaintingStyle.fill);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniLineChartPainter old) =>
      old.values != values || old.color != color || old.fill != fill;
}
