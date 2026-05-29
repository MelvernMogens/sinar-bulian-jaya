import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // <--- IMPORT WAJIB

import '../utils/constants.dart';
import '../utils/helpers.dart';

class LaporanPengirimanScreen extends StatefulWidget {
  const LaporanPengirimanScreen({super.key});

  @override
  State<LaporanPengirimanScreen> createState() => _LaporanPengirimanScreenState();
}

class _LaporanPengirimanScreenState extends State<LaporanPengirimanScreen> {
  DateTime selectedDate = DateTime.now();
  List terkirimList = [];
  List stockList = [];
  bool isLoading = false;

  Future<void> fetchLaporan() async {
    setState(() => isLoading = true);
    String tgl = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/pengiriman/laporan/?tanggal=$tgl&_t=${DateTime.now().millisecondsSinceEpoch}'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          terkirimList = data['terkirim'] ?? [];
          stockList = data['stock_aktif'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Gagal memuat laporan', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLaporan();
  }

  Future<void> pilihTanggal() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal.shade800,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.teal.shade800)
            )
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      fetchLaporan();
    }
  }

  String _formatAwal(dynamic val) {
    if (val == null) return '0';
    double parsed = double.tryParse(val.toString()) ?? 0;
    return parsed.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  // --- BOTTOM SHEET: PILIH/UBAH LOT PABRIK UNTUK PENGIRIMAN ---
  Future<void> _pilihLotUntukPengiriman(dynamic pengirimanId, dynamic currentLotId, String currentLotName) async {
    List lots = [];
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/lot/'));
      if (res.statusCode == 200) {
        final all = json.decode(res.body) as List;
        // Tampilkan semua yang belum selesai + lot yang sedang dipakai (meski sudah selesai)
        lots = all.where((l) => l['is_selesai'] != true || l['id'].toString() == currentLotId?.toString()).toList();
      }
    } catch (_) {}

    if (!mounted) return;

    String? selectedLotId = currentLotId?.toString();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(ctx).padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 16))),
                const Text('Ubah Lot Pabrik', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 4),
                Text('Pilih lot tujuan untuk wadah ini.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 16),

                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _buildLotOptionTile(
                        ctx: ctx,
                        label: 'Tanpa Lot',
                        subtitle: 'Lepaskan dari lot manapun',
                        isSelected: selectedLotId == null,
                        onTap: () => setSheet(() => selectedLotId = null),
                        color: Colors.grey.shade700,
                      ),
                      if (lots.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: Text('Belum ada lot. Buat lot di menu Lot Pabrik dulu.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12), textAlign: TextAlign.center)),
                        ),
                      ...lots.map((l) => _buildLotOptionTile(
                        ctx: ctx,
                        label: l['nama_lot'] ?? '-',
                        subtitle: 'Pabrik: ${l['pabrik'] ?? '-'}${l['is_selesai'] == true ? '  (selesai)' : ''}',
                        isSelected: selectedLotId == l['id'].toString(),
                        onTap: () => setSheet(() => selectedLotId = l['id'].toString()),
                        color: Colors.teal.shade700,
                      )),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Simpan Lot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final currentUsername = prefs.getString('username') ?? 'Sistem';
                        final res = await http.post(
                          Uri.parse('${AppConfig.baseUrl}/api/pengiriman/edit_pabrik/'),
                          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
                          body: json.encode({
                            'pengiriman_id': pengirimanId,
                            'lot_id': selectedLotId,
                            'username': currentUsername,
                          }),
                        );
                        if (!mounted) return;
                        if (res.statusCode == 200) {
                          showCustomSnackbar(context, 'Lot berhasil diperbarui!');
                          fetchLaporan();
                        } else {
                          showCustomSnackbar(context, 'Gagal update lot.', isError: true);
                        }
                      } catch (_) {
                        if (mounted) showCustomSnackbar(context, 'Koneksi ke server gagal!', isError: true);
                      }
                    },
                  ),
                )
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildLotOptionTile({required BuildContext ctx, required String label, required String subtitle, required bool isSelected, required VoidCallback onTap, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.08) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, color: isSelected ? color : Colors.grey.shade400, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? color : Colors.black87)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- DIALOG EDIT MUATAN SULTAN ---
  void _editMuatanDialog(Map item) {
    String tonaseAwal = item['tonase']?.toString() ?? '0';
    if (tonaseAwal.endsWith('.0')) tonaseAwal = tonaseAwal.replaceAll('.0', '');
    
    String hargaAwal = _formatAwal(item['harga'] ?? item['harga_jual'] ?? '0');

    final tonaseCtrl = TextEditingController(text: tonaseAwal);
    final hargaCtrl = TextEditingController(text: hargaAwal);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          bool isSubmitting = false;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Expanded(child: Text('Edit ${item['nama']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87), overflow: TextOverflow.ellipsis)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: TextField(
                    controller: tonaseCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    decoration: const InputDecoration(labelText: 'Tonase (Kg)', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: TextField(
                    controller: hargaCtrl, keyboardType: TextInputType.number, inputFormatters: [RibuanFormatter()],
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                    decoration: const InputDecoration(labelText: 'Harga Beli/Kg', prefixText: 'Rp ', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Sistem akan otomatis menambahkan Rp 200/Kg untuk Harga Jual Pabrik.', style: TextStyle(fontSize: 10, color: Colors.grey, height: 1.4)),
              ],
            ),
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
                  
                  String hargaMurni = hargaCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                  String tonaseMurni = tonaseCtrl.text.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9\.]'), '');
                  
                  try {
                    // --- KUNCI SAKTI: TARIK NAMA KASIR DARI MEMORI ---
                    final prefs = await SharedPreferences.getInstance();
                    final currentUsername = prefs.getString('username') ?? 'Sistem';

                    final res = await http.post(
                      Uri.parse('${AppConfig.baseUrl}/api/pengiriman/item/edit/'),
                      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
                      body: json.encode({
                        'item_id': item['id'], 
                        'tonase': tonaseMurni,
                        'harga': hargaMurni,
                        'username': currentUsername, // <--- KIRIM KE DJANGO
                      })
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    if (res.statusCode == 200) {
                       showCustomSnackbar(context, 'Data muatan berhasil diperbarui!');
                       fetchLaporan(); 
                    } else {
                       showCustomSnackbar(context, 'Gagal update data!', isError: true);
                    }
                  } catch(e) {
                    if(mounted) showCustomSnackbar(context, 'Terjadi kesalahan sistem!', isError: true);
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

  String _formatTglPendek(DateTime tgl) {
    return "${tgl.day.toString().padLeft(2, '0')}/${tgl.month.toString().padLeft(2, '0')}/${tgl.year}";
  }

  double hitungTotalUang(List list) {
    return list.fold(0, (sum, item) => sum + (double.tryParse(item['total_uang'].toString()) ?? 0));
  }

  double hitungTotalTonase(List list) {
    return list.fold(0, (sum, item) => sum + (double.tryParse(item['total_tonase'].toString()) ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned(top: -80, right: -60, child: CircleAvatar(radius: 140, backgroundColor: Colors.teal.shade50.withOpacity(0.6))),

            Column(
              children: [
                // --- CUSTOM HEADER SULTAN ---
                Container(
                  padding: const EdgeInsets.only(top: 60, left: 16, right: 24, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22), onPressed: () => Navigator.pop(context)),
                          const Text('Laporan Harian', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5)),
                        ],
                      ),
                      InkWell(
                        onTap: pilihTanggal,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.teal.shade100)),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_rounded, color: Colors.teal.shade800, size: 16),
                              const SizedBox(width: 6),
                              Text(_formatTglPendek(selectedDate), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal.shade900)),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                // --- TAB BAR iOS STYLE ---
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                    labelColor: Colors.teal.shade800,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    unselectedLabelColor: Colors.grey.shade500,
                    tabs: const [
                      Tab(text: 'TERKIRIM'),
                      Tab(text: 'STOCK GUDANG'),
                    ],
                  ),
                ),

                // --- TAB VIEW CONTENT ---
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildTabContent(terkirimList, 'Terkirim', Colors.teal.shade700, Colors.teal.shade500, Icons.local_shipping_rounded),
                            _buildTabContent(stockList, 'Stock', Colors.amber.shade700, Colors.amber.shade500, Icons.inventory_2_rounded),
                          ],
                        ),
                ),
              ],
            ),
          ],
        )
      ),
    );
  }

  // --- WIDGET ISI KONTEN (RINGKASAN + LIST) ---
  Widget _buildTabContent(List list, String label, Color colorPrimary, Color colorSecondary, IconData heroIcon) {
    double totalUang = hitungTotalUang(list);
    double totalTonase = hitungTotalTonase(list);

    return Column(
      children: [
        // --- KARTU RINGKASAN SULTAN ---
        Container(
          margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [colorPrimary, colorSecondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: colorPrimary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.scale_rounded, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      const Text('TOTAL TONASE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${formatTonase(totalTonase)} Kg', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)), 
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Text('ESTIMASI OMSET', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(width: 4),
                      const Icon(Icons.monetization_on_rounded, color: Colors.white70, size: 14),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(formatRp(totalUang), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ],
              ),
            ],
          ),
        ),

        // --- LIST WADAH SULTAN (ExpansionTile Bersih) ---
        Expanded(
          child: list.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(heroIcon, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text("Belum ada data $label hari ini", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 15))]))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final p = list[index];
                    List items = p['items'] ?? [];
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colorPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(heroIcon, color: colorPrimary, size: 24)),
                          title: Text(p['judul'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tonase: ${formatTonase(p['total_tonase'])} Kg  •  Omset: ${formatRp(p['total_uang'])}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _pilihLotUntukPengiriman(p['id'], p['lot_id'], p['nama_lot']),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (p['lot_id'] == null) ? Colors.amber.shade50 : Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: (p['lot_id'] == null) ? Colors.amber.shade200 : Colors.teal.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          (p['lot_id'] == null) ? Icons.add_circle_outline_rounded : Icons.edit_location_alt_rounded,
                                          size: 12,
                                          color: (p['lot_id'] == null) ? Colors.amber.shade900 : Colors.teal.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          (p['lot_id'] == null) ? 'Set Lot Pabrik' : 'Lot: ${p['nama_lot']}',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: (p['lot_id'] == null) ? Colors.amber.shade900 : Colors.teal.shade800),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          iconColor: colorPrimary,
                          collapsedIconColor: Colors.grey.shade400,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
                              child: Column(
                                children: items.map<Widget>((it) {
                                  // --- DESAIN BARU: TAMPILAN DETAIL HARGA SULTAN ---
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => _editMuatanDialog(it),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: colorPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                              child: Icon(Icons.person_rounded, size: 18, color: colorPrimary),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(it['nama'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis),
                                                  const SizedBox(height: 4),
                                                  // Nunjukin Tonase dan Harga Beli (Dasar)
                                                  Text('${formatTonase(it['tonase'])} Kg • Beli: ${formatRp(it['harga'])}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                                                  if ((it['no_telp'] ?? '').toString().trim().isNotEmpty) ...[
                                                    const SizedBox(height: 3),
                                                    Row(children: [
                                                      Icon(Icons.phone_rounded, size: 11, color: Colors.green.shade600),
                                                      const SizedBox(width: 3),
                                                      Text(it['no_telp'].toString(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.green.shade700)),
                                                    ]),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(formatRp(it['total']), style: TextStyle(fontWeight: FontWeight.w900, color: colorPrimary, fontSize: 14)),
                                                    const SizedBox(width: 6),
                                                    Icon(Icons.edit_rounded, size: 14, color: Colors.blue.shade400),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                // Nunjukin Harga Jual Pabrik (+200)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4)),
                                                  child: Text('Modal: ${formatRp(it['harga_jual'])}', style: TextStyle(fontSize: 10, color: Colors.amber.shade700, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}