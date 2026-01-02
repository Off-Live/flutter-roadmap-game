import 'package:flutter/material.dart';
import 'map/svg_map_controller.dart';

class ClearScreen extends StatelessWidget {
  final SvgMapController controller;
  
  const ClearScreen({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 뒤로가기 버튼 (좌측 상단)
          Positioned(
            top: 60,
            left: 30,
            child: IconButton(
              onPressed: () {
                controller.cancelCurrentStage();
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_back,
                size: 30,
                color: Colors.black,
              ),
            ),
          ),
          
          // CLEAR 버튼 (중앙)
          Center(
            child: ElevatedButton(
              onPressed: () {
                controller.completeCurrentStage();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: const BorderSide(color: Colors.white, width: 2),
                ),
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.3),
              ),
              child: const Text(
                'CLEAR',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}