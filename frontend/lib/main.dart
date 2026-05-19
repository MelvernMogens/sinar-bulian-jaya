import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart'; // <--- IMPORT FIREBASE Wajib
import 'package:firebase_messaging/firebase_messaging.dart'; // <--- IMPORT MESSAGING Wajib

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Notif Background Masuk: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(SinarBulianApp(isLoggedIn: isLoggedIn));
}

class SinarBulianApp extends StatelessWidget {
  final bool isLoggedIn;
  
  const SinarBulianApp({super.key, required this.isLoggedIn});

  @override 
  Widget build(BuildContext context) { 
    return MaterialApp(
      title: 'Sinar Bulian Jaya', 
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.grey.shade50,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal.shade800), 
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
        ),
        useMaterial3: true
      ), 
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    ); 
  }
}