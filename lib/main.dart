import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'map/svg_map_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const RoadmapGameApp());
}

class RoadmapGameApp extends StatelessWidget {
  const RoadmapGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roadmap Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SvgMapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
