# PLN JagaGRID - Tree Management Application

Aplikasi Flutter untuk manajemen dan monitoring pohon di area jaringan listrik PLN.

## 📚 Dokumentasi RBAC (Role-Based Access Control)

Aplikasi ini mengimplementasikan sistem RBAC untuk mengontrol akses pengguna. Untuk memahami bagian mana yang mengurus RBAC, silakan baca dokumentasi berikut:

### 📖 Dokumentasi yang Tersedia:

1. **[RBAC_QUICKSTART.md](RBAC_QUICKSTART.md)** ⭐ **Mulai dari sini!**
   - Panduan cepat dalam Bahasa Indonesia
   - Penjelasan sederhana tentang bagian mana yang ngurusin RBAC
   - Daftar lengkap file-file RBAC dengan penjelasan fungsinya
   - Quick reference untuk developer

2. **[RBAC_DOCUMENTATION.md](RBAC_DOCUMENTATION.md)**
   - Dokumentasi teknis lengkap
   - Detail implementasi di setiap komponen
   - Contoh kode dan best practices
   - Security considerations

3. **[RBAC_ARCHITECTURE.md](RBAC_ARCHITECTURE.md)**
   - Arsitektur sistem RBAC
   - Flow diagram dan visualisasi
   - Matrix akses fitur
   - Recommended Firebase Security Rules

### 🔑 Ringkasan Singkat RBAC:

**Level Akses:**
- **Level 1 (Unit Induk)**: Full access, bisa melihat dan mengelola semua data
- **Level 2 (Unit Layanan)**: Limited access, hanya bisa melihat data unit sendiri

**File-File Penting:**
- `lib/models/user.dart` - Model user dengan field `level`
- `lib/page/login/login.dart` - Authentication & session management
- `lib/services/user_service.dart` - User CRUD operations
- `lib/page/settings/settingcontent.dart` - Menu control berdasarkan level
- 17+ files lainnya yang mengimplementasikan filtering data

## Getting Started

This project is a Flutter application for PLN (Indonesian State Electricity Company) to manage and monitor trees around power lines.

### Prerequisites

- Flutter SDK
- Firebase account (Firestore)
- Android Studio / VS Code

### Installation

1. Clone repository
2. Run `flutter pub get`
3. Configure Firebase (`firebase.json`)
4. Run `flutter run`

## Features

- 🔐 User authentication with RBAC
- 🗺️ Tree mapping with GPS
- 📊 Tree growth prediction
- 📈 Reports and analytics
- 🔔 Notifications
- ⚡ Asset management (JTM)
- 📱 Cross-platform (Android/iOS/Web)

## Tech Stack

- **Framework**: Flutter
- **Language**: Dart
- **Backend**: Firebase Firestore
- **State Management**: Provider
- **Maps**: Google Maps
- **Authentication**: Custom (SharedPreferences)

## Project Structure

```
lib/
├── models/          # Data models
├── services/        # Firebase services
├── page/            # UI pages
├── providers/       # State management
├── constants/       # App constants
└── main.dart        # Entry point
```

## Contributing

For questions about RBAC implementation or to contribute, please read the RBAC documentation files first.

## License

[Add your license here]

## Contact

[Add contact information]
