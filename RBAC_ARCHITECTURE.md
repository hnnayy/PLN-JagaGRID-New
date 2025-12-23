# Arsitektur RBAC - PLN JagaGRID

## Flow Diagram RBAC

```
┌─────────────────────────────────────────────────────────────────┐
│                         LOGIN PROCESS                            │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│  lib/page/login/login.dart                                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 1. User input username & password                         │  │
│  │ 2. Query Firestore: users collection                      │  │
│  │ 3. Verify credentials                                     │  │
│  │ 4. Save to SharedPreferences:                             │  │
│  │    - session_level (1 atau 2)                             │  │
│  │    - session_unit (UP3/ULP)                               │  │
│  │    - session_id, session_username, dll                    │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SESSION MANAGEMENT                            │
│                    (SharedPreferences)                           │
│  ┌──────────────────────┐    ┌──────────────────────┐          │
│  │   Level 1 Session    │    │   Level 2 Session    │          │
│  │   (Unit Induk)       │    │   (Unit Layanan)     │          │
│  │                      │    │                      │          │
│  │ • Full Access        │    │ • Limited Access     │          │
│  │ • No Data Filter     │    │ • Filtered by Unit   │          │
│  │ • All Menus          │    │ • Limited Menus      │          │
│  └──────────────────────┘    └──────────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                │                            │
                ▼                            ▼
┌───────────────────────────┐    ┌───────────────────────────┐
│   Level 1 UI & Features   │    │   Level 2 UI & Features   │
└───────────────────────────┘    └───────────────────────────┘
                │                            │
                ▼                            ▼
```

## Komponen Inti RBAC

### 1. Data Layer
```
┌─────────────────────────────────────────────────────────────────┐
│                    FIRESTORE DATABASE                            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Collection: users                                        │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │ Document Fields:                                    │  │  │
│  │  │ • name: string                                      │  │  │
│  │  │ • username: string                                  │  │  │
│  │  │ • password: string                                  │  │  │
│  │  │ • unit: string (UP3/ULP)                            │  │  │
│  │  │ • level: int (1=Induk, 2=Layanan) ← RBAC KEY      │  │  │
│  │  │ • status: int (1=active, 0=deleted)                │  │  │
│  │  │ • username_telegram: string                         │  │  │
│  │  │ • chat_id_telegram: string                          │  │  │
│  │  │ • added: string                                     │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    MODEL LAYER                                   │
│  lib/models/user.dart                                            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ class UserModel {                                         │  │
│  │   final int level;  // RBAC level                        │  │
│  │   final String unit; // Unit untuk filtering             │  │
│  │                                                           │  │
│  │   // Helper methods                                      │  │
│  │   bool get isInduk => level == 1;                        │  │
│  │   bool get isLayanan => level == 2;                      │  │
│  │   bool get isActive => status == 1;                      │  │
│  │ }                                                         │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SERVICE LAYER                                 │
│  lib/services/user_service.dart                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ • addUser(UserModel user)                                 │  │
│  │ • updateUser(UserModel user)                              │  │
│  │ • deleteUser(String id)                                   │  │
│  │ • getUsers() → Stream<List<UserModel>>                    │  │
│  │ • getUserById(String id) → Future<UserModel?>             │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 2. Access Control Layer

```
┌─────────────────────────────────────────────────────────────────────┐
│                     UI LAYER - RBAC CONTROLS                         │
└─────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────┐
│  Settings Menu                      │
│  lib/page/settings/settingcontent.dart │
│  ┌──────────────────────────────┐  │
│  │ getSettingsItems()           │  │
│  │  ├─ if (level == 1)          │  │
│  │  │   ├─ Profile              │  │
│  │  │   ├─ Tambah User          │  │
│  │  │   ├─ Daftar Assets JTM    │  │
│  │  │   ├─ Master Pertumbuhan   │  │
│  │  │   └─ Logout               │  │
│  │  └─ else (level == 2)        │  │
│  │      ├─ Profile              │  │
│  │      ├─ Master Pertumbuhan   │  │
│  │      └─ Logout               │  │
│  └──────────────────────────────┘  │
└────────────────────────────────────┘
```

### 3. Data Filtering Layer

```
┌─────────────────────────────────────────────────────────────────────┐
│                     DATA FILTERING PATTERN                           │
└─────────────────────────────────────────────────────────────────────┘

