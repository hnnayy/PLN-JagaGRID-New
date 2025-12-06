# RBAC Implementation Summary - PLN JagaGRID

## File yang Mengurus RBAC (17+ Files)

### 🎯 CORE - Implementasi Dasar RBAC (3 files)

1. **lib/models/user.dart**
   - Mendefinisikan struktur user dengan field `level` (1 atau 2)
   - Helper methods: `isInduk`, `isLayanan`, `isActive`

2. **lib/page/login/login.dart**
   - Autentikasi user
   - Menyimpan `session_level` dan `session_unit` ke SharedPreferences
   - Gateway untuk semua akses aplikasi

3. **lib/services/user_service.dart**
   - CRUD operations untuk collection `users` di Firestore
   - Service layer untuk manajemen user

---

### 🎨 UI CONTROL - Menu & Navigasi (5 files)

4. **lib/page/settings/settingcontent.dart** ⭐ **UTAMA**
   - Menampilkan menu berbeda untuk Level 1 vs Level 2
   - Level 1: 5 menu items (Profile, Tambah User, Assets JTM, Master Pertumbuhan, Logout)
   - Level 2: 3 menu items (Profile, Master Pertumbuhan, Logout)

5. **lib/page/settings/profile/profile_page.dart**
   - Semua level bisa edit profile sendiri
   - Update session setelah edit profile

6. **lib/page/settings/profile/user_list_page.dart** (Level 1 only)
   - Menampilkan daftar semua user
   - Hanya bisa diakses Level 1

7. **lib/page/settings/profile/form_add_user_page.dart** (Level 1 only)
   - Form untuk tambah user baru
   - Hanya bisa diakses Level 1

8. **lib/page/settings/profile/edit_user_page.dart** (Level 1 only)
   - Edit data user lain
   - Hanya bisa diakses Level 1

---

### 📊 DATA FILTERING - Filter Berdasarkan Level & Unit (9 files)

9. **lib/page/home_page.dart**
   - Filter data pohon di dashboard
   - Level 2: hanya lihat data pohon dari unit sendiri

10. **lib/page/peta_pohon/map_page.dart**
    - Filter marker di peta
    - Level 2: hanya lihat marker dari unit sendiri

11. **lib/page/peta_pohon/pick_location_page.dart**
    - Filter lokasi yang bisa dipilih
    - Level 2: hanya lihat lokasi dari unit sendiri

12. **lib/page/report/treemapping_report.dart**
    - Filter laporan tree mapping
    - Level 2: hanya lihat laporan unit sendiri

13. **lib/page/report/riwayat_eksekusi.dart**
    - Filter riwayat eksekusi
    - Level 2: hanya lihat riwayat unit sendiri

14. **lib/page/report/eksekusi.dart**
    - Filter data eksekusi
    - Level 2: hanya lihat eksekusi unit sendiri

15. **lib/page/notification/notification_page.dart**
    - Filter notifikasi
    - Level 2: hanya lihat notifikasi relevan untuk unit sendiri

16. **lib/providers/notification_provider.dart**
    - State management untuk notifikasi
    - Filtering notifikasi berdasarkan level & unit

17. **lib/providers/growth_prediction_provider.dart**
    - State management untuk prediksi pertumbuhan
    - Filtering prediksi berdasarkan level & unit

---

## 📋 Pola Implementasi RBAC

### Pattern 1: Kontrol Menu (Conditional Rendering)

```dart
// lib/page/settings/settingcontent.dart
Future<List<SettingsItem>> getSettingsItems() async {
  final prefs = await SharedPreferences.getInstance();
  final level = prefs.getInt('session_level') ?? 2;
  
  if (level == 1) {
    return [/* semua menu items */];
  } else {
    return [/* menu items terbatas */];
  }
}
```

**Digunakan di:**
- settingcontent.dart

---

### Pattern 2: Data Filtering (Where Clause)

```dart
// Pattern umum di semua halaman data
Future<List<Data>> _filterData(List<Data> dataList) async {
  final prefs = await SharedPreferences.getInstance();
  final level = prefs.getInt('session_level') ?? 2;
  final sessionUnit = prefs.getString('session_unit') ?? '';
  
  if (level == 2) {
    // Level 2: Filter berdasarkan unit
    return dataList.where((item) => 
      item.up3 == sessionUnit || item.ulp == sessionUnit
    ).toList();
  }
  // Level 1: Return semua data tanpa filter
  return dataList;
}
```

**Digunakan di:**
- home_page.dart
- map_page.dart
- pick_location_page.dart
- treemapping_report.dart
- riwayat_eksekusi.dart
- eksekusi.dart
- notification_page.dart
- notification_provider.dart
- growth_prediction_provider.dart

---

### Pattern 3: Session Loading

```dart
Future<void> _loadSession() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _sessionLevel = prefs.getInt('session_level') ?? 2;
    _sessionUnit = prefs.getString('session_unit') ?? '';
  });
}
```

**Digunakan di:**
- Semua halaman yang perlu cek level user

---

### Pattern 4: Access Control (Route Guard)

