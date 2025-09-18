import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

// Model untuk notifikasi aplikasi
class AppNotification {
  final String title;
  final String message;
  final DateTime date;

  AppNotification({
    required this.title,
    required this.message,
    required this.date,
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

  // Getter untuk daftar notifikasi (read-only)
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

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
          // Payload format: "scheduled|<title>|<message>" untuk notifikasi terjadwal
          final parts = response.payload!.split('|');
          if (parts.length == 3 && parts[0] == 'scheduled') {
            final title = parts[1];
            final message = parts[2];
            // Kirim pesan Telegram saat notifikasi terjadwal dipicu
            await sendTelegramMessage('$title\n$message');
            debugPrint('Notifikasi terjadwal dipicu dan Telegram dikirim: $message');
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
        .toList();
  }

  // Fungsi kirim pesan ke Telegram (ke semua chat ID)
  Future<void> sendTelegramMessage(String message) async {
    // Jika belum ada chat ID, ambil dari database
    if (_telegramChatIds.isEmpty) {
      await fetchTelegramChatIds();
    }
    // Kirim ke setiap chat ID
    for (String chatId in _telegramChatIds) {
      final url = 'https://api.telegram.org/bot$_telegramBotToken/sendMessage?chat_id=$chatId&text=${Uri.encodeComponent(message)}';
      try {
        await http.get(Uri.parse(url));
        debugPrint('Pesan Telegram terkirim ke chat ID: $chatId');
      } catch (e) {
        debugPrint('Gagal kirim Telegram ke $chatId: $e');
      }
    }
  }

  // Fungsi utama untuk tambah notifikasi (dengan opsi scheduling)
  Future<void> addNotification(
    AppNotification notification, {
    DateTime? scheduleDate, // Tanggal jadwal (opsional)
    String? pohonId, // ID pohon (untuk pesan terjadwal)
    String? namaPohon, // Nama pohon (untuk pesan terjadwal)
  }) async {
    // Tambah ke daftar lokal dan beri tahu listener
    _notifications.insert(0, notification);
    notifyListeners();

    // Simpan ke Firestore
    await FirebaseFirestore.instance.collection('notification').add({
      'title': notification.title,
      'message': notification.message,
      'date': notification.date.toIso8601String(),
    });

    // Kirim pesan Telegram INSTAN
    await sendTelegramMessage('${notification.title}\n${notification.message}');

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
    );

    // JIKA ADA TANGGAL JADWAL, BUAT NOTIFIKASI TERJADWAL
    if (scheduleDate != null && pohonId != null && namaPohon != null) {
      // Pesan untuk notifikasi terjadwal sesuai permintaan
      final scheduledMessage =
          'Hari H Penebangan Letsgoow untuk Pohon $namaPohon (ID: $pohonId)';
      final scheduledTitle = 'Hari H Penebangan';

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

        // Jadwalkan notifikasi dengan payload khusus untuk trigger Telegram
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          (notification.date.millisecondsSinceEpoch % 100000) + 1, // ID unik untuk terjadwal
          scheduledTitle,
          scheduledMessage,
          finalScheduledTime, // Gunakan waktu yang sudah disesuaikan
          scheduledPlatformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'scheduled|$scheduledTitle|$scheduledMessage', // Payload untuk deteksi
        );
        debugPrint('Notifikasi terjadwal dibuat untuk: $finalScheduledTime dengan pesan: $scheduledMessage');
      } catch (e) {
        // Catch error scheduling agar fungsi tidak throw ke luar
        debugPrint('Error scheduling notifikasi terjadwal: $e');
      }
    }
  }
}