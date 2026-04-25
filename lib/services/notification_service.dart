import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // 1. تهيئة الإشعارات المحلية (الأندرويد والـ iOS)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response);
      },
    );

    // 2. طلب الإذن من المستخدم
    await _requestPermission();

    // 3. الحصول على الـ Token (مع معالجة خطأ APNS)
    await _getAndSaveFCMToken();

    // 4. الاستماع للرسائل في الـ Foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. الاستماع عند فتح التطبيق من الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 6. الاستماع لتحديثات الـ Token
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  Future<void> _requestPermission() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _getAndSaveFCMToken() async {
    try {
      // حل مشكلة الـ APNS Token في الـ iOS
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          // ننتظر قليلاً إذا لم يكن التوكن جاهزاً
          await Future.delayed(const Duration(seconds: 3));
          apnsToken = await _firebaseMessaging.getAPNSToken();
        }
        // إذا استمر null، لا نكمل طلب FCM لتجنب الـ Exception
        if (apnsToken == null && !kDebugMode) return;
      }

      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }
    } catch (e) {
      debugPrint('Error getting token: $e');
    }
  }

  Future<void> _saveFCMToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving token to Firestore: $e');
    }
  }

  void _onTokenRefresh(String newToken) {
    _saveFCMToken(newToken);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_messages_channel',
            'Chat Messages',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Notification opened app: ${message.data}');
  }

  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      debugPrint('Notification payload: ${response.payload}');
    }
  }
}
