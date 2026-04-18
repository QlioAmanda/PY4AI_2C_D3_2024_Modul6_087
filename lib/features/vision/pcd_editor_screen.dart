import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';

class PcdEditorScreen extends StatefulWidget {
  final String imagePath;
  final List<String> fullFilters;

  const PcdEditorScreen({super.key, required this.imagePath, required this.fullFilters});

  @override
  State<PcdEditorScreen> createState() => _PcdEditorScreenState();
}

class _PcdEditorScreenState extends State<PcdEditorScreen> {
  String selectedFilter = 'Normal';
  Uint8List? processedImageBytes;
  bool isProcessing = false;
  double arithmeticValue = 50.0;
  Uint8List? image2Bytes;

  static const List<String> aritmatikaFilters = ['Tambah', 'Kurang', 'Max', 'Min', 'Inverse'];
  static const List<String> logikaFilters = ['AND', 'XOR', 'NOT'];
  static const List<String> histogramFilters = ['Grayscale', 'Hist. Equalization', 'Hist. Specification'];
  static const List<String> statistikFilters = ['Hitung Statistik'];

  Future<void> saveToGallery() async {
    try {
      Uint8List bytesToSave = processedImageBytes ?? await File(widget.imagePath).readAsBytes();
      await Gal.putImageBytes(bytesToSave);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gambar berhasil disimpan ke Galeri!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan gambar: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Future<void> pickReferenceImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        image2Bytes = bytes;
      });
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Gambar referensi berhasil diunggah!"), backgroundColor: Colors.green),
         );
      }
    }
  }

  Future<void> applyFilter(String filterName) async {
    if (filterName == 'Hitung Statistik') {
      final bytes = processedImageBytes ?? await File(widget.imagePath).readAsBytes();
      img.Image? statImg = img.decodeImage(bytes);
      if (statImg != null) {
          double sum = 0;
          int n = statImg.width * statImg.height;
          List<int> histogram = List.filled(256, 0);
          for (int y = 0; y < statImg.height; y++) {
              for (int x = 0; x < statImg.width; x++) {
                  final pixel = statImg.getPixel(x, y);
                  int gray = (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114).toInt().clamp(0, 255);
                  sum += gray;
                  histogram[gray]++;
              }
          }
          double mean = sum / n;
          
          double sumVariance = 0;
          for (int y = 0; y < statImg.height; y++) {
              for (int x = 0; x < statImg.width; x++) {
                  final pixel = statImg.getPixel(x, y);
                  int gray = (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114).toInt();
                  sumVariance += pow(gray - mean, 2);
              }
          }
          double stdDev = sqrt(sumVariance / n);

          if (mounted) {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) {
                return Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    left: 24, right: 24, top: 24
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics, color: Colors.cyanAccent, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            "Dashboard Statistik Citra",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 16),
                      Text("Kecerahan Rata-rata (Mean): ${mean.toStringAsFixed(2)}", 
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text("Tingkat Kontras (Std. Deviasi): ${stdDev.toStringAsFixed(2)}", 
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0 || value == 64 || value == 128 || value == 192 || value == 255) {
                                      return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(256, (index) => FlSpot(index.toDouble(), histogram[index].toDouble())),
                                isCurved: false,
                                barWidth: 1.5,
                                color: Colors.cyan,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(show: true, color: Colors.cyan.withValues(alpha: 0.3)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            );
          }
      }
      return;
    }

    setState(() {
      isProcessing = true;
      selectedFilter = filterName;
    });

    await Future.delayed(const Duration(milliseconds: 50));

    try {
      if (filterName == 'Normal') {
        setState(() {
          processedImageBytes = null;
          isProcessing = false;
        });
        return;
      }

      final bytes = await File(widget.imagePath).readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) throw Exception("Failed to decode image");

      img.Image processed = img.Image.from(originalImage);

      if (['AND', 'XOR', 'Hist. Specification'].contains(filterName)) {
        if (image2Bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Pilih gambar referensi terlebih dahulu!"), backgroundColor: Colors.red),
            );
          }
          setState(() { isProcessing = false; });
          return;
        }
      }

      int v = arithmeticValue.toInt();

      if (filterName == 'Tambah') {
        for (int y = 0; y < processed.height; y++) {
          for (int x = 0; x < processed.width; x++) {
            final pixel = processed.getPixel(x, y);
            int r = (pixel.r + v).clamp(0, 255).toInt();
            int g = (pixel.g + v).clamp(0, 255).toInt();
            int b = (pixel.b + v).clamp(0, 255).toInt();
            processed.setPixelRgb(x, y, r, g, b);
          }
        }
      } else if (filterName == 'Kurang') {
        for (int y = 0; y < processed.height; y++) {
          for (int x = 0; x < processed.width; x++) {
            final pixel = processed.getPixel(x, y);
            int r = (pixel.r - v).clamp(0, 255).toInt();
            int g = (pixel.g - v).clamp(0, 255).toInt();
            int b = (pixel.b - v).clamp(0, 255).toInt();
            processed.setPixelRgb(x, y, r, g, b);
          }
        }
      } else if (filterName == 'Max') {
        for (int y = 0; y < processed.height; y++) {
          for (int x = 0; x < processed.width; x++) {
            final pixel = processed.getPixel(x, y);
            int r = max(pixel.r, v).toInt();
            int g = max(pixel.g, v).toInt();
            int b = max(pixel.b, v).toInt();
            processed.setPixelRgb(x, y, r, g, b);
          }
        }
      } else if (filterName == 'Min') {
        for (int y = 0; y < processed.height; y++) {
          for (int x = 0; x < processed.width; x++) {
            final pixel = processed.getPixel(x, y);
            int r = min(pixel.r, v).toInt();
            int g = min(pixel.g, v).toInt();
            int b = min(pixel.b, v).toInt();
            processed.setPixelRgb(x, y, r, g, b);
          }
        }
      } else if (filterName == 'Inverse' || filterName == 'NOT') {
        for (int y = 0; y < processed.height; y++) {
          for (int x = 0; x < processed.width; x++) {
            final pixel = processed.getPixel(x, y);
            processed.setPixelRgb(x, y, 255 - pixel.r.toInt(), 255 - pixel.g.toInt(), 255 - pixel.b.toInt());
          }
        }
      } else if (filterName == 'Grayscale') {
        for (int y = 0; y < processed.height; y++) {
          for (int x = 0; x < processed.width; x++) {
            final pixel = processed.getPixel(x, y);
            int gray = (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114).toInt();
            processed.setPixelRgb(x, y, gray, gray, gray);
          }
        }
      } else if (filterName == 'AND' || filterName == 'XOR') {
        img.Image refImg = img.decodeImage(image2Bytes!)!;
        img.Image resizedRef = img.copyResize(refImg, width: processed.width, height: processed.height);
        
        for (int y = 0; y < processed.height; y++) {
          for (int x = 0; x < processed.width; x++) {
            final p1 = processed.getPixel(x, y);
            final p2 = resizedRef.getPixel(x, y);
            int r, g, b;
            if (filterName == 'AND') {
               r = p1.r.toInt() & p2.r.toInt();
               g = p1.g.toInt() & p2.g.toInt();
               b = p1.b.toInt() & p2.b.toInt();
            } else {
               r = p1.r.toInt() ^ p2.r.toInt();
               g = p1.g.toInt() ^ p2.g.toInt();
               b = p1.b.toInt() ^ p2.b.toInt();
            }
            processed.setPixelRgb(x, y, r, g, b);
          }
        }
      } else if (filterName == 'Hist. Equalization') {
        int totalPixels = processed.width * processed.height;
        List<int> hist = List.filled(256, 0);
        for (int y = 0; y < processed.height; y++) {
          for (int x = 0; x < processed.width; x++) {
            final pixel = processed.getPixel(x, y);
            int gray = (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114).toInt().clamp(0, 255);
            hist[gray]++;
          }
        }

        List<int> cdf = List.filled(256, 0);
        cdf[0] = hist[0];
        for (int i = 1; i < 256; i++) {
          cdf[i] = cdf[i - 1] + hist[i];
        }

        int cdfMin = cdf.firstWhere((element) => element > 0, orElse: () => 0);

        List<int> eqMap = List.filled(256, 0);
        for (int i = 0; i < 256; i++) {
          if (totalPixels - cdfMin <= 0) {
            eqMap[i] = i;
          } else {
            eqMap[i] = (((cdf[i] - cdfMin) / (totalPixels - cdfMin)) * 255).round().clamp(0, 255);
          }
        }

        for (int y = 0; y < processed.height; y++) {
          for (int x = 0; x < processed.width; x++) {
            final pixel = processed.getPixel(x, y);
            int r = eqMap[pixel.r.toInt()];
            int g = eqMap[pixel.g.toInt()];
            int b = eqMap[pixel.b.toInt()];
            processed.setPixelRgb(x, y, r, g, b);
          }
        }
      } else if (filterName == 'Hist. Specification') {
        img.Image refImg = img.decodeImage(image2Bytes!)!;
        
        List<int> histOrig = List.filled(256, 0);
        for (int y = 0; y < processed.height; y++) {
          for (int x = 0; x < processed.width; x++) {
            final p = processed.getPixel(x, y);
            int gray = (p.r * 0.299 + p.g * 0.587 + p.b * 0.114).toInt().clamp(0, 255);
            histOrig[gray]++;
          }
        }
        
        List<int> histRef = List.filled(256, 0);
        for (int y = 0; y < refImg.height; y++) {
          for (int x = 0; x < refImg.width; x++) {
            final p = refImg.getPixel(x, y);
            int gray = (p.r * 0.299 + p.g * 0.587 + p.b * 0.114).toInt().clamp(0, 255);
            histRef[gray]++;
          }
        }
        
        List<double> cdfOrig = List.filled(256, 0.0);
        int totalOrig = processed.width * processed.height;
        num cumOrig = 0;
        for (int i=0; i<256; i++) {
           cumOrig += histOrig[i];
           cdfOrig[i] = cumOrig / totalOrig;
        }
        
        List<double> cdfRef = List.filled(256, 0.0);
        int totalRef = refImg.width * refImg.height;
        num cumRef = 0;
        for (int i=0; i<256; i++) {
           cumRef += histRef[i];
           cdfRef[i] = cumRef / totalRef;
        }

        List<int> specMap = List.filled(256, 0);
        for (int i = 0; i < 256; i++) {
           double valOrig = cdfOrig[i];
           int bestMatch = 0;
           double minDiff = double.infinity;
           for (int j = 0; j < 256; j++) {
              double diff = (valOrig - cdfRef[j]).abs();
              if (diff < minDiff) {
                 minDiff = diff;
                 bestMatch = j;
              }
           }
           specMap[i] = bestMatch;
        }

        for (int y = 0; y < processed.height; y++) {
          for (int x = 0; x < processed.width; x++) {
            final pixel = processed.getPixel(x, y);
            int r = specMap[pixel.r.toInt()];
            int g = specMap[pixel.g.toInt()];
            int b = specMap[pixel.b.toInt()];
            processed.setPixelRgb(x, y, r, g, b);
          }
        }
      }

      final newBytes = img.encodeJpg(processed);

      setState(() {
        processedImageBytes = newBytes;
        isProcessing = false;
      });
    } catch (e) {
      debugPrint("Error processing image: $e");
      setState(() {
        isProcessing = false;
      });
    }
  }

  Widget _buildFilterWrap(List<String> filters) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            alignment: WrapAlignment.center,
            children: filters.map((filter) {
              final isSelected = selectedFilter == filter;
              return ChoiceChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: Colors.cyanAccent,
                backgroundColor: Colors.grey.shade800,
                onSelected: (selected) {
                   if (!isProcessing) applyFilter(filter);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('PCD Editor', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Simpan Gambar',
              onPressed: () {
                if (!isProcessing) saveToGallery();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade400, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade600.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      processedImageBytes != null
                          ? Image.memory(
                              processedImageBytes!,
                              fit: BoxFit.contain,
                            )
                          : Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.contain,
                            ),
                      if (isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.cyanAccent),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Dynamic UI Elements (Sliders & Upload Buttons)
            if (['Tambah', 'Kurang', 'Max', 'Min'].contains(selectedFilter))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const Text('Intensitas Aritmatika:', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: arithmeticValue,
                            min: 0,
                            max: 255,
                            activeColor: Colors.cyanAccent,
                            inactiveColor: Colors.white24,
                            onChanged: (value) {
                              setState(() {
                                arithmeticValue = value;
                              });
                            },
                            onChangeEnd: (value) {
                              if (!isProcessing) applyFilter(selectedFilter);
                            },
                          ),
                        ),
                        Text(arithmeticValue.toInt().toString(), style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              
            if (['AND', 'XOR', 'Hist. Specification'].contains(selectedFilter))
               Column(
                 children: [
                   const SizedBox(height: 8),
                   if (image2Bytes != null) 
                     Padding(
                       padding: const EdgeInsets.only(bottom: 8.0),
                       child: Image.memory(image2Bytes!, height: 80, fit: BoxFit.contain),
                     ),
                   ElevatedButton.icon(
                     onPressed: pickReferenceImage,
                     icon: const Icon(Icons.add_a_photo),
                     label: const Text("Upload Gambar Kedua"),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.cyan,
                       foregroundColor: Colors.black,
                     ),
                   ),
                   const SizedBox(height: 8),
                 ],
               ),
               
            const Divider(color: Colors.white24, height: 1),
            
            // Tab Menu
            Container(
              color: Colors.grey.shade900,
              height: 180,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.cyanAccent,
                    unselectedLabelColor: Colors.white54,
                    indicatorColor: Colors.cyanAccent,
                    tabs: [
                      Tab(text: 'Aritmatika'),
                      Tab(text: 'Logika'),
                      Tab(text: 'Histogram'),
                      Tab(text: 'Analisis'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildFilterWrap(aritmatikaFilters),
                        _buildFilterWrap(logikaFilters),
                        _buildFilterWrap(histogramFilters),
                        _buildFilterWrap(statistikFilters),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
