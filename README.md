# 👁️ PCD Editor & Collaborative Logbook - Tugas ETS

Aplikasi ini merupakan gabungan antara sistem pencatatan berbasis *Offline-First* dan **Mesin Pengolahan Citra Digital (PCD)** mandiri. Modul Vision pada aplikasi ini dibangun untuk memanipulasi piksel gambar secara matematis murni dari nol (menggunakan `Uint8List`), tanpa bergantung pada *wrapper* instan seperti OpenCV.

---

## 👤 Identitas Mahasiswa

**Nama** : Qlio Amanda Febriany  
**NIM** : 241511087  
**Kelas** : 2C - D3 Teknik Informatika  

---

## 🚀 Fitur Unggulan (PCD ETS Edition)

### 1. Zero-Dependency Image Processing (Manual Array)
Seluruh operasi gambar dieksekusi secara manual dengan membedah *channel* warna (RGB). Ini membuktikan pemahaman fundamental terhadap struktur matriks gambar digital.

### 2. Multi-Domain Filtering (Spasial & Frekuensi)
- **Domain Spasial:** Implementasi algoritma konvolusi manual matriks 3x3 (*Average, Sharpen, Edge Detection*) dan *Zero Padding*.
- **Domain Frekuensi:** Menerapkan *2D Separable Fast Fourier Transform* (FFT) dan *Inverse FFT* untuk memfilter gelombang gambar (*Low Pass, High Pass, Band Pass*, *Reduce Periodic Noise*).

### 3. Operasi Logika & Histogram Lanjutan
Mendukung manipulasi satu citra (Aritmatika, Unary/NOT, Grayscale) dan dua citra (AND, XOR, Histogram Specification). Dilengkapi algoritma CDF manual untuk *Histogram Equalization*.

### 4. Isolate Multithreading (Anti-Lag Architecture)
Kalkulasi jutaan iterasi piksel (terutama saat Konvolusi dan FFT) diisolasi menggunakan *Background Thread* (`compute`), memastikan antarmuka aplikasi (*UI*) tetap berjalan mulus di angka 60 FPS tanpa *freeze*.

### 5. Dashboard Analisis Visual
Menyediakan fitur hitung statistik (Mean & Standar Deviasi) yang direpresentasikan melalui *Line Chart* kurva distribusi yang profesional di dalam *Bottom Sheet*.

---

## 🛠️ Stack Teknologi

- **Flutter & Dart** — *Core framework* aplikasi.
- **image (`^4.1.7`)** — Untuk *decoding* format JPEG/PNG menjadi byte array mentah.
- **fftea (`^0.2.6`)** — Pustaka matematika *Pure Dart* untuk perhitungan kompleks algoritma FFT 1D.
- **fl_chart (`^0.68.0`)** — Rendering grafik histogram.
- **image_picker & gal** — Manajemen *I/O* kamera dan penyimpanan langsung ke galeri Android/iOS.
- *(Fitur Logbook tetap didukung oleh Hive & MongoDB Atlas).*

---

## 🧠 Lesson Learnt (Refleksi Proyek ETS PCD)

### 1. OpenCV vs Fundamental Mathematics
Saya belajar bahwa *library* seperti OpenCV menyembunyikan banyak kompleksitas matematis. Dengan memprogram algoritma operasi Logika dan *Histogram Equalization* secara manual, saya memahami bagaimana *Cumulative Distribution Function* (CDF) secara nyata meratakan intensitas warna pada piksel gelap dan terang.

### 2. Manajemen Memori & Kinerja (The Spatial Challenge)
Tantangan terberat adalah mengeksekusi operasi spasial (Konvolusi 3x3) pada gambar beresolusi tinggi yang diambil dari kamera gawai modern. Saya belajar bahwa selain menggunakan `Isolate` untuk memindahkan beban komputasi ke *thread* latar belakang, membatasi resolusi (*dynamic resizing*) secara rasional adalah kunci agar aplikasi *mobile* tidak mengalami *Out of Memory* (OOM).

### 3. Keajaiban Domain Frekuensi (Fourier Transform)
Membangun fitur FFT dan IFFT secara manual mengajarkan saya pendekatan *Separable Transform* (menghitung baris demi baris, lalu kolom demi kolom). Saya menyadari betapa kuatnya memanipulasi gambar tidak dari bentuk visualnya, melainkan dari "gelombang sinyalnya" untuk menghapus *noise* secara spesifik melalui teknik *masking*.

---

## ⚙️ Petunjuk Instalasi & Menjalankan Aplikasi

1. Kloning repositori ini.
2. Buka terminal di dalam *root* folder proyek.
3. Jalankan perintah untuk mengunduh semua dependensi:
   ```bash
   flutter pub get
   ```
4. Hubungkan device Android/iOS fisik (disarankan untuk performa kamera yang maksimal) atau emulator.
5. Jalankan aplikasi:
   ```bash
   flutter run
   ```