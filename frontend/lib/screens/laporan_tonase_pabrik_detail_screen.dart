import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // <--- IMPORT SAKTI

import '../utils/constants.dart';
import '../utils/helpers.dart';

class LaporanTonasePabrikDetailScreen extends StatefulWidget {
  final dynamic lotId; 
  const LaporanTonasePabrikDetailScreen({super.key, required this.lotId});

  @override
  State<LaporanTonasePabrikDetailScreen> createState() => _LaporanTonasePabrikDetailScreenState();
}

class _LaporanTonasePabrikDetailScreenState extends State<LaporanTonasePabrikDetailScreen> {
  Map<String, dynamic>? data;
  bool isLoading = false;
  bool isPageLoading = true;

  Future<void> fetchDetail() async {
    setState(() => isLoading = true);
    try {
      String url = '${AppConfig.baseUrl}/api/lot/detail/${widget.lotId}/?_t=${DateTime.now().millisecondsSinceEpoch}';
      final res = await http.get(Uri.parse(url));
      
      if (res.statusCode == 200) {
        setState(() => data = json.decode(res.body));
      } else {
        if(mounted) showCustomSnackbar(context, 'Server menolak (Code ${res.statusCode})', isError: true);
      }
    } catch (e) {
      if(mounted) showCustomSnackbar(context, 'Gagal memuat rincian Lot', isError: true);
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
    fetchDetail();
  }

  // Helper Input Dialog Sultan
  Widget _buildDialogInput({required TextEditingController controller, required String hint, TextInputType type = TextInputType.text, List<TextInputFormatter>? formatters, String prefix = ''}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        inputFormatters: formatters,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        decoration: InputDecoration(
          labelText: hint,
          prefixText: prefix.isEmpty ? null : prefix,
          prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
          labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.normal, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // --- DIALOG EDIT INFO LOT (PABRIK, BL, VM, NAMA) ---
  // Init text input angka tanpa trailing .0 (kosong kalau <= 0)
  String _numInit(dynamic v) {
    final d = double.tryParse('$v') ?? 0;
    if (d <= 0) return '';
    return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
  }

  void dialogEditInfoLot() {
    final namaCtrl = TextEditingController(text: data!['nama_lot']);
    final pabrikCtrl = TextEditingController(text: data!['pabrik'] == '-' ? '' : data!['pabrik']);
    final gilinganBasahCtrl = TextEditingController(text: _numInit(data!['gilingan_basah']));
    final gilinganKeringCtrl = TextEditingController(text: _numInit(data!['gilingan_kering']));
    final hargaJualCtrl = TextEditingController(text: (double.tryParse('${data!['harga_jual_pabrik'] ?? 0}') ?? 0) > 0 ? formatRibuan(data!['harga_jual_pabrik']) : '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          bool isSubmitting = false;
          
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Edit Info Lot', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
            content: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogInput(controller: namaCtrl, hint: 'Nama / Kode Lot'),
                  _buildDialogInput(controller: pabrikCtrl, hint: 'Pabrik Tujuan'),
                  _buildDialogInput(controller: gilinganBasahCtrl, hint: 'Gilingan Pabrik Basah (→ BL)', type: const TextInputType.numberWithOptions(decimal: true)),
                  _buildDialogInput(controller: gilinganKeringCtrl, hint: 'Gilingan Pabrik Kering (→ VM)', type: const TextInputType.numberWithOptions(decimal: true)),
                  _buildDialogInput(controller: hargaJualCtrl, hint: 'Harga Jual Dasar Pabrik /Kg', type: const TextInputType.numberWithOptions(decimal: false), formatters: [RibuanFormatter()], prefix: 'Rp '),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
            actions: [
              TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white,
                  elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: isSubmitting ? null : () async {
                  setStateDialog(() => isSubmitting = true);
                  try {
                    // --- KUNCI SAKTI: TARIK NAMA USER ---
                    final prefs = await SharedPreferences.getInstance();
                    final currentUsername = prefs.getString('username') ?? 'Sistem';

                    await http.post(
                      Uri.parse('${AppConfig.baseUrl}/api/lot/edit/'),
                      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
                      body: json.encode({
                        'lot_id': widget.lotId.toString(), 
                        'nama_lot': namaCtrl.text, 
                        'pabrik': pabrikCtrl.text,
                        'gilingan_basah': gilinganBasahCtrl.text.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), ''),
                        'gilingan_kering': gilinganKeringCtrl.text.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), ''),
                        'harga_jual_pabrik': hargaJualCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
                        'username': currentUsername, // <--- KIRIM KE DJANGO
                      })
                    );
                    if(!mounted) return;
                    Navigator.pop(context);
                    fetchDetail(); 
                  } catch (e) {
                    showCustomSnackbar(context, 'Gagal terhubung ke server', isError: true);
                    setStateDialog(() => isSubmitting = false);
                  }
                },
                child: isSubmitting ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          );
        }
      ),
    );
  }

  // --- DIALOG HAPUS LOT ---
  void konfirmasiHapusLot() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Hapus Lot?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
          ],
        ),
        content: Text('Semua truk di dalam lot ini akan dikeluarkan secara otomatis (Truk tidak dihapus, hanya dilepas dari lot ini).', style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50, foregroundColor: Colors.red.shade700,
              elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            onPressed: () async {
              // --- KUNCI SAKTI: TARIK NAMA USER ---
              final prefs = await SharedPreferences.getInstance();
              final currentUsername = prefs.getString('username') ?? 'Sistem';

              await http.post(
                Uri.parse('${AppConfig.baseUrl}/api/lot/hapus/'), 
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'lot_id': widget.lotId.toString(),
                  'username': currentUsername, // <--- KIRIM KE DJANGO
                })
              );
              if(!mounted) return;
              Navigator.pop(context); 
              Navigator.pop(context); 
              showCustomSnackbar(context, 'Lot berhasil dihapus');
            }, 
            child: const Text('Ya, Hapus', style: TextStyle(fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  // --- DIALOG EDIT PER TRUK (HANYA INPUT TONASE) ---
  void dialogEditTonaseTruk(Map shipment) {
    String tAwal = shipment['tonase_pabrik'].toString();
    if (tAwal == '0' || tAwal == '0.0') tAwal = '';
    final tonaseCtrl = TextEditingController(text: tAwal);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          bool isSubmitting = false;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('Tonase: ${shipment['plat_mobil']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87)),
            content: _buildDialogInput(controller: tonaseCtrl, hint: 'Timbangan Pabrik (Kg)', type: const TextInputType.numberWithOptions(decimal: true)),
            actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
            actions: [
              TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white,
                  elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: isSubmitting ? null : () async {
                  setStateDialog(() => isSubmitting = true);
                  
                  String tonaseMurni = tonaseCtrl.text.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9\.]'), '');
                  double tonaseAngka = double.tryParse(tonaseMurni) ?? 0.0;

                  try {
                    // --- KUNCI SAKTI: TARIK NAMA USER ---
                    final prefs = await SharedPreferences.getInstance();
                    final currentUsername = prefs.getString('username') ?? 'Sistem';

                    await http.post(
                      Uri.parse('${AppConfig.baseUrl}/api/pengiriman/edit_pabrik/'),
                      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
                      body: json.encode({
                        'pengiriman_id': shipment['pengiriman_id'], 
                        'tonase_pabrik': tonaseAngka,
                        'username': currentUsername, // <--- KIRIM KE DJANGO
                      })
                    );
                    if(!mounted) return;
                    Navigator.pop(context);
                    fetchDetail(); 
                  } catch(e) {
                    showCustomSnackbar(context, 'Koneksi bermasalah!', isError: true);
                    setStateDialog(() => isSubmitting = false);
                  }
                },
                child: isSubmitting ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan Tonase', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          );
        }
      ),
    );
  }

  // Helper Format Uang Anti-Crash
  String _formatUangAman(dynamic value) {
    double parsed = double.tryParse(value.toString()) ?? 0.0;
    return formatRp(parsed);
  }

  // Rata-rata penyusutan LOT. Konvensi: naik (pabrik > gudang) = plus/hijau,
  // turun/susut (pabrik < gudang) = minus/oranye.
  Widget _buildPenyusutanRow() {
    final double pct = double.tryParse('${data!['avg_penyusutan_pct'] ?? 0}') ?? 0;
    final double kg = double.tryParse('${data!['total_penyusutan_kg'] ?? 0}') ?? 0;
    final bool ada = pct != 0 || kg != 0;
    final bool naik = kg > 0;
    final MaterialColor base = !ada ? Colors.grey : (naik ? Colors.green : Colors.orange);
    final String sign = kg > 0 ? '+' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(naik ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 16, color: base.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text('Rata-rata Penyusutan', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600))),
          Text(
            ada ? '$sign${pct.toStringAsFixed(2)}%  ($sign${formatTonase(kg)} Kg)' : 'Belum ditimbang',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: ada ? base.shade800 : Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // Kartu Analisa Harga & DRC per LOT
  Widget _buildAnalisaHargaCard() {
    final double hargaJual = double.tryParse('${data!['harga_jual_pabrik'] ?? 0}') ?? 0;
    final double modalGudang = double.tryParse('${data!['harga_modal_gudang'] ?? 0}') ?? 0;
    final double modalPabrik = double.tryParse('${data!['harga_modal_pabrik'] ?? 0}') ?? 0;
    final double drcGudang = double.tryParse('${data!['drc_gudang'] ?? 0}') ?? 0;
    final double drcPabrik = double.tryParse('${data!['drc_pabrik'] ?? 0}') ?? 0;
    final bool adaJual = hargaJual > 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 4, height: 16, decoration: BoxDecoration(color: Colors.teal.shade700, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('ANALISA HARGA & DRC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black45, letterSpacing: 1.2)),
            const Spacer(),
            Icon(Icons.edit_rounded, size: 13, color: Colors.teal.shade600),
            const SizedBox(width: 4),
            Text('Ketuk untuk Edit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.teal.shade700)),
          ]),
          const SizedBox(height: 12),
          _buildInfoRow('Harga Jual Dasar Pabrik', adaJual ? '${_formatUangAman(hargaJual)} /Kg' : 'Belum diisi', Icons.sell_rounded, valueColor: adaJual ? Colors.black87 : Colors.grey.shade400),
          Divider(height: 16, color: Colors.grey.shade200),
          _buildInfoRow('Harga Modal Gudang', modalGudang > 0 ? '${_formatUangAman(modalGudang)} /Kg' : '-', Icons.warehouse_rounded),
          Divider(height: 16, color: Colors.grey.shade200),
          _buildInfoRow('Harga Modal Pabrik', modalPabrik > 0 ? '${_formatUangAman(modalPabrik)} /Kg' : '-', Icons.factory_rounded),
          Divider(height: 16, color: Colors.grey.shade200),
          _buildInfoRow('DRC Gudang', (adaJual && drcGudang > 0) ? '${drcGudang.toStringAsFixed(2)}%' : '-', Icons.percent_rounded, valueColor: Colors.blue.shade700, iconColor: Colors.blue.shade700),
          Divider(height: 16, color: Colors.grey.shade200),
          _buildInfoRow('DRC Pabrik', (adaJual && drcPabrik > 0) ? '${drcPabrik.toStringAsFixed(2)}%' : '-', Icons.percent_rounded, valueColor: Colors.indigo.shade700, iconColor: Colors.indigo.shade700),
          if (!adaJual) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.shade100)),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, size: 14, color: Colors.amber.shade800),
                const SizedBox(width: 6),
                Expanded(child: Text('Isi "Harga Jual Dasar Pabrik" lewat Edit Info Lot buat lihat DRC.', style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w600))),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  // Helper Widget Info Pabrik
  Widget _buildInfoRow(String label, String value, IconData icon, {Color? valueColor, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor ?? Colors.teal.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isPageLoading) return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
    if (data == null) return const Scaffold(backgroundColor: Colors.white, body: Center(child: Text('Data tidak ditemukan.')));
    
    List shipments = data!['shipments'] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- BACKGROUND DEKORASI ---
          Positioned(top: -100, right: -50, child: CircleAvatar(radius: 150, backgroundColor: Colors.teal.shade50.withOpacity(0.5))),

          Column(
            children: [
              // --- HEADER SULTAN ---
              Container(
                padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22), onPressed: () => Navigator.pop(context)),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: Text(data!['nama_lot'] ?? 'Lot Detail', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: konfirmasiHapusLot,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
                        child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade600, size: 20),
                      ),
                    )
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: fetchDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- KARTU ESTIMASI MODAL SULTAN ---
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.teal.shade900, Colors.teal.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.warehouse_rounded, color: Colors.teal.shade100, size: 14),
                                          const SizedBox(width: 6),
                                          const Text('TIMBANGAN GUDANG', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('${formatTonase(data!['total_tonase_gudang'])} Kg', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                                    ]
                                  ),
                                  Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)), // Pembatas
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          const Text('TIMBANGAN PABRIK', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                          const SizedBox(width: 6),
                                          Icon(Icons.factory_rounded, color: Colors.teal.shade100, size: 14),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('${formatTonase(data!['total_tonase_pabrik'])} Kg', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                                    ]
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // INFO PABRIK & BL DI DALAM KARTU (tap untuk edit)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: dialogEditInfoLot,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                    child: Column(
                                      children: [
                                        Row(children: [
                                          const Text('INFO LOT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black38, letterSpacing: 1)),
                                          const Spacer(),
                                          Icon(Icons.edit_rounded, size: 13, color: Colors.teal.shade600),
                                          const SizedBox(width: 4),
                                          Text('Ketuk untuk Edit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.teal.shade700)),
                                        ]),
                                        Divider(height: 14, color: Colors.grey.shade200),
                                        _buildInfoRow('Pabrik Tujuan', data!['pabrik'] ?? '-', Icons.domain_rounded),
                                        Divider(height: 16, color: Colors.grey.shade200),
                                        _buildInfoRow('Gilingan Basah', (double.tryParse('${data!['gilingan_basah'] ?? 0}') ?? 0) > 0 ? '${formatTonase(data!['gilingan_basah'])} Kg' : '-', Icons.water_drop_rounded),
                                        Divider(height: 16, color: Colors.grey.shade200),
                                        _buildInfoRow('Gilingan Kering', (double.tryParse('${data!['gilingan_kering'] ?? 0}') ?? 0) > 0 ? '${formatTonase(data!['gilingan_kering'])} Kg' : '-', Icons.grain_rounded),
                                        Divider(height: 16, color: Colors.grey.shade200),
                                        _buildInfoRow('BL', (double.tryParse('${data!['bl'] ?? 0}') ?? 0) > 0 ? '${formatTonase(data!['bl'])}%' : '-', Icons.receipt_long_rounded, valueColor: Colors.teal.shade800),
                                        Divider(height: 16, color: Colors.grey.shade200),
                                        _buildInfoRow('VM', (double.tryParse('${data!['vm'] ?? 0}') ?? 0) > 0 ? '${formatTonase(data!['vm'])}%' : '-', Icons.confirmation_number_rounded, valueColor: Colors.teal.shade800),
                                        Divider(height: 16, color: Colors.grey.shade200),
                                        _buildPenyusutanRow(),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- KARTU ANALISA HARGA & DRC (tap untuk edit harga jual) ---
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: dialogEditInfoLot,
                            borderRadius: BorderRadius.circular(20),
                            child: _buildAnalisaHargaCard(),
                          ),
                        ),

                        const SizedBox(height: 36),
                        
                        // --- DAFTAR TRUK ---
                        Row(
                          children: [
                            Container(width: 4, height: 16, decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 8),
                            const Text('RINCIAN TRUK / WADAH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black45, letterSpacing: 1.2)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        shipments.isEmpty 
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Column(
                                  children: [
                                    Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey.shade300),
                                    const SizedBox(height: 16),
                                    Text('Belum ada truk di Lot ini.', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                ),
                              )
                            )
                          : Column(
                              children: shipments.map((s) {
                                double tPabrik = double.tryParse(s['tonase_pabrik'].toString()) ?? 0.0;
                                bool belumTimbang = tPabrik <= 0;
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.shade200),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        // Header: Plat & Tanggal & Edit Button
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                                                  child: Icon(Icons.local_shipping_rounded, color: Colors.amber.shade800, size: 16),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(s['plat_mobil'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87)),
                                                    const SizedBox(height: 2),
                                                    Text(s['tanggal'] ?? '-', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            InkWell(
                                              onTap: () => dialogEditTonaseTruk(s),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit_rounded, color: Colors.blue.shade700, size: 12),
                                                    const SizedBox(width: 4),
                                                    Text('Tonase', style: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.w900)),
                                                  ],
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                        
                                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                        
                                        // Footer: Perbandingan Gudang vs Pabrik
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Timbangan Gudang', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Text('${formatTonase(s['total_tonase_gudang'])} Kg', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87)),
                                                Text(_formatUangAman(s['total_uang_gudang']), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                const Text('Timbangan Pabrik', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Text(
                                                  belumTimbang ? 'Belum Input' : '${formatTonase(s['tonase_pabrik'])} Kg',
                                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: belumTimbang ? Colors.red.shade600 : Colors.amber.shade900)
                                                ),
                                                Text('Disimpan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: belumTimbang ? Colors.transparent : Colors.grey.shade500)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        // --- PENYUSUTAN PER MOBIL (naik = +/hijau, turun = -/oranye) ---
                                        if (!belumTimbang) ...[
                                          const SizedBox(height: 12),
                                          Builder(builder: (_) {
                                            final double pPct = double.tryParse('${s['penyusutan_pct'] ?? 0}') ?? 0;
                                            final double pKg = double.tryParse('${s['penyusutan_kg'] ?? 0}') ?? 0;
                                            final bool naik = pKg > 0;
                                            final MaterialColor base = pKg == 0 ? Colors.grey : (naik ? Colors.green : Colors.orange);
                                            final String sign = pKg > 0 ? '+' : '';
                                            return Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: base.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: base.shade100),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(naik ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: base.shade800),
                                                  const SizedBox(width: 6),
                                                  Text('Penyusutan: ', style: TextStyle(fontSize: 12, color: base.shade900, fontWeight: FontWeight.w700)),
                                                  Text('$sign${pPct.toStringAsFixed(2)}%', style: TextStyle(fontSize: 13, color: base.shade900, fontWeight: FontWeight.w900)),
                                                  Text('  ($sign${formatTonase(pKg)} Kg)', style: TextStyle(fontSize: 11, color: base.shade800, fontWeight: FontWeight.w600)),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            )
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}