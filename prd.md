# 📄 Project Requirements Document (PRD)

## Aplikasi: BRILink Pro Desktop (Owner Edition)

**Versi Dokumen:** 1.1 (Updated)  
**Platform:** Windows Desktop (Flutter + SQLite)  
**Target Pengguna:** Single Owner Operator (Tanpa Karyawan) - Kini dengan fungsionalitas Manajemen Akses Dasar (Admin & Kasir)

---

## 1. Visi & Objektif Produk
Menciptakan sistem kasir (POS) offline-first yang dirancang khusus untuk operasional Agen BRILink mandiri. Fokus utama aplikasi adalah **kecepatan transaksi ekstrim** (mengandalkan keyboard), **sinkronisasi dua pintu uang** (Tunai & Digital), serta **automasi perhitungan laba dan biaya operasional** agar mendapatkan angka Laba Bersih yang 100% akurat. 

---

## 2. Prinsip Desain (Core Philosophy)
1. **Keyboard-First:** Mouse memperlambat transaksi. Seluruh alur kasir harus bisa diselesaikan dengan *Tab*, *Arrow Keys*, dan *Enter* dalam waktu kurang dari 5 detik.
2. **Paperless (Tanpa Struk):** Menghilangkan fitur cetak struk fisik untuk memangkas waktu tunggu dan biaya kertas. Konfirmasi transaksi murni via layar (Visual Confirmation).
3. **Zero-Leakage:** Setiap pergerakan uang (transaksi, piutang, pengeluaran, penyesuaian modal) terhubung langsung dengan posisi saldo tunai (laci) dan digital (bank).
4. **Modern UI/UX:** Mengusung antarmuka yang bersih, profesional, dan responsif dengan dukungan Light dan Dark Theme untuk fleksibilitas kenyamanan pengguna.

---

## 3. Arsitektur Saldo (Dual Wallet System)
Aplikasi beroperasi di atas logika akuntansi multi-wadah dengan 2 kategori utama:
- **Saldo Digital (Bank):** Representasi uang elektronik. Mendukung banyak rekening secara dinamis (BRI, Mandiri, BCA, dll).
- **Saldo Tunai (Laci):** Representasi uang kertas/koin fisik di laci kasir Anda (Hanya ada satu laci utama).

---

## 4. Kebutuhan Fungsional (Functional Requirements)

### 4.1. Modul Kasir Utama (F1)
- **Automasi Biaya Admin:**
  - **Admin Bank:** Terisi otomatis saat 'Jenis Layanan' dipilih (referensi dari Master Data Layanan).
  - **Admin Pelanggan:** Terisi otomatis saat 'Nominal' diinput (referensi dari Master Range Nominal).
- **Logika Mode Transaksi:**
  - **Transfer:** Default menggunakan logika "Admin Luar" (Terima total cash = Nominal + Admin).
  - **Tarik Tunai:** Menampilkan opsi "Admin Dalam" (potong langsung dari uang yang diserahkan) atau "Admin Luar" (pelanggan bayar admin terpisah). Default = Admin Luar.
- **Validasi Cerdas:** Sistem menolak penyimpanan dan memberi peringatan visual jika Saldo Digital tidak mencukupi untuk transaksi Transfer.
- **Manajemen Riwayat:** Fitur langsung pada halaman Kasir untuk melakukan **Edit** dan **Hapus** transaksi pada list transaksi (untuk koreksi kesalahan input harian).

### 4.2. Modul Manajemen Piutang (F6)
- **Trigger Piutang:** Opsi *checkbox* di halaman Kasir. Jika dicentang:
  - Input "Nama Pelanggan" menjadi wajib (Mandatory).
  - Mengabaikan aliran uang tunai ke laci (100% dianggap hutang).
- **Buku Piutang:** Menampilkan *List View* nama pelanggan, total hutang, dan status (Lunas / Belum Lunas).
- **Sistem Pelunasan:** 
  - Mendukung cicilan nominal.
  - Mendukung dua metode pembayaran: Tunai (masuk ke Laci) atau Transfer (masuk ke Bank).

### 4.3. Modul Pengeluaran Operasional (F8)
- Form cepat untuk mencatat biaya di luar transaksi (Listrik, Wifi, ATK, Kopi, dll).
- Opsi pemilihan sumber dana (**Tunai** atau spesifik **Bank Digital**) yang akan dikurangkan secara tepat.
- Secara otomatis memotong Laba Kotor pada laporan bulanan.

