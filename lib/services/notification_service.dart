import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Request permission from the user (for iOS and web)
    await _firebaseMessaging.requestPermission();

    // Get the FCM token for this device
    final fcmToken = await _firebaseMessaging.getToken();

    if (fcmToken != null) {
      print("FCM Token: $fcmToken"); // For testing purposes
      await _saveTokenToDatabase(fcmToken);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  // Save the token to the user's document in Firestore
  Future<void> _saveTokenToDatabase(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'fcmToken': token,
    });
  }
}
