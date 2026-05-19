import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class LogAktivitasScreen extends StatefulWidget {
  const LogAktivitasScreen({super.key});

  @override
  State<LogAktivitasScreen> createState() => _LogAktivitasScreenState();
}

class _LogAktivitasScreenState extends State<LogAktivitasScreen> {
  List logs = [];
  bool isLoading = true;

  Future<void> fetchLogs() async {
    setState(() => isLoading = true);
    try {
      // FIX SAKTI: Tambah timestamp biar data selalu Fresh!
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/log_aktivitas/?_t=${DateTime.now().millisecondsSinceEpoch}'));
      if (res.statusCode == 200) {
        setState(() {
          logs = json.decode(res.body);
        });
      }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Gagal memuat data log!', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  // --- HELPER WARNA & ICON OTOMATIS BERDASARKAN MODUL ---
  Color _getModulColor(String modul) {
    String m = modul.toLowerCase();
    if (m.contains('nota')) return Colors.blue.shade600;
    if (m.contains('pengeluaran')) return Colors.red.shade600;
    if (m.contains('kas')) return Colors.green.shade600;
    if (m.contains('lot')) return Colors.purple.shade600;
    if (m.contains('pengiriman')) return Colors.orange.shade700;
    return Colors.teal.shade700;
  }

  IconData _getModulIcon(String modul) {
    String m = modul.toLowerCase();
    if (m.contains('nota')) return Icons.receipt_long_rounded;
    if (m.contains('pengeluaran')) return Icons.money_off_rounded;
    if (m.contains('kas')) return Icons.account_balance_wallet_rounded;
    if (m.contains('lot')) return Icons.factory_rounded;
    if (m.contains('pengiriman')) return Icons.local_shipping_rounded;
    return Icons.edit_note_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- BACKGROUND DEKORASI (MIRIP HOMEPAGE) ---
          Positioned(
            top: -100,
            right: -50,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: Colors.teal.shade50.withOpacity(0.5),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: Colors.amber.shade50.withOpacity(0.5),
            ),
          ),

          Column(
            children: [
              // --- CUSTOM HEADER SULTAN (MIRIP HOMEPAGE) ---
              Container(
                padding: const EdgeInsets.only(top: 60, left: 16, right: 24, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22), 
                          onPressed: () => Navigator.pop(context)
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SINAR BULIAN JAYA',
                              style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Audit Trail',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // TOMBOL REFRESH PREMIUM
                    InkWell(
                      onTap: fetchLogs,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.teal.shade100),
                        ),
                        child: Icon(Icons.refresh_rounded, color: Colors.teal.shade800, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // --- RINGKASAN LOG KARTU SULTAN ---
              if (!isLoading && logs.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade900, Colors.teal.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security_rounded, color: Colors.amber.shade400, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Monitoring Keamanan',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Menampilkan ${logs.length} riwayat perubahan data terbaru oleh user.',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // --- LIST VIEW LOG ---
              Expanded(
                child: isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                              child: Icon(Icons.verified_user_rounded, size: 64, color: Colors.grey.shade300),
                            ),
                            const SizedBox(height: 24),
                            Text('Aman Terkendali!', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.teal.shade800, fontSize: 20)),
                            const SizedBox(height: 8),
                            Text('Belum ada riwayat editan data hari ini.', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                          ],
                        )
                      )
                    : RefreshIndicator(
                        onRefresh: fetchLogs,
                        color: Colors.teal.shade800,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8, left: 24, right: 24, bottom: 40),
                          physics: const BouncingScrollPhysics(),
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            final Color modulColor = _getModulColor(log['modul']);
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // TOP ROW: Icon + Waktu
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: modulColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(_getModulIcon(log['modul']), color: modulColor, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${log['modul']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87, letterSpacing: -0.2)),
                                              const SizedBox(height: 2),
                                              Text('${log['waktu']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 20),
                                      ],
                                    ),
                                    
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
                                    ),

                                    // MIDDLE ROW: Keterangan
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.turn_right_rounded, color: Colors.grey.shade300, size: 18),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${log['keterangan']}', 
                                            style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 12),

                                    // BOTTOM ROW: Editor SULTAN
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.teal.shade100.withOpacity(0.5)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.person_pin_rounded, color: Colors.teal.shade800, size: 16),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Editor: ',
                                            style: TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                          Expanded(
                                            child: Text(
                                              '${log['user']}', 
                                              style: TextStyle(color: Colors.teal.shade900, fontSize: 12, fontWeight: FontWeight.w900),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      )
              ), 
            ]
          ),
        ],
      ),
    );
  }
}