Digunakan di semua halaman yang menampilkan data:

┌────────────────────────────────────────────────────────────────────┐
│  _filterList(List<Data> dataList) async {                          │
│    final prefs = await SharedPreferences.getInstance();            │
│    final level = prefs.getInt('session_level') ?? 2;               │
│    final sessionUnit = prefs.getString('session_unit') ?? '';      │
│                                                                     │
│    if (level == 2) {                                                │
│      // Filter hanya data milik unit user                          │
│      return dataList.where((d) =>                                  │
│        d.up3 == sessionUnit || d.ulp == sessionUnit                │
│      ).toList();                                                   │
│    }                                                                │
│    // Level 1: return semua data tanpa filter                      │
│    return dataList;                                                │
│  }                                                                  │
└────────────────────────────────────────────────────────────────────┘

Halaman yang menggunakan filtering:
├─ lib/page/home_page.dart
├─ lib/page/peta_pohon/map_page.dart
├─ lib/page/peta_pohon/pick_location_page.dart
├─ lib/page/report/treemapping_report.dart
├─ lib/page/report/riwayat_eksekusi.dart
├─ lib/page/report/eksekusi.dart
├─ lib/page/notification/notification_page.dart
├─ lib/providers/notification_provider.dart
└─ lib/providers/growth_prediction_provider.dart
```

## Matrix Akses Fitur

| Fitur / Menu               | Level 1 (Unit Induk) | Level 2 (Unit Layanan) |
|----------------------------|----------------------|------------------------|
| **Home Dashboard**         | ✅ All Data           | ✅ Unit Data Only      |
| **Peta Pohon (Map)**       | ✅ All Markers        | ✅ Unit Markers Only   |
| **Tree Mapping Report**    | ✅ All Reports        | ✅ Unit Reports Only   |
| **Riwayat Eksekusi**       | ✅ All History        | ✅ Unit History Only   |
| **Eksekusi Data**          | ✅ All Data           | ✅ Unit Data Only      |
| **Notifications**          | ✅ All Notifications  | ✅ Unit Notifications  |
| **Profile (View/Edit)**    | ✅ Yes                | ✅ Yes                 |
| **Tambah User**            | ✅ Yes                | ❌ No Access           |
| **Daftar User**            | ✅ Yes                | ❌ No Access           |
| **Edit User (Others)**     | ✅ Yes                | ❌ No Access           |
| **Delete User**            | ✅ Yes                | ❌ No Access           |
| **Daftar Assets JTM**      | ✅ Yes                | ❌ No Access           |
| **Master Pertumbuhan**     | ✅ Yes                | ✅ Yes                 |
| **Add Data Pohon**         | ✅ Yes                | ✅ Yes (Own Unit)      |
| **Edit Data Pohon**        | ✅ All Data           | ✅ Unit Data Only      |
| **Delete Data Pohon**      | ✅ All Data           | ✅ Unit Data Only      |

## Alur Autentikasi Detail

```
┌─────────────┐
│   User      │
│   Login     │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────────┐
│ LoginPage                                        │
│ lib/page/login/login.dart                        │
├─────────────────────────────────────────────────┤
│ 1. Input username & password                    │
│ 2. Add @ prefix if not present                  │
│ 3. Query Firestore:                             │
│    WHERE username == input_username             │
│    AND password == input_password               │
└──────┬──────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────┐
│ Authentication Result                            │
└──────┬──────────────────────────────────────────┘
       │
       ├─── Success? ──┐
       │               │
       NO              YES
       │               │
       ▼               ▼
