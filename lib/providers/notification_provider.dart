import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class AppNotification {
  final String title;
  final String message;
  final DateTime date;
  final String? idPohon;

  AppNotification({
    required this.title,
    required this.message,
    required this.date,
    this.idPohon,
  });
}

class NotificationProvider with ChangeNotifier {
  // ✅ Token tidak ada di Flutter sama sekali
  // Semua kirim Telegram lewat backend Railway
  static const String _backendUrl =
      'https://backend-pln-jagagrid-production.up.railway.app';

  final List<AppNotification> _notifications = [];
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Function(String? idPohon)? _onNotificationTapped;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  void setNotificationTapCallback(Function(String? idPohon) callback) {
    _onNotificationTapped = callback;
  }

  NotificationProvider() {
    _initializeNotifications();
  }

  // =========================================================
  // INIT
  // =========================================================
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          final parts = response.payload!.split('|');
          if (parts.length >= 2) {
            final idPohon = parts[1];
            if (_onNotificationTapped != null &&
                idPohon.isNotEmpty &&
                idPohon != 'null') {
              _onNotificationTapped!(idPohon);
            }
          }
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'pohon_channel',
      'Pohon Notification',
      description: 'Notifikasi penambahan dan penjadwalan pohon',
      importance: Importance.max,
      playSound: true,
      showBadge: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // =========================================================
  // KIRIM TELEGRAM VIA BACKEND RAILWAY
  // Flutter tidak pegang token — Railway yang kirim ke Telegram
  // =========================================================
  Future<void> sendTelegramMessageForTree(
    String message, {
    String? dataPohonId,
    String? up3,
    String? ulp,
    String? koordinat,
  }) async {
    try {
      String treeUp3 = up3 ?? '';
      String treeUlp = ulp ?? '';
      String treeKoordinat = koordinat ?? '';

      // Ambil up3/ulp/koordinat dari Firestore kalau tidak disupply
      if ((treeUp3.isEmpty || treeUlp.isEmpty) &&
          dataPohonId != null &&
          dataPohonId.isNotEmpty) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('data_pohon')
              .doc(dataPohonId)
              .get();

          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            treeUp3 = (data['up3'] ?? '').toString();
            treeUlp = (data['ulp'] ?? '').toString();
            treeKoordinat = (data['koordinat'] ?? '').toString();
          }
        } catch (e) {
          debugPrint('❌ Gagal ambil data pohon: $e');
        }
      }

      debugPrint('📤 Kirim Telegram via Railway untuk up3="$treeUp3" ulp="$treeUlp"');

      // ✅ POST ke endpoint Railway — token ada di Railway
      final response = await http.post(
        Uri.parse('$_backendUrl/send-telegram'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'up3': treeUp3,
          'ulp': treeUlp,
          'koordinat': treeKoordinat,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        debugPrint('✅ Telegram terkirim via Railway');
      } else {
        debugPrint('❌ Railway gagal: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error kirim Telegram via Railway: $e');
    }
  }

  // =========================================================
  // NOTIFIKASI UTAMA
  // Hanya simpan ke Firestore + tampilkan local notif HP
  // Telegram TIDAK dikirim dari sini — dikirim terpisah dari eksekusi_service
  // =========================================================
  Future<void> addNotification(
    AppNotification notification, {
    String? documentIdPohon,
    String? koordinat,
  }) async {
    String createdBy = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      createdBy = prefs.getString('session_id') ?? '';
    } catch (_) {}

    String up3 = '';
    String ulp = '';
    String treeKoordinat = koordinat ?? '';

    if (documentIdPohon != null && documentIdPohon.isNotEmpty) {
      try {
        final pohonDoc = await FirebaseFirestore.instance
            .collection('data_pohon')
            .doc(documentIdPohon)
            .get();

        if (pohonDoc.exists) {
          final data = pohonDoc.data() as Map<String, dynamic>;
          up3 = (data['up3'] ?? '').toString();
          ulp = (data['ulp'] ?? '').toString();
          if (treeKoordinat.isEmpty) {
            treeKoordinat = (data['koordinat'] ?? '').toString();
          }
        }
      } catch (e) {
        debugPrint('❌ Gagal ambil up3/ulp: $e');
      }
    }

    // ── Simpan ke list lokal ──
    _notifications.insert(0, notification);
    notifyListeners();

    // ── Simpan ke Firestore ──
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

    // ── Local notif instan (heads-up di HP) ──
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pohon_channel',
      'Pohon Notification',
      channelDescription: 'Notifikasi penambahan pohon',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableLights: true,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
    );

    await _flutterLocalNotificationsPlugin.show(
      notification.date.millisecondsSinceEpoch % 100000,
      notification.title,
      notification.message,
      const NotificationDetails(android: androidDetails),
      payload: 'instant|${documentIdPohon ?? ""}',
    );
  }

  // =========================================================
  // IN APP ONLY (tanpa Telegram, tanpa local notif)
  // =========================================================
  Future<void> addInAppOnly(
    AppNotification notification, {
    String? documentIdPohon,
  }) async {
    _notifications.insert(0, notification);
    notifyListeners();

    await FirebaseFirestore.instance.collection('notification').add({
      'title': notification.title,
      'message': notification.message,
      'date': notification.date.toIso8601String(),
      'id_pohon': notification.idPohon,
      'id_data_pohon': documentIdPohon,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}