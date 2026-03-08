# System Requirements untuk Menjalankan / Meng-compile Klik Agen

Aplikasi Klik Agen dirancang secara *native* sebagai aplikasi desktop dengan framework Flutter yang efisien di atas ekosistem Windows. Berikut adalah spesifikasi minimum dan perangkat lunak yang disarankan:

## Kebutuhan Pengguna Akhir (Running the App)

Untuk **menggunakan** Klik Agen setelah aplikasi dalam format `.msix` terinstal:

- **Sistem Operasi**: Windows 10 (versi 1809 atau lebih baru) / Windows 11 (arsitektur 64-bit / x64 disarankan).
  - *Catatan: Windows 7, 8, atau 8.1 secara resmi tidak lagi didukung oleh Microsoft maupun mesin grafis Flutter.*
- **Prosesor**: Intel Core i3 / AMD Ryzen 3 atau yang setara (Dual-core 2.0 GHz ke atas).
- **RAM**: Minimal 4 GB. Agar multitasking dengan software Windows lain lebih lancar, direkomendasikan 8 GB ke atas.
- **Ruang Penyimpanan (Storage)**: Minimal 200 MB sisa ruang kosong pada C:\. Idealnya Solid State Drive (SSD) agar kecepatan perpindahan aplikasi dan akses *database* SQLite optimal.
- **Layar (Display)**: Resolusi layar minimum 1366x768 yang umumnya ada di laptop standar.

---

## Kebutuhan Pengembang (Development)

Jika Anda ingin menyesuaikan (*compile*/*build*) kode sumber ini, Anda membutuhkan alat-alat pengembangan (SDKs) berikut yang terinstal di komputer Windows Anda:

- **Git for Windows:** (https://gitforwindows.org/) untuk *version control*.
- **Flutter SDK:** minimal berspesifikasi SDK `^3.12.0-14.0.dev` / kanal `stable` yang relevan.
- **Dart SDK:** secara otomatis di-bundle dalam Flutter versi di atas.
- **IDE / Text Editor**: Visual Studio Code, Android Studio, atau IntelliJ IDEA yang memiliki ekstensi/plugin untuk standar *Dart/Flutter*.
- **Visual Studio Build Tools untuk Desktop C++:**
  1. Unduh [Visual Studio Installer](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022).
  2. Klik instal fitur bernama `Desktop development with C++` yang meliputi konfigurasi compiler MSVC, Windows 10/11 SDK, dan CMake agar engine *desktop* Flutter dapat berhasil dibangun dalam mesin OS Anda.

### Perintah Pembangun Installer Windows Standar
Bagi developer yang sudah menyelesaikan integrasi / perbaikan fitur:
```powershell
flutter clean
flutter pub get
flutter build windows

# Menghasilkan installer / bundel .msix (Menggunakan plugin `msix`)
dart run msix:create
```

*Installer yang sudah dihasilkan (*`.msix`*) tersedia pada folder:*
`build/windows/x64/runner/Release/klik_agen.msix`.
