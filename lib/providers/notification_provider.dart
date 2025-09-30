import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

// Model untuk notifikasi aplikasi
class AppNotification {
  final String title;
  final String message;
  final DateTime date;
  final String? idPohon; // Tambahkan idPohon

  AppNotification({
    required this.title,
    required this.message,
    required this.date,
    this.idPohon, // Opsional, karena tidak semua notifikasi terkait pohon
  });
}

// Provider untuk mengelola notifikasi
class NotificationProvider with ChangeNotifier {
  // Token bot Telegram Anda (jangan bagikan!)
  final String _telegramBotToken = '8460425371:AAEhROYuwoKTst2LUUVDkv1zRQTSubHMN2Q';
  List<String> _telegramChatIds = []; // Daftar chat ID dari database
  final List<AppNotification> _notifications = []; // Daftar notifikasi lokal
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin(); // Plugin untuk notifikasi lokal

  // Callback untuk menangani navigasi ketika notifikasi diklik
  Function(String? idPohon)? _onNotificationTapped;

  // Getter untuk daftar notifikasi (read-only)
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  // Method untuk set callback navigasi
  void setNotificationTapCallback(Function(String? idPohon) callback) {
    _onNotificationTapped = callback;
  }

  // Konstruktor: Inisialisasi notifikasi saat provider dibuat
  NotificationProvider() {
    _initializeNotifications();
  }

