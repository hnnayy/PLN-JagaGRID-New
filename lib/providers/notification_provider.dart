import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

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

class NotificationProvider with ChangeNotifier {
  // Ganti dengan token bot dan chat id kamu
  final String _telegramBotToken = '8460425371:AAEhROYuwoKTst2LUUVDkv1zRQTSubHMN2Q';
  final String _telegramChatId = '1245445196';

  Future<void> sendTelegramMessage(String message) async {
    final url = 'https://api.telegram.org/bot$_telegramBotToken/sendMessage?chat_id=$_telegramChatId&text=${Uri.encodeComponent(message)}';
    try {
      await http.get(Uri.parse(url));
    } catch (e) {
      debugPrint('Gagal kirim Telegram: $e');
    }
  }
  final List<AppNotification> _notifications = [];
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  NotificationProvider() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create a high-importance notification channel for heads-up notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'pohon_channel', // Channel ID
      'Pohon Notification', // Channel name
      description: 'Notifikasi penambahan pohon',
      importance: Importance.max, // High importance for heads-up
      playSound: true,
      showBadge: true,
      enableVibration: true,
    );

    // Create the notification channel on Android
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> addNotification(AppNotification notification) async {
    // Add to local list and notify listeners
    _notifications.insert(0, notification);
    notifyListeners();

    // Save to Firestore
    await FirebaseFirestore.instance.collection('notification').add({
      'title': notification.title,
      'message': notification.message,
      'date': notification.date.toIso8601String(),
    });

  // Kirim ke Telegram
  await sendTelegramMessage('${notification.title}\n${notification.message}');

    // Show heads-up notification
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pohon_channel', // Must match channel ID
      'Pohon Notification',
      channelDescription: 'Notifikasi penambahan pohon',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      showWhen: true,
      enableLights: true,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true, // Enables heads-up notification
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      notification.date.millisecondsSinceEpoch % 100000, // Unique ID
      notification.title,
      notification.message,
      platformChannelSpecifics,
    );
  }
}