┌─────────────┐  ┌────────────────────────────────┐
│ Show Error  │  │ Save to SharedPreferences:     │
│ Message     │  │ • session_id                   │
└─────────────┘  │ • session_username             │
                 │ • session_name                 │
                 │ • session_unit                 │
                 │ • session_level ◄── RBAC KEY   │
                 │ • session_status               │
                 │ • session_added                │
                 │ • session_username_telegram    │
                 │ • session_chat_id_telegram     │
                 └────────┬───────────────────────┘
                          │
                          ▼
                 ┌────────────────────┐
                 │ Navigate to        │
                 │ NavigationMenu     │
                 │ (Home Page)        │
                 └────────────────────┘
```

## Alur Data Filtering

```
┌─────────────────────────────────────────────────────────────────┐
│  Firestore: data_pohon Collection                                │
│  (Contains ALL tree data from all units)                         │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  ▼
         ┌────────────────────┐
         │  Fetch All Data    │
         └────────┬───────────┘
                  │
                  ▼
         ┌────────────────────┐
         │ Check session_level│
         └────────┬───────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
   level == 1          level == 2
        │                   │
        ▼                   ▼
┌──────────────┐    ┌──────────────────────┐
│ NO FILTER    │    │ FILTER BY UNIT       │
│ Return ALL   │    │ WHERE:               │
│ data         │    │   data.up3 == unit   │
│              │    │   OR                 │
│              │    │   data.ulp == unit   │
└──────┬───────┘    └──────┬───────────────┘
       │                   │
       └─────────┬─────────┘
                 │
                 ▼
        ┌────────────────┐
        │ Display Data   │
        │ in UI          │
        └────────────────┘
```

## Session Management

### Session Creation (Login)
```dart
// lib/page/login/login.dart (Line ~305-314)
final prefs = await SharedPreferences.getInstance();
await prefs.setString('session_username', userData['username'] ?? '');
await prefs.setString('session_name', userData['name'] ?? '');
await prefs.setString('session_unit', userData['unit'] ?? '');
await prefs.setInt('session_level', userData['level'] ?? 2);  // ← RBAC
await prefs.setString('session_added', userData['added'] ?? '');
await prefs.setString('session_username_telegram', userData['username_telegram'] ?? '');
await prefs.setString('session_chat_id_telegram', userData['chat_id_telegram'] ?? '');
await prefs.setInt('session_status', userData['status'] ?? 1);
await prefs.setString('session_id', query.docs.first.id);
```

### Session Usage (Anywhere in App)
```dart
final prefs = await SharedPreferences.getInstance();
final level = prefs.getInt('session_level') ?? 2;  // Default to restricted
final unit = prefs.getString('session_unit') ?? '';

// Apply RBAC logic
if (level == 1) {
  // Full access
} else {
  // Restricted access, filter by unit
}
```

### Session Destruction (Logout)
```dart
// lib/page/settings/settingcontent.dart (Line ~131-140)
final prefs = await SharedPreferences.getInstance();
await prefs.remove('session_id');
await prefs.remove('session_username');
await prefs.remove('session_name');
await prefs.remove('session_unit');
await prefs.remove('session_level');  // ← Clear RBAC
await prefs.remove('session_added');
await prefs.remove('session_username_telegram');
await prefs.remove('session_chat_id_telegram');
await prefs.remove('session_status');
// ... remove other session keys
```

## Security Considerations

### ⚠️ Current Limitations

1. **Client-Side Only**: RBAC checks hanya di Flutter app
   - Solusi: Implementasi Firebase Security Rules

2. **Plain Text Password**: Password disimpan tanpa hashing
   - Solusi: Gunakan Firebase Authentication atau hash password

3. **No Session Timeout**: Session berlaku sampai logout manual
   - Solusi: Implement session expiry dengan timestamp

4. **No Audit Trail**: Tidak ada logging untuk aksi user
   - Solusi: Tambah audit logging collection

### 🔒 Recommended Firebase Security Rules

**⚠️ IMPORTANT NOTE:** 
Aplikasi saat ini menggunakan custom authentication dengan SharedPreferences, BUKAN Firebase Authentication. Rules berikut adalah rekomendasi untuk migrasi ke Firebase Auth di masa depan. 

Untuk implementasi saat ini, pertimbangkan untuk menambahkan simple rules yang membatasi akses berdasarkan authenticated state saja (jika sudah setup Firebase Auth minimal).

**Recommended Future Implementation dengan Firebase Authentication:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper: Get user data
    // NOTE: Ini memerlukan Firebase Authentication terlebih dahulu
    function getUser() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    
    // Helper: Check if user is Level 1
    function isAdmin() {
      return getUser().level == 1;
    }
    
    // Helper: Check if user's unit matches
    function matchesUnit(unit) {
      return getUser().unit == unit;
    }
    
    // Users collection - only Level 1 can modify
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if isAdmin();
      allow update: if isAdmin() || request.auth.uid == userId;
      allow delete: if isAdmin();
    }
    
    // Data pohon - Level 2 only sees their unit's data
    match /data_pohon/{pohonId} {
      allow read: if request.auth != null && 
                     (isAdmin() || 
                      matchesUnit(resource.data.up3) || 
                      matchesUnit(resource.data.ulp));
      allow create: if request.auth != null;
      allow update: if isAdmin() || 
                      matchesUnit(resource.data.up3) || 
                      matchesUnit(resource.data.ulp);
      allow delete: if isAdmin();
    }
    
    // Assets - only Level 1 can manage
    match /assets/{assetId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }
  }
}
```

