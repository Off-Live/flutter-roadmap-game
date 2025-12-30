import 'package:flutter/material.dart';
import 'map_spec.dart';
import 'map_controller.dart';

class CharacterLayer extends StatelessWidget {
  final MapController controller;
  final double scale;
  final Offset offset;

  const CharacterLayer({
    super.key,
    required this.controller,
    required this.scale,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    final mapSpec = controller.mapSpec;
    if (mapSpec == null) return const SizedBox();

    final characterPos = controller.characterPosition;
    final character = mapSpec.character;
    
    // Calculate the actual position considering the anchor point
    final scaledSize = Size(
      character.size.width * scale,
      character.size.height * scale,
    );
    
    final anchoredPosition = Offset(
      (characterPos.dx * scale) - (scaledSize.width * character.anchor.dx) + offset.dx,
      (characterPos.dy * scale) - (scaledSize.height * character.anchor.dy) + offset.dy,
    );

    return Positioned(
      left: anchoredPosition.dx,
      top: anchoredPosition.dy,
      child: _CharacterWidget(
        character: character,
        size: scaledSize,
      ),
    );
  }
}

class _CharacterWidget extends StatelessWidget {
  final Character character;
  final Size size;

  const _CharacterWidget({
    required this.character,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Image.asset(
        character.asset,
        width: size.width,
        height: size.height,
        fit: BoxFit.contain,
      ),
    );
  }
}