import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class VisionController extends ChangeNotifier {
  CameraController? cameraController;
  bool isInitialized = false;
  String? errorMessage;
  bool isFlashOn = false;

  Future<void> toggleFlash() async {
    if (cameraController == null || !isInitialized) return;
    try {
      if (isFlashOn) {
        await cameraController!.setFlashMode(FlashMode.off);
        isFlashOn = false;
      } else {
        await cameraController!.setFlashMode(FlashMode.torch);
        isFlashOn = true;
      }
      notifyListeners();
    } catch (e) {
      errorMessage = 'Gagal mengatur flash: $e';
      notifyListeners();
    }
  }

  Future<void> initializeCamera() async {
    try {
      // 1. Handle permissions
      var status = await Permission.camera.request();
      if (!status.isGranted) {
        errorMessage = 'Izin kamera ditolak. Silakan aktifkan izin di pengaturan perangkat.';
        notifyListeners();
        return;
      }

      // 2. Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        errorMessage = 'Kamera tidak ditemukan pada perangkat ini.';
        notifyListeners();
        return;
      }

      // 3. Select back camera
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // 4. Initialize CameraController with medium resolution
      cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await cameraController!.initialize();
      isInitialized = true;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Terjadi kesalahan saat menginisialisasi kamera: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }
}
