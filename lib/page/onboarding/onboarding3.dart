import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'onboarding_layout.dart';

class Onboarding3 {
  static OnboardingContentModel get data => OnboardingContentModel(
    title: 'Pantau Progres\nReal-Time',
    description: 'Pekerja Dapat Update Status Pohon (Sudah Ditebang / Belum), Juga Dapat Memantau Progres Secara Langsung.',
    imagePath: 'assets/images/onboarding3.png',
    additionalIcon: Positioned(
      bottom: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
      ),
    ),
  );
}