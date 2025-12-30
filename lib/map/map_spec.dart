import 'dart:ui';

class MapSpec {
  final int version;
  final Size designSize;
  final Background background;
  final List<Node> nodes;
  final Road road;
  final Character character;
  final PaintStyles paint;

  MapSpec({
    required this.version,
    required this.designSize,
    required this.background,
    required this.nodes,
    required this.road,
    required this.character,
    required this.paint,
  });

  factory MapSpec.fromJson(Map<String, dynamic> json) {
    return MapSpec(
      version: json['version'],
      designSize: Size(
        json['designSize']['w'].toDouble(),
        json['designSize']['h'].toDouble(),
      ),
      background: Background.fromJson(json['background']),
      nodes: (json['nodes'] as List)
          .map((node) => Node.fromJson(node))
          .toList(),
      road: Road.fromJson(json['road']),
      character: Character.fromJson(json['character']),
      paint: PaintStyles.fromJson(json['paint']),
    );
  }
}

class Background {
  final String asset;

  Background({required this.asset});

  factory Background.fromJson(Map<String, dynamic> json) {
    return Background(asset: json['asset']);
  }
}

class Node {
  final int id;
  final Offset pos;
  final double tapRadius;
  final NodeAssets assets;

  Node({
    required this.id,
    required this.pos,
    required this.tapRadius,
    required this.assets,
  });

  factory Node.fromJson(Map<String, dynamic> json) {
    return Node(
      id: json['id'],
      pos: Offset(
        json['pos']['x'].toDouble(),
        json['pos']['y'].toDouble(),
      ),
      tapRadius: json['tapRadius'].toDouble(),
      assets: NodeAssets.fromJson(json['assets']),
    );
  }
}

class NodeAssets {
  final String locked;
  final String next;
  final String done;

  NodeAssets({
    required this.locked,
    required this.next,
    required this.done,
  });

  factory NodeAssets.fromJson(Map<String, dynamic> json) {
    return NodeAssets(
      locked: json['locked'],
      next: json['next'],
      done: json['done'],
    );
  }
}

class Road {
  final String mode;
  final List<RoadSegment> segments;

  Road({
    required this.mode,
    required this.segments,
  });

  factory Road.fromJson(Map<String, dynamic> json) {
    return Road(
      mode: json['mode'],
      segments: (json['segments'] as List)
          .map((segment) => RoadSegment.fromJson(segment))
          .toList(),
    );
  }
}

class RoadSegment {
  final int fromId;
  final int toId;
  final List<Offset>? points;
  final List<CubicBezier>? beziers;
  final SegmentStyle style;

  RoadSegment({
    required this.fromId,
    required this.toId,
    this.points,
    this.beziers,
    required this.style,
  });

  factory RoadSegment.fromJson(Map<String, dynamic> json) {
    List<Offset>? points;
    List<CubicBezier>? beziers;

    if (json.containsKey('points')) {
      points = (json['points'] as List)
          .map((point) => Offset(
                point['x'].toDouble(),
                point['y'].toDouble(),
              ))
          .toList();
    }

    if (json.containsKey('beziers')) {
      beziers = (json['beziers'] as List)
          .map((bezier) => CubicBezier.fromJson(bezier))
          .toList();
    }

    return RoadSegment(
      fromId: json['fromId'],
      toId: json['toId'],
      points: points,
      beziers: beziers,
      style: SegmentStyle.fromJson(json['style']),
    );
  }
}

class CubicBezier {
  final Offset p0;
  final Offset c1;
  final Offset c2;
  final Offset p3;

  CubicBezier({
    required this.p0,
    required this.c1,
    required this.c2,
    required this.p3,
  });

  factory CubicBezier.fromJson(Map<String, dynamic> json) {
    return CubicBezier(
      p0: Offset(json['p0']['x'].toDouble(), json['p0']['y'].toDouble()),
      c1: Offset(json['c1']['x'].toDouble(), json['c1']['y'].toDouble()),
      c2: Offset(json['c2']['x'].toDouble(), json['c2']['y'].toDouble()),
      p3: Offset(json['p3']['x'].toDouble(), json['p3']['y'].toDouble()),
    );
  }
}

class SegmentStyle {
  final String base;
  final String completed;

