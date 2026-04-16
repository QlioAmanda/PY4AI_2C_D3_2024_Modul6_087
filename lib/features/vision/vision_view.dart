import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'vision_controller.dart';

class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  final VisionController _visionController = VisionController();

  @override
  void initState() {
    super.initState();
    _visionController.initializeCamera();
    _visionController.addListener(_onControllerStateChanged);
  }

  void _onControllerStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
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
            // Scanner Overlay
            Positioned.fill(
              child: CustomPaint(
                painter: ScannerOverlayPainter(color: Colors.blue.shade400),
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
          // Empty space to balance the Flash toggle
          const SizedBox(width: 48), 
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Color color;

  ScannerOverlayPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 30.0;
    const double padding = 16.0;

    // Adjust coordinates to give border padding
    final left = padding;
    final top = padding;
    final right = size.width - padding;
    final bottom = size.height - padding;

    // Top Left Frame
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), paint);

    // Top Right Frame
    canvas.drawLine(Offset(right, top), Offset(right - cornerLength, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLength), paint);

    // Bottom Left Frame
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLength, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left, bottom - cornerLength), paint);

    // Bottom Right Frame
    canvas.drawLine(Offset(right, bottom), Offset(right - cornerLength, bottom), paint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLength), paint);

    // Center Scanning Line
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2.0;
    canvas.drawLine(
        Offset(left + 10, size.height / 2), Offset(right - 10, size.height / 2), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
