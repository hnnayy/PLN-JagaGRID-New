import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../providers/notification_provider.dart';

class ReminderService {
  static const String _dailyRunKeyPrefix = 'h3_reminder_last_run_';
  static const String _sentKeyPrefix = 'h3_sent_'; // format: h3_sent_<predictionId>_<yyyymmdd>

  /// Run once per day to send Telegram reminders H-3 for active predictions
  static Future<void> runThreeDayTelegramRemindersIfNeeded(NotificationProvider notificationProvider) async {
    tz.initializeTimeZones();
    final prefs = await SharedPreferences.getInstance();
    final location = tz.getLocation('Asia/Makassar');
    final nowWita = tz.TZDateTime.now(location);
    final todayKey = _dailyRunKeyPrefix + DateFormat('yyyyMMdd').format(nowWita);

    // Run at most once per day
    if (prefs.getBool(todayKey) == true) {
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      // Fetch active predictions
      final snap = await firestore
          .collection('growth_predictions')
          .where('status', isEqualTo: 1)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        final predictionId = doc.id;
        final dataPohonId = (data['data_pohon_id'] ?? '') as String;
        final ts = data['predicted_next_execution'];
        if (ts == null) continue;

        final predictedNext = (ts as Timestamp).toDate();
        final predictedWita = tz.TZDateTime.from(predictedNext, location);

        // Compare date-only in WITA timezone
        final predictedDateOnly = DateTime(predictedWita.year, predictedWita.month, predictedWita.day);
        final todayDateOnly = DateTime(nowWita.year, nowWita.month, nowWita.day);
        final daysDiff = predictedDateOnly.difference(todayDateOnly).inDays;

        if (daysDiff == 3) {
          final key = _sentKeyPrefix + '${predictionId}_${DateFormat('yyyyMMdd').format(todayDateOnly)}';
          if (prefs.getBool(key) == true) {
            continue; // already sent today
          }

          // Load tree data
          final pohonDoc = await firestore.collection('data_pohon').doc(dataPohonId).get();
          if (!pohonDoc.exists) continue;
          final pohon = pohonDoc.data()!;
          final idPohon = (pohon['id_pohon'] ?? '') as String;
          final tujuan = (pohon['tujuan_penjadwalan'] ?? 1) as int;
          final tujuanText = tujuan == 2 ? 'Tebang Habis' : 'Tebang Pangkas';

          final dateText = DateFormat('dd/MM/yyyy').format(predictedWita);
          final message = 'Pohon dengan ID $idPohon harus dieksekusi pada tanggal $dateText dengan tujuan penjadwalan adalah $tujuanText';

          // Send Telegram now and add to in-app notifications list
          await notificationProvider.sendTelegramMessage('Pengingat Eksekusi (H-3)\n$message');

          await notificationProvider.addInAppOnly(
            AppNotification(
              title: 'Pengingat Eksekusi (H-3)',
              message: message,
              date: DateTime.now(),
              idPohon: idPohon,
            ),
            documentIdPohon: pohonDoc.id,
          );

          await prefs.setBool(key, true);
        }
      }
    } catch (_) {}

    // Mark daily run
    await prefs.setBool(todayKey, true);
  }
}
