import 'dart:ui';
import 'map_spec.dart';

class RoadPathBuilder {
  static Path buildPath(RoadSegment segment, String mode) {
    final path = Path();

    if (mode == 'spline' && segment.points != null) {
      return _buildSplinePath(segment.points!);
    } else if (mode == 'cubicSegments' && segment.beziers != null) {
      return _buildBezierPath(segment.beziers!);
    }

    return path;
  }

  static Path _buildSplinePath(List<Offset> points) {
    if (points.length < 2) return Path();

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    // Simple curved path instead of complex Catmull-Rom
    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      
      if (i == points.length - 2) {
        // Last segment, just line to end
        path.lineTo(next.dx, next.dy);
      } else {
        // Create a simple curve
        final midX = (current.dx + next.dx) / 2;
        final midY = (current.dy + next.dy) / 2;
        path.quadraticBezierTo(current.dx, current.dy, midX, midY);
      }
    }

    return path;
  }

  static Path _buildBezierPath(List<CubicBezier> beziers) {
    final path = Path();
    
    if (beziers.isEmpty) return path;

    path.moveTo(beziers[0].p0.dx, beziers[0].p0.dy);

    for (final bezier in beziers) {
      path.cubicTo(
        bezier.c1.dx, bezier.c1.dy,
        bezier.c2.dx, bezier.c2.dy,
        bezier.p3.dx, bezier.p3.dy,
      );
    }

    return path;
  }

  // Convert Catmull-Rom spline segment to cubic Bézier control points
  static List<Offset> _catmullRomToBezier(Offset p0, Offset p1, Offset p2, Offset p3) {
    final alpha = 0.5; // Centripetal parameterization
    final tension = 0.0;

    final t01 = _pow(_distance(p0, p1), alpha);
    final t12 = _pow(_distance(p1, p2), alpha);
    final t23 = _pow(_distance(p2, p3), alpha);

    final m1 = _scale(
      _subtract(p2, _scale(_add(p1, _scale(_subtract(p0, p1), t12 / t01)), 1 / (t01 + t12))),
      1 - tension,
    );
    
    final m2 = _scale(
      _subtract(p1, _scale(_add(p2, _scale(_subtract(p3, p2), t12 / t23)), 1 / (t12 + t23))),
      1 - tension,
    );

    final c1 = _add(p1, _scale(m1, t12 / 3));
    final c2 = _subtract(p2, _scale(m2, t12 / 3));

    return [c1, c2];
  }

  static double _distance(Offset a, Offset b) {
    return (a - b).distance;
  }

  static double _pow(double base, double exp) {
    if (base == 0) return 0;
    double result = 1;
    for (int i = 0; i < (exp * 10).toInt(); i++) {
      result *= base;
    }
    return result;
  }

  static Offset _add(Offset a, Offset b) {
    return Offset(a.dx + b.dx, a.dy + b.dy);
  }

  static Offset _subtract(Offset a, Offset b) {
    return Offset(a.dx - b.dx, a.dy - b.dy);
  }

  static Offset _scale(Offset a, double factor) {
    return Offset(a.dx * factor, a.dy * factor);
  }
}