```dart
// Implicit - Level 2 tidak bisa akses karena menu tidak muncul
// Sebaiknya ditambahkan explicit check di halaman-halaman sensitif:
if (_sessionLevel != 1) {
  Navigator.pop(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Akses ditolak. Anda tidak punya hak akses.')),
  );
  return;
}
```

**Sebaiknya ditambahkan di:**
- user_list_page.dart
- form_add_user_page.dart
- edit_user_page.dart
- assets_jtm pages

---

## 🔄 Flow RBAC

```
Login (login.dart)
    ↓
Save session_level & session_unit
    ↓
NavigationMenu
    ↓
    ├─→ Settings Menu (settingcontent.dart)
    │       ↓
    │   Read session_level
    │       ↓
    │   if level == 1: Show all menus
    │   if level == 2: Show limited menus
    │
    ├─→ Data Pages (home, map, reports, etc)
    │       ↓
    │   Read session_level & session_unit
    │       ↓
    │   if level == 1: Show all data
    │   if level == 2: Filter by unit
    │
    └─→ Logout (settingcontent.dart)
            ↓
        Clear all session data
            ↓
        Back to Login
```

---

## 📊 Session Keys

Session data disimpan di SharedPreferences dengan keys:

| Key                      | Type   | Description                    |
|--------------------------|--------|--------------------------------|
| `session_id`             | String | Firestore document ID          |
| `session_username`       | String | Username (dengan @)            |
| `session_name`           | String | Nama lengkap user              |
| `session_unit`           | String | Unit kerja (UP3/ULP) ⭐        |
| `session_level`          | int    | Level akses (1 atau 2) ⭐⭐⭐  |
| `session_added`          | String | Tanggal ditambahkan            |
| `session_username_telegram` | String | Username Telegram           |
| `session_chat_id_telegram`  | String | Chat ID Telegram            |
| `session_status`         | int    | Status (1=aktif, 0=terhapus)   |

⭐ = Penting untuk RBAC

---

## 🎯 Quick Reference: Cari File Berdasarkan Kebutuhan

**Mau ubah menu settings?**
→ `lib/page/settings/settingcontent.dart`

**Mau tambah filtering di halaman baru?**
→ Lihat `lib/page/home_page.dart` (line 14-31) sebagai template

**Mau tambah field di user?**
→ `lib/models/user.dart` + `lib/services/user_service.dart`

**Mau ubah proses login?**
→ `lib/page/login/login.dart`

**Mau tambah level baru (misal Level 3)?**
→ Update semua 17 files di atas + tambah kondisi untuk level 3

**Mau tambah Firebase Security Rules?**
→ Lihat `RBAC_ARCHITECTURE.md` bagian "Security Considerations"

---

## 🚨 Common Issues & Solutions

### Issue: Level 2 bisa lihat data unit lain
**Root Cause:** Filtering tidak diterapkan atau salah kondisi
**Fix:** Pastikan ada check `if (level == 2)` dan filter by unit

### Issue: Menu tidak muncul untuk Level 1
**Root Cause:** Kondisi `if (level == 1)` tidak benar
**Fix:** Debug dengan print `session_level`, pastikan tersimpan dengan benar

### Issue: Session hilang setelah restart app
**Root Cause:** SharedPreferences tidak persistent / logout dipanggil
**Fix:** Cek apakah ada call ke `prefs.remove()` yang tidak sengaja

### Issue: User bisa bypass RBAC dengan manipulasi client
**Root Cause:** RBAC hanya di client-side
**Fix:** Implementasi Firebase Security Rules di backend

---

## ✅ Testing Checklist

Saat test RBAC implementation:

**Test dengan Level 1:**
- [ ] Bisa lihat semua menu di settings
- [ ] Bisa akses Tambah User
- [ ] Bisa akses Daftar Assets JTM
- [ ] Bisa lihat semua data di dashboard
- [ ] Bisa lihat semua marker di peta
- [ ] Bisa lihat semua laporan

**Test dengan Level 2:**
- [ ] Hanya lihat 3 menu di settings (Profile, Master Pertumbuhan, Logout)
- [ ] TIDAK bisa akses Tambah User
- [ ] TIDAK bisa akses Daftar Assets JTM
- [ ] Hanya lihat data unit sendiri di dashboard
- [ ] Hanya lihat marker unit sendiri di peta
- [ ] Hanya lihat laporan unit sendiri

**Test Session Management:**
- [ ] Login dengan Level 1 → Verify session_level = 1
- [ ] Login dengan Level 2 → Verify session_level = 2
- [ ] Logout → Verify semua session_* keys terhapus
- [ ] Restart app → Session tetap ada (tidak auto-logout)

---

## 🔗 Related Files

- `RBAC_QUICKSTART.md` - Panduan cepat Bahasa Indonesia
- `RBAC_DOCUMENTATION.md` - Dokumentasi teknis lengkap
- `RBAC_ARCHITECTURE.md` - Arsitektur & diagram visual
- `README.md` - README utama project

---

**Total Files RBAC: 17+ files**
**Core Pattern: 4 patterns**
**Session Keys: 9 keys**
**Level Access: 2 levels**

---

Last Updated: 2025-12-06
