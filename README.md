# Duitin — Smart Daily Expense Tracker

![Flutter CI](https://github.com/ainiisolehaa/Duitin.App/actions/workflows/flutter-ci.yml/badge.svg)

**Duitin** adalah aplikasi pencatatan keuangan pribadi berbasis Flutter yang dirancang untuk membantu mahasiswa mengelola pemasukan, pengeluaran, anggaran bulanan, dan melihat statistik keuangan secara visual.

Aplikasi ini **sepenuhnya offline** — tidak membutuhkan backend atau koneksi internet. Semua data disimpan secara lokal menggunakan SQLite, sehingga tetap bisa dipakai kapan saja.

---

## ✨ Fitur Utama

| Fitur | Keterangan |
|---|---|
| 🔐 **Autentikasi** | Register, login, logout, validasi input, password di-hash SHA-256, dan sesi tersimpan di `SharedPreferences` |
| 🏠 **Dashboard** | Ringkasan saldo, total pemasukan, total pengeluaran, anggaran bulanan, dan transaksi terbaru |
| 💸 **CRUD Transaksi** | Tambah, lihat detail, edit, dan hapus transaksi pemasukan/pengeluaran |
| 🔎 **Riwayat & Filter** | Pencarian teks, filter jenis transaksi, filter kategori, dan filter periode (hari ini, minggu ini, bulan ini, rentang kustom) |
| 📊 **Statistik** | Grafik batang pemasukan vs pengeluaran dan grafik lingkaran pengeluaran per kategori, dengan periode mingguan/bulanan |
| 🎯 **Anggaran Bulanan** | Batas anggaran per kategori, progress bar, sisa anggaran, serta peringatan otomatis **Aman / Mendekati Batas / Melewati Batas** |
| 👤 **Profil** | Ubah nama dengan validasi, pilih tema terang/gelap/sistem, dan logout |
| 📱 **Responsif** | Layout tetap rapi saat orientasi portrait maupun landscape |

---

## 🧭 Halaman Aplikasi

Aplikasi memiliki **11 screen**:

1. `SplashScreen` — splash screen dan pengecekan sesi
2. `LoginScreen` — masuk ke akun
3. `RegisterScreen` — pendaftaran akun baru
4. `MainNavigationScreen` — navigasi utama 5 tab
5. `HomeScreen` — dashboard keuangan
6. `TransactionListScreen` — riwayat dan multi-filter transaksi
7. `TransactionFormScreen` — form tambah/edit transaksi
8. `TransactionDetailScreen` — detail, edit, dan hapus transaksi
9. `StatisticsScreen` — statistik dan grafik
10. `BudgetScreen` — pengelolaan anggaran bulanan
11. `ProfileScreen` — profil, tema, dan logout

Alur navigasi:

```text
Splash
  └── Login ──→ Register
        └── MainNavigation
              ├── Beranda
              ├── Transaksi ──→ Detail ──→ Edit
              ├── Statistik
              ├── Anggaran
              └── Profil
```

---

## 🏗️ Arsitektur

Project menggunakan pola berlapis agar UI, state, dan akses data tidak saling bercampur:

```text
Screen / Widget
      ↓
Provider (ChangeNotifier)
      ↓
Repository
      ↓
SQLite (sqflite) / SharedPreferences
```

- **Models** — struktur data: `User`, `Transaction`, `Budget`, `BudgetDetail`, `StatisticData`
- **Providers** — state management dengan `provider` dan `ChangeNotifier`
- **Repositories** — query SQL dan operasi database
- **Screens** — halaman aplikasi
- **Widgets** — komponen UI yang dapat digunakan ulang
- **Utils** — format Rupiah/tanggal dan data seeder

---

## 🛠️ Teknologi

| Kebutuhan | Package |
|---|---|
| Framework | Flutter / Dart |
| State management | `provider` |
| Database lokal | `sqflite` |
| Preferensi & sesi | `shared_preferences` |
| Grafik | `fl_chart` |
| Format Rupiah & tanggal | `intl` |
| Hash password | `crypto` (SHA-256) |
| UI | Material 3 |

---

## 📁 Struktur Folder

```text
duitin/
├── android/                  # Konfigurasi Android
├── lib/
│   ├── database/
│   │   └── database_helper.dart
│   ├── models/
│   ├── providers/
│   ├── repositories/
│   ├── screens/
│   ├── utils/
│   ├── widgets/
│   └── main.dart
├── test/                     # Unit & widget tests
├── .github/workflows/        # CI GitHub Actions
├── analysis_options.yaml
├── pubspec.yaml
└── README.md
```

---

## 🚀 Cara Menjalankan

### Prasyarat

- Flutter SDK `3.13.5` atau lebih baru
- Android Studio / VS Code dengan plugin Flutter
- Emulator Android atau perangkat fisik

### Langkah

```bash
# 1. Clone repository
git clone https://github.com/ainiisolehaa/Duitin.App.git
cd Duitin.App

# 2. Install dependency
flutter pub get

# 3. Jalankan aplikasi
flutter run
```

---

## 🔑 Akun Demo

Saat aplikasi pertama kali dijalankan, data demo akan otomatis dibuat:

```text
Email    : mahasiswa@duitin.id
Password : password123
```

Di halaman login juga tersedia tombol **“Gunakan Akun Demo”** untuk mengisi form secara otomatis.

Data demo mencakup:
- 1 akun mahasiswa
- 6 pos anggaran bulanan
- 17 transaksi pemasukan dan pengeluaran

---

## 🧪 Pengujian

```bash
# Cek kualitas kode
flutter analyze

# Jalankan seluruh test
flutter test
```

Saat ini terdapat **76 test** yang mencakup:
- Autentikasi dan validasi
- CRUD transaksi dan perhitungan saldo
- Riwayat dan multi-filter
- Statistik mingguan/bulanan
- Anggaran dan status peringatan
- Persistensi tema dan sesi
- Orientasi portrait/landscape
- Isolasi data antar pengguna

---

## ⚙️ CI/CD

Workflow GitHub Actions tersedia di `.github/workflows/flutter-ci.yml` dan otomatis menjalankan:

1. `flutter pub get`
2. Pemeriksaan format kode
3. `flutter analyze`
4. `flutter test`

setiap kali ada push atau pull request ke branch `main`.

---

## 📌 Catatan

- Aplikasi tidak memakai API/backend eksternal.
- Semua data tersimpan di SQLite lokal perangkat.
- Data demo hanya digunakan untuk keperluan demonstrasi dan pembelajaran.

---

## 👩‍💻 Pengembang

**Nur'Aini Siti Soleha**

Project ini dibuat untuk keperluan pembelajaran dan demonstrasi aplikasi mobile.
