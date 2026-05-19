# PT Sinar Bulian Jaya — Sistem Operasional Digital Pembelian Karet

> **Thesis project** — Program Studi Sarjana Rekayasa Perangkat Lunak, Universitas Prasetiya Mulya (2026)

Sistem operasional digital untuk pedagang pengumpul karet mentah skala menengah di Jambi. Menggantikan proses pencatatan manual (nota kertas + buku tulis) dengan sistem terintegrasi berbasis Django backend + Flutter frontend.

## 🌳 Project Structure

```
sinarbulianjaya/
├── backend/                # Django REST API
│   ├── core/              # Django project settings, URLs, WSGI
│   ├── operasional/       # Main app — models, views, admin
│   ├── manage.py
│   └── requirements.txt
├── frontend/               # Flutter mobile app (Android)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/       # UI screens (login, nota, keuangan, dll)
│   │   └── utils/         # Helpers, constants, thermal printer
│   └── pubspec.yaml
└── README.md
```

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Django 4.2 + Django REST Framework |
| Frontend | Flutter (Android, min API 26) |
| Database | SQLite |
| ML Prediction | Support Vector Regression (scikit-learn) — SVR RBF kernel |
| Notifications | Firebase Cloud Messaging (topic-based) |
| Thermal Printing | RPP02N 58mm via Bluetooth SPP |
| Data Source | SGX Commodities API (SICOM TFM26 futures) |

## 🚀 Features

- **Perhitungan nota otomatis** — Pembulatan dua arah (ceil potongan, floor total) + alokasi materai
- **Pembayaran multi-skenario** — CASH, transfer, Belum Bayar, split payment
- **Kas gudang digital** — Single source of truth, real-time saldo
- **Buku kasbon pelanggan** — PINJAM/SETOR tracking per petani
- **Lot pabrik & tonase** — Pelacakan pengiriman + selisih gudang-pabrik
- **Audit trail otomatis** — Log perubahan data kritis
- **Cetak nota thermal** — Bluetooth printer RPP02N
- **Notifikasi FCM** — Push notification ke Owner
- **Prediksi harga karet** — SVR berbasis data SGX SICOM TFM26

## ⚙️ Setup

### Backend (Django)

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

### Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

> **Note:** Firebase Admin SDK credentials (`firebase-admin.json`) and any API keys are **not** included in this repository. You must supply your own.

## 📄 License

This project is part of an academic thesis. All rights reserved by the author.

## 👤 Author

**Melvern Mogens** — Universitas Prasetiya Mulya  
Thesis: *Pengembangan Sistem Operasional Digital Pembelian Karet di PT Sinar Bulian Jaya Berbasis Django dan Flutter*
