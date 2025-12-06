# Dokumentasi RBAC (Role-Based Access Control) - PLN JagaGRID

## Ringkasan
Aplikasi PLN JagaGRID mengimplementasikan sistem RBAC sederhana berbasis **level** pengguna untuk mengontrol akses ke fitur-fitur tertentu. Sistem ini membedakan pengguna menjadi dua level:
- **Level 1**: Unit Induk (Admin/Supervisor) - akses penuh
- **Level 2**: Unit Layanan (User biasa) - akses terbatas

## 1. Model Data User

### File: `lib/models/user.dart`

**Field RBAC:**
- `level` (int): Menentukan tingkat akses user
  - `1` = Unit Induk (Admin)
  - `2` = Unit Layanan (User biasa)
- `unit` (String): Unit kerja pengguna (UP3/ULP)
- `status` (int): Status aktif/non-aktif (1 = aktif, 0 = terhapus)

**Helper Methods:**
```dart
bool get isInduk => level == 1;    // Cek apakah user adalah Unit Induk
bool get isLayanan => level == 2;  // Cek apakah user adalah Unit Layanan
bool get isActive => status == 1;  // Cek apakah user aktif
```

## 2. Autentikasi & Session Management

### File: `lib/page/login/login.dart`

**Proses Login (Baris 282-336):**
1. User memasukkan username dan password
2. Query ke Firestore collection `users`
3. Jika berhasil, data user disimpan ke SharedPreferences:
   ```dart
   await prefs.setInt('session_level', userData['level'] ?? 2);
   await prefs.setString('session_unit', userData['unit'] ?? '');
   await prefs.setString('session_id', query.docs.first.id);
   await prefs.setString('session_username', userData['username'] ?? '');
   await prefs.setString('session_name', userData['name'] ?? '');
   // ... dan field lainnya
   ```

**Session Keys:**
- `session_level`: Level akses user (1 atau 2)
- `session_unit`: Unit kerja user (untuk filtering data)
- `session_id`: ID dokumen Firestore user
- `session_username`: Username
- `session_name`: Nama lengkap
- `session_username_telegram`: Username Telegram
- `session_chat_id_telegram`: Chat ID Telegram
- `session_status`: Status aktif/non-aktif

## 3. Implementasi RBAC di UI

### A. Settings Menu (`lib/page/settings/settingcontent.dart`)

**Kontrol Menu (Baris 14-59):**

**Level 1 (Unit Induk) - Dapat mengakses:**
1. Profile
2. Tambah User
3. Daftar Assets JTM
4. Master Pertumbuhan pohon
5. Logout

**Level 2 (Unit Layanan) - Dapat mengakses:**
1. Profile
2. Master Pertumbuhan pohon
3. Logout

**Kode:**
```dart
Future<List<SettingsItem>> getSettingsItems() async {
  final prefs = await SharedPreferences.getInstance();
  final level = prefs.getInt('session_level') ?? 2;
  
  if (level == 1) {
    // Tampilkan semua menu untuk Level 1
    return [...semua items...];
  } else {
    // Tampilkan menu terbatas untuk Level 2
    return [...items terbatas...];
  }
}
```

**Navigasi (Baris 61-114):**
Handler berbeda untuk setiap level berdasarkan index menu yang ditampilkan.

### B. Logout (`lib/page/settings/settingcontent.dart`)

**Proses Logout (Baris 129-140):**
Menghapus semua data session dari SharedPreferences:
```dart
await prefs.remove('session_id');
await prefs.remove('session_username');
await prefs.remove('session_level');
await prefs.remove('session_unit');
// ... dan semua session keys lainnya
```

## 4. Data Filtering Berdasarkan RBAC

### A. Home Page (`lib/page/home_page.dart`)

