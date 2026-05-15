# Panduan Cepat RBAC - PLN JagaGRID

## Apa itu RBAC di Aplikasi Ini?

RBAC (Role-Based Access Control) adalah sistem pengaturan hak akses pengguna berdasarkan **level** mereka. Aplikasi ini menggunakan 2 level:

- **Level 1: Unit Induk** - Akses penuh, bisa melihat dan mengelola semua data
- **Level 2: Unit Layanan** - Akses terbatas, hanya bisa melihat data unit sendiri

## Bagian Mana yang Ngurusin RBAC?

### 📁 File Inti RBAC

#### 1. **Model User** - `lib/models/user.dart`
File ini mendefinisikan struktur data user dengan field `level` yang menentukan hak akses.

**Field Penting:**
- `level` (int): 1 = Unit Induk, 2 = Unit Layanan
- `unit` (String): Nama unit (UP3/ULP) untuk filtering data
- `status` (int): 1 = aktif, 0 = terhapus

**Helper Methods:**
```dart
bool get isInduk => level == 1;     // Cek apakah user Level 1
bool get isLayanan => level == 2;   // Cek apakah user Level 2
```

---

#### 2. **Login & Session** - `lib/page/login/login.dart`
File ini menangani proses login dan menyimpan data user ke session.

**Yang Dilakukan:**
- Cek username & password di database Firestore
- Kalau berhasil, simpan data user ke `SharedPreferences`:
  - `session_level` → Level akses (1 atau 2)
  - `session_unit` → Unit kerja user
  - `session_id` → ID user di database
  - dll

**Baris Kode Penting:** Line 305-314

---

#### 3. **User Service** - `lib/services/user_service.dart`
File ini mengurus operasi CRUD (Create, Read, Update, Delete) untuk data user di Firestore.

**Fungsi Utama:**
- `addUser()` - Tambah user baru
- `updateUser()` - Update data user
- `deleteUser()` - Hapus user
- `getUsers()` - Ambil semua user

---

### 🎯 Kontrol Akses Menu

#### 4. **Settings Menu** - `lib/page/settings/settingcontent.dart`
File ini menentukan menu apa saja yang bisa diakses tiap level.

**Level 1 bisa akses:**
1. Profile
2. Tambah User
3. Daftar Assets JTM
4. Master Pertumbuhan pohon
5. Logout

**Level 2 bisa akses:**
1. Profile
2. Master Pertumbuhan pohon
3. Logout

**Baris Kode Penting:** Line 14-114

---

### 📊 Filter Data Berdasarkan Level

File-file berikut menerapkan filtering data berdasarkan level dan unit user:

#### 5. **Home Page** - `lib/page/home_page.dart`
- **Level 1**: Lihat semua data pohon
- **Level 2**: Hanya lihat data pohon dari unit sendiri

**Cara Kerja:** Line 14-31
```dart
if (level == 2) {
  filteredList = pohonList.where((p) => 
    p.up3 == sessionUnit || p.ulp == sessionUnit
  ).toList();
}
```

---

#### 6. **Map Page** - `lib/page/peta_pohon/map_page.dart`
Filter marker di peta berdasarkan level dan unit.

---

#### 7. **Report Page** - `lib/page/report/treemapping_report.dart`
Filter laporan tree mapping berdasarkan level dan unit.

---

#### 8. **Riwayat Eksekusi** - `lib/page/report/riwayat_eksekusi.dart`
Filter riwayat eksekusi berdasarkan level dan unit.

---

#### 9. **Halaman Eksekusi** - `lib/page/report/eksekusi.dart`
Filter data eksekusi berdasarkan level dan unit.

---

#### 10. **Pick Location** - `lib/page/peta_pohon/pick_location_page.dart`
Filter lokasi berdasarkan level dan unit.

---

#### 11. **Notification** - `lib/page/notification/notification_page.dart`
Filter notifikasi berdasarkan level dan unit.

---

### 👥 Manajemen User (Level 1 Only)

#### 12. **User List** - `lib/page/settings/profile/user_list_page.dart`
Menampilkan daftar semua user. Hanya Level 1 yang bisa akses.

---

#### 13. **Add User** - `lib/page/settings/profile/form_add_user_page.dart`
Form tambah user baru. Hanya Level 1 yang bisa akses.

---

#### 14. **Edit User** - `lib/page/settings/profile/edit_user_page.dart`
Edit data user lain. Hanya Level 1 yang bisa akses.

---

#### 15. **Profile Page** - `lib/page/settings/profile/profile_page.dart`
Setiap user bisa edit profile sendiri.

---

### 🔌 Providers (State Management)

#### 16. **Notification Provider** - `lib/providers/notification_provider.dart`
Manage state notifikasi dengan filtering RBAC.

---

#### 17. **Growth Prediction Provider** - `lib/providers/growth_prediction_provider.dart`
Manage state prediksi pertumbuhan dengan filtering RBAC.

---

## 🔍 Cara Cek Level User di Kode

Kalau mau tambah fitur baru yang perlu cek level user, gunakan pattern ini:

