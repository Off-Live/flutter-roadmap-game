import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'svg_map_spec.dart';
import 'svg_map_controller.dart';
import 'svg_road_painter.dart';
import 'svg_nodes_layer.dart';
import 'character_layer.dart';
import 'svg_finger_pointer.dart';
import '../clear_screen.dart';
import '../transitions/light_burst_route.dart';

class SvgMapScreen extends StatefulWidget {
  const SvgMapScreen({super.key});

  @override
  State<SvgMapScreen> createState() => _SvgMapScreenState();
}

class _SvgMapScreenState extends State<SvgMapScreen> with TickerProviderStateMixin {
  late final SvgMapController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = SvgMapController();
    _loadMap();
  }

  Future<void> _loadMap() async {
    try {
      print('Loading JSON file...');
      final jsonString = await rootBundle.loadString('assets/map/aqua_world_map.json');
      print('JSON loaded, parsing...');
      final jsonData = jsonDecode(jsonString);
      print('JSON parsed, creating SvgMapSpec...');
      final mapSpec = SvgMapSpec.fromJson(jsonData);
      print('SvgMapSpec created, loading into controller...');
      
      _controller.loadMapSpec(mapSpec);
      print('Map loaded successfully');
      
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading map: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load SVG map: $e';
      });
    }
  }

  void _onNodeTap(int nodeId) {
    if (_controller.canTapNode(nodeId)) {
      _controller.moveToNode(
        nodeId, 
        this,
        onMovementComplete: () {
          // Navigate to clear screen with light burst transition
          Navigator.of(context).push(
            LightBurstRoute(page: ClearScreen(controller: _controller)),
          );
        },
      );
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
        return _SvgMapView(
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

class _SvgMapView extends StatelessWidget {
  final SvgMapController controller;
  final Function(int nodeId) onNodeTap;
  final TickerProvider tickerProvider;

  const _SvgMapView({
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
        final designSize = mapSpec.designSize;
        final viewportSize = constraints.biggest;
        
        // For 3:2 aspect ratio, fill height and crop horizontally
        final scale = viewportSize.height / designSize.height;
        
        final scaledMapSize = Size(
          designSize.width * scale,
          designSize.height * scale,
        );
        
        final offset = Offset(
          (viewportSize.width - scaledMapSize.width) / 2, // Center horizontally (crop sides)
          0, // Fill height (no vertical offset)
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
                    // SVG Road
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: SvgRoadPainter(
                          mapSpec: mapSpec,
                          controller: controller,
                          scale: scale,
                          offset: offset,
                        ),
                        size: viewportSize,
                      ),
                    ),
                    
                    // Nodes
                    SvgNodesLayer(
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
                    SvgFingerPointer(
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
                  if (!controller.isMoving && controller.mapSpec != null) {
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