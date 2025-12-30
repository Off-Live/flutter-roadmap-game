import 'package:flutter/material.dart';
import 'map_spec.dart';
import 'map_controller.dart';

class FingerPointer extends StatefulWidget {
  final MapController controller;
  final double scale;
  final Offset offset;

  const FingerPointer({
    super.key,
    required this.controller,
    required this.scale,
    required this.offset,
  });

  @override
  State<FingerPointer> createState() => _FingerPointerState();
}

class _FingerPointerState extends State<FingerPointer>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: -15.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));

    // Start bouncing animation
    _bounceController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final mapSpec = widget.controller.mapSpec;
        if (mapSpec == null) return const SizedBox();

        // Don't show finger when character is moving
        if (widget.controller.isMoving) return const SizedBox();

        // Find the next node (orange node)
        final currentStageId = widget.controller.currentStageId;
        final nextNode = mapSpec.nodes.cast<Node?>().firstWhere(
          (node) => node?.id == currentStageId,
          orElse: () => null,
        );

        if (nextNode == null) return const SizedBox();

        // Calculate finger position (bottom-right of the node)
        final nodePos = Offset(
          nextNode.pos.dx * widget.scale + widget.offset.dx,
          nextNode.pos.dy * widget.scale + widget.offset.dy,
        );

        // Position finger at bottom-right of node
        final fingerPos = Offset(
          nodePos.dx + (6 * widget.scale), // Node radius + some offset
          nodePos.dy + (6 * widget.scale),
        );

        return AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Positioned(
              left: fingerPos.dx,
              top: fingerPos.dy + _bounceAnimation.value,
              child: Transform.scale(
                scale: widget.scale * 0.95, // Scale with map but slightly smaller
                child: Image.asset(
                  'assets/image/finger.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        );
      },
    );
  }
}