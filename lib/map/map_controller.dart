import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'map_spec.dart';
import 'road_path_builder.dart';
import '../character_layer.dart';

class MapController extends ChangeNotifier implements CharacterController {
  MapSpec? _mapSpec;
  int _currentStageId = 1; // Next stage to unlock (starts at 1, so 0 is already done)
  bool _isMoving = false;
  Offset _characterPosition = Offset.zero;
  
  MapSpec? get mapSpec => _mapSpec;
  int get currentStageId => _currentStageId;
  bool get isMoving => _isMoving;
  Offset get characterPosition => _characterPosition;

  void loadMapSpec(MapSpec spec) {
    _mapSpec = spec;
    _currentStageId = 1; // Next stage to unlock (character starts at 0, can move to 1)
    if (spec.nodes.isNotEmpty) {
      _characterPosition = spec.nodes.first.pos; // Start at node 0
    }
    notifyListeners();
  }

  bool canTapNode(int nodeId) {
    return nodeId == _currentStageId && !_isMoving;
  }

  NodeState getNodeState(int nodeId) {
    if (nodeId < _currentStageId) {
      return NodeState.done;
    } else if (nodeId == _currentStageId) {
      return NodeState.next;
    } else {
      return NodeState.locked;
    }
  }

  Future<void> moveToNode(int nodeId, TickerProvider tickerProvider) async {
    if (!canTapNode(nodeId) || _mapSpec == null) return;

    _isMoving = true;
    notifyListeners();

    final fromNode = _mapSpec!.nodes.firstWhere((node) => node.id == nodeId - 1);
    final toNode = _mapSpec!.nodes.firstWhere((node) => node.id == nodeId);
    
    final segment = _mapSpec!.road.segments.firstWhere(
      (seg) => seg.fromId == fromNode.id && seg.toId == toNode.id,
      orElse: () => _mapSpec!.road.segments.first,
    );

    final path = RoadPathBuilder.buildPath(segment, _mapSpec!.road.mode);
    if (path.computeMetrics().isEmpty) {
      _isMoving = false;
      notifyListeners();
      return;
    }
    
    final pathMetric = path.computeMetrics().first;

    final animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: tickerProvider,
    );

    final animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    );

    // Throttle notifications to reduce CPU usage
    DateTime? lastNotification;
    animation.addListener(() {
      final now = DateTime.now();
      if (lastNotification == null || now.difference(lastNotification!).inMilliseconds > 16) { // ~60fps max
        final distance = pathMetric.length * animation.value;
        final tangent = pathMetric.getTangentForOffset(distance);
        if (tangent != null) {
          _characterPosition = tangent.position;
          notifyListeners();
          lastNotification = now;
        }
      }
    });

    await animationController.forward();
    
    _currentStageId++;
    _isMoving = false;
    animationController.dispose();
    notifyListeners();
  }

  void skipToNode(int nodeId) {
    if (_mapSpec == null) return;
    
    final targetNode = _mapSpec!.nodes.cast<Node?>().firstWhere(
      (node) => node?.id == nodeId,
      orElse: () => null,
    );
    
    if (targetNode != null) {
      _currentStageId = nodeId + 1; // Set to next stage after target
      _characterPosition = targetNode.pos;
      notifyListeners();
    }
  }
}

enum NodeState {
  locked,
  next,
  done,
}