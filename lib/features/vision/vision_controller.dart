import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:flutter/foundation.dart';

enum VisionStatus { initializing, ready, error, permissionDenied }

class VisionController extends ChangeNotifier {
  CameraController? cameraController;
  VisionStatus status = VisionStatus.initializing;
  bool isInitialized = false;
  String? errorMessage;
  bool isFlashOn = false;
  bool isOverlayVisible = true;

  void toggleOverlay() {
    isOverlayVisible = !isOverlayVisible;
    notifyListeners();
  }

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

  Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }

  Future<void> initializeCamera() async {
    try {
      status = VisionStatus.initializing;
      notifyListeners();

      // 1. Handle permissions
      var permissionStatus = await ph.Permission.camera.request();
      if (!permissionStatus.isGranted) {
        status = VisionStatus.permissionDenied;
        errorMessage = 'Izin kamera ditolak. Silakan aktifkan izin di pengaturan perangkat.';
        notifyListeners();
        return;
      }

      // 2. Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        status = VisionStatus.error;
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
      status = VisionStatus.ready;
      notifyListeners();
    } catch (e) {
      status = VisionStatus.error;
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
