import 'package:flutter/material.dart';
import 'svg_map_spec.dart';
import 'svg_map_controller.dart';

class SvgFingerPointer extends StatefulWidget {
  final SvgMapController controller;
  final double scale;
  final Offset offset;

  const SvgFingerPointer({
    super.key,
    required this.controller,
    required this.scale,
    required this.offset,
  });

  @override
  State<SvgFingerPointer> createState() => _SvgFingerPointerState();
}

class _SvgFingerPointerState extends State<SvgFingerPointer>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: -15.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimation() {
    if (!_bounceController.isAnimating) {
      _bounceController.repeat(reverse: true);
    }
  }

  void _stopAnimation() {
    if (_bounceController.isAnimating) {
      _bounceController.stop();
      _bounceController.reset();
    }
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
        if (mapSpec == null || widget.controller.roadPathMetric == null) {
          _stopAnimation();
          return const SizedBox();
        }

        // Don't show finger when character is moving
        if (widget.controller.isMoving) {
          _stopAnimation();
          return const SizedBox();
        }

        // Find the next node (orange node)
        final currentStageId = widget.controller.currentStageId;
        final nextNode = mapSpec.nodes.cast<SvgNode?>().firstWhere(
          (node) => node?.id == currentStageId,
          orElse: () => null,
        );

        if (nextNode == null) {
          _stopAnimation();
          return const SizedBox();
        }

        // Start animation only when finger should be visible
        _startAnimation();

        // Get node position from path
        final roadPathMetric = widget.controller.roadPathMetric!;
        final distance = roadPathMetric.length * nextNode.position;
        final tangent = roadPathMetric.getTangentForOffset(distance);
        
        if (tangent == null) {
          _stopAnimation();
          return const SizedBox();
        }

        // Calculate finger position (bottom-right of the node)
        final nodePos = Offset(
          tangent.position.dx * widget.scale + widget.offset.dx,
          tangent.position.dy * widget.scale + widget.offset.dy,
        );

        // Position finger at bottom-right of node
        final fingerPos = Offset(
          nodePos.dx + (6 * widget.scale),
          nodePos.dy + (6 * widget.scale),
        );

        return AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Positioned(
              left: fingerPos.dx,
              top: fingerPos.dy + _bounceAnimation.value,
              child: SizedBox(
                width: 120,
                height: 120,
                child: Transform.scale(
                  scale: widget.scale * 0.8,
                  child: Image.asset(
                    'assets/image/finger.png',
                    fit: BoxFit.contain,
                    cacheWidth: 120,
                    cacheHeight: 120,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}