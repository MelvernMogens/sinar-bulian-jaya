import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'laporan_tonase_pabrik_detail_screen.dart'; 

class LaporanTonasePabrikScreen extends StatefulWidget {
  const LaporanTonasePabrikScreen({super.key});

  @override
  State<LaporanTonasePabrikScreen> createState() => _LaporanTonasePabrikScreenState();
}

class _LaporanTonasePabrikScreenState extends State<LaporanTonasePabrikScreen> {
  List lots = [];
  List filteredLots = []; 
  bool isLoading = false;
  bool isPageLoading = true;
  TextEditingController searchCtrl = TextEditingController(); 

  Future<void> fetchLots() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/lot/'));
      if (res.statusCode == 200) {
        setState(() {
          lots = json.decode(res.body);
          filteredLots = lots; 
        });
      }
    } catch (e) {
      if(mounted) showCustomSnackbar(context, 'Gagal memuat Daftar Lot', isError: true);
    } finally {
      if(mounted) {
        setState(() {
        isLoading = false;
        isPageLoading = false;
      });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLots();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  // --- FUNGSI PENCARIAN REAL-TIME ---
  void _runFilter(String enteredKeyword) {
    List results = [];
    if (enteredKeyword.isEmpty) {
      results = lots; 
    } else {
      results = lots.where((lot) =>
          lot['nama_lot'].toString().toLowerCase().contains(enteredKeyword.toLowerCase()) ||
          (lot['pabrik'] ?? '').toString().toLowerCase().contains(enteredKeyword.toLowerCase())
      ).toList(); 
    }

    setState(() {
      filteredLots = results;
    });
  }

  void dialogBuatLot() {
    final namaCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Buat Lot Baru', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
        content: Container(
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: TextField(
            controller: namaCtrl,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cth: LOT 01 - JAN', hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
              border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white,
              elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            onPressed: () async {
              if (namaCtrl.text.isNotEmpty) {
                await http.post(
                  Uri.parse('${AppConfig.baseUrl}/api/lot/buat/'), 
                  body: json.encode({'nama_lot': namaCtrl.text})
                );
                if(!mounted) return;
                Navigator.pop(context);
                fetchLots();
                searchCtrl.clear(); 
                _runFilter('');
                showCustomSnackbar(context, 'Berhasil membuat Lot baru!');
              }
            },
            child: const Text('Buat Lot', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isPageLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              // --- BACKGROUND DEKORASI ---
              Positioned(top: -100, right: -50, child: CircleAvatar(radius: 150, backgroundColor: Colors.teal.shade50.withOpacity(0.5))),

              Column(
                children: [
                  // --- HEADER SULTAN ---
                  Container(
                    padding: const EdgeInsets.only(top: 60, left: 16, right: 24, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22), onPressed: () => Navigator.pop(context)),
                            const Text('Daftar Lot Pabrik', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5)),
                          ],
                        ),
                        InkWell(
                          onTap: fetchLots,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.refresh_rounded, color: Colors.teal.shade800, size: 20),
                          ),
                        )
                      ],
                    ),
                  ),

                  // --- SEARCH BAR SULTAN ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: (value) => _runFilter(value), 
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Cari Nama Lot atau Pabrik...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                          prefixIcon: Icon(Icons.search_rounded, color: Colors.teal.shade700),
                          suffixIcon: searchCtrl.text.isNotEmpty 
                            ? IconButton(icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 20), onPressed: () { searchCtrl.clear(); _runFilter(''); })
                            : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  
                  // --- LIST DATA LOT ---
                  Expanded(
                    child: isLoading 
                      ? const Center(child: CircularProgressIndicator()) 
                      : filteredLots.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(searchCtrl.text.isEmpty ? "Belum ada Lot." : "Lot tidak ditemukan.", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              )
                            )
                          : RefreshIndicator(
                              onRefresh: fetchLots,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100), // Padding bawah lega buat Floating Button
                                itemCount: filteredLots.length, 
                                itemBuilder: (context, index) {
                                  final l = filteredLots[index];
                                  bool isSelesai = l['is_selesai'] ?? false;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: Colors.grey.shade100),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(24),
                                        onTap: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => LaporanTonasePabrikDetailScreen(lotId: l['id'].toString())))
                                          .then((_) {
                                            fetchLots(); // Refresh on back
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Header Kartu
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(10),
                                                        decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)),
                                                        child: Icon(Icons.layers_rounded, color: Colors.teal.shade800, size: 20),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(l['nama_lot'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5)),
                                                          const SizedBox(height: 2),
                                                          Text(l['tanggal'], style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 28),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              
                                              // Info Pabrik & Status
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.factory_rounded, size: 14, color: Colors.grey.shade500),
                                                      const SizedBox(width: 6),
                                                      Text(l['pabrik'] == '-' ? 'Belum diset' : l['pabrik'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                                                    ],
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: isSelesai ? Colors.green.shade50 : Colors.orange.shade50,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: isSelesai ? Colors.green.shade200 : Colors.orange.shade200)
                                                    ),
                                                    child: Text(isSelesai ? 'Selesai' : 'Aktif', style: TextStyle(color: isSelesai ? Colors.green.shade700 : Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                                  )
                                                ],
                                              ),
                                              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                              
                                              // Ringkasan Keuangan
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  _buildColumnStats('Total Gudang', formatRp(l['total_uang_gudang'] ?? 0)),
                                                  _buildColumnStats('Timbangan', '${formatTonase(l['total_tonase_pabrik'] ?? 0)} Kg'),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                  ),
                ],
              ),
              
              // --- FLOATING ACTION BUTTON ---
              Positioned(
                bottom: 30, left: 24, right: 24,
                child: Container(
                  decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    onPressed: dialogBuatLot,
                    icon: const Icon(Icons.add_box_rounded, size: 22),
                    label: const Text('BUAT LOT BARU', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.5)),
                  ),
                ),
              )
            ],
          )
    );
  }

  Widget _buildColumnStats(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ],
    );
  }
}