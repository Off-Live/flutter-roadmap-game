import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'map_spec.dart';
import 'map_controller.dart';
import 'road_painter.dart';
import 'nodes_layer.dart';
import 'character_layer.dart';
import 'finger_pointer.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late final MapController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = MapController();
    _loadMap();
  }

  Future<void> _loadMap() async {
    try {
      // Try to load from JSON file first
      final jsonString = await rootBundle.loadString('assets/map/safari_world_map.json');
      final jsonData = jsonDecode(jsonString);
      final mapSpec = MapSpec.fromJson(jsonData);
      
      _controller.loadMapSpec(mapSpec);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // If JSON loading fails, fallback to hardcoded data
      print('Failed to load JSON, using hardcoded data: $e');
      try {
        final mapData = _getHardcodedMapData();
        final mapSpec = MapSpec.fromJson(mapData);
        
        _controller.loadMapSpec(mapSpec);
        
        setState(() {
          _isLoading = false;
        });
      } catch (fallbackError) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load map: $fallbackError';
        });
      }
    }
  }

  Map<String, dynamic> _getHardcodedMapData() {
    return {
      "version": 1,
      "designSize": {"w": 1536, "h": 1024},
      "background": {"asset": "assets/BG.png"},
      "nodes": [
        {
          "id": 0,
          "pos": {"x": 150, "y": 500},
          "tapRadius": 58,
          "assets": {
            "locked": "assets/nodes/node_locked.png",
            "next": "assets/nodes/node_next.png",
            "done": "assets/nodes/node_done.png"
          }
        },
        {
          "id": 1,
          "pos": {"x": 300, "y": 350},
          "tapRadius": 58,
          "assets": {
            "locked": "assets/nodes/node_locked.png",
            "next": "assets/nodes/node_next.png",
            "done": "assets/nodes/node_done.png"
          }
        },
        {
          "id": 2,
          "pos": {"x": 450, "y": 600},
          "tapRadius": 58,
          "assets": {
            "locked": "assets/nodes/node_locked.png",
            "next": "assets/nodes/node_next.png",
            "done": "assets/nodes/node_done.png"
          }
        },
        {
          "id": 3,
          "pos": {"x": 600, "y": 200},
          "tapRadius": 58,
          "assets": {
            "locked": "assets/nodes/node_locked.png",
            "next": "assets/nodes/node_next.png",
            "done": "assets/nodes/node_done.png"
          }
        },
        {
          "id": 4,
          "pos": {"x": 750, "y": 480},
          "tapRadius": 58,
          "assets": {
            "locked": "assets/nodes/node_locked.png",
            "next": "assets/nodes/node_next.png",
            "done": "assets/nodes/node_done.png"
          }
        },
        {
          "id": 5,
          "pos": {"x": 900, "y": 150},
          "tapRadius": 58,
          "assets": {
            "locked": "assets/nodes/node_locked.png",
            "next": "assets/nodes/node_next.png",
            "done": "assets/nodes/node_done.png"
          }
        },
        {
          "id": 6,
          "pos": {"x": 1050, "y": 400},
          "tapRadius": 58,
          "assets": {
            "locked": "assets/nodes/node_locked.png",
            "next": "assets/nodes/node_next.png",
            "done": "assets/nodes/node_done.png"
          }
        },
        {
          "id": 7,
          "pos": {"x": 1200, "y": 250},
          "tapRadius": 58,
          "assets": {
            "locked": "assets/nodes/node_locked.png",
            "next": "assets/nodes/node_next.png",
            "done": "assets/nodes/node_done.png"
          }
        },
        {
          "id": 8,
          "pos": {"x": 1350, "y": 550},
          "tapRadius": 58,
          "assets": {
            "locked": "assets/nodes/node_locked.png",
            "next": "assets/nodes/node_next.png",
            "done": "assets/nodes/node_done.png"
          }
        },
        {
          "id": 9,
          "pos": {"x": 1450, "y": 350},
          "tapRadius": 58,
          "assets": {
            "locked": "assets/nodes/node_locked.png",
            "next": "assets/nodes/node_next.png",
            "done": "assets/nodes/node_done.png"
          }
        },
        {
          "id": 10,
          "pos": {"x": 1300, "y": 700},
          "tapRadius": 58,
          "assets": {
            "locked": "assets/nodes/node_locked.png",
            "next": "assets/nodes/node_next.png",
            "done": "assets/nodes/node_done.png"
          }
        },
        {
          "id": 11,
          "pos": {"x": 1100, "y": 800},
          "tapRadius": 58,
          "assets": {
            "locked": "assets/nodes/node_locked.png",
            "next": "assets/nodes/node_next.png",
            "done": "assets/nodes/node_done.png"
          }
        },
        {
          "id": 12,
          "pos": {"x": 850, "y": 750},
          "tapRadius": 58,
          "assets": {
            "locked": "assets/nodes/node_locked.png",
            "next": "assets/nodes/node_next.png",
            "done": "assets/nodes/node_done.png"
          }
        },
        {
          "id": 13,
          "pos": {"x": 600, "y": 850},
          "tapRadius": 58,
          "assets": {
            "locked": "assets/nodes/node_locked.png",
            "next": "assets/nodes/node_next.png",
            "done": "assets/nodes/node_done.png"
          }
        },
        {
          "id": 14,
          "pos": {"x": 350, "y": 800},
          "tapRadius": 58,
          "assets": {
            "locked": "assets/nodes/node_locked.png",
            "next": "assets/nodes/node_next.png",
            "done": "assets/nodes/node_done.png"
          }
        }
      ],
      "road": {
        "mode": "cubicSegments", 
        "segments": [
          {
            "fromId": 0,
            "toId": 1,
            "beziers": [
              {
                "p0": {"x": 150, "y": 500},
                "c1": {"x": 200, "y": 460},
                "c2": {"x": 250, "y": 380},
                "p3": {"x": 300, "y": 350}
              }
            ],
            "style": {"base": "dirt", "completed": "rainbow"}
          },
          {
            "fromId": 1,
            "toId": 2,
            "beziers": [
              {
                "p0": {"x": 300, "y": 350},
                "c1": {"x": 330, "y": 400},
                "c2": {"x": 400, "y": 550},
                "p3": {"x": 450, "y": 600}
              }
            ],
            "style": {"base": "dirt", "completed": "rainbow"}
          },
          {
            "fromId": 2,
            "toId": 3,
            "beziers": [
              {
                "p0": {"x": 450, "y": 600},
                "c1": {"x": 500, "y": 500},
                "c2": {"x": 550, "y": 300},
                "p3": {"x": 600, "y": 200}
              }
            ],
            "style": {"base": "dirt", "completed": "rainbow"}
          },
          {
            "fromId": 3,
            "toId": 4,
            "beziers": [
              {
                "p0": {"x": 600, "y": 200},
                "c1": {"x": 650, "y": 260},
                "c2": {"x": 700, "y": 400},
                "p3": {"x": 750, "y": 480}
              }
            ],
            "style": {"base": "dirt", "completed": "rainbow"}
          },
          {
            "fromId": 4,
            "toId": 5,
            "beziers": [
              {
                "p0": {"x": 750, "y": 480},
                "c1": {"x": 790, "y": 400},
                "c2": {"x": 850, "y": 220},
                "p3": {"x": 900, "y": 150}
              }
            ],
            "style": {"base": "dirt", "completed": "rainbow"}
          },
          {
            "fromId": 5,
            "toId": 6,
            "beziers": [
              {
                "p0": {"x": 900, "y": 150},
                "c1": {"x": 950, "y": 200},
                "c2": {"x": 1000, "y": 320},
                "p3": {"x": 1050, "y": 400}
              }
            ],
            "style": {"base": "dirt", "completed": "rainbow"}
          },
          {
            "fromId": 6,
            "toId": 7,
            "beziers": [
              {
                "p0": {"x": 1050, "y": 400},
                "c1": {"x": 1100, "y": 370},
                "c2": {"x": 1150, "y": 280},
                "p3": {"x": 1200, "y": 250}
              }
            ],
            "style": {"base": "dirt", "completed": "rainbow"}
          },
          {
            "fromId": 7,
            "toId": 8,
            "beziers": [
              {
                "p0": {"x": 1200, "y": 250},
                "c1": {"x": 1250, "y": 300},
                "c2": {"x": 1300, "y": 450},
                "p3": {"x": 1350, "y": 550}
              }
            ],
            "style": {"base": "dirt", "completed": "rainbow"}
          },
          {
            "fromId": 8,
            "toId": 9,
            "beziers": [
              {
                "p0": {"x": 1350, "y": 550},
                "c1": {"x": 1400, "y": 500},
                "c2": {"x": 1430, "y": 400},
                "p3": {"x": 1450, "y": 350}
              }
            ],
            "style": {"base": "dirt", "completed": "rainbow"}
          },
          {
            "fromId": 9,
            "toId": 10,
            "beziers": [
              {
                "p0": {"x": 1450, "y": 350},
                "c1": {"x": 1440, "y": 430},
                "c2": {"x": 1380, "y": 580},
                "p3": {"x": 1300, "y": 700}
              }
            ],
            "style": {"base": "dirt", "completed": "rainbow"}
          },
          {
            "fromId": 10,
            "toId": 11,
            "beziers": [
              {
                "p0": {"x": 1300, "y": 700},
                "c1": {"x": 1230, "y": 720},
                "c2": {"x": 1150, "y": 770},
                "p3": {"x": 1100, "y": 800}
              }
            ],
            "style": {"base": "dirt", "completed": "rainbow"}
          },
          {
            "fromId": 11,
            "toId": 12,
            "beziers": [
              {
                "p0": {"x": 1100, "y": 800},
                "c1": {"x": 1020, "y": 790},
                "c2": {"x": 920, "y": 770},
                "p3": {"x": 850, "y": 750}
              }
            ],
            "style": {"base": "dirt", "completed": "rainbow"}
          },
          {
            "fromId": 12,
            "toId": 13,
            "beziers": [
              {
                "p0": {"x": 850, "y": 750},
                "c1": {"x": 770, "y": 780},
                "c2": {"x": 670, "y": 830},
                "p3": {"x": 600, "y": 850}
              }
            ],
            "style": {"base": "dirt", "completed": "rainbow"}
          },
          {
            "fromId": 13,
            "toId": 14,
            "beziers": [
              {
                "p0": {"x": 600, "y": 850},
                "c1": {"x": 520, "y": 840},
                "c2": {"x": 420, "y": 820},
                "p3": {"x": 350, "y": 800}
              }
            ],
            "style": {"base": "dirt", "completed": "rainbow"}
          }
        ]
      },
      "character": {
        "asset": "assets/character/koala_cloud.png",
        "size": {"w": 100, "h": 100},
        "anchor": {"x": 0.5, "y": 0.75}
      },
      "paint": {
        "dirt": {
          "strokeWidth": 30,
          "color": "#CDA46B",
          "shadow": {"blur": 6, "dx": 0, "dy": 3, "color": "#33000000"},
          "dash": {"enabled": false, "pattern": [12, 10]},
          "footprints": {"enabled": true, "spacing": 80, "asset": "assets/map/footprint.png"}
        },
        "rainbow": {
          "strokeWidth": 34,
          "colors": ["#FF4D4D","#FFA94D","#FFE44D","#55D66B","#4DA3FF","#7B5BFF","#C04DFF"],
          "glow": {"enabled": true, "blur": 10, "color": "#66FFFFFF"}
        }
      }
    };
  }

  void _onNodeTap(int nodeId) {
    if (_controller.canTapNode(nodeId)) {
      _controller.moveToNode(nodeId, this);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadMap();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _MapView(
          controller: _controller,
          onNodeTap: _onNodeTap,
          tickerProvider: this,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _MapView extends StatelessWidget {
  final MapController controller;
  final Function(int nodeId) onNodeTap;
  final TickerProvider tickerProvider;

  const _MapView({
    required this.controller,
    required this.onNodeTap,
    required this.tickerProvider,
  });

  @override
  Widget build(BuildContext context) {
    final mapSpec = controller.mapSpec;
    if (mapSpec == null) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate scaling to fit the map in the viewport
        final designSize = mapSpec.designSize;
        final viewportSize = constraints.biggest;
        
        // Fill the entire screen
        final scaleX = viewportSize.width / designSize.width;
        final scaleY = viewportSize.height / designSize.height;
        final scale = scaleX > scaleY ? scaleX : scaleY; // Fill screen completely
        
        final scaledMapSize = Size(
          designSize.width * scale,
          designSize.height * scale,
        );
        
        final offset = Offset(
          (viewportSize.width - scaledMapSize.width) / 2,
          (viewportSize.height - scaledMapSize.height) / 2,
        );

        return Stack(
          children: [
            // Full-screen background
            Positioned.fill(
              child: Image.asset(
                mapSpec.background.asset,
                fit: BoxFit.cover,
                cacheWidth: 1536,
                cacheHeight: 1024,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.orange.shade200,
                    child: const Center(
                      child: Text('Background Loading...'),
                    ),
                  );
                },
              ),
            ),
            
            // Interactive map content
            InteractiveViewer(
              boundaryMargin: EdgeInsets.zero,
              minScale: 0.3,
              maxScale: 3.0,
              child: SizedBox(
                width: viewportSize.width,
                height: viewportSize.height,
                child: Stack(
                  children: [
                    // Road
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: RoadPainter(
                          mapSpec: mapSpec,
                          currentStageId: controller.currentStageId,
                          scale: scale,
                          offset: offset,
                        ),
                        size: viewportSize,
                      ),
                    ),
                    
                    // Nodes
                    NodesLayer(
                      controller: controller,
                      scale: scale,
                      offset: offset,
                      onNodeTap: onNodeTap,
                    ),
                    
                    // Character
                    CharacterLayer(
                      controller: controller,
                      scale: scale,
                      offset: offset,
                    ),
                    
                    // Finger Pointer
                    FingerPointer(
                      controller: controller,
                      scale: scale,
                      offset: offset,
                    ),
                  ],
                ),
              ),
            ),
            
            // SKIP Button
            Positioned(
              bottom: 50,
              right: 30,
              child: ElevatedButton(
                onPressed: () {
                  // Skip directly to node 11
                  if (!controller.isMoving && controller.mapSpec != null) {
                    // Set current stage to 11 and move character to node 11
                    controller.skipToNode(11);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.3),
                ),
                child: const Text(
                  'SKIP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}