**Filtering Data Pohon (Baris 14-31):**
```dart
Future<List<DataPohon>> _filterList(List<DataPohon> pohonList) async {
  final prefs = await SharedPreferences.getInstance();
  final level = prefs.getInt('session_level') ?? 2;
  final sessionUnit = prefs.getString('session_unit') ?? '';
  
  // Level 2: Filter berdasarkan unit
  if (level == 2) {
    filteredList = filteredList.where((p) => 
      p.up3 == sessionUnit || p.ulp == sessionUnit
    ).toList();
  }
  // Level 1: Tidak ada filter, lihat semua data
  
  return filteredList;
}
```

### B. Map Page (`lib/page/peta_pohon/map_page.dart`)

**Load Session & Filtering:**
```dart
Future<void> _loadSession() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _sessionLevel = prefs.getInt('session_level') ?? 2;
    _sessionUnit = prefs.getString('session_unit') ?? '';
  });
}
```

Data marker di peta difilter berdasarkan `_sessionLevel` dan `_sessionUnit`.

### C. Pick Location Page (`lib/page/peta_pohon/pick_location_page.dart`)

Sama seperti Map Page, menggunakan session level untuk filtering data.

### D. Report Pages

**treemapping_report.dart:**
```dart
final prefs = await SharedPreferences.getInstance();
final level = prefs.getInt('session_level') ?? 2;
final sessionUnit = prefs.getString('session_unit') ?? '';

if (level == 2) {
  filteredList = filteredList.where((p) => 
    p.up3 == sessionUnit || p.ulp == sessionUnit
  ).toList();
}
```

**riwayat_eksekusi.dart & eksekusi.dart:**
Menggunakan pola yang sama untuk filtering data eksekusi berdasarkan unit.

## 5. Notification System

### File: `lib/page/notification/notification_page.dart`

Menggunakan session level untuk menentukan notifikasi yang ditampilkan:
```dart
'session_level': prefs.getInt('session_level') ?? 2,
'session_unit': prefs.getString('session_unit') ?? '',
```

### File: `lib/providers/notification_provider.dart`

Provider menggunakan session level untuk filtering notifikasi yang relevan.

## 6. Growth Prediction Provider

### File: `lib/providers/growth_prediction_provider.dart`

Filtering prediksi pertumbuhan berdasarkan level dan unit:
```dart
final level = prefs.getInt('session_level') ?? 2;
final sessionUnit = prefs.getString('session_unit') ?? '';
```

## 7. Profile Management

### File: `lib/page/settings/profile/profile_page.dart`

**Update Level setelah edit:**
```dart
await prefs.setInt('session_level', user.level);
```

**Display Level:**
```dart
_levelController.text = (prefs.getInt('session_level') ?? 2) == 1 
  ? 'Unit Induk' 
  : 'Unit Layanan';
```

## 8. User Service

### File: `lib/services/user_service.dart`

Service untuk CRUD operations pada collection `users` di Firestore:
- `addUser()`: Tambah user baru
- `updateUser()`: Update data user
- `deleteUser()`: Hapus user
- `getUsers()`: Ambil semua user (Stream)
- `getUserById()`: Ambil user by ID

## Ringkasan File-File yang Mengimplementasikan RBAC

### Core RBAC Files:
1. **lib/models/user.dart** - Model data user dengan field `level`
2. **lib/services/user_service.dart** - Service untuk manajemen user
3. **lib/page/login/login.dart** - Autentikasi dan session management

### UI dengan RBAC Control:
4. **lib/page/settings/settingcontent.dart** - Menu settings berbeda per level
5. **lib/page/settings/profile/profile_page.dart** - Profile management
6. **lib/page/settings/profile/user_list_page.dart** - List user (Level 1 only)
7. **lib/page/settings/profile/form_add_user_page.dart** - Add user (Level 1 only)
8. **lib/page/settings/profile/edit_user_page.dart** - Edit user (Level 1 only)