## File Structure RBAC

```
lib/
├── models/
│   └── user.dart                          # User model dengan field level
├── services/
│   └── user_service.dart                  # CRUD operations untuk users
├── page/
│   ├── login/
│   │   └── login.dart                     # Authentication & session creation
│   ├── settings/
│   │   ├── settingcontent.dart            # Menu berbeda per level
│   │   └── profile/
│   │       ├── profile_page.dart          # View/edit profile
│   │       ├── user_list_page.dart        # Level 1 only
│   │       ├── form_add_user_page.dart    # Level 1 only
│   │       └── edit_user_page.dart        # Level 1 only
│   ├── home_page.dart                     # Data filtering
│   ├── peta_pohon/
│   │   ├── map_page.dart                  # Marker filtering
│   │   └── pick_location_page.dart        # Location filtering
│   ├── report/
│   │   ├── treemapping_report.dart        # Report filtering
│   │   ├── riwayat_eksekusi.dart          # History filtering
│   │   └── eksekusi.dart                  # Eksekusi filtering
│   └── notification/
│       └── notification_page.dart         # Notification filtering
└── providers/
    ├── notification_provider.dart         # Notification state
    └── growth_prediction_provider.dart    # Prediction state
```

## Testing RBAC

### Manual Test Scenarios

#### Test Level 1 (Unit Induk)
1. ✅ Login dengan user level 1
2. ✅ Verify dapat melihat semua menu settings
3. ✅ Verify dapat mengakses Tambah User
4. ✅ Verify dapat mengakses Daftar Assets JTM
5. ✅ Verify dapat melihat semua data tanpa filter
6. ✅ Verify dapat edit/delete data dari unit manapun

#### Test Level 2 (Unit Layanan)
1. ✅ Login dengan user level 2
2. ✅ Verify hanya melihat menu terbatas di settings
3. ✅ Verify TIDAK dapat mengakses Tambah User
4. ✅ Verify TIDAK dapat mengakses Daftar Assets JTM
5. ✅ Verify hanya melihat data sesuai unit
6. ✅ Verify hanya dapat edit/delete data unitnya sendiri

#### Test Session Management
1. ✅ Logout clears all session data
2. ✅ Login dengan user berbeda updates session dengan benar
3. ✅ Refresh app tetap maintain session

## Kesimpulan

Sistem RBAC di PLN JagaGRID menggunakan pendekatan sederhana namun efektif:

✅ **Strengths:**
- Simple 2-level hierarchy (mudah dipahami)
- Konsisten di seluruh aplikasi
- Clear separation of concerns
- Good use of helper methods

⚠️ **Areas for Improvement:**
- Perlu backend validation (Firebase Security Rules)
- Password security perlu ditingkatkan
- Session management bisa lebih robust
- Audit logging belum ada

**Core Principle:** Level 1 = Full Access, Level 2 = Unit-Filtered Access
