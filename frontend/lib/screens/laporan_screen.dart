import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart'; 

import '../utils/helpers.dart';
import '../utils/constants.dart'; 

class LaporanScreen extends StatefulWidget { 
  const LaporanScreen({super.key}); 
  @override State<LaporanScreen> createState() => _LaporanScreenState(); 
}

class _LaporanScreenState extends State<LaporanScreen> { 
  DateTime selectedDate = DateTime.now(); 
  List transaksiNota = []; 
  List transaksiKasMasuk = []; 
  List transaksiKasKeluarLain = []; 
  List transaksiPengeluaran = []; 
  List transaksiPelunasan = []; // <--- TAMBAHAN LIST BARU
  bool isLoading = false; 
  double totalKasMasukLaporan = 0; 
  double totalKasKeluarLaporan = 0; 

  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance; 
  
  Future<void> fetchLaporan() async { 
    setState(() => isLoading = true); 
    try {
      String tglStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}"; 
      String url = '${AppConfig.baseUrl}/api/laporan/?tanggal=$tglStr&_t=${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await http.get(Uri.parse(url)); 
      
      if (response.statusCode == 200) { 
        final data = json.decode(response.body); 
        setState(() { 
          transaksiNota = data['nota'] ?? []; 
          transaksiKasMasuk = data['kas_masuk'] ?? []; 
          transaksiKasKeluarLain = data['kas_keluar_lain'] ?? []; 
          transaksiPengeluaran = data['pengeluaran'] ?? []; 
          transaksiPelunasan = data['pelunasan_hutang'] ?? []; // <--- TARIK DATA PELUNASAN
          
          if(data['summary'] != null) {
            totalKasMasukLaporan = double.tryParse(data['summary']['total_kas_masuk'].toString()) ?? 0; 
            totalKasKeluarLaporan = double.tryParse(data['summary']['total_kas_keluar'].toString()) ?? 0; 
          }
        }); 
      } 
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Gagal mengambil data laporan!', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false); 
    }
  } 
  
  @override void initState() { 
    super.initState(); 
    fetchLaporan(); 
  } 

  String _formatTglPendek(DateTime tgl) {
    return "${tgl.day.toString().padLeft(2, '0')}/${tgl.month.toString().padLeft(2, '0')}/${tgl.year}";
  }

  String _formatAwal(double val) {
    return val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  // =======================================================================
  // DIALOG EDIT TRANSAKSI UMUM
  // =======================================================================
  void _tampilkanDialogEditUmum(String tipe, int id, String keteranganLama, double nominalLama) {
    final ketController = TextEditingController(text: keteranganLama);
    final nomController = TextEditingController(text: _formatAwal(nominalLama));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          bool isSubmittingDialog = false; 
          bool isDialogClosed = false;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('Edit $tipe', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: TextField(
                    controller: ketController,
                    decoration: const InputDecoration(labelText: 'Keterangan', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: TextField(
                    controller: nomController, keyboardType: TextInputType.number, inputFormatters: [RibuanFormatter()],
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                    decoration: const InputDecoration(labelText: 'Nominal Baru', prefixText: 'Rp ', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
            actions: [
              TextButton(onPressed: isSubmittingDialog ? null : () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                onPressed: isSubmittingDialog ? null : () async {
                  setStateDialog(() => isSubmittingDialog = true); 
                  String nominalMurni = nomController.text.replaceAll(RegExp(r'[^0-9]'), '');
                  int nominalAngka = int.tryParse(nominalMurni) ?? 0;
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final currentUsername = prefs.getString('username') ?? 'Sistem';

                    final res = await http.post(
                      Uri.parse('${AppConfig.baseUrl}/api/laporan/edit/'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({'tipe': tipe, 'id': id, 'keterangan': ketController.text, 'nominal': nominalAngka, 'username': currentUsername})
                    );
                    if (!mounted) return;
                    if (res.statusCode == 200) {
                        isDialogClosed = true; 
                        Navigator.pop(context);
                        showCustomSnackbar(context, 'Berhasil diupdate!');
                        fetchLaporan(); 
                    }
                  } catch (e) {
                    if (mounted) showCustomSnackbar(context, 'Koneksi bermasalah!', isError: true);
                  } finally {
                    if (!isDialogClosed) setStateDialog(() => isSubmittingDialog = false); 
                  }
                },
                child: isSubmittingDialog ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  // =======================================================================
  // DIALOG EDIT NOTA KHUSUS
  // =======================================================================
  void _tampilkanDialogEditNota(int id, String namaPelanggan, double beratLama, double hargaLama, double totalLama) {
    String strBerat = beratLama.toString();
    if (strBerat.endsWith('.0')) strBerat = strBerat.replaceAll('.0', '');
    
    final beratController = TextEditingController(text: strBerat);
    final hargaController = TextEditingController(text: _formatAwal(hargaLama));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          bool isSubmittingDialog = false;
          bool isDialogClosed = false; 

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.edit_document, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                Expanded(child: Text('Edit Nota: $namaPelanggan', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87), overflow: TextOverflow.ellipsis)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Bersih Awal:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      Text(formatRp(totalLama), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: TextField(
                    controller: beratController, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(labelText: 'Revisi Berat (Kg)', labelStyle: TextStyle(fontSize: 13), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: TextField(
                    controller: hargaController, inputFormatters: [RibuanFormatter()], keyboardType: TextInputType.number,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                    decoration: const InputDecoration(labelText: 'Revisi Harga Dasar/Kg', labelStyle: TextStyle(fontSize: 13), prefixText: 'Rp ', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Sistem akan otomatis menghitung ulang komisi, buruh, dan tagihan kasir setelah disimpan.', style: TextStyle(fontSize: 10, color: Colors.grey, height: 1.4, fontStyle: FontStyle.italic)),
              ],
            ),
            actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
            actions: [
              TextButton(onPressed: isSubmittingDialog ? null : () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: isSubmittingDialog ? null : () async {
                  if (beratController.text.isEmpty || hargaController.text.isEmpty) { showCustomSnackbar(context, 'Berat dan Harga wajib diisi!', isError: true); return; }
                  setStateDialog(() => isSubmittingDialog = true);

                  String hargaMurni = hargaController.text.replaceAll(RegExp(r'[^0-9]'), '');
                  String beratMurni = beratController.text.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9\.]'), '');

                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final currentUsername = prefs.getString('username') ?? 'Sistem';

                    final res = await http.post(
                      Uri.parse('${AppConfig.baseUrl}/api/laporan/edit/'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({'tipe': 'Nota', 'id': id, 'berat_kg': double.tryParse(beratMurni) ?? 0, 'harga_per_kg': int.tryParse(hargaMurni) ?? 0, 'username': currentUsername})
                    );
                    
                    if (!mounted) return;
                    if (res.statusCode == 200) {
                        isDialogClosed = true;
                        Navigator.pop(context);
                        showCustomSnackbar(context, 'Nota berhasil diupdate!');
                        fetchLaporan();
                    }
                  } catch (e) {
                    if (mounted) showCustomSnackbar(context, 'Koneksi bermasalah!', isError: true);
                  } finally {
                    if (!isDialogClosed) setStateDialog(() => isSubmittingDialog = false);
                  }
                },
                child: isSubmittingDialog ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan Nota', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  // =======================================================================
  // DIALOG CETAK ULANG NOTA (RE-PRINT)
  // =======================================================================
  void _tampilkanDialogCetakUlang(Map t) {
    List<BluetoothDevice> devices = [];
    BluetoothDevice? selectedDevice;
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          
          void getDevices() async {
            devices = await bluetooth.getBondedDevices();
            try {
              selectedDevice = devices.firstWhere((d) => d.name != null && d.name!.contains('RPP02N'));
            } catch (e) {
              if (devices.isNotEmpty) selectedDevice = devices[0];
            }
            if (mounted) setStateDialog(() {});
          }

          if (devices.isEmpty) getDevices();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.print_rounded, color: Colors.teal), SizedBox(width: 8),
                Text('Cetak Ulang Nota', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nota #${t['id']} - ${t['nama_pelanggan']}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                const SizedBox(height: 16),
                const Text('Pilih Printer Bluetooth:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<BluetoothDevice>(
                      isExpanded: true,
                      value: selectedDevice,
                      hint: const Text('Mencari printer...'),
                      items: devices.map((e) => DropdownMenuItem(value: e, child: Text(e.name ?? 'Unknown'))).toList(),
                      onChanged: isProcessing ? null : (val) => setStateDialog(() => selectedDevice = val),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(context), 
                child: const Text('Batal', style: TextStyle(color: Colors.grey))
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: isProcessing ? const SizedBox.shrink() : const Icon(Icons.print, size: 18),
                label: isProcessing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('CETAK RE-PRINT'),
                onPressed: isProcessing ? null : () async {
                  if (selectedDevice == null) { showCustomSnackbar(context, 'Pilih printer dulu Bos!', isError: true); return; }
                  
                  setStateDialog(() => isProcessing = true);

                  bool? isConnected = await bluetooth.isConnected;
                  if (isConnected != true) {
                    try {
                      await bluetooth.connect(selectedDevice!);
                    } catch (e) {
                      setStateDialog(() => isProcessing = false);
                      showCustomSnackbar(context, 'Gagal nyambung ke Printer!', isError: true);
                      return; 
                    }
                  }

                  double berat = double.tryParse(t['berat_kg'].toString()) ?? 0;
                  double harga = double.tryParse(t['harga_per_kg'].toString()) ?? 0;
                  double totalBersihApi = double.tryParse(t['total_bersih'].toString()) ?? 0;
                  
                  double kotor = berat * harga;
                  double komisi = (kotor * 0.01 / 1000).ceil() * 1000.0;
                  double buruh = (berat * 35 / 1000).ceil() * 1000.0;
                  double materai = 6000;
                  
                  double sisaSebelumKasbon = kotor - komisi - buruh - materai;
                  double kasbon = 0;
                  
                  if (totalBersihApi > sisaSebelumKasbon) {
                      materai = 0; 
                      sisaSebelumKasbon = kotor - komisi - buruh;
                  }
                  if (sisaSebelumKasbon > totalBersihApi) {
                      kasbon = sisaSebelumKasbon - totalBersihApi;
                  }

                  _eksekusiCetakRePrint(t['id'].toString(), t['nama_pelanggan'], t['jam'] ?? '', t['metode'] ?? 'CASH', berat, harga, kotor, komisi, buruh, materai, kasbon, totalBersihApi);
                  
                  await Future.delayed(const Duration(seconds: 3));

                  if (!mounted) return;
                  Navigator.pop(context); 
                  showCustomSnackbar(context, 'Berhasil mencetak ulang!');
                },
              )
            ],
          );
        }
      ),
    );
  }

  void _eksekusiCetakRePrint(String notaId, String nama, String jam, String metode, double berat, double harga, double kotor, double komisi, double buruh, double materai, double kasbon, double bersih) {
    String tglStr = "${selectedDate.day.toString().padLeft(2,'0')}/${selectedDate.month.toString().padLeft(2,'0')}/${selectedDate.year} $jam";

    bluetooth.printNewLine();
    bluetooth.printCustom("PT SINAR BULIAN JAYA", 2, 1);
    bluetooth.printCustom("Pembelian Karet Basah", 0, 1);
    bluetooth.printCustom("( COPY RE-PRINT )", 1, 1); 
    bluetooth.printCustom("--------------------------------", 0, 1);
    
    bluetooth.printLeftRight("Nota:", "#$notaId", 0);
    bluetooth.printLeftRight("Tgl:", tglStr, 0);
    bluetooth.printLeftRight("Petani:", nama, 0);
    bluetooth.printLeftRight("Metode:", metode, 0); 
    bluetooth.printCustom("--------------------------------", 0, 1);
    
    bluetooth.printLeftRight("Berat:", "${berat.toStringAsFixed(1)} Kg", 0);
    bluetooth.printLeftRight("Harga/Kg:", formatRp(harga), 0);
    bluetooth.printCustom("--------------------------------", 0, 1);
    
    bluetooth.printLeftRight("Total Kotor", formatRp(kotor), 1); 
    
    if (komisi > 0) bluetooth.printLeftRight("Pot. Komisi", "- ${formatRp(komisi)}", 0);
    if (buruh > 0) bluetooth.printLeftRight("Pot. Buruh", "- ${formatRp(buruh)}", 0);
    if (materai > 0) bluetooth.printLeftRight("Pot. Materai", "- ${formatRp(materai)}", 0);
    if (kasbon > 0) bluetooth.printLeftRight("Pot. Kasbon", "- ${formatRp(kasbon)}", 0);
    
    bluetooth.printCustom("--------------------------------", 0, 1);
    bluetooth.printLeftRight("TOTAL BERSIH", formatRp(bersih), 2); 

    bluetooth.printNewLine();
    bluetooth.printCustom("Terima Kasih", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printNewLine();
    bluetooth.printNewLine();
  }

  // =======================================================================
  // UI HELPER COMPONENTS
  // =======================================================================
  Widget _buildSectionHeader(String title, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 16),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black54, fontSize: 12, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  // --- PARAMETER showEditIcon DITAMBAH BIAR PELUNASAN GAK BISA DIEDIT MANUAL ---
  Widget _buildTransactionCard({required String title, required String subtitle, required String amountText, required Color color, required VoidCallback onTap, bool isMinus = false, bool showEditIcon = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3)), boxShadow: [BoxShadow(color: color.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16), onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500))])),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(amountText, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)), 
                  if (showEditIcon) ...[
                    const SizedBox(width: 12), 
                    Icon(Icons.edit_rounded, size: 16, color: Colors.grey.shade300)
                  ]
                ])
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === BUILDER BARU: 1 CARD PER NOTA (group split payment di dalam 1 card) ===
  Widget _buildNotaCardGrouped(Map g) {
    final List payments = g['payments'] ?? [];
    final bool isSplit = payments.length > 1;
    final String namaPelanggan = g['nama_pelanggan'] ?? '-';
    final String jam = g['jam'] ?? '-';
    final double berat = double.tryParse((g['berat_kg'] ?? 0).toString()) ?? 0;
    final double harga = double.tryParse((g['harga_per_kg'] ?? 0).toString()) ?? 0;
    final double totalNotaFull = double.tryParse((g['total_nota_full'] ?? 0).toString()) ?? 0;
    final int notaId = g['id'] is int ? g['id'] as int : int.tryParse((g['id'] ?? '0').toString()) ?? 0;

    // Cek apakah ada BB di dalam payments
    final bool hasBB = payments.any((p) => p['metode'] == 'BB');
    final Color headerColor = hasBB ? Colors.red.shade600 : Colors.teal.shade700;

    // Breakdown nota (komisi/buruh/materai/kasbon) — pakai total NOTA UTUH
    double kotor = berat * harga;
    double komisi = (kotor * 0.01 / 1000).ceil() * 1000.0;
    double buruh = (berat * 35 / 1000).ceil() * 1000.0;
    double materai = 6000;
    double sisaSebelumKasbon = kotor - komisi - buruh - materai;
    double kasbon = 0;
    if (totalNotaFull > sisaSebelumKasbon) {
      materai = 0;
      sisaSebelumKasbon = kotor - komisi - buruh;
    }
    if (sisaSebelumKasbon > totalNotaFull) {
      kasbon = sisaSebelumKasbon - totalNotaFull;
    }

    // Build payment summary string utk subtitle (e.g. "CASH 20jt + BB 5jt")
    String paymentSummary = payments.map((p) {
      final double n = double.tryParse((p['nominal'] ?? 0).toString()) ?? 0;
      return '${p['metode']} ${_formatRpShort(n)}';
    }).join(' + ');

    Color colorForMetode(String? m) {
      switch (m) {
        case 'BB': return Colors.red.shade600;
        case 'TRANSFER': return Colors.blue.shade700;
        case 'AMPERA': return Colors.purple.shade700;
        default: return Colors.green.shade700; // CASH
      }
    }

    IconData iconForMetode(String? m) {
      switch (m) {
        case 'BB': return Icons.warning_amber_rounded;
        case 'TRANSFER': return Icons.account_balance_rounded;
        case 'AMPERA': return Icons.swap_horiz_rounded;
        default: return Icons.payments_rounded; // CASH
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: headerColor.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: headerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.receipt_rounded, color: headerColor, size: 20),
          ),
          title: Text(namaPelanggan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(jam, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (isSplit)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Text('SPLIT ${payments.length}x', style: TextStyle(color: Colors.amber.shade900, fontSize: 9, fontWeight: FontWeight.w900)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: headerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(payments.first['metode'] ?? '-', style: TextStyle(color: headerColor, fontSize: 9, fontWeight: FontWeight.w900)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(paymentSummary, style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatRp(totalNotaFull), style: TextStyle(color: headerColor, fontWeight: FontWeight.w900, fontSize: 14)),
              if (isSplit) Text('Total Nota', style: TextStyle(fontSize: 8, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('No. Nota', style: TextStyle(fontSize: 12, color: Colors.black54)), Text('#$notaId', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Berat', style: TextStyle(fontSize: 12, color: Colors.black54)), Text('${berat.toStringAsFixed(1)} Kg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Harga/Kg', style: TextStyle(fontSize: 12, color: Colors.black54)), Text(formatRp(harga), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),

                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),

                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Kotor', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)), Text(formatRp(kotor), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))]),
                  if (komisi > 0) const SizedBox(height: 6),
                  if (komisi > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pot. Komisi', style: TextStyle(fontSize: 12, color: Colors.red.shade400)), Text('- ${formatRp(komisi)}', style: TextStyle(fontSize: 12, color: Colors.red.shade600, fontWeight: FontWeight.bold))]),
                  if (buruh > 0) const SizedBox(height: 6),
                  if (buruh > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pot. Buruh', style: TextStyle(fontSize: 12, color: Colors.red.shade400)), Text('- ${formatRp(buruh)}', style: TextStyle(fontSize: 12, color: Colors.red.shade600, fontWeight: FontWeight.bold))]),
                  if (materai > 0) const SizedBox(height: 6),
                  if (materai > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pot. Materai', style: TextStyle(fontSize: 12, color: Colors.red.shade400)), Text('- ${formatRp(materai)}', style: TextStyle(fontSize: 12, color: Colors.red.shade600, fontWeight: FontWeight.bold))]),
                  if (kasbon > 0) const SizedBox(height: 6),
                  if (kasbon > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pot. Kasbon', style: TextStyle(fontSize: 12, color: Colors.red.shade400)), Text('- ${formatRp(kasbon)}', style: TextStyle(fontSize: 12, color: Colors.red.shade600, fontWeight: FontWeight.bold))]),

                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),

                  // PAYMENT BREAKDOWN
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Komposisi Pembayaran', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
                    if (isSplit) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                      child: Text('${payments.length} BAGIAN', style: TextStyle(color: Colors.amber.shade900, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  ...payments.asMap().entries.map((e) {
                    final i = e.key;
                    final p = e.value;
                    final Color cm = colorForMetode(p['metode']);
                    final double nominal = double.tryParse((p['nominal'] ?? 0).toString()) ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: cm.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cm.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: cm.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                            child: Icon(iconForMetode(p['metode']), size: 14, color: cm),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['metode'] ?? '-', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: cm)),
                                if (isSplit) Text('Bagian ${i + 1} dari ${payments.length}', style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Text(formatRp(nominal), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: cm)),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.teal.shade700, side: BorderSide(color: Colors.teal.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          icon: const Icon(Icons.edit_note_rounded, size: 16),
                          label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => _tampilkanDialogEditNota(notaId, namaPelanggan, berat, harga, totalNotaFull),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          icon: const Icon(Icons.print_rounded, size: 16),
                          label: const Text('Cetak Ulang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => _tampilkanDialogCetakUlang({
                            'id': notaId,
                            'nama_pelanggan': namaPelanggan,
                            'jam': jam,
                            'metode': isSplit ? 'SPLIT' : (payments.first['metode'] ?? 'CASH'),
                            'berat_kg': berat,
                            'harga_per_kg': harga,
                            'total_bersih': totalNotaFull,
                          }),
                        ),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  String _formatRpShort(double n) {
    if (n >= 1000000) return 'Rp${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}jt';
    if (n >= 1000) return 'Rp${(n / 1000).toStringAsFixed(0)}rb';
    return 'Rp${n.toStringAsFixed(0)}';
  }

  Widget _buildNotaCard(Map t) {
    Color badgeColor = t['metode'] == 'BB' ? Colors.red.shade600 : Colors.teal.shade700;

    double berat = double.tryParse(t['berat_kg'].toString()) ?? 0;
    double harga = double.tryParse(t['harga_per_kg'].toString()) ?? 0;
    double totalBersihApi = double.tryParse(t['total_bersih'].toString()) ?? 0;

    // Split-part info
    final bool isSplitPart = t['is_split_part'] == true;
    final int? splitIdx = t['split_part_index'] is int ? t['split_part_index'] as int : null;
    final int? splitTotal = t['split_total_parts'] is int ? t['split_total_parts'] as int : null;
    final double totalNotaFull = double.tryParse((t['total_nota_full'] ?? totalBersihApi).toString()) ?? totalBersihApi;

    // Untuk kalkulasi breakdown (komisi/buruh/materai/kasbon), pakai total nota utuh — bukan nominal per bagian
    double kotor = berat * harga;
    double komisi = (kotor * 0.01 / 1000).ceil() * 1000.0;
    double buruh = (berat * 35 / 1000).ceil() * 1000.0;
    double materai = 6000;

    double sisaSebelumKasbon = kotor - komisi - buruh - materai;
    double kasbon = 0;

    if (totalNotaFull > sisaSebelumKasbon) {
        materai = 0;
        sisaSebelumKasbon = kotor - komisi - buruh;
    }
    if (sisaSebelumKasbon > totalNotaFull) {
        kasbon = sisaSebelumKasbon - totalNotaFull;
    }

    // Split-part: render simplified card (tanpa expandable breakdown)
    if (isSplitPart) {
      final String partLabel = (splitIdx != null && splitTotal != null) ? 'BAGIAN $splitIdx/$splitTotal' : 'SPLIT';
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: badgeColor.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.call_split_rounded, color: badgeColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(t['nama_pelanggan'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                      const SizedBox(width: 6),
                      Text('#${t['id']}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
                        child: Text(t['metode'] ?? '-', style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 6),
                      Text(partLabel, style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      Icon(Icons.access_time_rounded, size: 10, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Text(t['jam'] ?? '-', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            Text(formatRp(totalBersihApi), style: TextStyle(color: badgeColor, fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: badgeColor.withOpacity(0.3)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.receipt_rounded, color: badgeColor, size: 20)),
          title: Text(t['nama_pelanggan'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade500), const SizedBox(width: 4),
                Text(t['jam'] ?? '-', style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(t['metode'], style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.w900))),
              ],
            ),
          ),
          trailing: Text(formatRp(totalBersihApi), style: TextStyle(color: badgeColor, fontWeight: FontWeight.w900, fontSize: 14)),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('No. Nota', style: TextStyle(fontSize: 12, color: Colors.black54)), Text('#${t['id']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Berat', style: TextStyle(fontSize: 12, color: Colors.black54)), Text('${berat.toStringAsFixed(1)} Kg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Harga/Kg', style: TextStyle(fontSize: 12, color: Colors.black54)), Text(formatRp(harga), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                  
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Colors.black12)),
                  
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Kotor', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)), Text(formatRp(kotor), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))]),
                  if (komisi > 0) const SizedBox(height: 6),
                  if (komisi > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pot. Komisi', style: TextStyle(fontSize: 12, color: Colors.red.shade400)), Text('- ${formatRp(komisi)}', style: TextStyle(fontSize: 12, color: Colors.red.shade600, fontWeight: FontWeight.bold))]),
                  if (buruh > 0) const SizedBox(height: 6),
                  if (buruh > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pot. Buruh', style: TextStyle(fontSize: 12, color: Colors.red.shade400)), Text('- ${formatRp(buruh)}', style: TextStyle(fontSize: 12, color: Colors.red.shade600, fontWeight: FontWeight.bold))]),
                  if (materai > 0) const SizedBox(height: 6),
                  if (materai > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pot. Materai', style: TextStyle(fontSize: 12, color: Colors.red.shade400)), Text('- ${formatRp(materai)}', style: TextStyle(fontSize: 12, color: Colors.red.shade600, fontWeight: FontWeight.bold))]),
                  if (kasbon > 0) const SizedBox(height: 6),
                  if (kasbon > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pot. Kasbon', style: TextStyle(fontSize: 12, color: Colors.red.shade400)), Text('- ${formatRp(kasbon)}', style: TextStyle(fontSize: 12, color: Colors.red.shade600, fontWeight: FontWeight.bold))]),

                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.teal.shade700, side: BorderSide(color: Colors.teal.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          icon: const Icon(Icons.edit_note_rounded, size: 16),
                          label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => _tampilkanDialogEditNota(t['id'], t['nama_pelanggan'], double.parse(t['berat_kg'].toString()), double.parse((t['harga_per_kg'] ?? 0).toString()), double.parse((t['total_bersih'] ?? 0).toString())),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          icon: const Icon(Icons.print_rounded, size: 16),
                          label: const Text('Cetak Ulang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => _tampilkanDialogCetakUlang(t),
                        ),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  
  // =======================================================================
  // MAIN BUILDER
  // =======================================================================
  @override 
  Widget build(BuildContext context) { 
    double totalKg = 0;
    double totalBB = 0;
    for (var t in transaksiNota) {
      // Berat hanya dihitung pada row pertama (untuk hindari double-count saat split payment)
      final bool isSplitPart = t['is_split_part'] == true;
      final bool isFirstPart = t['is_first_part'] != false;
      if (!isSplitPart || isFirstPart) {
        totalKg += double.parse((t['berat_kg'] ?? 0).toString());
      }
      // BB hanya dihitung pada row dengan metode 'BB' (nominal sudah merupakan porsi BB-nya saja)
      if (t['metode'] == 'BB') {
        totalBB += double.parse((t['total_bersih'] ?? 0).toString());
      }
    }

    // Group rows per nota (id) supaya 1 nota = 1 card meskipun split payment
    final Map<int, Map<String, dynamic>> _groupedMap = {};
    for (var t in transaksiNota) {
      final int notaId = (t['id'] is int) ? t['id'] : int.tryParse(t['id'].toString()) ?? -1;
      if (!_groupedMap.containsKey(notaId)) {
        _groupedMap[notaId] = {
          'id': notaId,
          'nama_pelanggan': t['nama_pelanggan'],
          'jam': t['jam'],
          'berat_kg': t['berat_kg'],
          'harga_per_kg': t['harga_per_kg'],
          'status_bayar': t['status_bayar'],
          'total_nota_full': t['total_nota_full'] ?? t['total_bersih'],
          'payments': <Map>[],
        };
      }
      _groupedMap[notaId]!['payments'].add({
        'metode': t['metode'],
        'nominal': t['total_bersih'],
        'pembayaran_id': t['pembayaran_id'],
      });
    }
    final List<Map<String, dynamic>> groupedNotas = _groupedMap.values.toList();

    bool isDataKosong = transaksiKasMasuk.isEmpty && transaksiNota.isEmpty && transaksiPengeluaran.isEmpty && transaksiKasKeluarLain.isEmpty && transaksiPelunasan.isEmpty;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(top: -100, left: -50, child: CircleAvatar(radius: 150, backgroundColor: Colors.teal.shade50.withOpacity(0.4))),

          Column(
            children: [
              // --- HEADER ---
              Container(
                padding: const EdgeInsets.only(top: 60, left: 16, right: 24, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22), onPressed: () => Navigator.pop(context)),
                        const Text('Rekap Harian', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5)),
                      ],
                    ),
                    InkWell(
                      onTap: () async { 
                        final tgl = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: Colors.teal.shade800)), child: child!)); 
                        if(tgl != null){ setState(()=> selectedDate=tgl); fetchLaporan();} 
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.teal.shade100)),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_rounded, color: Colors.teal.shade800, size: 16), const SizedBox(width: 6),
                            Text(_formatTglPendek(selectedDate), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal.shade900)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),

              if (totalBB > 0 && !isLoading)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade100)),
                  child: Row(
                    children: [
                      Icon(Icons.warning_rounded, color: Colors.red.shade600, size: 20), const SizedBox(width: 12),
                      Expanded(child: Text("Terdapat Nota Belum Bayar (BB) hari ini.", style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.w600))),
                      Text(formatRp(totalBB), style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w900, fontSize: 14)),
                    ],
                  ),
                ),

              // --- KONTEN LIST ---
              Expanded(
                child: isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : isDataKosong 
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text("Belum ada transaksi hari ini.", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 15))]))
                    : RefreshIndicator(
                        onRefresh: fetchLaporan,
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(24, 8, 24, 160 + MediaQuery.of(context).padding.bottom),
                          children: [
                            if (transaksiKasMasuk.isNotEmpty) ...[
                              _buildSectionHeader('UANG MASUK / TAMBAH SALDO', Colors.green.shade600, Icons.arrow_downward_rounded),
                              ...transaksiKasMasuk.map((k) => _buildTransactionCard(title: k['keterangan'], subtitle: 'Kas Masuk', amountText: "+ ${formatRp(k['nominal'])}", color: Colors.green.shade600, onTap: () => _tampilkanDialogEditUmum('Kas Masuk', k['id'], k['keterangan'], double.parse(k['nominal'].toString())))),
                            ],
                            
                            if (groupedNotas.isNotEmpty) ...[
                              _buildSectionHeader('PEMBELIAN NOTA', Colors.teal.shade600, Icons.receipt_rounded),
                              ...groupedNotas.map((g) => _buildNotaCardGrouped(g)),
                            ],

                            // --- TAMPILAN BARU: PELUNASAN HUTANG ---
                            if (transaksiPelunasan.isNotEmpty) ...[
                              _buildSectionHeader('PELUNASAN HUTANG (BB & TRANSFER)', Colors.blue.shade700, Icons.verified_rounded),
                              ...transaksiPelunasan.map((p) => _buildTransactionCard(
                                title: 'Pelunasan Nota #${p['id_nota']} - ${p['nama_pelanggan']}', 
                                subtitle: p['keterangan'] == 'Pelunasan BB' ? 'Dibayar via ${p['metode']}' : 'Status: Selesai di-Transfer', 
                                amountText: "- ${formatRp(p['nominal'])}", 
                                color: Colors.blue.shade700, 
                                isMinus: true, 
                                showEditIcon: false, // Pelunasan gak boleh diedit manual dari layar ini
                                onTap: () => showCustomSnackbar(context, 'Riwayat pelunasan tidak dapat diedit langsung.')
                              )),
                            ],
                            
                            if (transaksiPengeluaran.isNotEmpty) ...[
                              _buildSectionHeader('PENGELUARAN OPERASIONAL', Colors.purple.shade600, Icons.outbox_rounded),
                              ...transaksiPengeluaran.map((p) => _buildTransactionCard(title: p['kategori'], subtitle: p['keterangan'], amountText: "- ${formatRp(p['nominal'])}", color: Colors.purple.shade600, isMinus: true, onTap: () => _tampilkanDialogEditUmum('Pengeluaran', p['id'], p['keterangan'], double.parse(p['nominal'].toString())))),
                            ],
                            
                            if (transaksiKasKeluarLain.isNotEmpty) ...[
                              _buildSectionHeader('KAS KELUAR LAINNYA', Colors.red.shade600, Icons.money_off_rounded),
                              ...transaksiKasKeluarLain.map((k) => _buildTransactionCard(title: k['keterangan'], subtitle: 'Kas Keluar', amountText: "- ${formatRp(k['nominal'])}", color: Colors.red.shade600, isMinus: true, onTap: () => _tampilkanDialogEditUmum('Kas Keluar', k['id'], k['keterangan'], double.parse(k['nominal'].toString())))),
                            ],
                          ]
                        ),
                      )
              ), 
            ]
          ),

          // --- FLOATING BOTTOM DOCK SULTAN ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              // Tambah safe-inset bawah biar gak ketutup home indicator / gesture bar
              padding: EdgeInsets.fromLTRB(24, 20, 24, 32 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, -10))]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Row(children: [Icon(Icons.arrow_circle_down_rounded, color: Colors.green.shade600, size: 14), const SizedBox(width: 4), const Text("TOTAL MASUK", style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))]), 
                      const SizedBox(height: 4), 
                      Text(formatRp(totalKasMasukLaporan), style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5))
                    ]
                  ), 
                  Column(
                    mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, 
                    children: [
                      Row(children: [const Text("TOTAL KELUAR", style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)), const SizedBox(width: 4), Icon(Icons.arrow_circle_up_rounded, color: Colors.red.shade600, size: 14)]),
                      const SizedBox(height: 4), 
                      Text(formatRp(totalKasKeluarLaporan), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)), 
                      const SizedBox(height: 8), 
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.teal.shade100)), child: Text("Tonase: ${totalKg.toStringAsFixed(0)} Kg", style: TextStyle(color: Colors.teal.shade800, fontSize: 11, fontWeight: FontWeight.bold)))
                    ]
                  )
                ]
              ),
            ),
          )
        ],
      )
    ); 
  } 
}