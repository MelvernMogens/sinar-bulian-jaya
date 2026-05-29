import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // <--- IMPORT SAKTI
import '../utils/helpers.dart';
import '../utils/constants.dart';

class KeuanganScreen extends StatefulWidget { 
  const KeuanganScreen({super.key}); 
  @override State<KeuanganScreen> createState() => _KeuanganScreenState(); 
}

class _KeuanganScreenState extends State<KeuanganScreen> {
  double saldoSekarang = 0; 
  bool isLoading = false; 
  bool isPageLoading = true;
  final nominalController = TextEditingController(); 
  bool isAmpera = false; 
  List listBB = []; 
  List listTF = [];

  Future<void> fetchData() async { 
    try {
      final resSaldo = await http.get(Uri.parse('${AppConfig.baseUrl}/api/kas/info/?_t=${DateTime.now().millisecondsSinceEpoch}')); 
      if (resSaldo.statusCode == 200) {
        setState(() => saldoSekarang = json.decode(resSaldo.body)['saldo_sekarang']);
      }
      
      final resTanggungan = await http.get(Uri.parse('${AppConfig.baseUrl}/api/tanggungan/list/?_t=${DateTime.now().millisecondsSinceEpoch}')); 
      if (resTanggungan.statusCode == 200) { 
        final data = json.decode(resTanggungan.body); 
        setState(() { 
          listBB = data['bb']; 
          listTF = data['tf']; 
        }); 

        final prefs = await SharedPreferences.getInstance();
        final role = prefs.getString('role') ?? 'KASIR';

        if (role == 'OWNER' && (listBB.isNotEmpty || listTF.isNotEmpty)) {
          _munculkanNotifikasiOwner(listBB.length, listTF.length);
        }
      }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Koneksi ke server gagal!', isError: true);
    } finally {
      if (mounted) setState(() => isPageLoading = false);
    }
  }

