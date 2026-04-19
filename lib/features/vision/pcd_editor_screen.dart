import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fftea/fftea.dart';

// Top-Level Function untuk Multithreading (Isolate)
Future<dynamic> _processImageInBackground(Map<String, dynamic> data) async {
  String filterName = data['filterName'];
  Uint8List imageBytes = data['imageBytes'];
  Uint8List? image2Bytes = data['image2Bytes'];
  int v = data['arithmeticValue'];

  if (filterName == 'Normal') return null;

  img.Image? originalImage = img.decodeImage(imageBytes);
  if (originalImage == null) throw Exception("Failed to decode image");

  // Optimasi ukuran gambar agar konvolusi tidak nge-lag berlebihan 
  // (Lebih baik menahan Max 1024 supaya CPU tak terbakar di mobile devices)
  img.Image processed = originalImage;
  if (processed.width > 1024 || processed.height > 1024) {
    processed = img.copyResize(processed, width: 1024);
  }

  if (filterName == 'Hitung Statistik') {
    double sum = 0;
    int n = processed.width * processed.height;
    List<int> histogram = List.filled(256, 0);
    for (int y = 0; y < processed.height; y++) {
      for (int x = 0; x < processed.width; x++) {
        final pixel = processed.getPixel(x, y);
        int gray = (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114).toInt().clamp(0, 255);
        sum += gray;
        histogram[gray]++;
      }
    }
    double mean = sum / n;

    double sumVariance = 0;
    for (int y = 0; y < processed.height; y++) {
      for (int x = 0; x < processed.width; x++) {
        final pixel = processed.getPixel(x, y);
        int gray = (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114).toInt().clamp(0, 255);
        sumVariance += pow(gray - mean, 2);
      }
    }
    double stdDev = sqrt(sumVariance / n);

    return {
      'type': 'stats',
      'mean': mean,
      'stdDev': stdDev,
      'histogram': histogram
    };
  }

  // --- Operasi Aritmatika ---
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
        int gray = (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114).toInt().clamp(0, 255);
        processed.setPixelRgb(x, y, gray, gray, gray);
      }
    }
  } 
  
  // --- Operasi Logika Milti-Gambar ---
  else if (filterName == 'AND' || filterName == 'XOR') {
    if (image2Bytes != null) {
      img.Image refImg = img.decodeImage(image2Bytes)!;
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
    }
  } 
  
  // --- Operasi Histogram ---
  else if (filterName == 'Hist. Equalization') {
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
    if (image2Bytes != null) {
      img.Image refImg = img.decodeImage(image2Bytes)!;
      
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
  } 
  
  // --- Operasi Spasial ---
  else if (filterName == 'Zero Padding') {
    int p = v; // Menggunakan arithmeticValue untuk ketebalan padding
    img.Image padded = img.Image(width: processed.width + 2 * p, height: processed.height + 2 * p);
    for (int y = 0; y < processed.height; y++) {
      for (int x = 0; x < processed.width; x++) {
        padded.setPixel(x + p, y + p, processed.getPixel(x, y));
      }
    }
    processed = padded;
  } else if (filterName.startsWith('Conv:')) {
    List<List<double>> kernel;
    if (filterName == 'Conv: Average') {
        kernel = [
            [1/9, 1/9, 1/9],
            [1/9, 1/9, 1/9],
            [1/9, 1/9, 1/9],
        ];
    } else if (filterName == 'Conv: Sharpen') {
        kernel = [
            [ 0, -1,  0],
            [-1,  5, -1],
            [ 0, -1,  0],
        ];
    } else /* Conv: Edge */ {
        kernel = [
            [-1, -1, -1],
            [-1,  8, -1],
            [-1, -1, -1],
        ];
    }

    // Hindari modifikasi sepihak dalam loop ketetanggaan 
    img.Image newImg = img.Image.from(processed);
    int w = processed.width;
    int h = processed.height;

    // Abaikan 1 pixel terluar untuk antisipasi OutOfBounds Array Matriks 3x3
    for (int y = 1; y < h - 1; y++) {
        for (int x = 1; x < w - 1; x++) {
            double sumR = 0.0;
            double sumG = 0.0;
            double sumB = 0.0;

            for (int ky = -1; ky <= 1; ky++) {
                for (int kx = -1; kx <= 1; kx++) {
                    final p = processed.getPixel(x + kx, y + ky);
                    double weight = kernel[ky + 1][kx + 1];
                    sumR += p.r * weight;
                    sumG += p.g * weight;
                    sumB += p.b * weight;
                }
            }

            int nr = sumR.round().clamp(0, 255);
            int ng = sumG.round().clamp(0, 255);
            int nb = sumB.round().clamp(0, 255);
            
            newImg.setPixelRgb(x, y, nr, ng, nb);
        }
    }
    processed = newImg;
  } else if (filterName == 'Fourier Transform') {
    int size = 128;
    img.Image resized = img.copyResize(processed, width: size, height: size);
    
    List<Float64x2List> matrix = List.generate(size, (y) {
      Float64x2List row = Float64x2List(size);
      for (int x = 0; x < size; x++) {
        final pixel = resized.getPixel(x, y);
        double gray = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114;
        row[x] = Float64x2(gray, 0.0);
      }
      return row;
    });

    final fft = FFT(size);

    for (int y = 0; y < size; y++) {
      fft.inPlaceFft(matrix[y]);
    }

    for (int x = 0; x < size; x++) {
      Float64x2List col = Float64x2List(size);
      for (int y = 0; y < size; y++) col[y] = matrix[y][x];
      fft.inPlaceFft(col);
      for (int y = 0; y < size; y++) matrix[y][x] = col[y];
    }

    List<List<double>> magMap = List.generate(size, (_) => List.filled(size, 0.0));
    double maxMag = 0.0;

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        int shiftX = (x + size ~/ 2) % size;
        int shiftY = (y + size ~/ 2) % size;
        double real = matrix[y][x].x;
        double imag = matrix[y][x].y;
        double mag = sqrt(real * real + imag * imag);
        magMap[shiftY][shiftX] = mag;
        if (mag > maxMag) maxMag = mag;
      }
    }

    double c = 255.0 / log(1 + maxMag);
    img.Image fourierImg = img.Image(width: size, height: size);
    
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        int vLog = (c * log(1 + magMap[y][x])).round().clamp(0, 255);
        fourierImg.setPixelRgb(x, y, vLog, vLog, vLog);
      }
    }
    processed = img.copyResize(fourierImg, width: processed.width, height: processed.height);
  }
  
  // --- Operasi Frekuensi Domain (Inverse FFT) ---
  else if (['Low Pass', 'High Pass', 'Band Pass', 'Reduce Periodic Noise'].contains(filterName)) {
    int size = 128; // Pakai 128 agar performa komputasi HP aman
    img.Image resized = img.copyResize(processed, width: size, height: size);
    
    // 1. Dekomposisi ke Bilangan Kompleks
    List<Float64x2List> matrix = List.generate(size, (y) {
      Float64x2List row = Float64x2List(size);
      for (int x = 0; x < size; x++) {
        final pixel = resized.getPixel(x, y);
        double gray = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114;
        row[x] = Float64x2(gray, 0.0);
      }
      return row;
    });

    final fft = FFT(size);

    // 2. FORWARD FFT (Ubah ke Frequency Domain)
    for (int y = 0; y < size; y++) fft.inPlaceFft(matrix[y]);
    for (int x = 0; x < size; x++) {
      Float64x2List col = Float64x2List(size);
      for (int y = 0; y < size; y++) col[y] = matrix[y][x];
      fft.inPlaceFft(col);
      for (int y = 0; y < size; y++) matrix[y][x] = col[y];
    }

    // 3. TERAPKAN MASKING (Saringan Frekuensi)
    double rLow = 0;
    double rHigh = 9999;
    bool isBandStop = false;

    if (filterName == 'Low Pass') { rHigh = 25; } // Cuma loloskan pusat
    else if (filterName == 'High Pass') { rLow = 15; } // Blokir pusat (DC)
    else if (filterName == 'Band Pass') { rLow = 10; rHigh = 35; } // Ambil bentuk cincin
    else if (filterName == 'Reduce Periodic Noise') { isBandStop = true; rLow = 28; rHigh = 32; } // Blokir radius ~30

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        int cx = x - (size ~/ 2);
        int cy = y - (size ~/ 2);
        double dist = sqrt(cx * cx + cy * cy);
        
        // Cari letak koordinat aslinya di memori matriks
        int origX = (x + size ~/ 2) % size;
        int origY = (y + size ~/ 2) % size;

        // Hapus spektrum cahaya sesuai mode filter
        if (isBandStop) {
           if (dist >= rLow && dist <= rHigh) {
              matrix[origY][origX] = Float64x2(0.0, 0.0); 
           }
        } else {
           if (dist < rLow || dist > rHigh) {
              matrix[origY][origX] = Float64x2(0.0, 0.0); 
           }
        }
      }
    }

    // 4. INVERSE FFT (Kembalikan ke Gambar Asli dengan taktik Konjugat)
    // Baris
    for (int y = 0; y < size; y++) {
      for (int x=0; x<size; x++) matrix[y][x] = Float64x2(matrix[y][x].x, -matrix[y][x].y); 
      fft.inPlaceFft(matrix[y]);
      for (int x=0; x<size; x++) matrix[y][x] = Float64x2(matrix[y][x].x, -matrix[y][x].y); 
    }
    // Kolom
    for (int x = 0; x < size; x++) {
      Float64x2List col = Float64x2List(size);
      for (int y = 0; y < size; y++) col[y] = Float64x2(matrix[y][x].x, -matrix[y][x].y); 
      fft.inPlaceFft(col);
      for (int y = 0; y < size; y++) matrix[y][x] = Float64x2(col[y].x, -col[y].y); 
    }

    // 5. Render Hasil Akhir ke Grayscale
    img.Image outputImg = img.Image(width: size, height: size);
    double maxVal = 0.0;
    
    // Cari nilai maksimum dari magnitudo (dibagi dimensi matriks)
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        double val = matrix[y][x].x / (size * size); 
        if (val > maxVal) maxVal = val;
      }
    }

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        double val = matrix[y][x].x / (size * size);
        int v = ((val / maxVal) * 255).round().clamp(0, 255);
        outputImg.setPixelRgb(x, y, v, v, v);
      }
    }

    // Perbesar ukurannya agar proporsional dengan layar seperti sebelumnya
    processed = img.copyResize(outputImg, width: processed.width, height: processed.height);
  }

  return img.encodeJpg(processed);
}



