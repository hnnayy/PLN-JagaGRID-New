import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = Provider.of<NotificationProvider>(context).notifications;
    return Scaffold(
      backgroundColor: const Color(0xFF2E5D6F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E5D6F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Notifikasi",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFFFFD700),
          ),
        ),
        leading: const SizedBox(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: notifications.isEmpty
            ? const Center(child: Text('Belum ada notifikasi'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                itemCount: notifications.length,
                itemBuilder: (context, i) {
                  final notif = notifications[i];
                  return _buildNotificationItem(notif);
                },
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notif) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFD700),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  notif.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _formatDate(notif.date),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Format: HH:mm - dd MMM yyyy
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} - ${date.day} ${months[date.month]} ${date.year}';
  }
}