### Data Filtering dengan RBAC:
9. **lib/page/home_page.dart** - Filter data pohon
10. **lib/page/peta_pohon/map_page.dart** - Filter marker di peta
11. **lib/page/peta_pohon/pick_location_page.dart** - Filter lokasi
12. **lib/page/report/treemapping_report.dart** - Filter report tree mapping
13. **lib/page/report/riwayat_eksekusi.dart** - Filter riwayat eksekusi
14. **lib/page/report/eksekusi.dart** - Filter eksekusi
15. **lib/page/notification/notification_page.dart** - Filter notifikasi
16. **lib/providers/notification_provider.dart** - Provider notifikasi
17. **lib/providers/growth_prediction_provider.dart** - Provider prediksi

## Cara Kerja RBAC Secara Keseluruhan

### 1. Login
- User login dengan username & password
- Data user diambil dari Firestore
- `level` dan `unit` disimpan di SharedPreferences

### 2. Access Control
- Setiap halaman membaca `session_level` dari SharedPreferences
- **Level 1**: Akses penuh ke semua fitur dan data
- **Level 2**: Akses terbatas, hanya bisa lihat data sesuai `session_unit`

### 3. Data Filtering
- **Level 1**: Melihat semua data tanpa filter
- **Level 2**: Data difilter berdasarkan `session_unit` (UP3/ULP)
  - Filter: `p.up3 == sessionUnit || p.ulp == sessionUnit`

### 4. UI Adaptation
- Menu dan navigasi berubah berdasarkan level
- Fitur management (Add User, Assets JTM) hanya untuk Level 1

## Best Practices yang Digunakan

1. **Default to Restrictive**: Default level adalah 2 (terbatas)
   ```dart
   final level = prefs.getInt('session_level') ?? 2;
   ```

2. **Consistent Session Keys**: Semua session data menggunakan prefix `session_`

3. **Soft Delete**: User tidak dihapus permanen, hanya di-mark dengan `status = 0`

4. **Helper Methods**: Model memiliki helper methods untuk readability:
   ```dart
   bool get isInduk => level == 1;
   bool get isLayanan => level == 2;
   ```

5. **Stream-based**: User data menggunakan Firestore Streams untuk realtime updates

## Pertimbangan Keamanan

⚠️ **PENTING**: Implementasi RBAC saat ini hanya di client-side (Flutter app). Untuk keamanan optimal, perlu ditambahkan:

1. **Firebase Security Rules** di Firestore untuk enforce level-based access
2. **Backend validation** untuk operasi sensitif
3. **Token-based authentication** untuk menggantikan password plain text
4. **Session timeout** untuk auto-logout
5. **Audit logging** untuk tracking aksi user

## Contoh Firebase Security Rules (Rekomendasi)

**⚠️ CATATAN PENTING:** 
Rules berikut memerlukan migrasi dari custom authentication (SharedPreferences) ke Firebase Authentication terlebih dahulu. Aplikasi saat ini belum menggunakan Firebase Auth, jadi rules ini adalah panduan untuk future improvement.

**Simple Rules untuk Current Implementation:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write hanya jika authenticated (basic protection)
    // Implementasi ini memerlukan setup Firebase Auth minimal
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Advanced Rules dengan Level-Based Access (Future Implementation):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function untuk cek level user
    function getUserLevel() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.level;
    }
    
    // Collection users - hanya Level 1 yang bisa edit
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if getUserLevel() == 1;
    }
    
    // Collection data_pohon - Level 2 hanya lihat data unitnya
    match /data_pohon/{pohonId} {
      allow read: if request.auth != null;
      allow write: if getUserLevel() == 1;
    }
  }
}
```

## Kesimpulan

Sistem RBAC di PLN JagaGRID adalah implementasi sederhana namun efektif dengan 2 level akses:
- **Level 1 (Unit Induk)**: Full access untuk management dan melihat semua data
- **Level 2 (Unit Layanan)**: Limited access dengan data filtering per unit

Implementasi tersebar di 17+ file dengan pola yang konsisten menggunakan SharedPreferences untuk session management dan filtering data berdasarkan level & unit.
