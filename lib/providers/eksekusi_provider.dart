import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import '../models/eksekusi.dart';
import '../services/eksekusi_service.dart';
import '../providers/notification_provider.dart';

class EksekusiProvider extends ChangeNotifier {
  List<Eksekusi> _eksekusiList = [];
  StreamSubscription<List<Eksekusi>>? _subscription;

  List<Eksekusi> get eksekusiList => _eksekusiList;

  void setEksekusiStream(Stream<List<Eksekusi>> stream) {
    _subscription?.cancel();
    _subscription = stream.listen(
      (eksekusiList) {
        _eksekusiList = eksekusiList;
        notifyListeners();
      },
      onError: (error) {
        developer.log('Error streaming eksekusi: $error', name: 'EksekusiProvider');
      },
    );
  }

  Future<void> addEksekusi(
    Eksekusi eksekusi,
    File image,
    NotificationProvider notificationProvider,
  ) async {
    try {
      final eksekusiService = EksekusiService();
      await eksekusiService.addEksekusi(eksekusi, image, notificationProvider);
      setEksekusiStream(eksekusiService.getAllEksekusi());
    } catch (e) {
      developer.log('Error adding eksekusi: $e', name: 'EksekusiProvider');
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}