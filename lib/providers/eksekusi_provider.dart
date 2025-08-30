import 'package:flutter/material.dart';
import 'dart:io';
import '../models/eksekusi.dart';
import '../services/eksekusi_service.dart';

class EksekusiProvider with ChangeNotifier {
  final EksekusiService _eksekusiService = EksekusiService();

  Future<void> addEksekusi(Eksekusi eksekusi, File image) async {
    try {
      final imageUrl = await _eksekusiService.uploadImage(image);
      final updatedEksekusi = Eksekusi(
        id: eksekusi.id,
        dataPohonId: eksekusi.dataPohonId,
        statusEksekusi: eksekusi.statusEksekusi,
        tanggalEksekusi: eksekusi.tanggalEksekusi,
        fotoSetelah: imageUrl,
        createdBy: eksekusi.createdBy,
        createdDate: eksekusi.createdDate,
        status: eksekusi.status,
        tinggiPohon: eksekusi.tinggiPohon,
        diameterPohon: eksekusi.diameterPohon,
      );
      await _eksekusiService.addEksekusi(updatedEksekusi);
      notifyListeners();
    } catch (e) {
      throw Exception('Error in provider: $e');
    }
  }
}