import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  // Function to mark a single notification as read when tapped.
  Future<void> _markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please log in to see notifications.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "You have no notifications.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notificationDoc = notifications[index];
              final notificationData = notificationDoc.data() as Map<String, dynamic>;
              final timestamp = (notificationData['timestamp'] as Timestamp?)?.toDate();

              return _buildNotificationTile(
                context,
                notificationId: notificationDoc.id,
                title: notificationData['title'] ?? 'No Title',
                subtitle: notificationData['body'] ?? 'No Content',
                time: timestamp != null ? DateFormat('MMM d, h:mm a').format(timestamp) : 'Just now',
                isRead: notificationData['isRead'] ?? false,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, {required String notificationId, required String title, required String subtitle, required String time, required bool isRead}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      // Use theme-aware colors to differentiate read/unread notifications
      color: isRead ? Theme.of(context).cardColor : Theme.of(context).primaryColor.withOpacity(0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(Icons.notifications, color: Theme.of(context).primaryColor),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isRead ? FontWeight.normal : FontWeight.w600, // Make unread titles bold
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        trailing: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        onTap: () {
          if (!isRead) {
            _markAsRead(notificationId);
          }
        },
      ),
    );
  }
}