// === KELAS UTAMA STATEFUL WIDGET ===
class PcdEditorScreen extends StatefulWidget {
  final String imagePath;
  final List<String> fullFilters;
  final VoidCallback? onBackToCamera;

  const PcdEditorScreen({super.key, required this.imagePath, required this.fullFilters, this.onBackToCamera});

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
  static const List<String> spasialFilters = ['Zero Padding', 'Conv: Average', 'Conv: Sharpen', 'Conv: Edge', 'Fourier Transform'];
  static const List<String> statistikFilters = ['Hitung Statistik'];
  static const List<String> frekuensiFilters = ['Low Pass', 'High Pass', 'Band Pass', 'Reduce Periodic Noise'];

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
    setState(() {
      isProcessing = true;
      selectedFilter = filterName;
    });

    try {
      if (['AND', 'XOR', 'Hist. Specification'].contains(filterName) && image2Bytes == null) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Pilih gambar referensi terlebih dahulu!"), backgroundColor: Colors.red),
            );
         }
         setState(() { isProcessing = false; });
         return;
      }
      
      final bytes = await File(widget.imagePath).readAsBytes();

      // Mendelegasikan komputasi Array Image ke Thread Background lewat Fungsi Top-Level
      final result = await compute(_processImageInBackground, {
          'filterName': filterName,
          'imageBytes': bytes,
          'image2Bytes': image2Bytes,
          'arithmeticValue': arithmeticValue.toInt(),
      });

      if (result == null) {
          // Fallback UI Reset to Normal
          setState(() {
            processedImageBytes = null;
            isProcessing = false;
          });
          return;
      }

      if (filterName == 'Hitung Statistik') {
          setState(() { isProcessing = false; });
          
          if (mounted) {
             final stats = result as Map<String, dynamic>;
             final double mean = stats['mean'];
             final double stdDev = stats['stdDev'];
             final List<int> histogram = stats['histogram'];
             
             _showStatDialog(mean, stdDev, histogram);
          }
          return;
      }

      // Final state untuk update gambar berfilter standard & spasial
      setState(() {
        processedImageBytes = result as Uint8List;
        isProcessing = false;
      });
      
    } catch (e) {
      debugPrint("Error processing image: $e");
      setState(() {
        isProcessing = false;
      });
    }
  }
  
  void _showStatDialog(double mean, double stdDev, List<int> histogram) {
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
    // 1. KITA CEK DULU: Apakah gambarnya kosong?
    bool isImageEmpty = widget.imagePath.isEmpty;

    // 2. JIKA KOSONG: Tampilkan layar "Pintu Gerbang" (Empty State)
    if (isImageEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('PCD Editor', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (widget.onBackToCamera != null) {
                widget.onBackToCamera!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_search, size: 100, color: Colors.cyan.withOpacity(0.5)),
              const SizedBox(height: 20),
              const Text(
                "Belum ada gambar yang dipilih.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text("Silahkan ambil gambar terlebih dahulu"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  if (widget.onBackToCamera != null) {
                    widget.onBackToCamera!();
                  } else {
                    Navigator.pop(context); 
                  }
                },
              )
            ],
          ),
        ),
      );
    }
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('PCD Editor', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (widget.onBackToCamera != null) {
                widget.onBackToCamera!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
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
              child: Center( 
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
                          Positioned.fill( // Memastikan loading overlay tidak keluar dari bingkai
                            child: Container(
                              color: Colors.black54,
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.cyanAccent),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Dynamic UI Elements (Sliders & Upload Buttons)
            if (['Tambah', 'Kurang', 'Max', 'Min', 'Zero Padding'].contains(selectedFilter))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Text(selectedFilter == 'Zero Padding' ? 'Ketebalan Padding (0-100):' : 'Intensitas Aritmatika:', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: arithmeticValue.clamp(0.0, selectedFilter == 'Zero Padding' ? 100.0 : 255.0),
                            min: 0.0,
                            max: selectedFilter == 'Zero Padding' ? 100.0 : 255.0,
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
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'Aritmatika'),
                      Tab(text: 'Logika'),
                      Tab(text: 'Histogram'),
                      Tab(text: 'Spasial'),
                      Tab(text: 'Analisis'),
                      Tab(text: 'Frekuensi'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildFilterWrap(aritmatikaFilters),
                        _buildFilterWrap(logikaFilters),
                        _buildFilterWrap(histogramFilters),
                        _buildFilterWrap(spasialFilters),
                        _buildFilterWrap(statistikFilters),
                        _buildFilterWrap(frekuensiFilters),
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
