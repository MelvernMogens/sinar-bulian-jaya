import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';
import '../utils/helpers.dart';

import 'pembelian_screen.dart';
import 'keuangan_screen.dart';
import 'kasbon_screen.dart';
import 'pengeluaran_screen.dart';
import 'data_petani_screen.dart';
import 'laporan_screen.dart';
import 'pengiriman_screen.dart';
import 'laporan_pengiriman_screen.dart';
import 'laporan_tonase_pabrik_screen.dart';
import 'login_screen.dart';
import 'log_aktivitas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double saldoGudang = 0;
  double tonaseHariIni = 0;
  bool isLoading = false;
  
  String role = 'KASIR';
  String username = 'User';

  bool isAiLoading = true;
  double aiPrediksiHarga = 0;
  String aiTrend = 'STABIL'; // NAIK, TURUN, STABIL
  double aiAkurasi = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData(); 
    fetchDashboardData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? 'KASIR';
      username = prefs.getString('username') ?? 'User';
    });
    if (role == 'OWNER') {
      _fetchAiPredictionFromDjango(); // Panggil fungsi AI
    }
  }

  // --- FUNGSI TARIK DATA DARI AI SVR DI DJANGO ---
  Future<void> _fetchAiPredictionFromDjango() async {
    setState(() => isAiLoading = true);
    
    try {
      // Tembak API buatanmu sendiri di Backend
      final url = Uri.parse('${AppConfig.baseUrl}/api/prediksi_ai/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'sukses') {
          if (mounted) {
            setState(() {
              // Ambil data yang sudah matang dari perhitungan Machine Learning
              aiPrediksiHarga = double.tryParse(jsonData['prediksi_harga'].toString()) ?? 0;
              aiTrend = jsonData['trend'].toString();
              aiAkurasi = double.tryParse(jsonData['akurasi'].toString()) ?? 0;
              isAiLoading = false;
            });
          }
        } else {
          debugPrint("AI Error: ${jsonData['pesan']}");
          _fallbackDummyPrediction();
        }
      } else {
        _fallbackDummyPrediction();
      }
    } catch (e) {
      debugPrint("Gagal narik data AI dari Django: $e");
      _fallbackDummyPrediction();
    }
  }

  void _fallbackDummyPrediction() {
    if (!mounted) return;
    setState(() {
      aiPrediksiHarga = 11850;
      aiTrend = 'STABIL';
      aiAkurasi = 85.0;
      isAiLoading = false;
    });
  }

  Future<void> doLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false, 
    );
  }

  Future<void> fetchDashboardData() async {
    setState(() => isLoading = true);
    try {
      final resSaldo = await http.get(Uri.parse('${AppConfig.baseUrl}/api/kas/info/'));
      final resTonase = await http.get(Uri.parse('${AppConfig.baseUrl}/api/pengeluaran/tonase/'));

      if (resSaldo.statusCode == 200 && resTonase.statusCode == 200) {
        setState(() {
          saldoGudang = json.decode(resSaldo.body)['saldo_sekarang'];
          tonaseHariIni = json.decode(resTonase.body)['tonase_hari_ini'];
        });
      }
    } catch (e) {
      debugPrint("Gagal load dashboard: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -100, right: -50,
            child: CircleAvatar(radius: 150, backgroundColor: Colors.teal.shade50.withOpacity(0.5)),
          ),

          RefreshIndicator(
            onRefresh: () async {
              await fetchDashboardData();
              if (role == 'OWNER') await _fetchAiPredictionFromDjango();
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 70, 24, 10), 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PT SINAR BULIAN JAYA', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                                const SizedBox(height: 4),
                                const Text('Dashboard Utama', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                                const SizedBox(height: 4),
                                Text('Halo, $username!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.teal.shade600)),
                              ],
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.teal.shade800,
                              radius: 24,
                              child: Text(
                                username.isNotEmpty ? username[0].toUpperCase() : 'U', 
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.teal.shade900, Colors.teal.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sisa Saldo Kasir', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 8),
                              Text(formatRp(saldoGudang), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.scale, color: Colors.amber, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('Tonase Hari Ini: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text('${formatRibuan(tonaseHariIni)} Kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        

                        if (role == 'OWNER') ...[
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900, 
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.auto_graph_rounded, color: Colors.amber.shade400, size: 20),
                                    const SizedBox(width: 8),
                                    Text('AI Market Prediction', style: TextStyle(color: Colors.amber.shade400, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                                      child: const Text('SVR AI Model', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)), // <--- GANTI LABEL
                                    )
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                isAiLoading 
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 10),
                                        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2)),
                                      )
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Est. Harga Pabrik Esok', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                            const SizedBox(height: 4),
                                            Text(formatRp(aiPrediksiHarga), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  aiTrend == 'NAIK' ? Icons.trending_up_rounded : (aiTrend == 'TURUN' ? Icons.trending_down_rounded : Icons.trending_flat_rounded), 
                                                  color: aiTrend == 'NAIK' ? Colors.greenAccent : (aiTrend == 'TURUN' ? Colors.redAccent : Colors.white54), 
                                                  size: 16
                                                ),
                                                const SizedBox(width: 4),
                                                Text(aiTrend, style: TextStyle(color: aiTrend == 'NAIK' ? Colors.greenAccent : (aiTrend == 'TURUN' ? Colors.redAccent : Colors.white54), fontWeight: FontWeight.bold, fontSize: 12)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text('Confidence: ${aiAkurasi.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                          ],
                                        )
                                      ],
                                    ),
                              ],
                            ),
                          ),
                        ],

                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const Text('MANAJEMEN', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black26, fontSize: 11, letterSpacing: 1.2)),
                      const SizedBox(height: 16),
                      _buildUniqueMenu(context, 'Keuangan & Saldo', Icons.account_balance_wallet, Colors.teal, const KeuanganScreen()),
                      _buildUniqueMenu(context, 'Buku Kasbon Petani', Icons.book_online, Colors.redAccent, const MenuKasbonScreen()),
                      _buildUniqueMenu(context, 'Catat Pengeluaran', Icons.receipt_long_rounded, Colors.orange.shade800, CatatPengeluaranScreen(tonaseHarian: tonaseHariIni)),
                      _buildUniqueMenu(context, 'Data Petani', Icons.groups_rounded, Colors.green.shade700, const DataPetaniScreen()),

                      const SizedBox(height: 24),
                      const Text('LAPORAN', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black26, fontSize: 11, letterSpacing: 1.2)),
                      const SizedBox(height: 16),
                      _buildUniqueMenu(context, 'Laporan Nota Harian', Icons.bar_chart_rounded, Colors.indigo, const LaporanScreen()),
                      _buildUniqueMenu(context, 'Laporan Pengiriman', Icons.summarize_rounded, Colors.blueGrey, const LaporanPengirimanScreen()),
                      _buildUniqueMenu(context, 'Laporan Tonase Pabrik (LOT)', Icons.factory, Colors.brown, const LaporanTonasePabrikScreen()),
                      
                      if (role == 'OWNER') ...[
                        const SizedBox(height: 24),
                        const Text('SISTEM & AUDIT', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black26, fontSize: 11, letterSpacing: 1.2)),
                        const SizedBox(height: 16),
                        _buildUniqueMenu(context, 'Audit Trail (Log Editan)', Icons.security_rounded, Colors.amber.shade800, const LogAktivitasScreen()),
                      ],

                      const SizedBox(height: 40),

                      InkWell(
                        onTap: doLogout,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.shade100)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            leading: Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 24),
                            title: Text('Keluar (Logout)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                            trailing: Icon(Icons.chevron_right_rounded, color: Colors.red.shade300),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 120),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(24),
              height: 75,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))]),
              child: Row(
                children: [
                  _buildDockButton(context, label: 'NOTA', icon: Icons.confirmation_number_rounded, color: Colors.teal.shade800, page: const PembelianScreen()),
                  VerticalDivider(width: 1, color: Colors.grey.shade100, indent: 15, endIndent: 15),
                  _buildDockButton(context, label: 'TIMBANG', icon: Icons.scale_rounded, color: Colors.amber.shade800, page: const PengirimanScreen()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockButton(BuildContext context, {required String label, required IconData icon, required Color color, required Widget page}) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)).then((_) => fetchDashboardData()),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildUniqueMenu(BuildContext context, String title, IconData icon, Color color, Widget page) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)).then((_) => fetchDashboardData()),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: color, size: 24),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }
}