  // Fungsi inisialisasi notifikasi (dipanggil sekali di awal)
  Future<void> _initializeNotifications() async {
    // Inisialisasi data timezone untuk scheduling akurat
    tz.initializeTimeZones();

    // Pengaturan inisialisasi untuk Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Inisialisasi plugin dengan callback saat notifikasi ditekan/dipicu
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Tangani respons notifikasi (misalnya, saat user tap notifikasi)
        if (response.payload != null) {
          // Payload format: "scheduled|<title>|<message>|<idPohon>" untuk notifikasi terjadwal
          // atau "instant|<title>|<message>|<idPohon>" untuk notifikasi instan
          final parts = response.payload!.split('|');
          if (parts.length == 4) {
            final notificationType = parts[0];
            final title = parts[1];
            final message = parts[2];
            final idPohon = parts[3]; // Ambil idPohon dari payload

            // Panggil callback navigasi jika tersedia dan idPohon tidak kosong
            if (_onNotificationTapped != null && idPohon.isNotEmpty && idPohon != 'null') {
              debugPrint('🔗 Memanggil callback navigasi dengan documentId: $idPohon');
              _onNotificationTapped!(idPohon);
            } else {
              debugPrint('⚠️ Callback navigasi tidak tersedia atau ID kosong: $idPohon');
            }

            // Kirim Telegram untuk notifikasi terjadwal sesuai hak akses pohon
            if (notificationType == 'scheduled') {
              await sendTelegramMessageForTree('$title\n$message', dataPohonId: idPohon);
              debugPrint('Notifikasi terjadwal dipicu dan Telegram dikirim: $message, idPohon: $idPohon');
            } else if (notificationType == 'instant') {
              debugPrint('Notifikasi instan diklik: $message, idPohon: $idPohon');
            }
          }
        }
      },
    );

    // Buat channel notifikasi untuk Android (penting untuk heads-up notification)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'pohon_channel', // ID channel
      'Pohon Notification', // Nama channel
      description: 'Notifikasi penambahan dan penjadwalan pohon', // Deskripsi
      importance: Importance.max, // Tinggi agar muncul heads-up
      playSound: true, // Mainkan suara
      showBadge: true, // Tampilkan badge
      enableVibration: true, // Getar
    );

    // Buat channel di Android
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Ambil daftar chat ID Telegram dari Firestore (dari koleksi 'users')
  Future<void> fetchTelegramChatIds() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    _telegramChatIds = snapshot.docs
        .map((doc) => doc.data()['chat_id_telegram']?.toString() ?? '')
        .where((id) => id.isNotEmpty) // Filter ID kosong
        .where((id) => _isValidChatId(id)) // Filter ID yang valid (numeric)
        .toList();
    debugPrint('📱 Valid chat IDs loaded: ${_telegramChatIds.length} IDs');
  }

  // Validasi apakah chat ID valid (harus numeric)
  bool _isValidChatId(String chatId) {
    // Chat ID Telegram: user biasanya angka positif; grup/supergroup sering diawali -100...
    final numericRegex = RegExp(r'^-?\d+$');
    final isNumeric = numericRegex.hasMatch(chatId);
    final isValidLength = chatId.length >= 8 && chatId.length <= 20; // toleransi untuk -100xxxxxxxxxx

    if (!isNumeric || !isValidLength) {
      debugPrint('⚠️ Invalid chat ID filtered out: "$chatId"');
      return false;
    }
    return true;
  }

  // Fungsi kirim pesan ke Telegram (ke semua chat ID)
  Future<void> sendTelegramMessage(String message) async {
    // Jika belum ada chat ID, ambil dari database
    if (_telegramChatIds.isEmpty) {
      await fetchTelegramChatIds();
    }

    if (_telegramChatIds.isEmpty) {
      debugPrint('⚠️ Tidak ada chat ID Telegram yang valid tersedia');
      return;
    }

    debugPrint('📤 Mengirim pesan Telegram ke ${_telegramChatIds.length} chat ID(s)');
    debugPrint('💬 Pesan: "$message"');

    // Kirim ke setiap chat ID
    for (String chatId in _telegramChatIds) {
      final url = 'https://api.telegram.org/bot$_telegramBotToken/sendMessage?chat_id=$chatId&text=${Uri.encodeComponent(message)}';
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          debugPrint('✅ Pesan Telegram terkirim ke chat ID: $chatId');
        } else {
          debugPrint('❌ Gagal kirim Telegram ke $chatId (Status: ${response.statusCode})');
          debugPrint('📄 Response: ${response.body}');
        }
      } catch (e) {
        debugPrint('❌ Error kirim Telegram ke $chatId: $e');
      }
    }
  }

  // Ambil chatId yang berhak untuk suatu pohon berdasarkan unit (level 2 dibatasi unit; level lain bebas)
  Future<List<String>> _getChatIdsForTree({required String up3, required String ulp}) async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final result = <String>{};
    String norm(String s) => s.trim().toLowerCase();
    final nUp3 = norm(up3);
    final nUlp = norm(ulp);
    debugPrint('🔎 Filter Telegram recipients for tree up3="$up3" ulp="$ulp" (normalized: "$nUp3"/"$nUlp")');
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final chatId = (data['chat_id_telegram'] ?? '').toString();
      if (chatId.isEmpty || !_isValidChatId(chatId)) continue;
      // level can be int or string
      int level;
      final rawLevel = data['level'];
      if (rawLevel is int) level = rawLevel; else if (rawLevel is String) level = int.tryParse(rawLevel) ?? 2; else level = 2;
      final unit = (data['unit'] ?? '').toString();
      final nUnit = norm(unit);
      if (level == 2) {
        if (nUnit == nUp3 || nUnit == nUlp) {
          result.add(chatId);
        }
      } else {
        result.add(chatId);
      }
    }
    return result.toList();
  }

  // Kirim pesan Telegram hanya ke user yang berhak melihat pohon tertentu
  Future<void> sendTelegramMessageForTree(String message, {String? dataPohonId, String? up3, String? ulp}) async {
    String treeUp3 = up3 ?? '';
    String treeUlp = ulp ?? '';
    if ((treeUp3.isEmpty && treeUlp.isEmpty) && dataPohonId != null && dataPohonId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance.collection('data_pohon').doc(dataPohonId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          treeUp3 = (data['up3'] ?? '').toString();
          treeUlp = (data['ulp'] ?? '').toString();
        }
      } catch (e) {
        debugPrint('⚠️ Gagal mengambil unit pohon untuk filter Telegram: $e');
      }
    }

    List<String> targetIds;
    if (treeUp3.isEmpty && treeUlp.isEmpty) {
      if (_telegramChatIds.isEmpty) {
        await fetchTelegramChatIds();
      }
      targetIds = List<String>.from(_telegramChatIds);
    } else {
      targetIds = await _getChatIdsForTree(up3: treeUp3, ulp: treeUlp);
    }

    if (targetIds.isEmpty) {
      debugPrint('⚠️ Tidak ada penerima Telegram yang berhak untuk pesan ini (up3="$treeUp3", ulp="$treeUlp")');
      return;
    }

    for (final chatId in targetIds) {
      final url = 'https://api.telegram.org/bot$_telegramBotToken/sendMessage?chat_id=$chatId&text=${Uri.encodeComponent(message)}';
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          debugPrint('❌ Gagal kirim Telegram ke $chatId (Status: ${response.statusCode})');
        }
      } catch (e) {
        debugPrint('❌ Error kirim Telegram ke $chatId: $e');
      }
    }
  }

  // Fungsi utama untuk tambah notifikasi (dengan opsi scheduling)
  Future<void> addNotification(
    AppNotification notification, {
    DateTime? scheduleDate, // Tanggal jadwal (opsional)
    String? pohonId, // ID pohon (untuk pesan terjadwal)
    String? namaPohon, // Nama pohon (untuk pesan terjadwal)
    String? documentIdPohon, // Document ID pohon Firestore
    String? scheduledTitleOverride, // Judul custom untuk notifikasi terjadwal
    String? scheduledMessageOverride, // Pesan custom untuk notifikasi terjadwal
  }) async {
    // Jika bukan terjadwal, langsung masukkan ke page notif + Firestore
    if (scheduleDate == null) {
      // Get creator id from session
      String createdBy = '';
      try {
        final prefs = await SharedPreferences.getInstance();
        createdBy = prefs.getString('session_id') ?? '';
      } catch (_) {}
      // Coba ambil metadata unit (up3/ulp) dari data_pohon agar bisa difilter di halaman notifikasi
      String up3 = '';
      String ulp = '';
      if (documentIdPohon != null && documentIdPohon.isNotEmpty) {
        try {
          final pohonDoc = await FirebaseFirestore.instance.collection('data_pohon').doc(documentIdPohon).get();
          if (pohonDoc.exists) {
            final data = pohonDoc.data() as Map<String, dynamic>;
            up3 = (data['up3'] ?? '').toString();
            ulp = (data['ulp'] ?? '').toString();
          }
        } catch (e) {
          debugPrint('⚠️ Gagal ambil up3/ulp untuk notification: $e');
        }
      }

      _notifications.insert(0, notification);
      notifyListeners();

      await FirebaseFirestore.instance.collection('notification').add({
        'title': notification.title,
        'message': notification.message,
        'date': notification.date.toIso8601String(),
        'id_pohon': notification.idPohon,
        'id_data_pohon': documentIdPohon,
        'created_by': createdBy,
        'up3': up3,
        'ulp': ulp,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    // Hanya kirim Telegram & tampilkan notifikasi lokal instan jika TIDAK terjadwal
    if (scheduleDate == null) {
      // Kirim Telegram instan sesuai hak akses pohon (jika ada documentIdPohon)
      await sendTelegramMessageForTree('${notification.title}\n${notification.message}', dataPohonId: documentIdPohon);

      // Tampilkan notifikasi lokal INSTAN (heads-up)
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'pohon_channel',
        'Pohon Notification',
        channelDescription: 'Notifikasi penambahan pohon',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        showWhen: true,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true, // Muncul heads-up
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _flutterLocalNotificationsPlugin.show(
        notification.date.millisecondsSinceEpoch % 100000, // ID unik untuk instan
        notification.title,
        notification.message,
        platformChannelSpecifics,
        payload: 'instant|${notification.title}|${notification.message}|${documentIdPohon ?? ""}', // Gunakan documentIdPohon untuk navigasi
      );
    }

    // JIKA ADA TANGGAL JADWAL, BUAT NOTIFIKASI TERJADWAL
    if (scheduleDate != null && pohonId != null && namaPohon != null) {
      // Gunakan pesan custom jika diberikan, jika tidak gunakan default lama
      final scheduledMessage = scheduledMessageOverride ??
          'Hari H Penebangan Letsgoow untuk Pohon $namaPohon (ID: $pohonId)';
      final scheduledTitle = scheduledTitleOverride ?? 'Hari H Penebangan';

      // Konversi ke timezone WITA (Asia/Makassar, UTC+8)
      final tz.TZDateTime baseScheduledTime = tz.TZDateTime.from(
        scheduleDate,
        tz.getLocation('Asia/Makassar'),
      );

      final nowInWita = tz.TZDateTime.now(tz.getLocation('Asia/Makassar'));

      // **PERBAIKAN: Pastikan scheduledTime di masa depan**
      tz.TZDateTime finalScheduledTime;
      if (baseScheduledTime.isBefore(nowInWita)) {
        // Masa lalu: Skip scheduling dan log warning
        debugPrint('Tanggal penjadwalan masa lalu ($baseScheduledTime), skip notifikasi terjadwal.');
        return;
      } else if (!baseScheduledTime.isAfter(nowInWita)) {
        // Sama dengan sekarang (hari ini): Tambah delay 1 menit agar masa depan
        finalScheduledTime = nowInWita.add(const Duration(minutes: 1));
        debugPrint('Jadwal hari ini, tambah delay 1 menit menjadi: $finalScheduledTime');
      } else {
        // Masa depan: Gunakan langsung
        finalScheduledTime = baseScheduledTime;
      }

      try {
        const AndroidNotificationDetails scheduledAndroidDetails =
            AndroidNotificationDetails(
          'pohon_channel',
          'Pohon Notification',
          channelDescription: 'Notifikasi penjadwalan pohon',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          showWhen: true,
          enableLights: true,
          enableVibration: true,
          playSound: true,
          fullScreenIntent: true,
        );

        const NotificationDetails scheduledPlatformDetails =
            NotificationDetails(android: scheduledAndroidDetails);

        // Jadwalkan notifikasi dengan inexact alarms (lebih reliable)
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          (notification.date.millisecondsSinceEpoch % 100000) + 1, // ID unik untuk terjadwal
          scheduledTitle,
          scheduledMessage,
          finalScheduledTime, // Gunakan waktu yang sudah disesuaikan
          scheduledPlatformDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // Ganti ke inexact
          payload: 'scheduled|$scheduledTitle|$scheduledMessage|$documentIdPohon', // Gunakan documentIdPohon untuk navigasi
        );
        debugPrint('✅ Notifikasi terjadwal berhasil dibuat untuk: $finalScheduledTime');
        debugPrint('📅 Detail: ID=${(notification.date.millisecondsSinceEpoch % 100000) + 1}, Title="$scheduledTitle"');
      } catch (e) {
        // Enhanced error handling dengan lebih detail
        debugPrint('❌ Error scheduling notifikasi terjadwal: $e');
        debugPrint('📊 Error details: Time=$finalScheduledTime, Title="$scheduledTitle"');

        // Jika exact alarms gagal, coba dengan inexact (fallback)
        if (e.toString().contains('exact_alarms_not_permitted')) {
          debugPrint('🔄 Mencoba fallback dengan inexact alarm...');
          try {
            const AndroidNotificationDetails fallbackAndroidDetails =
                AndroidNotificationDetails(
              'pohon_channel',
              'Pohon Notification',
              channelDescription: 'Notifikasi penjadwalan pohon (fallback)',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
              showWhen: true,
              enableLights: true,
              enableVibration: true,
              playSound: true,
              fullScreenIntent: true,
            );

            const NotificationDetails fallbackPlatformDetails =
                NotificationDetails(android: fallbackAndroidDetails);

            await _flutterLocalNotificationsPlugin.zonedSchedule(
              (notification.date.millisecondsSinceEpoch % 100000) + 1,
              scheduledTitle,
              scheduledMessage,
              finalScheduledTime,
              fallbackPlatformDetails,
              androidScheduleMode: AndroidScheduleMode.inexact,
              payload: 'scheduled|$scheduledTitle|$scheduledMessage|$documentIdPohon',
            );
            debugPrint('✅ Fallback inexact alarm berhasil');
          } catch (fallbackError) {
            debugPrint('❌ Fallback inexact alarm juga gagal: $fallbackError');
          }
        }
      }
    }
  }

  // Tambahkan notifikasi hanya ke page notif + Firestore (tanpa local heads-up dan tanpa Telegram)
  Future<void> addInAppOnly(AppNotification notification, {String? documentIdPohon}) async {
    // Get creator id from session
    String createdBy = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      createdBy = prefs.getString('session_id') ?? '';
    } catch (_) {}
    // Coba ambil metadata unit (up3/ulp) dari data_pohon agar bisa difilter di halaman notifikasi
    String up3 = '';
    String ulp = '';
    if (documentIdPohon != null && documentIdPohon.isNotEmpty) {
      try {
        final pohonDoc = await FirebaseFirestore.instance.collection('data_pohon').doc(documentIdPohon).get();
        if (pohonDoc.exists) {
          final data = pohonDoc.data() as Map<String, dynamic>;
          up3 = (data['up3'] ?? '').toString();
          ulp = (data['ulp'] ?? '').toString();
        }
      } catch (e) {
        debugPrint('⚠️ Gagal ambil up3/ulp untuk notification (inAppOnly): $e');
      }
    }

    _notifications.insert(0, notification);
    notifyListeners();

    await FirebaseFirestore.instance.collection('notification').add({
      'title': notification.title,
      'message': notification.message,
      'date': notification.date.toIso8601String(),
      'id_pohon': notification.idPohon,
      'id_data_pohon': documentIdPohon,
      'created_by': createdBy,
      'up3': up3,
      'ulp': ulp,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}