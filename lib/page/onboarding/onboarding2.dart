import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'onboarding_layout.dart';

class Onboarding2 {
  static OnboardingContentModel get data => OnboardingContentModel(
    title: 'Notifikasi Tugas\nTepat Waktu',
    description: 'Penebang Menerima Tugas Dengan Deadline Jelas, Juga Dapat Menambahkan Data Pohon, Dan Semua Pekerjaan Tercatat Otomatis.',
    imagePath: 'assets/images/onboarding2.png',
    additionalIcon: Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
      ),
    ),
  );
}