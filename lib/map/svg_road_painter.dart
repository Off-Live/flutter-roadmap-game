import 'dart:ui';
import 'package:flutter/material.dart';
import 'svg_map_spec.dart';
import 'svg_map_controller.dart';

class SvgRoadPainter extends CustomPainter {
  final SvgMapSpec mapSpec;
  final SvgMapController controller;
  final double scale;
  final Offset offset;

  SvgRoadPainter({
    required this.mapSpec,
    required this.controller,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final roadPath = controller.roadPath;
    if (roadPath == null) {
      print('Road path is null');
      return;
    }

    // Only paint completed section (rainbow trail)
    final completedPath = controller.getCompletedPath();
    print('Completed path is null: ${completedPath == null}');
    print('Current stage ID: ${controller.currentStageId}');
    print('Is moving: ${controller.isMoving}');
    
    if (completedPath != null) {
      print('Drawing rainbow trail for completed path');
      _paintRainbowRoad(canvas, completedPath, mapSpec.paint.rainbow);
    }

    canvas.restore();
  }

  void _paintDirtRoad(Canvas canvas, Path path, DirtStyle style) {
    final paint = Paint()
      ..color = style.color
      ..strokeWidth = style.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Add shadow if specified
    if (style.shadow != null) {
      final shadowPaint = Paint()
        ..color = style.shadow!.color
        ..strokeWidth = style.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.shadow!.blur);

      canvas.save();
      canvas.translate(style.shadow!.dx, style.shadow!.dy);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
    }

    canvas.drawPath(path, paint);
  }

  void _paintRainbowRoad(Canvas canvas, Path path, RainbowStyle style) {
    final pathBounds = path.getBounds();
    if (pathBounds.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = style.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Create linear gradient along the path length for better rainbow effect
    paint.shader = LinearGradient(
      colors: style.colors,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(pathBounds);

    // Add stronger glow effect for rainbow trail
    if (style.glow?.enabled == true) {
      final glowPaint = Paint()
        ..strokeWidth = style.strokeWidth + 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = style.glow!.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.glow!.blur);
      
      canvas.drawPath(path, glowPaint);
      
      // Add inner glow
      final innerGlowPaint = Paint()
        ..strokeWidth = style.strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = paint.shader
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.glow!.blur * 0.3);
      
      canvas.drawPath(path, innerGlowPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SvgRoadPainter oldDelegate) {
    return oldDelegate.controller.currentStageId != controller.currentStageId ||
           oldDelegate.controller.characterPosition != controller.characterPosition ||
           oldDelegate.controller.isMoving != controller.isMoving ||
           oldDelegate.scale != scale ||
           oldDelegate.offset != offset;
  }
}