  void _munculkanNotifikasiOwner(int jumlahBB, int jumlahTF) {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Laporan Antrian, Bos!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(
                      'Ada $jumlahBB Nota Belum Bayar dan $jumlahTF antrian Transfer yang butuh diproses.', 
                      style: const TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w500)
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue.shade800, // Warna biru eksekutif
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 6), // Tampil agak lama biar kebaca
          elevation: 10,
        ),
      );
    });
  }

  Future<void> submitTambahSaldo() async { 
    if (nominalController.text.isEmpty) {
      showCustomSnackbar(context, 'Masukkan nominal saldo terlebih dahulu!', isError: true);
      return; 
    }
    setState(() => isLoading = true); 
    
    try {
      String nominalMurni = nominalController.text.replaceAll('.', ''); 
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/kas/tambah/'), 
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'nominal': nominalMurni, 'is_ampera': isAmpera})
      ); 
      
      FocusScope.of(context).unfocus();
      nominalController.clear(); 
      setState(() => isAmpera = false); 
      await fetchData(); 
      
      if (mounted) showCustomSnackbar(context, 'Berhasil! Saldo kas bertambah.'); 
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Gagal menambah saldo!', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void konfirmasiLunasinBB(int notaId, String nama, String total) {
    String selectedMetode = 'CASH'; 

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Pelunasan Nota BB', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lunasi tagihan $nama senilai $total?', style: const TextStyle(height: 1.5, color: Colors.black87)),
                const SizedBox(height: 20),
                const Text('METODE PEMBAYARAN:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black45, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => selectedMetode = 'CASH'),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedMetode == 'CASH' ? Colors.teal.shade600 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selectedMetode == 'CASH' ? Colors.teal.shade700 : Colors.grey.shade300, width: selectedMetode == 'CASH' ? 2 : 1)
                          ),
                          child: Center(
                            child: Text('CASH', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: selectedMetode == 'CASH' ? Colors.white : Colors.grey.shade600))
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => selectedMetode = 'TF'),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedMetode == 'TF' ? Colors.blue.shade600 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selectedMetode == 'TF' ? Colors.blue.shade700 : Colors.grey.shade300, width: selectedMetode == 'TF' ? 2 : 1)
                          ),
                          child: Center(
                            child: Text('TRANSFER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: selectedMetode == 'TF' ? Colors.white : Colors.grey.shade600))
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
            actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.pop(context);
                  _eksekusiLunasinBB(notaId, selectedMetode);
                },
                child: const Text('Simpan & Lunasi', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          );
        }
      )
    );
  }

  Future<void> _eksekusiLunasinBB(int notaId, String metode) async { 
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/tanggungan/lunasin_bb/'), 
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'nota_id': notaId, 'metode': metode})
      ); 
      
      if (res.statusCode == 200) { 
        fetchData(); 
        if (mounted) showCustomSnackbar(context, 'Mantap! Tagihan BB berhasil dilunasi via $metode!'); 
      } else { 
        if (mounted) showCustomSnackbar(context, json.decode(res.body)['pesan'] ?? 'Gagal', isError: true); 
      }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Gagal menghubungi server!', isError: true);
    }
  }

  void konfirmasiSelesaiTF(int pId, String nama, String total) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Konfirmasi Transfer', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: Text('Apakah kamu sudah mentransfer uang sejumlah $total ke rekening $nama?\n\nAksi ini akan mencatat pengeluaran di Laporan Harian.', style: const TextStyle(height: 1.5, color: Colors.black87)),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Belum', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(context);
              _eksekusiSelesaiTF(pId);
            },
            child: const Text('Sudah Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }

  Future<void> _eksekusiSelesaiTF(int pId) async { 
    try {
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/tanggungan/selesai_tf/'), 
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'pembayaran_id': pId})
      ); 
      fetchData(); 
      if (mounted) showCustomSnackbar(context, 'Oke! Transfer masuk ke Laporan Harian.');
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Gagal update status transfer!', isError: true);
    }
  }

  @override void initState() { 
    super.initState();
    fetchData();
  }

  // Group list-of-map by nama → preserve order pertama kali muncul
  Map<String, List<dynamic>> _groupByNama(List source) {
    final Map<String, List<dynamic>> result = {};
    for (var item in source) {
      final String nama = (item['nama'] ?? '').toString();
      result.putIfAbsent(nama, () => []).add(item);
    }
    return result;
  }

  // Chip telp & rekening petani (rekening opsional)
  Widget _kontakChips(dynamic telp, dynamic rekening) {
    final String t = (telp ?? '').toString().trim();
    final String r = (rekening ?? '').toString().trim();
    if (t.isEmpty && r.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          if (t.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.green.shade200)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.phone_rounded, size: 11, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green.shade800)),
              ]),
            ),
          if (r.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.indigo.shade200)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.account_balance_rounded, size: 11, color: Colors.indigo.shade700),
                const SizedBox(width: 4),
                Text(r, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.indigo.shade800)),
              ]),
            ),
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
              Positioned(top: -100, right: -50, child: CircleAvatar(radius: 150, backgroundColor: Colors.teal.shade50.withOpacity(0.5))),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 60, left: 16, right: 24, bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22), onPressed: () => Navigator.pop(context)),
                            const Text('Keuangan Gudang', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5)),
                          ],
                        ),
                        InkWell(
                          onTap: fetchData,
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

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container( 
                            padding: const EdgeInsets.all(28.0), 
                            width: double.infinity,
                            decoration: BoxDecoration( 
                              gradient: LinearGradient(colors: [Colors.teal.shade900, Colors.teal.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight), 
                              borderRadius: BorderRadius.circular(28), 
                              boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))] 
                            ), 
                            child: Column( 
                              crossAxisAlignment: CrossAxisAlignment.start, 
                              children: [ 
                                Row( 
                                  children: [ 
                                    Icon(Icons.account_balance_wallet_rounded, color: Colors.teal.shade100, size: 24), 
                                    const SizedBox(width: 8), 
                                    Text('TOTAL SALDO GUDANG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.teal.shade100, letterSpacing: 1.5)), 
                                  ], 
                                ), 
                                const SizedBox(height: 16), 
                                Text(formatRp(saldoSekarang), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)), 
                                const SizedBox(height: 8), 
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Diperbarui secara real-time', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                                ), 
                              ] 
                            ) 
                          ), 
                          
                          const SizedBox(height: 36), 
                          
                          const Text('TAMBAH SALDO KAS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2, color: Colors.black45)),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 5))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Nominal Masuk', style: TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                                const SizedBox(height: 4),
                                TextField( 
                                  controller: nominalController, 
                                  keyboardType: TextInputType.number, 
                                  inputFormatters: [RibuanFormatter()], 
                                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.teal.shade900, letterSpacing: -1), 
                                  decoration: InputDecoration(
                                    prefixText: 'Rp ',
                                    prefixStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.teal.shade900),
                                    border: InputBorder.none,
                                    hintText: '0',
                                    hintStyle: TextStyle(color: Colors.grey.shade300),
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ), 
                                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                                
                                InkWell(
                                  onTap: () => setState(() => isAmpera = !isAmpera),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 24, height: 24,
                                          child: Checkbox(
                                            value: isAmpera,
                                            activeColor: Colors.amber.shade700,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                            onChanged: (val) => setState(() => isAmpera = val!),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(child: Text('Sumber dana kas dari Ampera', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87))),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                SizedBox( 
                                  width: double.infinity, 
                                  child: ElevatedButton.icon( 
                                    style: ElevatedButton.styleFrom( 
                                      backgroundColor: Colors.amber.shade700, 
                                      foregroundColor: Colors.white, 
                                      padding: const EdgeInsets.symmetric(vertical: 16), 
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                                      elevation: 0, 
                                    ), 
                                    onPressed: isLoading ? null : submitTambahSaldo, 
                                    icon: isLoading ? const SizedBox.shrink() : const Icon(Icons.add_card_rounded, size: 20),
                                    label: isLoading 
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                      : const Text('SIMPAN SALDO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)) 
                                  ), 
                                ) 
                              ],
                            ),
                          ),

                          const SizedBox(height: 40), 
                          
                          Row(
                            children: [
                              Container(width: 4, height: 16, decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 8),
                              const Text('TAGIHAN BELUM BAYAR (BB)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black45, letterSpacing: 1.2)),
                            ],
                          ),
                          const SizedBox(height: 16), 
                          
                          listBB.isEmpty
                            ? Container(
                                width: double.infinity, padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid)),
                                child: Column(
                                  children: [
                                    Icon(Icons.sentiment_very_satisfied_rounded, size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text('Hore! Semua nota sudah lunas.', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                            : Column(
                                children: _groupByNama(listBB).entries.map((entry) {
                                  final String nama = entry.key;
                                  final List notas = entry.value;
                                  final double totalAll = notas.fold(0.0, (sum, n) => sum + (double.tryParse(n['total'].toString()) ?? 0));
                                  final String fTotalAll = formatRp(totalAll);
                                  final bool isMulti = notas.length > 1;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.red.shade100),
                                      boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                      child: ExpansionTile(
                                        initiallyExpanded: !isMulti,
                                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        leading: CircleAvatar(backgroundColor: Colors.red.shade50, radius: 18, child: Icon(Icons.warning_rounded, color: Colors.red.shade600, size: 18)),
                                        title: Row(
                                          children: [
                                            Expanded(child: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87))),
                                            if (isMulti) Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                                              child: Text('${notas.length} nota', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.amber.shade900)),
                                            ),
                                          ],
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(isMulti ? 'Total Tagihan' : 'Tagihan', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                  const SizedBox(width: 8),
                                                  Text(fTotalAll, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.red.shade700)),
                                                ],
                                              ),
                                              _kontakChips(notas.first['no_telp'], notas.first['no_rekening']),
                                            ],
                                          ),
                                        ),
                                        iconColor: Colors.red.shade600,
                                        collapsedIconColor: Colors.red.shade400,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(color: Colors.red.shade50.withOpacity(0.3), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              children: notas.map<Widget>((bb) {
                                                final String fTotal = formatRp(bb['total']);
                                                return Container(
                                                  margin: const EdgeInsets.only(bottom: 8),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade100)),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)), child: Text('Nota #${bb['id']}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.red.shade800))),
                                                                const SizedBox(width: 6),
                                                                Text(bb['tgl'], style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(fTotal, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.red.shade700)),
                                                          ],
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.red.shade600, foregroundColor: Colors.white,
                                                          elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                        ),
                                                        onPressed: () => konfirmasiLunasinBB(bb['id'], bb['nama'], fTotal),
                                                        child: const Text('LUNASI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList()
                              ),

                          const SizedBox(height: 40), 
                          
                          Row(
                            children: [
                              Container(width: 4, height: 16, decoration: BoxDecoration(color: Colors.blue.shade700, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 8),
                              const Text('ANTRIAN TRANSFER PABRIK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black45, letterSpacing: 1.2)),
                            ],
                          ),
                          const SizedBox(height: 16), 

                          listTF.isEmpty
                            ? Container(
                                width: double.infinity, padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid)),
                                child: Column(
                                  children: [
                                    Icon(Icons.task_alt_rounded, size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text('Bagus! Tidak ada antrian transfer.', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                            : Column(
                                children: _groupByNama(listTF).entries.map((entry) {
                                  final String nama = entry.key;
                                  final List items = entry.value;
                                  final double totalAll = items.fold(0.0, (sum, n) => sum + (double.tryParse(n['nominal'].toString()) ?? 0));
                                  final String fTotalAll = formatRp(totalAll);
                                  final bool isMulti = items.length > 1;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.blue.shade100),
                                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                      child: ExpansionTile(
                                        initiallyExpanded: !isMulti,
                                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        leading: CircleAvatar(backgroundColor: Colors.blue.shade50, radius: 18, child: Icon(Icons.account_balance_rounded, color: Colors.blue.shade600, size: 18)),
                                        title: Row(
                                          children: [
                                            Expanded(child: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87))),
                                            if (isMulti) Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                                              child: Text('${items.length} TF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.amber.shade900)),
                                            ),
                                          ],
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(isMulti ? 'Total Antrian' : 'Antrian', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                  const SizedBox(width: 8),
                                                  Text(fTotalAll, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.blue.shade700)),
                                                ],
                                              ),
                                              _kontakChips(items.first['no_telp'], items.first['no_rekening']),
                                            ],
                                          ),
                                        ),
                                        iconColor: Colors.blue.shade600,
                                        collapsedIconColor: Colors.blue.shade400,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.3), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              children: items.map<Widget>((tf) {
                                                final String fNom = formatRp(tf['nominal']);
                                                return Container(
                                                  margin: const EdgeInsets.only(bottom: 8),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)), child: Text('TF', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blue.shade800))),
                                                                const SizedBox(width: 6),
                                                                Text(tf['tgl_tf'] ?? '-', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(fNom, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blue.shade700)),
                                                          ],
                                                        ),
                                                      ),
                                                      ElevatedButton.icon(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white,
                                                          elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                        ),
                                                        onPressed: () => konfirmasiSelesaiTF(tf['id'], tf['nama'], fNom),
                                                        icon: const Icon(Icons.check_rounded, size: 14),
                                                        label: const Text('SELESAI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList()
                              ),
                          const SizedBox(height: 40),
                        ] 
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
    ); 
  } 
}