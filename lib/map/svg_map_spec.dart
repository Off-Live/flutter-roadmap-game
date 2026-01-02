import 'dart:ui';

class SvgMapSpec {
  final int version;
  final Size designSize;
  final Background background;
  final SvgRoad road;
  final List<SvgNode> nodes;
  final Character character;
  final PaintStyles paint;

  SvgMapSpec({
    required this.version,
    required this.designSize,
    required this.background,
    required this.road,
    required this.nodes,
    required this.character,
    required this.paint,
  });

  factory SvgMapSpec.fromJson(Map<String, dynamic> json) {
    return SvgMapSpec(
      version: json['version'],
      designSize: Size(
        json['designSize']['w'].toDouble(),
        json['designSize']['h'].toDouble(),
      ),
      background: Background.fromJson(json['background']),
      road: SvgRoad.fromJson(json['road']),
      nodes: (json['nodes'] as List)
          .map((nodeJson) => SvgNode.fromJson(nodeJson))
          .toList(),
      character: Character.fromJson(json['character']),
      paint: PaintStyles.fromJson(json['paint']),
    );
  }
}

class SvgRoad {
  final String svgPath;
  final double strokeWidth;

  SvgRoad({
    required this.svgPath,
    required this.strokeWidth,
  });

  factory SvgRoad.fromJson(Map<String, dynamic> json) {
    return SvgRoad(
      svgPath: json['svgPath'],
      strokeWidth: json['strokeWidth'].toDouble(),
    );
  }
}

class SvgNode {
  final int id;
  final double position; // 0.0 to 1.0 (percentage along path)
  final double tapRadius;
  final NodeAssets assets;

  SvgNode({
    required this.id,
    required this.position,
    required this.tapRadius,
    required this.assets,
  });

  factory SvgNode.fromJson(Map<String, dynamic> json) {
    return SvgNode(
      id: json['id'],
      position: json['position'].toDouble(),
      tapRadius: json['tapRadius'].toDouble(),
      assets: NodeAssets.fromJson(json['assets']),
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

class PaintStyles {
  final DirtStyle? dirt;
  final RainbowStyle rainbow;

  PaintStyles({
    this.dirt,
    required this.rainbow,
  });

  factory PaintStyles.fromJson(Map<String, dynamic> json) {
    return PaintStyles(
      dirt: json['dirt'] != null ? DirtStyle.fromJson(json['dirt']) : null,
      rainbow: RainbowStyle.fromJson(json['rainbow']),
    );
  }
}

class DirtStyle {
  final double strokeWidth;
  final Color color;
  final Shadow? shadow;

  DirtStyle({
    required this.strokeWidth,
    required this.color,
    this.shadow,
  });

  factory DirtStyle.fromJson(Map<String, dynamic> json) {
    return DirtStyle(
      strokeWidth: json['strokeWidth'].toDouble(),
      color: Color(int.parse(json['color'].substring(1), radix: 16) + 0xFF000000),
      shadow: json['shadow'] != null ? Shadow.fromJson(json['shadow']) : null,
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
          .map((colorStr) => Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000))
          .toList(),
      glow: json['glow'] != null ? Glow.fromJson(json['glow']) : null,
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