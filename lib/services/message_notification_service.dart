import 'dart:async'; // نحتاجه للـ StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class MessageNotificationService {
  static final MessageNotificationService _instance =
      MessageNotificationService._internal();
  factory MessageNotificationService() => _instance;
  MessageNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // بنحفظ هنا الـ Listeners عشان منكررهمش
  final Map<String, StreamSubscription> _activeListeners = {};

  void startListeningForNewMessages() {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .listen((chatRoomsSnapshot) {
          for (final chatRoomDoc in chatRoomsSnapshot.docs) {
            // لو بنسمع للمحادثة دي فعلاً، متعملش Listen جديد
            if (!_activeListeners.containsKey(chatRoomDoc.id)) {
              _listenToMessagesInChat(chatRoomDoc.id, user.uid);
            }
          }
        });
  }

  void _listenToMessagesInChat(String chatRoomId, String currentUserId) {
    final subscription = _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .skip(1) // تخطي أول رسالة (القديمة) عشان م يبعتش إشعار أول ما يفتح
        .listen((messagesSnapshot) {
          if (messagesSnapshot.docs.isEmpty) return;

          final messageDoc = messagesSnapshot.docs.first;
          final messageData = messageDoc.data();

          // التأكد من الوقت (إن الرسالة لسه مبعوتة حالاً)
          final timestamp = messageData['timestamp'] as Timestamp?;
          if (timestamp == null ||
              DateTime.now().difference(timestamp.toDate()).inMinutes > 1)
            return;

          final senderId = messageData['senderId'] as String?;
          if (senderId == currentUserId) return;

          _getSenderName(senderId).then((senderName) {
            _notificationService;
          });
        });

    _activeListeners[chatRoomId] = subscription;
  }


  // دالة مهمة عشان تقفل كل الـ Listeners لما المستخدم يعمل Logout
  void stopListening() {
    for (var sub in _activeListeners.values) {
      sub.cancel();
    }
    _activeListeners.clear();
  }

  Future<String> _getSenderName(String? senderId) async {
    if (senderId == null) return 'Unknown';
    try {
      final userDoc = await _firestore.collection('users').doc(senderId).get();
      return userDoc.data()?['name'] ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }
}