```dart
// 1. Import SharedPreferences
import 'package:shared_preferences/shared_preferences.dart';

// 2. Ambil session level
final prefs = await SharedPreferences.getInstance();
final level = prefs.getInt('session_level') ?? 2; // Default: Level 2
final sessionUnit = prefs.getString('session_unit') ?? '';

// 3. Terapkan logic RBAC
if (level == 1) {
  // Level 1: Full access
  // Tampilkan semua data tanpa filter
} else {
  // Level 2: Limited access
  // Filter data berdasarkan unit
  dataList = dataList.where((item) => 
    item.up3 == sessionUnit || item.ulp == sessionUnit
  ).toList();
}
```

---

## 📝 Tabel Akses Fitur

| Fitur                  | Level 1 (Unit Induk) | Level 2 (Unit Layanan) |
|------------------------|----------------------|------------------------|
| Lihat Dashboard        | ✅ Semua data         | ✅ Data unit saja      |
| Peta Pohon             | ✅ Semua marker       | ✅ Marker unit saja    |
| Laporan                | ✅ Semua laporan      | ✅ Laporan unit saja   |
| Tambah Data Pohon      | ✅ Ya                 | ✅ Ya                  |
| Edit Data Pohon        | ✅ Semua data         | ✅ Data unit saja      |
| Hapus Data Pohon       | ✅ Semua data         | ✅ Data unit saja      |
| **Tambah User**        | ✅ Ya                 | ❌ Tidak bisa          |
| **Edit User Lain**     | ✅ Ya                 | ❌ Tidak bisa          |
| **Hapus User**         | ✅ Ya                 | ❌ Tidak bisa          |
| **Assets JTM**         | ✅ Ya                 | ❌ Tidak bisa          |
| Edit Profile Sendiri   | ✅ Ya                 | ✅ Ya                  |
| Master Pertumbuhan     | ✅ Ya                 | ✅ Ya                  |

---

## 🚀 Quick Start - Implementasi RBAC di Fitur Baru

Kalau mau bikin fitur baru yang perlu RBAC, ikuti langkah ini:

### Step 1: Ambil Session Data
```dart
Future<void> _loadSession() async {
  final prefs = await SharedPreferences.getInstance();
  final level = prefs.getInt('session_level') ?? 2;
  final unit = prefs.getString('session_unit') ?? '';
  
  setState(() {
    _sessionLevel = level;
    _sessionUnit = unit;
  });
}
```

### Step 2: Terapkan Filtering (Kalau Perlu)
```dart
List<YourData> _applyFilter(List<YourData> dataList) {
  if (_sessionLevel == 1) {
    // Level 1: No filter
    return dataList;
  } else {
    // Level 2: Filter by unit
    return dataList.where((item) => 
      item.unit == _sessionUnit
    ).toList();
  }
}
```

### Step 3: Kontrol UI (Kalau Perlu)
```dart
Widget build(BuildContext context) {
  return Column(
    children: [
      // Widget yang semua bisa akses
      CommonWidget(),
      
      // Widget khusus Level 1
      if (_sessionLevel == 1)
        AdminOnlyWidget(),
    ],
  );
}
```

---

## 🔒 Keamanan

### ⚠️ Perhatian Penting

Saat ini, RBAC hanya di-enforce di **client-side** (aplikasi Flutter). Untuk keamanan maksimal, perlu ditambahkan **Firebase Security Rules** di backend.

**Contoh Security Rules yang Direkomendasikan:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Fungsi helper cek level user
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
      allow write: if getUserLevel() == 1 || 
                      resource.data.unit == get(/databases/$(database)/documents/users/$(request.auth.uid)).data.unit;
    }
  }
}
```

---

## 🐛 Troubleshooting

### Problem: User Level 2 bisa lihat data unit lain
**Solusi:** Pastikan filtering diterapkan dengan benar di semua halaman yang menampilkan data.

### Problem: Menu tidak sesuai dengan level
**Solusi:** Cek `lib/page/settings/settingcontent.dart`, pastikan kondisi `if (level == 1)` berfungsi dengan benar.

### Problem: Session hilang setelah restart app
**Solusi:** SharedPreferences seharusnya persistent. Cek apakah logout tidak terpanggil secara tidak sengaja.

### Problem: Password user ketahuan
**Solusi:** Saat ini password disimpan plain text. Untuk production, gunakan Firebase Authentication atau hash password dengan bcrypt.

---

## 📞 Kontak & Support

Jika ada pertanyaan tentang RBAC implementation:
1. Baca dokumentasi lengkap di `RBAC_DOCUMENTATION.md`
2. Lihat arsitektur detail di `RBAC_ARCHITECTURE.md`
3. Review kode di file-file yang disebutkan di atas

---

## ✅ Checklist Implementasi RBAC

Saat menambah fitur baru, pastikan:

- [ ] Cek session level di awal
- [ ] Terapkan filtering data kalau Level 2
- [ ] Hide/disable UI kalau Level 2 tidak punya akses
- [ ] Test dengan user Level 1 dan Level 2
- [ ] Update dokumentasi kalau ada perubahan RBAC

---

## 📚 File Dokumentasi

1. **RBAC_QUICKSTART.md** (file ini) - Panduan cepat dalam Bahasa Indonesia
2. **RBAC_DOCUMENTATION.md** - Dokumentasi lengkap dengan detail teknis
3. **RBAC_ARCHITECTURE.md** - Arsitektur dan diagram visual RBAC

---

**Version:** 1.0
**Last Updated:** December 2024
