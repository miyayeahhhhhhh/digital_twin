import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class Heart3DViewer extends StatelessWidget {
  const Heart3DViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF10131F),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: const ModelViewer(
        src: 'assets/models/heart.glb',
        alt: 'Interactive 3D anatomical heart',
        backgroundColor: Color(0xFF10131F),
        autoRotate: true,
        cameraControls: true,
        disableZoom: false,
        ar: false,
      ),
    );
  }
}
