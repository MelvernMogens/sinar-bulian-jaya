import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // <--- IMPORT INI WAJIB BUAT AUDIT
import '../utils/helpers.dart';
import '../utils/constants.dart';

// --- MODEL BANTUAN UNTUK INPUT DINAMIS DI GUDANG ---
class GudangItemData {
  TextEditingController namaCtrl = TextEditingController(); 
  TextEditingController tonaseCtrl = TextEditingController();
  TextEditingController hargaCtrl = TextEditingController();

  void dispose() {
    namaCtrl.dispose();
    tonaseCtrl.dispose();
    hargaCtrl.dispose();
  }
}

// ============================================================================
// HALAMAN 1: LIST STOCK & KIRIM
// ============================================================================
class PengirimanScreen extends StatefulWidget {
  const PengirimanScreen({super.key});
  @override 
  State<PengirimanScreen> createState() => _PengirimanScreenState();
}

class _PengirimanScreenState extends State<PengirimanScreen> {
  List aktifList = [];
  bool isLoading = false;

  Future<void> fetchAktif() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/pengiriman/aktif/'));
      if (res.statusCode == 200) setState(() => aktifList = json.decode(res.body));
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Gagal mengambil data!', isError: true);
    }
    setState(() => isLoading = false);
  }

  @override 
  void initState() {
    super.initState();
    fetchAktif();
  }

  // --- Helper Input Form Sultan ---
  Widget _buildDialogInput({required TextEditingController controller, required String hint, TextInputType type = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        controller: controller, keyboardType: type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      ),
    );
  }

  void dialogBuatBaru() {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Buat Wadah Baru', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      content: const Text('Pilih jenis pencatatan ke gudang:', style: TextStyle(color: Colors.black54)),
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade50, foregroundColor: Colors.teal.shade800, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () { Navigator.pop(context); _pilihLotDanBuat('STOCK', ''); },
                child: const Text('Timbang Taruh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () { Navigator.pop(context); dialogPlatMobil(); },
                child: const Text('Kirim (Mobil)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
              ),
            ),
          ],
        )
      ],
    ));
  }

  void dialogPlatMobil() {
    final platCtrl = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Mobil / Supir', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      content: _buildDialogInput(controller: platCtrl, hint: 'Cth: B 1234 CD / Udin'),
      actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () { if(platCtrl.text.isNotEmpty) { Navigator.pop(context); _pilihLotDanBuat('KIRIM', platCtrl.text); } },
          child: const Text('Lanjut', style: TextStyle(fontWeight: FontWeight.bold))
        )
      ],
    ));
  }

  // STEP 2: fetch lot aktif & tampilkan picker → trigger create
  Future<void> _pilihLotDanBuat(String tipe, String plat) async {
    List lots = [];
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/lot/'));
      if (res.statusCode == 200) {
        final all = json.decode(res.body) as List;
        lots = all.where((l) => l['is_selesai'] != true).toList();
      }
    } catch (_) {}

    if (!mounted) return;

    String? selectedLotId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 16, left: 130)),
                const Text('Pilih Lot Pabrik', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 4),
                Text('Wadah ini akan dimasukkan ke lot pabrik berikut.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 16),

                // "Tanpa Lot" option
                _buildLotOption(
                  context: ctx,
                  label: 'Tanpa Lot (Pilih nanti)',
                  subtitle: 'Wadah dibuat dulu, lot di-set kemudian',
                  isSelected: selectedLotId == null,
                  onTap: () => setSheet(() => selectedLotId = null),
                  color: Colors.grey.shade700,
                ),
                if (lots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text('Belum ada lot aktif. Buat lot di menu Lot Pabrik.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12), textAlign: TextAlign.center)),
                  ),
                ...lots.map((l) => _buildLotOption(
                  context: ctx,
                  label: l['nama_lot'] ?? '-',
                  subtitle: 'Pabrik: ${l['pabrik'] ?? '-'}',
                  isSelected: selectedLotId == l['id'].toString(),
                  onTap: () => setSheet(() => selectedLotId = l['id'].toString()),
                  color: Colors.teal.shade700,
                )),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tipe == 'KIRIM' ? Colors.amber.shade700 : Colors.teal.shade700,
                      foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text('Buat Wadah ${tipe == 'KIRIM' ? 'Kirim' : 'Stock'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: () { Navigator.pop(ctx); buatPengiriman(tipe, plat, selectedLotId); },
                  ),
                )
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildLotOption({required BuildContext context, required String label, required String subtitle, required bool isSelected, required VoidCallback onTap, required Color color}) {
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

  Future<void> buatPengiriman(String tipe, String plat, [String? lotId]) async {
    try {
      final body = <String, dynamic>{'tipe': tipe, 'plat_mobil': plat};
      if (lotId != null) body['lot_id'] = lotId;
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/pengiriman/buat/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (res.statusCode == 200) {
        if (!mounted) return;
        showCustomSnackbar(context, 'Wadah berhasil dibuat!');
        fetchAktif();
      }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Gagal membuat pengiriman!', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    List kirimList = aktifList.where((p) => p['tipe'] == 'KIRIM').toList();
    List stockList = aktifList.where((p) => p['tipe'] == 'STOCK').toList();

    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned(top: -100, right: -50, child: CircleAvatar(radius: 150, backgroundColor: Colors.teal.shade50.withOpacity(0.5))),
            Column(
              children: [
                // --- CUSTOM HEADER ---
                Container(
                  padding: const EdgeInsets.only(top: 60, left: 16, right: 24, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22), onPressed: () => Navigator.pop(context)),
                          const Text('Gudang & Kirim', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5)),
                        ],
                      ),
                      InkWell(
                        onTap: fetchAktif,
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
                      Tab(text: 'MOBIL KIRIM'),
                      Tab(text: 'TIMBANG TARUH'),
                    ],
                  ),
                ),

                // --- LIST VIEW KONTEN ---
                Expanded(
                  child: isLoading 
                    ? const Center(child: CircularProgressIndicator()) 
                    : TabBarView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildListView(kirimList, 'Belum ada mobil yang sedang dimuat.', Icons.local_shipping_rounded, Colors.amber),
                          _buildListView(stockList, 'Belum ada stock aktif.', Icons.inventory_2_rounded, Colors.teal),
                        ],
                      ),
                ),
              ],
            ),
          ]
        ),
        // --- FLOATING ACTION BUTTON ---
        floatingActionButton: FloatingActionButton.extended(
          heroTag: null, 
          backgroundColor: Colors.teal.shade800,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onPressed: dialogBuatBaru,
          icon: const Icon(Icons.add_box_rounded, color: Colors.white, size: 20),
          label: const Text('BUAT WADAH BARU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildListView(List list, String emptyMessage, IconData heroIcon, MaterialColor themeColor) {
    if (list.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(heroIcon, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text(emptyMessage, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 15))]));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index];
        bool isKirim = p['tipe'] == 'KIRIM';
        String statusText = isKirim ? 'Sedang Dimuat' : 'Proses Tumpuk';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPengirimanScreen(id: p['id']))).then((_) => fetchAktif()),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: themeColor.shade50, borderRadius: BorderRadius.circular(14)), child: Icon(heroIcon, color: themeColor.shade800, size: 24)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['judul'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text('Tgl: ${p['tanggal']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: isKirim ? Colors.amber.shade50 : Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(statusText, style: TextStyle(color: isKirim ? Colors.amber.shade800 : Colors.teal.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey.shade500),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (v) {
                        if (v == 'hapus') _konfirmasiHapusPengiriman(p['id'], p['judul']);
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'hapus',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, color: Colors.red.shade600, size: 16),
                              const SizedBox(width: 8),
                              Text('Hapus Wadah', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          )
        );
      },
    );
  }

  Future<void> _konfirmasiHapusPengiriman(int id, String judul, {bool force = false}) async {
    if (!force) {
      // Show initial confirmation
      bool? proceed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text('Hapus Wadah?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
        ]),
        content: Text('Hapus wadah [$judul]?', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ));
      if (proceed != true) return;
    }
    // Execute
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? 'Sistem';
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/pengiriman/hapus/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'pengiriman_id': id, 'username': username, 'force': force}),
      );
      if (!mounted) return;
      final body = json.decode(res.body);
      if (res.statusCode == 200) {
        showCustomSnackbar(context, body['pesan'] ?? 'Wadah dihapus.');
        fetchAktif();
      } else if (res.statusCode == 409) {
        // Cascade confirm
        bool? proceed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 22),
            const SizedBox(width: 8),
            const Expanded(child: Text('Item Sudah Jadi Nota', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(body['pesan'] ?? 'Cascade needed', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text('Tetap hapus akan ikut hapus: item + nota + pembayaran + kas + restore kasbon.', style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.w600)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.delete_forever_rounded, size: 16),
              label: const Text('Tetap Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ));
        if (proceed == true) _konfirmasiHapusPengiriman(id, judul, force: true);
      } else {
        showCustomSnackbar(context, body['pesan'] ?? 'Gagal hapus.', isError: true);
      }
    } catch (_) {
      if (mounted) showCustomSnackbar(context, 'Koneksi gagal!', isError: true);
    }
  }
}

