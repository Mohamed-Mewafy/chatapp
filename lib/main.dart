import 'package:chatapp/firebase_options.dart' show DefaultFirebaseOptions;
import 'package:chatapp/theme/theme.dart';
import 'package:chatapp/view/Auth/login.dart';
import 'package:chatapp/view/Auth/singup.dart';
import 'package:chatapp/view/Home/Homepage.dart';
import 'package:chatapp/view/Home/setting.dart';
import 'package:chatapp/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// 1. معالج الخلفية (يجب أن يكون Top-Level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const Homepage();
          }
          return const Login();
        },
      ),
      routes: {
        "Login": (context) => const Login(),
        "SingUp": (context) => const Singup(),
        "Home": (context) => const Homepage(),
        "Setting": (context) => const Setting(),
      },
    );
  }
}