### 4.4. Modul Penyesuaian Saldo / Adjustment (F7)
- Fitur untuk melakukan koreksi saldo secara akurat, mendukung: **Penambahan**, **Koreksi Minus**, **Pindah Saldo**, dan penarikan keuntungan (**Tarik Prive**).
- Mencatat log aktivitas sebagai "Adjustment" tanpa merusak statistik profit maupun histori transaksi pelanggan.

### 4.5. Modul Pelaporan (Reporting Engine)
- **Quick Report (F5):** Popup *overlay* instan yang menampilkan Laba Hari Ini, Volume Transaksi, dan Cek Fisik Uang Laci.
- **Full Report:** Halaman analitik untuk melihat Laba Kotor, Total Pengeluaran, dan **Laba Bersih** berdasarkan input rentang waktu yang custom dan disajikan detail.

### 4.6. Manajemen Pengguna & Pengaturan
- **Manajemen Pengguna:** Penambahan, pengeditan, dan penghapusan akses user dengan Role (Admin / Kasir).
- **Personalisasi Tema & Preferensi:** Mendukung pengaturan nama & nomor hp toko, dan manajemen tema antarmuka secara dinamis (Light Mode / Dark Mode).

---

## 5. Pemetaan Shortcut Keyboard (UX Navigasi)

| Tombol | Fungsi / Aksi |
| :--- | :--- |
| **F1** | Buka Halaman Kasir (Dashboard Utama) |
| **F5** | Buka Quick Report (Laporan Instan) |
| **F6** | Buka Buku Piutang |
| **F7** | Buka Form Penyesuaian Saldo (Adjustment) |
| **F8** | Buka Form Pengeluaran Operasional |
| **Arrow Up/Down** | Memilih Jenis Layanan di Dropdown Kasir |
| **Tab** | Pindah antar kolom input dengan cepat |
| **Space** | Toggle Checkbox Piutang atau Admin Luar/Dalam |
| **Enter** | Eksekusi / Simpan Transaksi |

---

## 6. Logika Mutasi Saldo (Accounting Rules)

| Jenis Eksekusi | Saldo Digital (Bank) | Saldo Tunai (Laci) | Perhitungan Laba |
| :--- | :--- | :--- | :--- |
| **Transfer Normal** | `-(Nominal + Adm Bank)` | `+(Nominal + Adm User)` | `Adm User - Adm Bank` |
| **Tarik Tunai Normal** | `+Nominal` | `-(Nominal - Adm User)` | `Adm User` |
| **Transfer (Via Piutang)** | `-(Nominal + Adm Bank)` | `Tidak Berubah (0)` | Tercatat sebagai Tagihan |
| **Pelunasan Piutang (Tunai)** | `Tidak Berubah (0)` | `+Nominal Dibayar` | Hutang Berkurang/Lunas |
| **Input Pengeluaran** | Saldo sumber (`-Nominal`) | Saldo sumber (`-Nominal`)| Mengurangi Laba Bersih |
| **Adjustment (Penambahan)**| `+Nominal` (Jika Bank) | `+Nominal` (Jika Tunai)| Tidak Berubah |
| **Adjustment (Minus/Prive)**| `-Nominal` (Jika Bank) | `-Nominal` (Jika Tunai)| Tidak Berubah |

---

## 7. Skema Database (SQLite Entity - v5)

1. **`wallets`**: ID, Type (Digital/Tunai), Name, Balance.
2. **`services`**: ID, Name, Admin_Bank.
3. **`price_configs`**: ID, Type, Min_Nominal, Max_Nominal, Admin_User.
4. **`transactions`**: ID, Type, Amount, Admin_Bank, Admin_User, Profit, Is_Piutang, Customer_Name, Wallet_ID, Created_At.
5. **`expenses`**: ID, Category, Amount, Description, Wallet_ID, Created_At.
6. **`receivables`**: ID, Customer_Name, Total_Debt, Status.
7. **`receivable_logs`**: ID, Receivable_ID, Amount_Paid, Wallet_ID, Created_At.
8. **`adjustments`**: ID, Type, Wallet_ID, Amount, Description, Created_At.
9. **`app_settings`**: Key (Username, App PIN, Theme Mode, dll), Value.
10. **`users`**: ID, Username, Password, Role.

---

## 8. Batasan Teknis & Keamanan (Constraints)
- **Data Snapshot:** Nilai biaya admin di-copy permanen ke dalam baris transaksi. Perubahan pengaturan harga di masa depan tidak akan mengubah data historis.
- **Offline-First:** Tidak memerlukan koneksi internet untuk beroperasi, seluruh komputasi berjalan di CPU lokal menggunakan SQLite.
- **Autentikasi Aman:** Sistem Role-Based Access Control sederhana, membatasi akses pengaturan sensitif hanya pada role Admin dan membatasi manipulasi data dari Kasir.