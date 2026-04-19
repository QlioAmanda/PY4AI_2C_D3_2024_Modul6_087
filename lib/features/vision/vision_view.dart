import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'vision_controller.dart';
import 'damage_painter.dart';
import 'pcd_editor_screen.dart';

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
  String currentDamage = 'Pothole D40';
  String selectedFilter = 'Normal';
  double filterIntensity = 1.0;
  bool isThresholded = false;
  bool isFourierMode = false;
  bool simulateSaltPepper = false;
  Timer? _mockTimer;

  int currentIndex = 0;
  String currentImagePath = '';

  final List<String> pcdFilters = [
    'Normal', 'Grayscale', 'Brightness', 'Gelap', 'Kontras', 'Inverse (Negatif)', 'Hist. Equalization', 'Hist. Specification', 'Konversi Warna', 'Indexed',
    'Konvolusi', 'Average', 'Gaussian', 'Median Filter', 'Sharpen', 'Edge Detection',
    'Thresholding', 'Erosi', 'Dilasi', 'Opening', 'Closing', 'Boundary', 'Region Filling', 'Thinning', 'Skeleton', 'Convex Hull', 'Labelling',
    'AND', 'OR', 'XOR', 'NOT', 'Tambah', 'Kurang', 'MAX', 'MIN',
    'Transformasi Fourier', 'Notch Filter',
    'Histogram', 'Ukur Jarak'
  ];

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

          if (scanStep % 2 == 0) {
            currentDamage = 'Pothole D40';
          } else {
            currentDamage = 'Longitudinal Crack D00';
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
      appBar: currentIndex == 0 ? AppBar(
        title: const Text('Vision Scanner', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ) : null,
      body: IndexedStack(
        index: currentIndex,
        children: [
          // Index 0: Scanner
          Column(
            children: [
              Expanded(
                child: Center(
                  child: _buildCameraBody(),
                ),
              ),
              _buildBottomControlBar(),
            ],
          ),
          // Index 1: PcdEditorScreen didesain user
          PcdEditorScreen(
            imagePath: currentImagePath,
            fullFilters: pcdFilters,
            onBackToCamera: () {
              setState(() {
                currentIndex = 0; // Kembalikan ke halaman Scanner
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCameraBody() {
    switch (_visionController.status) {
      case VisionStatus.initializing:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text('Menghubungkan ke Sensor Visual...', style: TextStyle(color: Colors.white)),
          ],
        );

      case VisionStatus.error:
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _visionController.errorMessage ?? 'Terjadi kesalahan internal.',
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        );

      case VisionStatus.permissionDenied:
        return Container(
          color: Colors.black,
          width: double.infinity,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 72),
              const SizedBox(height: 24),
              const Text(
                'Akses Kamera Ditolak.\nAplikasi memerlukan izin kamera untuk mendeteksi kerusakan jalan.',
                style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  _visionController.openAppSettings();
                },
                child: const Text('Buka Pengaturan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        );

      case VisionStatus.ready:
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
                  child: _buildFilteredCamera(controller),
                ),
                // MOTS: Damage Painter (Static Anchor & Label)
                if (_visionController.isOverlayVisible)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: DamagePainter(mockX: mockX, mockY: mockY, damageType: currentDamage),
                    ),
                  ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildFilteredCamera(CameraController controller) {
    if (selectedFilter == 'Grayscale') {
      final inv = 1.0 - (filterIntensity.clamp(0.0, 1.0));
      final gVal = filterIntensity.clamp(0.0, 1.0);
      final ColorFilter grayscaleFilter = ColorFilter.matrix(<double>[
        inv + (0.2126 * gVal), 0.7152 * gVal,       0.0722 * gVal,       0, 0,
        0.2126 * gVal,       inv + (0.7152 * gVal), 0.0722 * gVal,       0, 0,
        0.2126 * gVal,       0.7152 * gVal,       inv + (0.0722 * gVal), 0, 0,
        0,                   0,                   0,                   1, 0,
      ]);
      return ColorFiltered(
        colorFilter: grayscaleFilter,
        child: CameraPreview(controller),
      );
    }

    if (selectedFilter == 'Brightness') {
      final b = filterIntensity;
      final ColorFilter brightFilter = ColorFilter.matrix(<double>[
        b, 0, 0, 0, 0,
        0, b, 0, 0, 0,
        0, 0, b, 0, 0,
        0, 0, 0, 1, 0,
      ]);
      return ColorFiltered(
        colorFilter: brightFilter,
        child: CameraPreview(controller),
      );
    }

    if (selectedFilter == 'Inverse (Negatif)') {
      const ColorFilter invertFilter = ColorFilter.matrix(<double>[
        -1,  0,  0, 0, 255,
         0, -1,  0, 0, 255,
         0,  0, -1, 0, 255,
         0,  0,  0, 1,   0,
      ]);
      return ColorFiltered(
        colorFilter: invertFilter,
        child: CameraPreview(controller),
      );
    }

    // Normal or placeholders for complex filters pending OpenCV integration
    return CameraPreview(controller);
  }

  Widget _buildBottomControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
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
          IconButton(
            icon: const Icon(Icons.photo_library, color: Colors.white, size: 28),
            onPressed: () async {
              final picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null && context.mounted) {
                setState(() {
                  currentImagePath = image.path;
                  currentIndex = 1; // Pindah Tab otomatis
                });
              }
            },
          ),
          // Prominent Capture Button
          GestureDetector(
            onTap: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  );
                },
              );

              final XFile? image = await _visionController.takePicture();
              
              if (!mounted) return;
              Navigator.of(context).pop(); // Remove loading overlay

              if (image != null) {
                setState(() {
                  currentImagePath = image.path;
                  currentIndex = 1; // Pindah Tab Otomatis
                });
              } else if (_visionController.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_visionController.errorMessage!), 
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white, size: 28),
            onPressed: () {
              setState(() {
                currentIndex = 1; // Pindah ke Editor Filter PCD
              });
            },
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

