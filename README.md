# 📝 Note-Taking App — Flutter

Aplikasi catatan sederhana berbasis Flutter yang mendukung teks dan lampiran gambar, dengan penyimpanan lokal menggunakan sistem file perangkat.

---

## Fitur Utama

- **Buat & edit catatan** — judul dan isi teks bebas
- **Lampiran gambar** — hingga 3 gambar per catatan (dari galeri), dikompres otomatis
- **Penyimpanan lokal** — data tersimpan di direktori dokumen aplikasi, tanpa database eksternal
- **Daftar catatan** — diurutkan dari yang terbaru, lengkap dengan tanggal modifikasi dan pratinjau isi
- **Hapus catatan** — menghapus catatan beserta seluruh gambar lampirannya

---

## Struktur Proyek

```
lib/
├── main.dart                  # Entry point aplikasi
├── models/
│   └── note.dart              # Model data catatan
├── helpers/
│   └── file_helper.dart       # Logika baca/tulis file & gambar
└── screens/
    ├── note_list_screen.dart  # Layar daftar catatan
    └── note_editor_screen.dart# Layar buat & edit catatan
```

---

## Format Penyimpanan File

Setiap catatan disimpan sebagai sebuah direktori di dalam folder `notes/` pada direktori dokumen aplikasi:

```
<app_documents>/
└── notes/
    └── note_<timestamp>/
        ├── content.txt     # Baris 1: judul | Baris 2: lastModified (ISO 8601) | Baris 3+: isi
        ├── image_1.jpg     # Gambar slot 1 (opsional)
        ├── image_2.jpg     # Gambar slot 2 (opsional)
        └── image_3.jpg     # Gambar slot 3 (opsional)
```

---

## Dependencies

Tambahkan dependensi berikut ke `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  path_provider: ^2.1.0
  path: ^1.9.0
  image_picker: ^1.0.0
  flutter_image_compress: ^2.1.0
```

---

## Instalasi & Menjalankan Aplikasi

1. **Clone repositori**
   ```bash
   git clone <url-repositori>
   cd <nama-folder>
   ```

2. **Install dependensi**
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi**
   ```bash
   flutter run
   ```

> Pastikan emulator/device sudah terhubung dan Flutter SDK sudah terinstall.

---

## Konfigurasi Platform

### Android

Tambahkan izin berikut di `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<!-- Untuk Android < 13 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

### iOS

Tambahkan key berikut di `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Aplikasi membutuhkan akses galeri untuk melampirkan gambar ke catatan.</string>
```

---

## Cara Penggunaan

| Aksi | Cara |
|---|---|
| Buat catatan baru | Tekan tombol **+** di pojok kanan bawah |
| Edit catatan | Ketuk salah satu catatan di daftar |
| Tambah gambar | Di editor, tekan **Tambah Gambar** (maks. 3) |
| Hapus gambar | Tekan ikon **×** di sudut gambar |
| Simpan catatan | Tekan ikon **💾** di app bar |
| Hapus catatan | Tekan ikon 🗑️ di daftar, lalu konfirmasi |

---

## Catatan Teknis

- Gambar dikompres ke kualitas JPEG 70% dengan resolusi minimal 1080×1080 px sebelum disimpan.
- ID catatan dibuat dari timestamp (`note_<millisecondsSinceEpoch>`), sehingga urutan kronologis terjaga.
- Slot gambar bersifat independen — menghapus gambar di slot tertentu tidak menggeser slot lainnya.

---

## Lisensi

Proyek ini bersifat open source. Silakan gunakan dan modifikasi sesuai kebutuhan.
