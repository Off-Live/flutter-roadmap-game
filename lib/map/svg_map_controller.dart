import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:path_drawing/path_drawing.dart';
import 'svg_map_spec.dart';

class SvgMapController extends ChangeNotifier {
  SvgMapSpec? _mapSpec;
  int _currentStageId = 1; // 현재 진행 중인 단계
  bool _isCurrentStageCompleted = false; // 현재 단계 완료 여부
  bool _isMoving = false;
  Offset _characterPosition = Offset.zero;
  Path? _roadPath;
  PathMetric? _roadPathMetric;
  
  SvgMapSpec? get mapSpec => _mapSpec;
  int get currentStageId => _currentStageId;
  bool get isCurrentStageCompleted => _isCurrentStageCompleted;
  bool get isMoving => _isMoving;
  Offset get characterPosition => _characterPosition;
  Path? get roadPath => _roadPath;
  PathMetric? get roadPathMetric => _roadPathMetric;

  void loadMapSpec(SvgMapSpec spec) {
    _mapSpec = spec;
    _currentStageId = 1;
    _isCurrentStageCompleted = false;
    
    if (kDebugMode) {
      print('Loading map spec with ${spec.nodes.length} nodes');
      print('Nodes: ${spec.nodes.map((n) => 'id:${n.id}').join(', ')}');
    }
    
    // Parse SVG path and create Flutter Path
    _roadPath = _parseSvgPathData(spec.road.svgPath);
    final pathMetrics = _roadPath!.computeMetrics().toList(); // Convert to list
    if (kDebugMode) {
      print('Path metrics count: ${pathMetrics.length}');
      print('Path bounds: ${_roadPath!.getBounds()}');
    }
    
    // Check if we have valid path metrics
    if (pathMetrics.isNotEmpty) {
      final firstMetric = pathMetrics.first;
      if (kDebugMode) {
        print('First path metric length: ${firstMetric.length}');
      }
      if (firstMetric.length > 0) {
        _roadPathMetric = firstMetric;
        if (kDebugMode) {
          print('Valid path metric length: ${_roadPathMetric!.length}');
        }
      } else {
        if (kDebugMode) {
          print('Path metric has zero length, using fallback path');
        }
        _roadPath = _createFallbackPath();
        _roadPathMetric = _roadPath!.computeMetrics().first;
      }
    } else {
      if (kDebugMode) {
        print('No path metrics found, using fallback path');
      }
      _roadPath = _createFallbackPath();
      _roadPathMetric = _roadPath!.computeMetrics().first;
    }
    
    // Set character at the starting position (node 0)
    if (spec.nodes.isNotEmpty) {
      final startNode = spec.nodes.first;
      if (kDebugMode) {
        print('Start node: ${startNode.id}');
      }
      _characterPosition = _getNodePosition(startNode);
    } else {
      if (kDebugMode) {
        print('No nodes found in spec!');
      }
    }
    
    notifyListeners();
  }

  Offset _getNodePosition(SvgNode node) {
    if (_roadPathMetric == null) return Offset.zero;
    
    final distance = _roadPathMetric!.length * node.position;
    final tangent = _roadPathMetric!.getTangentForOffset(distance);
    
    return tangent?.position ?? Offset.zero;
  }

  bool canTapNode(int nodeId) {
    return nodeId == _currentStageId && !_isCurrentStageCompleted && !_isMoving;
  }

  NodeState getNodeState(int nodeId) {
    if (nodeId < _currentStageId) {
      return NodeState.done; // 이전 단계들은 완료
    } else if (nodeId == _currentStageId) {
      if (_isCurrentStageCompleted) {
        return NodeState.done; // 현재 단계 완료됨
      } else {
        return NodeState.next; // 현재 단계 진행 가능
      }
    } else {
      return NodeState.locked; // 미래 단계들은 잠김
    }
  }

