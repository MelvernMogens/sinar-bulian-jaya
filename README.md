# PT Sinar Bulian Jaya — Sistem Operasional Digital Pembelian Karet

> **Proyek skripsi.** Program Studi Sarjana Rekayasa Perangkat Lunak, Universitas Prasetiya Mulya (2026).
> *Pengembangan Sistem Operasional Digital Pembelian Karet di PT Sinar Bulian Jaya Berbasis Django dan Flutter*

**Aplikasi Android + REST API untuk operasional harian pedagang pengumpul karet mentah skala menengah di Jambi.** Nota kertas dan buku tulis diganti satu sistem yang mencakup pembelian dari petani, kas gudang, kasbon, pengiriman ke pabrik dan laporan.

![Logo Sinar Bulian Jaya](frontend/assets/icon/logo_sbj.png)

## Fitur

- **Pembelian & nota otomatis.** Rumus timbang × harga dengan potongan komisi dan buruh, ditambah pembulatan dua arah (potongan dibulatkan ke atas, total ke bawah) dan alokasi materai.
- **Pembayaran multi-skenario**: CASH, transfer ke rekening petani, Belum Bayar, dan split payment. Ada daftar tanggungan untuk melunasi Belum Bayar dan menyelesaikan transfer.
- **Kas gudang digital** dengan saldo real-time sebagai satu sumber kebenaran, termasuk pencatatan pengeluaran.
- **Buku kasbon** per petani (PINJAM / SETOR) lengkap dengan riwayatnya.
- **Data petani**: profil, nomor rekening dan riwayat transaksi.
- **Pengiriman ke pabrik & LOT**: buat pengiriman dari item yang sudah dibeli, finalisasi, catat tonase pabrik, harga jual dan gilingan, lalu hitung selisih gudang vs pabrik. Item laporan pengiriman bisa diedit manual (tonase, harga beli, modal/kg).
- **Laporan harian**, **laporan pengiriman** dan **laporan tonase pabrik**.
- **Audit trail** yang mencatat otomatis setiap perubahan data penting (layar Log Aktivitas).
- **Cetak nota thermal** ke printer 58 mm (RPP02N) via Bluetooth.
- **Notifikasi push** ke Owner lewat Firebase Cloud Messaging (topic-based).
- **Prediksi harga karet**: model SVR (kernel RBF, scikit-learn) yang dilatih dari harga settlement 1 tahun kontrak SGX SICOM TFM26.
- **Dua peran pengguna**: Kasir dan Owner.

## Arsitektur

| Lapis | Teknologi |
|---|---|
| Backend | Django 4.2 (REST API function-based views), SQLite, Django Admin |
| Frontend | Flutter (Android), `http`, `shared_preferences`, `pdf`/`printing`, `blue_thermal_printer` |
| Notifikasi | Firebase Admin SDK (server) + `firebase_messaging` (app) |
| Prediksi | scikit-learn SVR + pandas/numpy, data dari SGX Derivatives API |
| Deploy | gunicorn + whitenoise, konfigurasi via `.env` |

Endpoint utama ada di bawah `/api/` (`pelanggan`, `nota`, `kas`, `kasbon`, `rekening`, `tanggungan`, `pengeluaran`, `laporan`, `pengiriman`, `lot`, `login`, `log_aktivitas`, `prediksi_ai`). Daftar lengkapnya ada di `backend/core/urls.py`.

## Menjalankan

### Backend (Django)

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0:8000   # 0 = dengarkan di semua interface, supaya bisa diakses dari HP
```

Konfigurasi dibaca dari `backend/.env`: `SECRET_KEY`, `DEBUG`, `ALLOWED_HOSTS`. Untuk notifikasi FCM, letakkan `firebase-admin.json` (kredensial Firebase Admin SDK) di folder `backend/`. File itu **tidak** ada di repo, jadi siapkan sendiri.

### Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

Arahkan aplikasi ke server dengan mengganti `baseUrl` di `frontend/lib/utils/constants.dart`. Aplikasinya juga butuh konfigurasi Firebase untuk Android.

## Struktur

```
backend/
  core/              settings, urls (semua route API), wsgi/asgi
  operasional/       models (Pelanggan, Nota, Pembayaran, BukuKasbon, KasGudang, LotPabrik,
                     Pengiriman, LogAktivitas, …), views, admin, migrations
frontend/lib/
  screens/           login, home, pembelian, keuangan, kasbon, data petani, pengeluaran,
                     pengiriman, laporan (harian / pengiriman / tonase pabrik), log aktivitas
  utils/             constants, helpers, cetak_thermal_helper
```

Kalkulator nota versi web yang lebih sederhana ada di repo [Calculator](https://github.com/MelvernMogens/Calculator).

## Lisensi

Bagian dari skripsi akademik. All rights reserved.

---

Dibuat oleh [Melvern Mogens](https://github.com/MelvernMogens), Universitas Prasetiya Mulya.
