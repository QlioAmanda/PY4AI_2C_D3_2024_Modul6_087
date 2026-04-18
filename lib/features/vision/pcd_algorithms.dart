import 'dart:typed_data';
import 'dart:math';
import 'package:image/image.dart' as img;

/// [applyManualEdgeDetection] menerapkan filter Edge Detection dengan pendekatan
/// perulangan matematis manual mutlak menggunakan operator matik konvolusi Sobel
/// ke setiap piksel ketetanggaan (3x3). Dioptimalkan menggunakan isolate background
/// jika dipanggil secara asinkronus ke depannya.
Future<Uint8List> applyManualEdgeDetection(Uint8List imageBytes) async {
  // 1. Decode Image dari bytes (dari memori kamera)
  final image = img.decodeImage(imageBytes);
  if (image == null) return imageBytes;

  final int width = image.width;
  final int height = image.height;
  
  // 2. Siapkan output image kosong dengan ukuran yang sama (3 channels RGB)
  final output = img.Image(width: width, height: height, numChannels: 3);

  // Kernel Sobel Horisontal (Gx)
  final gx = [
    [-1,  0,  1],
    [-2,  0,  2],
    [-1,  0,  1],
  ];

  // Kernel Sobel Vertikal (Gy)
  final gy = [
    [-1, -2, -1],
    [ 0,  0,  0],
    [ 1,  2,  1],
  ];

  // 3. Iterasi pixel per pixel (Melewati border 1px untuk mencegah Out-of-Bounds ketetanggaan)
  for (int y = 1; y < height - 1; y++) {
    for (int x = 1; x < width - 1; x++) {
      num sumX = 0;
      num sumY = 0;

      // Konvolusi menggunakan Matrix 3x3 
      for (int ky = -1; ky <= 1; ky++) {
        for (int kx = -1; kx <= 1; kx++) {
          // Ambil tetangga pixel
          final pixel = image.getPixel(x + kx, y + ky);
          
          // Konversikan langsung nilai RGB tetangga ke Grayscale Luma untuk Edge Detection
          final luma = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;

          // Kalikan dengan matrix X dan Y
          sumX += luma * gx[ky + 1][kx + 1];
          sumY += luma * gy[ky + 1][kx + 1];
        }
      }

      // 4. Kalkulasi Magnitudo/Gabungan vektor (akar dari penjumlahan kuadrat x dan y)
      final magnitude = sqrt((sumX * sumX) + (sumY * sumY)).toInt();
      
      // Amankan agar rentang piksel tetap di koridor warna 8-bit (0-255)
      final clampedMag = magnitude.clamp(0, 255);

      // Sketsa ke gambar hasil dengan model hitam-putih
      output.setPixelRgb(x, y, clampedMag, clampedMag, clampedMag);
    }
  }

  // 5. Encod ulang gambar hasil pengolahan bersih (tanpa metadata korup) ke JPG byte array
  return Uint8List.fromList(img.encodeJpg(output));
}
