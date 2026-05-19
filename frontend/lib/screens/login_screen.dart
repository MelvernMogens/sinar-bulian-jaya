import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <--- IMPORT FIREBASE MESSAGING WAJIB

import 'home_screen.dart'; // Wajib import HomeScreen
import '../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool isLoading = false;
  bool isObscure = true;


  Future<void> doLogin() async {
    if (usernameCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
      _showToast('Username dan Password wajib diisi!', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/login/'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({
          'username': usernameCtrl.text.trim(),
          'password': passwordCtrl.text.trim(),
        }),
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200 && data['status'] == 'sukses') {
        // --- SIMPAN SESI (BIAR GAK PERLU LOGIN ULANG TERUS) ---
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('username', data['username']);
        await prefs.setString('role', data['role']);

        // --- KUNCI SAKTI: PASANG ANTENA NOTIFIKASI SULTAN ---
        try {
          if (data['role'] == 'OWNER') {
            await FirebaseMessaging.instance.subscribeToTopic('notif_owner');
            print("Antena Owner ON!"); // Buat ngecek di terminal
          } else {
            await FirebaseMessaging.instance.unsubscribeFromTopic('notif_owner');
            print("Antena Owner OFF! (Kasir Mode)"); // Buat ngecek di terminal
          }
        } catch (e) {
          print("Gagal seting antena Firebase: $e");
        }
        // ---------------------------------------------------

        if (!mounted) return;
        _showToast(data['pesan']);
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        _showToast(data['pesan'] ?? 'Gagal Login', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showToast('Tidak dapat terhubung ke server!', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.teal.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          // --- HEADER BACKGROUND MELENGKUNG SULTAN ---
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade900, Colors.teal.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // --- DEKORASI LINGKARAN (Khas Homepage Sinar Bulian) ---
          Positioned(
            top: -50, right: -50,
            child: CircleAvatar(radius: 120, backgroundColor: Colors.white.withOpacity(0.05)),
          ),
          Positioned(
            top: 150, left: -30,
            child: CircleAvatar(radius: 60, backgroundColor: Colors.white.withOpacity(0.05)),
          ),

          // --- KONTEN UTAMA ---
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- LOGO & NAMA PERUSAHAAN ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.teal.shade900.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                      ),
                      child: const Icon(Icons.warehouse_rounded, size: 64, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'SINAR BULIAN JAYA',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sistem Operasional & Logistik',
                      style: TextStyle(color: Colors.teal.shade100, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                    ),
                    
                    const SizedBox(height: 40),

                    // --- KARTU FORM LOGIN SULTAN ---
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.login_rounded, color: Colors.teal.shade800, size: 24),
                              const SizedBox(width: 8),
                              Text('Portal Masuk', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.teal.shade900, letterSpacing: -0.5)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Gunakan kredensial yang valid untuk mengakses data.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500, height: 1.4)),
                          const SizedBox(height: 32),

                          // --- INPUT USERNAME ---
                          Container(
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                            child: TextFormField(
                              controller: usernameCtrl,
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
                              decoration: InputDecoration(
                                labelText: 'Username',
                                labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 13),
                                floatingLabelStyle: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                                prefixIcon: Icon(Icons.person_outline_rounded, color: Colors.teal.shade600),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // --- INPUT PASSWORD ---
                          Container(
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                            child: TextFormField(
                              controller: passwordCtrl,
                              obscureText: isObscure,
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 13),
                                floatingLabelStyle: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                                prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.teal.shade600),
                                suffixIcon: IconButton(
                                  icon: Icon(isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey.shade400, size: 20),
                                  onPressed: () => setState(() => isObscure = !isObscure),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // --- TOMBOL LOGIN PREMIUM ---
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 0,
                              ),
                              onPressed: isLoading ? null : doLogin,
                              child: isLoading
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                  : const Text('MASUK APLIKASI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // --- FOOTER VERSION ---
                    Text(
                      'v1.0.0 • Internal System',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}