  Future<void> moveToNode(int nodeId, TickerProvider tickerProvider, {VoidCallback? onMovementComplete}) async {
    if (!canTapNode(nodeId) || _mapSpec == null || _roadPathMetric == null) return;

    _isMoving = true;
    notifyListeners();

    if (kDebugMode) {
      print('Moving to node $nodeId');
      print('Available nodes: ${_mapSpec!.nodes.map((n) => n.id).toList()}');
    }

    final targetNode = _mapSpec!.nodes.cast<SvgNode?>().firstWhere(
      (node) => node?.id == nodeId,
      orElse: () => null,
    );
    final currentNode = _mapSpec!.nodes.cast<SvgNode?>().firstWhere(
      (node) => node?.id == nodeId - 1,
      orElse: () => null,
    );
    
    if (kDebugMode) {
      print('Target node: ${targetNode?.id}, Current node: ${currentNode?.id}');
    }
    
    if (targetNode == null || currentNode == null) {
      _isMoving = false;
      notifyListeners();
      return;
    }
    
    final startDistance = _roadPathMetric!.length * currentNode.position;
    final endDistance = _roadPathMetric!.length * targetNode.position;

    final animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: tickerProvider,
    );

    final animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    );

    DateTime? lastNotification;
    animation.addListener(() {
      final now = DateTime.now();
      if (lastNotification == null || now.difference(lastNotification!).inMilliseconds > 16) {
        final currentDistance = startDistance + (endDistance - startDistance) * animation.value;
        final tangent = _roadPathMetric!.getTangentForOffset(currentDistance);
        
        if (tangent != null) {
          _characterPosition = tangent.position;
          notifyListeners();
          lastNotification = now;
        }
      }
    });

    await animationController.forward();
    
    _isCurrentStageCompleted = true; // 현재 단계 완료로 표시
    _isMoving = false;
    animationController.dispose();
    notifyListeners();
    
    // Call completion callback if provided
    onMovementComplete?.call();
  }

  // CLEAR 화면에서 완료 확인 후 다음 단계로 진행
  void completeCurrentStage() {
    if (_isCurrentStageCompleted) {
      _currentStageId++;
      _isCurrentStageCompleted = false;
      notifyListeners();
    }
  }

  // 현재 단계를 취소하고 이전 상태로 돌아가기
  void cancelCurrentStage() {
    if (_isCurrentStageCompleted && _mapSpec != null) {
      _isCurrentStageCompleted = false;
      
      // 캐릭터를 이전 노드 위치로 되돌리기
      final previousNodeId = _currentStageId - 1;
      if (previousNodeId >= 0) {
        final previousNode = _mapSpec!.nodes.cast<SvgNode?>().firstWhere(
          (node) => node?.id == previousNodeId,
          orElse: () => null,
        );
        
        if (previousNode != null) {
          _characterPosition = _getNodePosition(previousNode);
        }
      }
      
      notifyListeners();
    }
  }

  void skipToNode(int nodeId) {
    if (_mapSpec == null) return;
    
    final targetNode = _mapSpec!.nodes.cast<SvgNode?>().firstWhere(
      (node) => node?.id == nodeId,
      orElse: () => null,
    );
    
    if (targetNode != null) {
      _currentStageId = nodeId + 1;
      _isCurrentStageCompleted = false;
      _characterPosition = _getNodePosition(targetNode);
      notifyListeners();
    }
  }

  // Get completed path from start to current character position
  Path? getCompletedPath() {
    if (_roadPathMetric == null || _mapSpec == null) return null;
    
    double endDistance;
    
    if (_isMoving) {
      // During movement, show rainbow trail up to current character position
      final currentPosOnPath = _getDistanceForPosition(_characterPosition);
      endDistance = currentPosOnPath;
    } else {
      // When stationary, show rainbow trail based on completion status
      final completedStages = _currentStageId - 1; // 완전히 완료된 단계들
      if (completedStages <= 0) {
        if (_isCurrentStageCompleted) {
          // 첫 번째 단계를 완료했으면 첫 번째 노드까지 표시
          final currentNode = _mapSpec!.nodes.firstWhere((node) => node.id == _currentStageId);
          endDistance = _roadPathMetric!.length * currentNode.position;
        } else {
          return null; // 아직 아무것도 완료하지 않음
        }
      } else {
        // 이전 단계들까지는 확실히 표시
        var targetStage = completedStages;
        if (_isCurrentStageCompleted) {
          targetStage = _currentStageId; // 현재 단계도 완료됨
        }
        final targetNode = _mapSpec!.nodes.firstWhere((node) => node.id == targetStage);
        endDistance = _roadPathMetric!.length * targetNode.position;
      }
    }
    
    // Only return path if there's actual distance to show
    if (endDistance <= 0) return null;
    
    return _roadPathMetric!.extractPath(0, endDistance);
  }
  
  // Helper method to find distance along path for a given position
  double _getDistanceForPosition(Offset position) {
    if (_roadPathMetric == null) return 0;
    
    double closestDistance = 0;
    double minDistanceToPoint = double.infinity;
    
    // Sample the path to find the closest point
    final pathLength = _roadPathMetric!.length;
    for (double i = 0; i <= pathLength; i += pathLength / 100) {
      final tangent = _roadPathMetric!.getTangentForOffset(i);
      if (tangent != null) {
        final distance = (tangent.position - position).distance;
        if (distance < minDistanceToPoint) {
          minDistanceToPoint = distance;
          closestDistance = i;
        }
      }
    }
    
    return closestDistance;
  }

  // Get remaining path from current position to end
  Path? getRemainingPath() {
    if (_roadPathMetric == null || _mapSpec == null) return null;
    
    double startDistance;
    
    if (_isMoving) {
      // During movement, show dirt road from current character position to end
      final currentPosOnPath = _getDistanceForPosition(_characterPosition);
      startDistance = currentPosOnPath;
    } else {
      // When stationary, show dirt road from last completed node to end
      final completedNodes = _mapSpec!.nodes.where((node) => node.id < _currentStageId).toList();
      if (completedNodes.isEmpty) return _roadPath;
      
      final lastCompletedNode = completedNodes.last;
      startDistance = _roadPathMetric!.length * lastCompletedNode.position;
    }
    
    // Only return path if there's remaining distance to show
    if (startDistance >= _roadPathMetric!.length) return null;
    
    return _roadPathMetric!.extractPath(startDistance, _roadPathMetric!.length);
  }

  Path _parseSvgPathData(String svgPath) {
    try {
      // Use path_drawing package to parse the actual SVG path
      if (kDebugMode) {
        print('Parsing SVG path: ${svgPath.substring(0, 50)}...');
      }
      final path = parseSvgPathData(svgPath);
      if (kDebugMode) {
        print('Successfully parsed SVG path');
      }
      return path;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to parse SVG path, using fallback: $e');
      }
      return _createFallbackPath();
    }
  }

  Path _createFallbackPath() {
    // Fallback path if SVG parsing fails or produces invalid path
    final path = Path();
    
    // Simulate the safari road with a curved path
    path.moveTo(184, 900); // Start point (flipped Y from SVG)
    path.cubicTo(250, 700, 350, 600, 500, 650); // First curve
    path.cubicTo(650, 700, 800, 750, 950, 750); // Second curve  
    path.cubicTo(1100, 750, 1150, 650, 1150, 550); // Third curve
    path.cubicTo(1150, 450, 1050, 400, 950, 420); // Fourth curve
    path.cubicTo(850, 440, 750, 460, 650, 480); // Fifth curve
    path.cubicTo(550, 500, 400, 520, 300, 480); // Sixth curve
    path.cubicTo(200, 440, 150, 380, 150, 300); // Seventh curve
    path.cubicTo(150, 220, 200, 150, 300, 120); // Eighth curve
    path.cubicTo(400, 90, 500, 100, 600, 140); // Ninth curve
    path.cubicTo(700, 180, 800, 200, 900, 210); // Tenth curve
    path.cubicTo(1000, 220, 1100, 200, 1190, 150); // End curve
    
    return path;
  }
}

enum NodeState {
  locked,
  next,
  done,
}