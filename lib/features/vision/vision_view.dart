import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:math';
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

  void _showFilterBottomSheet(BuildContext context) {
    final tabWarna = ['Normal', 'Grayscale', 'Brightness', 'Gelap', 'Kontras', 'Inverse (Negatif)', 'Hist. Equalization', 'Hist. Specification', 'Konversi Warna', 'Indexed'];
    final tabSpasial = ['Konvolusi', 'Average', 'Gaussian', 'Median Filter', 'Sharpen', 'Edge Detection'];
    final tabMorfologi = ['Thresholding', 'Erosi', 'Dilasi', 'Opening', 'Closing', 'Boundary', 'Region Filling', 'Thinning', 'Skeleton', 'Convex Hull', 'Labelling'];
    final tabMulti = ['AND', 'OR', 'XOR', 'NOT', 'Tambah', 'Kurang', 'MAX', 'MIN'];
    final tabFrekuensi = ['Transformasi Fourier', 'Notch Filter'];
    final tabAnalisis = ['Histogram', 'Ukur Jarak'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildChoiceChips(List<String> filters) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 12.0,
                    children: filters.map((String filter) {
                      final isSelected = selectedFilter == filter;
                      return ChoiceChip(
                        label: Text(
                          filter, 
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.cyanAccent,
                        backgroundColor: Colors.grey.shade800,
                        onSelected: (selected) {
                          if (selected) {
                            // Validation Logic
                            final morphoRequiresThreshold = ['Erosi', 'Dilasi', 'Opening', 'Closing', 'Boundary', 'Region Filling', 'Thinning', 'Skeleton', 'Convex Hull', 'Labelling'];
                            if (morphoRequiresThreshold.contains(filter) && !isThresholded) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Harus menggunakan Thresholding (Biner) terlebih dahulu!"), backgroundColor: Colors.red),
                              );
                              return; // Cancel assignment
                            }
                            
                            if (filter == 'Notch Filter' && !isFourierMode) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Harus masuk ke mode Fourier terlebih dahulu!"), backgroundColor: Colors.red),
                              );
                              return; // Cancel assignment
                            }

                            // Dynamic Flag Toggling
                            if (filter == 'Thresholding' || filter == 'Threshold') {
                              isThresholded = true;
                            } else if (filter == 'Transformasi Fourier') {
                              isFourierMode = true;
                            } else if (filter == 'Normal') {
                               isThresholded = false;
                               isFourierMode = false;
                            }

                            setModalState(() { selectedFilter = filter; });
                            setState(() { selectedFilter = filter; });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: DefaultTabController(
                length: 6,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 48, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 12),
                    const Text('Katalog Filter PCD', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    const TabBar(
                      isScrollable: true,
                      indicatorColor: Colors.cyanAccent,
                      labelColor: Colors.cyanAccent,
                      unselectedLabelColor: Colors.white54,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.white10,
                      tabs: [
                        Tab(text: "Warna"),
                        Tab(text: "Spasial"),
                        Tab(text: "Morfologi"),
                        Tab(text: "Multi-Gambar"),
                        Tab(text: "Frekuensi"),
                        Tab(text: "Analisis"),
                      ],
                    ),
                    
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TabBarView(
                          children: [
                            buildChoiceChips(tabWarna),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: buildChoiceChips(tabSpasial)),
                                if (selectedFilter == 'Median Filter')
                                  Container(
                                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: CheckboxListTile(
                                      title: const Text("Simulate Salt & Pepper Noise", style: TextStyle(color: Colors.white, fontSize: 14)),
                                      value: simulateSaltPepper,
                                      activeColor: Colors.cyanAccent,
                                      checkColor: Colors.black,
                                      onChanged: (val) {
                                        if (val != null) {
                                          setModalState(() { simulateSaltPepper = val; });
                                          setState(() { simulateSaltPepper = val; });
                                        }
                                      },
                                    ),
                                  )
                              ],
                            ),
                            buildChoiceChips(tabMorfologi),
                            buildChoiceChips(tabMulti),
                            buildChoiceChips(tabFrekuensi),
                            buildChoiceChips(tabAnalisis),
                          ],
                        ),
                      ),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 32.0),
                      decoration: const BoxDecoration(
                        color: Colors.black12,
                        border: Border(top: BorderSide(color: Colors.white10)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Intensitas Parameter', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              Text(filterIntensity.toStringAsFixed(2), style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Slider(
                            value: filterIntensity,
                            min: 0.0,
                            max: 2.0,
                            activeColor: Colors.cyanAccent,
                            inactiveColor: Colors.white24,
                            onChanged: (value) {
                              setModalState(() { filterIntensity = value; });
                              setState(() { filterIntensity = value; });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
              
              if (context.mounted) {
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

