# 📔 Secure Cloud Logbook App - Modul 4

Aplikasi Logbook digital berbasis Flutter yang terintegrasi dengan **MongoDB Atlas Cloud Database**. Proyek ini merupakan evolusi dari Modul 3, dengan fokus utama pada keamanan data, arsitektur asinkron, dan manajemen infrastruktur cloud yang profesional.

## 👤 Identitas Mahasiswa
- [cite_start]**Nama** : Qlio Amanda Febriany [cite: 3]
- [cite_start]**NIM** : 241511087 [cite: 3]
- [cite_start]**Kelas** : 2C - D3 Teknik Informatika [cite: 3]

## 🚀 Fitur Utama
- [cite_start]**Cloud Persistence**: Data tersimpan secara permanen dan terpusat di MongoDB Atlas[cite: 48, 83].
- [cite_start]**Privacy Isolation**: Setiap user (admin, qlio, dosen) hanya dapat melihat dan mengelola catatan miliknya sendiri berdasarkan field `author`[cite: 372].
- [cite_start]**Connection Guard**: Penanganan cerdas saat perangkat offline dengan pesan error yang ramah (Homework Task)[cite: 315, 421].
- [cite_start]**Professional Logging**: Sistem audit trail yang dapat dikendalikan level sensitivitasnya melalui konfigurasi khusus[cite: 236, 345].
- [cite_start]**Reactive UI**: Antarmuka responsif yang menangani status loading dan refresh otomatis[cite: 315, 318].

## 🛠️ Arsitektur & Teknologi
- [cite_start]**Flutter & Dart**: Frontend framework[cite: 49].
- [cite_start]**MongoDB Atlas**: Database as a Service (DBaaS)[cite: 48, 105].
- [cite_start]**mongo_dart**: Driver SDK untuk koneksi langsung ke cloud[cite: 61, 214].
- [cite_start]**flutter_dotenv**: Manajemen variabel lingkungan untuk keamanan kredensial[cite: 216].
- [cite_start]**Singleton Pattern**: Memastikan hanya satu instansi koneksi database yang aktif (MongoService)[cite: 290, 346].

## [cite_start]🧠 Lesson Learnt (Refleksi Akhir) [cite: 41, 451]

Berdasarkan proses pengembangan Modul 4, berikut adalah poin-poin pembelajaran utama:

### 1. Tantangan Koneksi Infrastruktur Cloud
[cite_start]Bagian yang paling menantang adalah melakukan inisialisasi awal koneksi ke MongoDB Atlas[cite: 430]. [cite_start]Saya belajar bahwa keamanan Cloud sangat ketat; akses akan diblokir total jika **IP Whitelist (0.0.0.0/0)** belum aktif atau jika **Database User** tidak memiliki hak akses *readWrite*[cite: 180, 190, 325]. [cite_start]Memahami alur kerja *Direct Driver* memberikan pemahaman baru tentang efisiensi komunikasi data tanpa perantara Backend tambahan[cite: 62, 172].

### 2. Pentingnya Credential Safety (DIP)
[cite_start]Saya menyadari bahaya besar melakukan *hardcoding* Connection String di dalam kode Dart[cite: 220, 386]. [cite_start]Melalui penggunaan file konfigurasi eksternal, saya belajar menerapkan prinsip *Dependency Inversion* (DIP), di mana konfigurasi sensitif disuntikkan dari luar[cite: 254, 258]. [cite_start]Ini memastikan bahwa meskipun kode dibagikan ke repositori publik, rahasia database tetap aman karena file kredensial tidak ikut terunggah[cite: 68, 69].

### 3. Manajemen State Asinkron dan User Experience (UX)
[cite_start]Berpindah dari data lokal yang instan ke data internet yang memiliki latensi (jeda) memaksa saya untuk lebih mahir menggunakan **Future**, **async**, dan **await**[cite: 10, 73, 307]. [cite_start]Saya belajar bahwa UX yang baik wajib menyertakan *Loading Indicator* agar pengguna tidak mengira aplikasi rusak saat menunggu respon server[cite: 307, 309]. [cite_start]Selain itu, menangani error tampilan menggunakan widget penyesuai pada data dinamis adalah kemenangan kecil yang sangat berguna untuk menjaga estetika UI[cite: 316, 453].

---
[cite_start]*Proyek ini disusun untuk memenuhi tugas praktikum Proyek 4 - Modul 4.* [cite: 1]