// ============================================================================
// HALAMAN 2: DETAIL WADAH & KIRIM
// ============================================================================
class DetailPengirimanScreen extends StatefulWidget {
  final int id;
  const DetailPengirimanScreen({super.key, required this.id});
  @override 
  State<DetailPengirimanScreen> createState() => _DetailPengirimanScreenState();
}

class _DetailPengirimanScreenState extends State<DetailPengirimanScreen> {
  Map<String, dynamic>? data;
  List<String> daftarNamaPetani = [];
  List<Map<String, dynamic>> lots = []; 
  bool isLoading = false;

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/pengiriman/detail/${widget.id}/'));
      if (res.statusCode == 200) data = json.decode(res.body);
      
      final resPel = await http.get(Uri.parse('${AppConfig.baseUrl}/api/pelanggan/'));
      if (resPel.statusCode == 200) {
        List pData = json.decode(resPel.body);
        setState(() => daftarNamaPetani = pData.map((e) => (e['nama'] ?? '').toString()).toList());
      }

      final resLot = await http.get(Uri.parse('${AppConfig.baseUrl}/api/lot/'));
      if (resLot.statusCode == 200) {
        List rawLots = json.decode(resLot.body);
        setState(() => lots = List<Map<String, dynamic>>.from(rawLots));
      }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Gagal mengambil data!', isError: true);
    }
    setState(() => isLoading = false);
  }

  @override 
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> hapusMuatan(int itemId, {bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUsername = prefs.getString('username') ?? 'Sistem';
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/pengiriman/item/hapus/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'item_id': itemId, 'force': force, 'username': currentUsername}),
      );
      if (!mounted) return;
      final body = json.decode(res.body);
      if (res.statusCode == 200) {
        fetchData();
        showCustomSnackbar(context, body['pesan'] ?? 'Muatan dihapus!');
      } else if (res.statusCode == 409) {
        // Butuh konfirmasi force karena item sudah jadi nota
        showDialog(context: context, builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 8),
              const Expanded(child: Text('Item Sudah Jadi Nota', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(body['pesan'] ?? 'Cascade delete diperlukan.', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
              const SizedBox(height: 8),
              Text('Aksi ini akan menghapus juga:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
              const SizedBox(height: 4),
              Text('• Nota terkait\n• Pembayaran (CASH/TF/BB)\n• Mutasi Kas Gudang\n• Restore kasbon pelanggan jika ada setoran',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
            ],
          ),
          actionsPadding: const EdgeInsets.only(bottom: 12, right: 12, left: 12),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.delete_forever_rounded, size: 16),
              label: const Text('Tetap Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () { Navigator.pop(ctx); hapusMuatan(itemId, force: true); },
            ),
          ],
        ));
      } else {
        showCustomSnackbar(context, body['pesan'] ?? 'Gagal menghapus muatan!', isError: true);
      }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Gagal menghapus muatan!', isError: true);
    }
  }

  Widget _buildDialogInput({required TextEditingController controller, required String hint, TextInputType type = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        controller: controller, keyboardType: type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      ),
    );
  }

  // --- KUNCI SAKTI AUDIT OWNER ---
  void dialogEditMuatan(Map item) {
    String tonaseAwal = item['tonase']?.toString().replaceAll(RegExp(r'\.0$'), '') ?? '';
    String hargaAwal = item['harga_input']?.toString().replaceAll(RegExp(r'\.0$'), '') ?? '';

    final tonaseCtrl = TextEditingController(text: tonaseAwal);
    final hargaCtrl = TextEditingController(text: hargaAwal);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Edit: ${item['nama_tujuan']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogInput(controller: tonaseCtrl, hint: 'Tonase Baru (Kg)', type: TextInputType.number),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                controller: hargaCtrl, keyboardType: TextInputType.number, inputFormatters: [RibuanFormatter()], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                decoration: const InputDecoration(prefixText: 'Rp ', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              String hargaBersih = hargaCtrl.text.replaceAll('.', '');
              
              // --- TAMBAHAN KUNCI SAKTI: AMBIL USERNAME KASIR ---
              final prefs = await SharedPreferences.getInstance();
              final currentUsername = prefs.getString('username') ?? 'Sistem';

              await http.post(
                Uri.parse('${AppConfig.baseUrl}/api/pengiriman/item/edit/'), 
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'item_id': item['id'], 
                  'tonase': tonaseCtrl.text, 
                  'harga': hargaBersih,
                  'username': currentUsername // <--- DIKIRIM KE DJANGO BIAR MASUK AUDIT
                })
              );
              
              if (!mounted) return;
              Navigator.pop(context);
              fetchData();
            },
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void showOpsiMuatan(Map item) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.edit_rounded, color: Colors.blue.shade700)),
              title: const Text('Edit Tonase / Harga', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () { Navigator.pop(context); dialogEditMuatan(item); },
            ),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.delete_forever_rounded, color: Colors.red.shade700)),
              title: const Text('Hapus Muatan Ini', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              onTap: () { Navigator.pop(context); hapusMuatan(item['id']); },
            ),
          ],
        ),
      ),
    );
  }

  void dialogTambahItem() {
    List<GudangItemData> listInputGudang = [GudangItemData()];
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Tambah Muatan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...listInputGudang.asMap().entries.map((entry) {
                      int index = entry.key; GudangItemData item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.shopping_bag_rounded, size: 16, color: Colors.teal.shade600),
                                    const SizedBox(width: 8),
                                    Text("Muatan #${index + 1}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.teal.shade800)),
                                  ],
                                ),
                                if (listInputGudang.length > 1)
                                  InkWell(onTap: () => setStateDialog(() => listInputGudang.removeAt(index)), child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.close_rounded, color: Colors.red.shade700, size: 16)))
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                              child: Autocomplete<String>(
                                optionsBuilder: (TextEditingValue t) {
                                  if (t.text == '') return const Iterable<String>.empty();
                                  return daftarNamaPetani.where((String option) => option.toLowerCase().contains(t.text.toLowerCase()));
                                },
                                onSelected: (String sel) => item.namaCtrl.text = sel,
                                fieldViewBuilder: (ctx, ctrl, focusNode, onFieldSub) {
                                  return TextField(
                                    controller: ctrl, focusNode: focusNode, onChanged: (val) => item.namaCtrl.text = val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(hintText: 'Nama Petani...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12))
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: TextField(controller: item.tonaseCtrl, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), decoration: const InputDecoration(hintText: 'Kg', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12))))),
                                const SizedBox(width: 8),
                                Expanded(flex: 2, child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: TextField(controller: item.hargaCtrl, keyboardType: TextInputType.number, inputFormatters: [RibuanFormatter()], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal.shade900), decoration: const InputDecoration(prefixText: 'Rp ', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12))))),
                              ],
                            )
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () => setStateDialog(() => listInputGudang.add(GudangItemData())),
                      icon: Icon(Icons.add_circle_outline_rounded, color: Colors.amber.shade700),
                      label: Text('Tambah Baris Muatan', style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  if (listInputGudang.any((e) => e.namaCtrl.text.isEmpty || e.tonaseCtrl.text.isEmpty || e.hargaCtrl.text.isEmpty)) {
                    showCustomSnackbar(context, 'Mohon lengkapi semua baris!', isError: true);
                    return;
                  }
                  Navigator.pop(context);
                  setState(() => isLoading = true);
                  List itemsData = listInputGudang.map((e) => { 'nama_petani': e.namaCtrl.text, 'tonase': e.tonaseCtrl.text, 'harga': e.hargaCtrl.text.replaceAll('.', '') }).toList();
                  try {
                    await http.post(
                      Uri.parse('${AppConfig.baseUrl}/api/pengiriman/item/tambah/'), 
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({'pengiriman_id': widget.id, 'items': itemsData})
                    );
                    fetchData();
                  } catch (e) {
                    if (mounted) showCustomSnackbar(context, 'Gagal menambah muatan!', isError: true);
                  } finally {
                    if (mounted) setState(() => isLoading = false);
                  }
                },
                child: const Text('Simpan Muatan', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          );
        }
      ),
    );
  }

  Future<void> _eksekusiKirimKeAPI(String platMobilInput, String? lotId) async {
    setState(() => isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/pengiriman/finalisasi/'), 
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'pengiriman_id': widget.id, 'plat_mobil': platMobilInput, 'lot_id': lotId})
      );
      if (!mounted) return;
      if (res.statusCode == 200) { showCustomSnackbar(context, 'Berhasil dikirim ke Pabrik!'); } 
      else { showCustomSnackbar(context, 'Gagal memproses pengiriman!', isError: true); }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Terjadi kesalahan jaringan!', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
      Navigator.pop(context); 
    }
  }

  void finalisasiKirim() {
    final platCtrl = TextEditingController(text: data!['tipe'] == 'KIRIM' ? data!['judul'] : '');
    String? selectedLotId; 

    showDialog(
      context: context, 
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Kirim ke Pabrik', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data!['tipe'] == 'STOCK') ...[
                _buildDialogInput(controller: platCtrl, hint: 'Masukkan Mobil / Supir'),
                const SizedBox(height: 12),
              ],
              Container(
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: Autocomplete<Map<String, dynamic>>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') return const Iterable<Map<String, dynamic>>.empty();
                    return lots.where((lot) => (lot['nama_lot'] ?? '').toString().toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  displayStringForOption: (option) => (option['nama_lot'] ?? '').toString(),
                  
                  onSelected: (Map<String, dynamic> selection) {
                    selectedLotId = selection['id'].toString(); 
                  },
                  
                  fieldViewBuilder: (ctx, ctrl, focus, onSub) {
                    return TextField(
                      controller: ctrl, focusNode: focus, 
                      onChanged: (val) { 
                        selectedLotId = null; 
                        var listCocok = lots.where((l) => (l['nama_lot'] ?? '').toString().toLowerCase() == val.toLowerCase()).toList();
                        if (listCocok.isNotEmpty) { selectedLotId = listCocok.first['id'].toString(); }
                      }, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      decoration: const InputDecoration(hintText: 'Ketik & Pilih Lot (Opsional)', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Text('Data Pabrik (BL, VM, Timbangan) bisa diedit nanti di menu Laporan LOT.', style: TextStyle(fontSize: 10, color: Colors.grey, height: 1.4)),
            ],
          ),
          actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
          actions: [
            TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                if (data!['tipe'] == 'STOCK' && platCtrl.text.isEmpty) { showCustomSnackbar(context, 'Plat mobil wajib diisi!', isError: true); return; }
                
                FocusScope.of(context).unfocus();
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (context.mounted) { 
                    Navigator.pop(context); 
                    _eksekusiKirimKeAPI(platCtrl.text, selectedLotId); 
                  }
                });
              }, 
              child: const Text('Jalan Sekarang', style: TextStyle(fontWeight: FontWeight.bold))
            )
          ],
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (data == null || isLoading) return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
    List items = data!['items'];

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), 
        child: FloatingActionButton(
          heroTag: null, 
          elevation: 4,
          backgroundColor: Colors.amber.shade700,
          onPressed: dialogTambahItem,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -50, child: CircleAvatar(radius: 150, backgroundColor: Colors.teal.shade50.withOpacity(0.5))),
          Column(
            children: [
              // --- HEADER ---
              Container(
                padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 20),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22), onPressed: () => Navigator.pop(context)),
                    Expanded(child: Text(data!['judul'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- SUMMARY KARTU SULTAN ---
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.teal.shade900, Colors.teal.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.scale_rounded, color: Colors.teal.shade100, size: 14),
                                    const SizedBox(width: 6),
                                    const Text('TOTAL TONASE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('${data!['total_tonase']} Kg', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                              ]
                            ),
                            Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    const Text('ESTIMASI OMSET', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                    const SizedBox(width: 6),
                                    Icon(Icons.monetization_on_rounded, color: Colors.amber.shade400, size: 14),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(formatRp(data!['total_uang']), style: TextStyle(color: Colors.amber.shade400, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                              ]
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Container(width: 4, height: 16, decoration: BoxDecoration(color: Colors.teal.shade700, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          const Text('DAFTAR MUATAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black45, letterSpacing: 1.2)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      items.isEmpty 
                        ? Center(child: Padding(padding: const EdgeInsets.only(top: 20), child: Column(children: [Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text("Wadah masih kosong.", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 15))]),))
                        : Column(
                            children: items.map((it) => Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => showOpsiMuatan(it),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.person_rounded, color: Colors.teal.shade800, size: 20)),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(it['nama_tujuan'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87)),
                                              const SizedBox(height: 2),
                                              Text('T: ${it['tonase']} kg • Jual: ${formatRp(it['harga_jual'])}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                        Text(formatRp(it['total_harga']), style: TextStyle(fontWeight: FontWeight.w900, color: Colors.teal.shade700, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )).toList(),
                          )
                    ],
                  ),
                ),
              )
            ],
          ),
          
          // --- FLOATING BOTTOM DOCK SULTAN ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, -10))],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white, 
                    padding: const EdgeInsets.symmetric(vertical: 18), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0
                  ),
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label: const Text('SELESAI & KIRIM PABRIK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2)),
                  onPressed: items.isEmpty ? null : finalisasiKirim,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}