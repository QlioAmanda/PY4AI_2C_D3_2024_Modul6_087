import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

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

  Future<void> applyFilter(String filterName) async {
    setState(() {
      isProcessing = true;
      selectedFilter = filterName;
    });

    // Run asynchronously to allow UI to show loading indicator
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

      if (filterName == 'Grayscale') {
        for (int y = 0; y < processed.height; y++) {
          for (int x = 0; x < processed.width; x++) {
            final pixel = processed.getPixel(x, y);
            final r = pixel.r;
            final g = pixel.g;
            final b = pixel.b;
            int gray = (r * 0.299 + g * 0.587 + b * 0.114).toInt();
            processed.setPixelRgb(x, y, gray, gray, gray);
          }
        }
      } else if (filterName == 'Inverse (Negatif)') {
        for (int y = 0; y < processed.height; y++) {
          for (int x = 0; x < processed.width; x++) {
            final pixel = processed.getPixel(x, y);
            final r = 255 - pixel.r;
            final g = 255 - pixel.g;
            final b = 255 - pixel.b;
            processed.setPixelRgba(x, y, r, g, b, pixel.a);
          }
        }
      } else if (filterName == 'Thresholding') {
        for (int y = 0; y < processed.height; y++) {
          for (int x = 0; x < processed.width; x++) {
            final pixel = processed.getPixel(x, y);
            final r = pixel.r;
            final g = pixel.g;
            final b = pixel.b;
            int gray = (r * 0.299 + g * 0.587 + b * 0.114).toInt();
            int bin = gray > 128 ? 255 : 0;
            processed.setPixelRgb(x, y, bin, bin, bin);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('PCD Editor', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
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
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey.shade900,
        height: 140,
        child: SingleChildScrollView(
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8.0,
              runSpacing: 8.0,
              children: widget.fullFilters.map((filter) => _buildFilterChip(filter)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterName) {
    final isSelected = selectedFilter == filterName;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: ChoiceChip(
        label: Text(
          filterName,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: Colors.cyanAccent,
        backgroundColor: Colors.grey.shade800,
        onSelected: (selected) {
          if (selected && !isProcessing) {
            applyFilter(filterName);
          }
        },
      ),
    );
  }
}
