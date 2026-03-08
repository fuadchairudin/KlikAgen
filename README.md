# Klik Agen - Aplikasi Pencatatan Keuangan Agen

Klik Agen adalah aplikasi *point-of-sale* (POS) dan pembukuan berskala UMKM yang dirancang khusus untuk memenuhi kebutuhan agen BRILink, Mandiri Agen, BNI Agen46, atau agen bank/laku pandai serupa. Aplikasi ini mempermudah pencatatan transaksi pemasukan, pengeluaran, transfer saldo antar rekening/digital, serta memantau kesehatan usaha melalui laporan dan dasbor interaktif.

## Fitur Utama

- **Pencatatan Transaksi Harian:** Catat pemasukan (biaya admin, setor/tarik tunai) yang masuk ke berbagai bank atau dompet digital Anda.
- **Pengaturan Multi-Wallet:** Dukungan manajemen saldo untuk lebih dari satu bank atau dompet digital (misalnya: Tunai, BRI, Mandiri, OVO, DANA).
- **Pengeluaran Operasional (Expense Tracker):** Memantau pengeluaran pulsa operasional, listrik, konsumsi, dan biaya lainnya terkait usaha.
- **Penyesuaian Saldo (Adjustment):** Tambahkan modal tambahan, catat penarikan prive (pribadi), atau pindahkan saldo antar bank secara efisien.
- **Laporan Otomatis:** Laporan laba kotor, sisa kas, hingga ringkasan transaksi per periode, dilengkapi bagan grafik.
- **Database Lokal Offline:** Seluruh data tersimpan aman di dalam satu perangkat tanpa memerlukan koneksi internet, menjadikannya sangat cepat, responsif, dan aman dari pemutusan layanan.
- **Pencadangan (Backup) Otomatis:** Fitur pencadangan *database* lokal `.db` dalam satu klik yang bisa dieksternalkan ke flashdisk/hdd untuk keamanan ekstra.

## Cara Instalasi

Aplikasi Klik Agen tersedia dalam bentuk installer `.msix` secara khusus agar mudah dipasang pada sistem operasi Windows 10/11.

1. Hubungi pengembang untuk mendapatkan file `.msix` terkait dengan Klik Agen versi stabil terbaru.
2. Klik dua kali pada file `klik_agen.msix`. Jendela instalasi paket MSIX Windows akan muncul menanyakan verifikasi.
3. Klik **Install**.
4. Setelah proses instalasi selesai, Klik Agen akan otomatis meluncur atau dapat dibuka secara mandiri melalui menu Start Windows.
5. Anda juga dapat dengan mudah menghapus aplikasi ini melalui fitur Settings > Apps di Windows dengan bersih.

## Melakukan Pencadangan Data (Database)

Karena ini adalah aplikasi *offline*, sangat disarankan untuk disiplin mencadangkan pembukuan secara berkala guna mengantisipasi kerusakan sistem *hardware* Windows.

1. Buka menu **Pengaturan** di aplikasi Klik Agen.
2. Cari seksi / menu bagian **Manage Database** atau **Backup / Cadangkan Database**.
3. Klik tombol tersebut lalu ikuti dialog penyimpanan Windows.
4. Pilih folder tujuan (`Flashdisk`, `Google Drive` app, dll) dan tekan Simpan (Save).
5. File `.db` (beserta detail waktu pencadangan otomatis) telah tersimpan untuk keamanan ekstra data usaha Anda.

## Tentang Pengembang

Aplikasi ini dikembangkan untuk memfasilitasi kebutuhan pencatatan UMKM dan Agen perbankan lokal Indonesia dalam era digital melalui antarmuka grafis yang estetis dan rapi, tanpa kerumitan administrasi atau keharusan bayaran utilitas layanan online di awan. Dibangun di atas fondasi _Flutter_ (berjalan lincah di ekosistem Desktop) serta *Drift SQLite* untuk manajemen basis data terstruktur.
