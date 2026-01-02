import 'package:flutter/material.dart';
import 'svg_map_spec.dart';
import 'svg_map_controller.dart';

class SvgNodesLayer extends StatelessWidget {
  final SvgMapController controller;
  final double scale;
  final Offset offset;
  final Function(int nodeId) onNodeTap;

  const SvgNodesLayer({
    super.key,
    required this.controller,
    required this.scale,
    required this.offset,
    required this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    final mapSpec = controller.mapSpec;
    if (mapSpec == null || controller.roadPathMetric == null) return const SizedBox();

    return Stack(
      children: mapSpec.nodes.map((node) {
        return _SvgNodeWidget(
          node: node,
          controller: controller,
          scale: scale,
          offset: offset,
          onTap: () => onNodeTap(node.id),
        );
      }).toList(),
    );
  }
}

class _SvgNodeWidget extends StatelessWidget {
  final SvgNode node;
  final SvgMapController controller;
  final double scale;
  final Offset offset;
  final VoidCallback onTap;

  const _SvgNodeWidget({
    required this.node,
    required this.controller,
    required this.scale,
    required this.offset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nodeState = controller.getNodeState(node.id);
    final canTap = controller.canTapNode(node.id);
    
    // Get node position from path
    final roadPathMetric = controller.roadPathMetric!;
    final distance = roadPathMetric.length * node.position;
    final tangent = roadPathMetric.getTangentForOffset(distance);
    
    if (tangent == null) return const SizedBox();
    
    // Apply same transform as road painter: translate offset, then scale
    // Canvas does: translate(offset) then scale(scale)
    // Matrix math: final_pos = (original_pos + offset) * scale
    // But widgets need the final screen position, so we calculate: 
    // screen_pos = (original_pos * scale) + (offset * scale)
    final scaledPosition = Offset(
      tangent.position.dx * scale + offset.dx,
      tangent.position.dy * scale + offset.dy,
    );


    return Positioned(
      left: scaledPosition.dx - (node.tapRadius * scale),
      top: scaledPosition.dy - (node.tapRadius * scale),
      child: GestureDetector(
        onTap: canTap ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: node.tapRadius * 2 * scale,
          height: node.tapRadius * 2 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: canTap ? Colors.blue.withOpacity(0.3) : Colors.transparent,
          ),
          child: Center(
            child: _SvgNodeImage(
              node: node,
              nodeState: nodeState,
              scale: scale,
            ),
          ),
        ),
      ),
    );
  }
}

class _SvgNodeImage extends StatelessWidget {
  final SvgNode node;
  final NodeState nodeState;
  final double scale;

  const _SvgNodeImage({
    required this.node,
    required this.nodeState,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show node 0
    if (node.id == 0) {
      return const SizedBox();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 96 * scale,
      height: 96 * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getNodeColor(nodeState),
        border: Border.all(
          color: nodeState == NodeState.next ? Colors.yellow : Colors.white,
          width: nodeState == NodeState.next ? 4 * scale : 3 * scale,
        ),
        boxShadow: nodeState == NodeState.next ? [
          BoxShadow(
            color: Colors.orange.withOpacity(0.6),
            blurRadius: 8 * scale,
            spreadRadius: 2 * scale,
          ),
        ] : null,
      ),
      child: Center(
        child: Text(
          nodeState == NodeState.locked ? '?' : (nodeState == NodeState.next ? 'GO' : '${node.id}'),
          style: TextStyle(
            color: Colors.white,
            fontSize: nodeState == NodeState.next ? 32 * scale : 36 * scale,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Color _getNodeColor(NodeState state) {
    switch (state) {
      case NodeState.locked:
        return Colors.grey.shade600;
      case NodeState.next:
        return Colors.orange.shade600;
      case NodeState.done:
        return Colors.green.shade600;
    }
  }
}