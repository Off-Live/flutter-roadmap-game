import 'dart:ui';
import 'package:flutter/material.dart';
import 'map_spec.dart';
import 'road_path_builder.dart';

class RoadPainter extends CustomPainter {
  final MapSpec mapSpec;
  final int currentStageId;
  final double scale;
  final Offset offset;
  
  // Cache for paint objects to avoid recreating them
  static final Map<String, Paint> _paintCache = {};

  RoadPainter({
    required this.mapSpec,
    required this.currentStageId,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // Build completed segments as one continuous path for global rainbow
    final completedSegments = mapSpec.road.segments
        .where((segment) => segment.toId < currentStageId)
        .toList();
    
    if (completedSegments.isNotEmpty) {
      _paintGlobalRainbowRoad(canvas, completedSegments, mapSpec.paint.rainbow);
    }

    // Paint remaining segments as dirt roads
    for (final segment in mapSpec.road.segments) {
      final isCompleted = segment.toId < currentStageId;
      if (!isCompleted) {
        final path = RoadPathBuilder.buildPath(segment, mapSpec.road.mode);
        if (!path.getBounds().isEmpty) {
          _paintDirtRoad(canvas, path, mapSpec.paint.dirt);
        }
      }
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

  void _paintGlobalRainbowRoad(Canvas canvas, List<RoadSegment> segments, RainbowStyle style) {
    // Paint each segment individually with perpendicular rainbow gradient
    for (final segment in segments) {
      final segmentPath = RoadPathBuilder.buildPath(segment, mapSpec.road.mode);
      if (segmentPath.getBounds().isEmpty) continue;
      
      _paintRainbowSegment(canvas, segmentPath, style);
    }
  }

  void _paintRainbowSegment(Canvas canvas, Path path, RainbowStyle style) {
    final pathBounds = path.getBounds();
    if (pathBounds.isEmpty) return;
    
    // Use cached paint object
    final cacheKey = 'rainbow_${style.strokeWidth}_${style.colors.length}';
    Paint paint = _paintCache[cacheKey] ??= Paint()
      ..strokeWidth = style.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Only create shader when bounds change significantly
    paint.shader = LinearGradient(
      colors: style.colors,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(pathBounds);

    canvas.drawPath(path, paint);

    // Simplified glow - only if absolutely necessary
    if (style.glow?.enabled == true) {
      final glowCacheKey = 'rainbow_glow_${style.strokeWidth}_${style.glow!.blur}';
      Paint glowPaint = _paintCache[glowCacheKey] ??= Paint()
        ..strokeWidth = style.strokeWidth + 4  // Reduced glow thickness
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.glow!.blur * 0.5); // Reduced blur
      
      glowPaint.shader = paint.shader;
      canvas.drawPath(path, glowPaint);
    }
  }

  Path _extractPathSegment(PathMetric pathMetric, double start, double end) {
    return pathMetric.extractPath(start, end);
  }

  @override
  bool shouldRepaint(covariant RoadPainter oldDelegate) {
    return oldDelegate.currentStageId != currentStageId ||
           oldDelegate.scale != scale ||
           oldDelegate.offset != offset;
  }
}