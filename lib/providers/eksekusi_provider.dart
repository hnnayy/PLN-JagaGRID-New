import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/eksekusi.dart';
import 'dart:async'; // Already present
import 'dart:io'; // Add this import for File type
import 'dart:developer' as developer;
import '../services/eksekusi_service.dart'; // Already present

class EksekusiProvider extends ChangeNotifier {
  List<Eksekusi> _eksekusiList = [];
  StreamSubscription<List<Eksekusi>>? _subscription;

  List<Eksekusi> get eksekusiList => _eksekusiList;

  // Method to set and listen to the eksekusi stream
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

  // Method to handle adding eksekusi via EksekusiService
  Future<void> addEksekusi(Eksekusi eksekusi, File image) async {
    try {
      final eksekusiService = EksekusiService();
      await eksekusiService.addEksekusi(eksekusi, image);
      // Refresh the stream after adding
      setEksekusiStream(eksekusiService.getAllEksekusi());
    } catch (e) {
      developer.log('Error adding eksekusi: $e', name: 'EksekusiProvider');
      rethrow;
    }
  }

  // Cleanup subscription when provider is disposed
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}