  SegmentStyle({
    required this.base,
    required this.completed,
  });

  factory SegmentStyle.fromJson(Map<String, dynamic> json) {
    return SegmentStyle(
      base: json['base'],
      completed: json['completed'],
    );
  }
}

class Character {
  final String asset;
  final Size size;
  final Offset anchor;

  Character({
    required this.asset,
    required this.size,
    required this.anchor,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      asset: json['asset'],
      size: Size(
        json['size']['w'].toDouble(),
        json['size']['h'].toDouble(),
      ),
      anchor: Offset(
        json['anchor']['x'].toDouble(),
        json['anchor']['y'].toDouble(),
      ),
    );
  }
}

class PaintStyles {
  final DirtStyle dirt;
  final RainbowStyle rainbow;

  PaintStyles({
    required this.dirt,
    required this.rainbow,
  });

  factory PaintStyles.fromJson(Map<String, dynamic> json) {
    return PaintStyles(
      dirt: DirtStyle.fromJson(json['dirt']),
      rainbow: RainbowStyle.fromJson(json['rainbow']),
    );
  }
}

class DirtStyle {
  final double strokeWidth;
  final Color color;
  final Shadow? shadow;
  final DashPattern? dash;
  final Footprints? footprints;

  DirtStyle({
    required this.strokeWidth,
    required this.color,
    this.shadow,
    this.dash,
    this.footprints,
  });

  factory DirtStyle.fromJson(Map<String, dynamic> json) {
    return DirtStyle(
      strokeWidth: json['strokeWidth'].toDouble(),
      color: Color(int.parse(json['color'].substring(1), radix: 16) | 0xFF000000),
      shadow: json.containsKey('shadow') ? Shadow.fromJson(json['shadow']) : null,
      dash: json.containsKey('dash') ? DashPattern.fromJson(json['dash']) : null,
      footprints: json.containsKey('footprints') 
          ? Footprints.fromJson(json['footprints']) 
          : null,
    );
  }
}

class Shadow {
  final double blur;
  final double dx;
  final double dy;
  final Color color;

  Shadow({
    required this.blur,
    required this.dx,
    required this.dy,
    required this.color,
  });

  factory Shadow.fromJson(Map<String, dynamic> json) {
    return Shadow(
      blur: json['blur'].toDouble(),
      dx: json['dx'].toDouble(),
      dy: json['dy'].toDouble(),
      color: Color(int.parse(json['color'].substring(1), radix: 16)),
    );
  }
}

class DashPattern {
  final bool enabled;
  final List<double> pattern;

  DashPattern({
    required this.enabled,
    required this.pattern,
  });

  factory DashPattern.fromJson(Map<String, dynamic> json) {
    return DashPattern(
      enabled: json['enabled'],
      pattern: (json['pattern'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}

class Footprints {
  final bool enabled;
  final double spacing;
  final String asset;

  Footprints({
    required this.enabled,
    required this.spacing,
    required this.asset,
  });

  factory Footprints.fromJson(Map<String, dynamic> json) {
    return Footprints(
      enabled: json['enabled'],
      spacing: json['spacing'].toDouble(),
      asset: json['asset'],
    );
  }
}

class RainbowStyle {
  final double strokeWidth;
  final List<Color> colors;
  final Glow? glow;

  RainbowStyle({
    required this.strokeWidth,
    required this.colors,
    this.glow,
  });

  factory RainbowStyle.fromJson(Map<String, dynamic> json) {
    return RainbowStyle(
      strokeWidth: json['strokeWidth'].toDouble(),
      colors: (json['colors'] as List)
          .map((colorStr) => Color(
                int.parse(colorStr.toString().substring(1), radix: 16) | 0xFF000000,
              ))
          .toList(),
      glow: json.containsKey('glow') ? Glow.fromJson(json['glow']) : null,
    );
  }
}

class Glow {
  final bool enabled;
  final double blur;
  final Color color;

  Glow({
    required this.enabled,
    required this.blur,
    required this.color,
  });

  factory Glow.fromJson(Map<String, dynamic> json) {
    return Glow(
      enabled: json['enabled'],
      blur: json['blur'].toDouble(),
      color: Color(int.parse(json['color'].substring(1), radix: 16)),
    );
  }
}