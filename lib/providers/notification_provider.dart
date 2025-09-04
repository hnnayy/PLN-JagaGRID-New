import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  Future<void> addNotification(AppNotification notification) async {
    _notifications.insert(0, notification);
    notifyListeners();
    // Simpan ke Firestore
    await FirebaseFirestore.instance.collection('notification').add({
      'title': notification.title,
      'message': notification.message,
      'date': notification.date.toIso8601String(),
    });
  }
}
