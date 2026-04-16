import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:math';
import 'vision_controller.dart';
import 'damage_painter.dart';

class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  final VisionController _visionController = VisionController();

  double mockX = 0.5;
  double mockY = 0.5;
  int scanStep = 0;
  Timer? _mockTimer;

  @override
  void initState() {
    super.initState();
    _visionController.initializeCamera();
    _visionController.addListener(_onControllerStateChanged);

    _mockTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (mounted) {
        setState(() {
          if (scanStep == 0) {
            mockX = 0.45;
            mockY = 0.45;
          } else if (scanStep == 1) {
            mockX = 0.55;
            mockY = 0.45;
          } else if (scanStep == 2) {
            mockX = 0.55;
            mockY = 0.55;
          } else if (scanStep == 3) {
            mockX = 0.45;
            mockY = 0.55;
          }
          scanStep = (scanStep + 1) % 4;
        });
      }
    });
  }

  void _onControllerStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    _visionController.removeListener(_onControllerStateChanged);
    _visionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Vision Scanner', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _buildCameraBody(),
            ),
          ),
          _buildBottomControlBar(),
        ],
      ),
    );
  }

  Widget _buildCameraBody() {
    if (_visionController.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _visionController.errorMessage!,
          style: const TextStyle(color: Colors.red, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (!_visionController.isInitialized || _visionController.cameraController == null) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text('Menginisialisasi Kamera...', style: TextStyle(color: Colors.white)),
        ],
      );
    }

    final controller = _visionController.cameraController!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      // Glowing blue border
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade400, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade600.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      // Clip to keep the corners rounded
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: 1 / controller.value.aspectRatio,
              child: CameraPreview(controller),
            ),
            // MOTS: Damage Painter (Static Anchor & Label)
            if (_visionController.isOverlayVisible)
              Positioned.fill(
                child: CustomPaint(
                  painter: DamagePainter(mockX: mockX, mockY: mockY),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Flash toggle functionality
          IconButton(
            icon: Icon(
              _visionController.isFlashOn ? Icons.flash_on : Icons.flash_off_rounded,
              color: _visionController.isFlashOn ? Colors.yellowAccent : Colors.white,
              size: 28,
            ),
            onPressed: () {
              _visionController.toggleFlash();
            },
          ),
          // Prominent Capture Button
          GestureDetector(
            onTap: () {
              // TODO: Implement capture logic
            },
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ),
          // Overlay Visibility Toggle
          IconButton(
            icon: Icon(
              _visionController.isOverlayVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              _visionController.toggleOverlay();
            },
          ), 
        ],
      ),
    );
  }
}

