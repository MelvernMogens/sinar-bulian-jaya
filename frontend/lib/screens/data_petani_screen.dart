import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/helpers.dart';
import '../utils/constants.dart';

// ============================================================================
// DATA PETANI — list alfabet + search + CRUD + tap → profil lengkap
// ============================================================================
class DataPetaniScreen extends StatefulWidget {
  const DataPetaniScreen({super.key});
  @override
  State<DataPetaniScreen> createState() => _DataPetaniScreenState();
}

class _DataPetaniScreenState extends State<DataPetaniScreen> {
  List petani = [];
  List filtered = [];
  final searchCtrl = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPetani();
  }

  Future<void> fetchPetani() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/pelanggan/?_t=${DateTime.now().millisecondsSinceEpoch}'));
      if (res.statusCode == 200) {
        List data = json.decode(res.body);
        // Sort alfabet (case-insensitive)
        data.sort((a, b) => (a['nama'] ?? '').toString().toLowerCase().compareTo((b['nama'] ?? '').toString().toLowerCase()));
        setState(() {
          petani = data;
          _applyFilter(searchCtrl.text);
        });
      }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Koneksi ke server gagal!', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _applyFilter(String q) {
    setState(() {
      if (q.isEmpty) {
        filtered = petani;
      } else {
        final ql = q.toLowerCase();
        filtered = petani.where((p) {
          final nama = (p['nama'] ?? '').toString().toLowerCase();
          final telp = (p['no_telp'] ?? '').toString().toLowerCase();
          return nama.contains(ql) || telp.contains(ql);
        }).toList();
      }
    });
  }

  Widget _field(TextEditingController c, String label, String hint, IconData icon, {TextInputType? type, TextCapitalization cap = TextCapitalization.none}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        controller: c, keyboardType: type, textCapitalization: cap,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, size: 18, color: Colors.teal.shade700),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  void _dialogForm({Map? existing}) {
    final bool isEdit = existing != null;
    final namaC = TextEditingController(text: isEdit ? (existing['nama'] ?? '') : '');
    final telpC = TextEditingController(text: isEdit ? (existing['no_telp'] ?? '') : '');
    final rekC = TextEditingController(text: isEdit ? (existing['no_rekening'] ?? '') : '');

    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(isEdit ? 'Edit Info Petani' : 'Tambah Petani Baru', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(namaC, 'Nama Petani *', 'Nama lengkap', Icons.person_rounded, cap: TextCapitalization.words),
          _field(telpC, 'No. Telepon (opsional)', 'Cth: 0812xxxx', Icons.phone_rounded, type: TextInputType.phone),
          _field(rekC, 'No. Rekening (opsional)', 'Cth: BCA 1234567', Icons.account_balance_rounded),
          Align(alignment: Alignment.centerLeft, child: Text('* Nama wajib. Telp & rekening opsional.', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic))),
        ]),
      ),
      actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () async {
            final nama = namaC.text.trim();
            if (nama.isEmpty) { showCustomSnackbar(context, 'Nama wajib diisi!', isError: true); return; }
            try {
              final prefs = await SharedPreferences.getInstance();
              final username = prefs.getString('username') ?? 'Sistem';
              final url = isEdit ? '${AppConfig.baseUrl}/api/pelanggan/edit/' : '${AppConfig.baseUrl}/api/pelanggan/tambah/';
              final payload = isEdit
                ? {'pelanggan_id': existing['id'], 'nama': nama, 'no_telp': telpC.text.trim(), 'no_rekening': rekC.text.trim(), 'username': username}
                : {'nama': nama, 'no_telp': telpC.text.trim(), 'no_rekening': rekC.text.trim()};
              final res = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: json.encode(payload));
              if (!mounted) return;
              final body = json.decode(res.body);
              if (res.statusCode == 200) {
                Navigator.pop(ctx);
                showCustomSnackbar(context, body['pesan'] ?? 'Tersimpan!');
                fetchPetani();
              } else {
                showCustomSnackbar(context, body['pesan'] ?? 'Gagal!', isError: true);
              }
            } catch (e) {
              if (mounted) showCustomSnackbar(context, 'Koneksi gagal!', isError: true);
            }
          },
          child: Text(isEdit ? 'Update' : 'Simpan', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  void _konfirmasiHapus(Map p) {
    final kasbon = double.tryParse((p['total_kasbon'] ?? 0).toString()) ?? 0;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 22), const SizedBox(width: 8), const Expanded(child: Text('Hapus Petani?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)))]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)), child: Text(p['nama'] ?? '-', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red.shade900))),
        if (kasbon > 0) ...[const SizedBox(height: 8), Text('⚠ Masih ada kasbon ${formatRp(kasbon)}', style: TextStyle(fontSize: 11, color: Colors.orange.shade900, fontWeight: FontWeight.w600))],
        const SizedBox(height: 8),
        Text('Aksi permanen. Tercatat di audit log.', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
      ]),
      actionsPadding: const EdgeInsets.only(bottom: 12, right: 12, left: 12),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () { Navigator.pop(ctx); _kirimHapus(p['id'], p['nama'], false); },
          child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  Future<void> _kirimHapus(dynamic id, String nama, bool force) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? 'Sistem';
      final res = await http.post(Uri.parse('${AppConfig.baseUrl}/api/pelanggan/hapus/'), headers: {'Content-Type': 'application/json'}, body: json.encode({'pelanggan_id': id, 'force': force, 'username': username}));
      if (!mounted) return;
      final body = json.decode(res.body);
      if (res.statusCode == 200) {
        showCustomSnackbar(context, body['pesan'] ?? 'Dihapus.');
        fetchPetani();
      } else if (res.statusCode == 409) {
        showDialog(context: context, builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Petani Punya Data Aktif', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          content: Text(body['pesan'] ?? 'Cascade needed', style: const TextStyle(fontSize: 12)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white), onPressed: () { Navigator.pop(ctx); _kirimHapus(id, nama, true); }, child: const Text('Tetap Hapus')),
          ],
        ));
      } else {
        showCustomSnackbar(context, body['pesan'] ?? 'Gagal.', isError: true);
      }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Koneksi gagal!', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _dialogForm(),
        backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, elevation: 4,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: const Text('Tambah Petani', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -50, child: CircleAvatar(radius: 150, backgroundColor: Colors.teal.shade50.withOpacity(0.5))),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 60, left: 16, right: 24, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22), onPressed: () => Navigator.pop(context)),
                      const Text('Data Petani', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5)),
                    ]),
                    InkWell(
                      onTap: fetchPetani, borderRadius: BorderRadius.circular(12),
                      child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.refresh_rounded, color: Colors.teal.shade800, size: 20)),
                    ),
                  ],
                ),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                  child: TextField(
                    controller: searchCtrl, onChanged: _applyFilter,
                    decoration: InputDecoration(hintText: 'Cari nama / telepon...', hintStyle: TextStyle(color: Colors.grey.shade400), icon: Icon(Icons.search_rounded, color: Colors.teal.shade700), border: InputBorder.none),
                  ),
                ),
              ),
              // Counter
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                child: Align(alignment: Alignment.centerLeft, child: Text('${filtered.length} petani terdaftar', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold))),
              ),
              Expanded(
                child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                    ? Center(child: Text('Petani tidak ditemukan', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final p = filtered[i];
                          final kasbon = double.tryParse((p['total_kasbon'] ?? 0).toString()) ?? 0;
                          final telp = (p['no_telp'] ?? '').toString();
                          final rek = (p['no_rekening'] ?? '').toString();
                          final bool adaHutang = kasbon > 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))]),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPetaniScreen(pelangganId: p['id'].toString(), nama: p['nama']))).then((_) => fetchPetani()),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 46, height: 46,
                                        decoration: BoxDecoration(color: adaHutang ? Colors.red.shade50 : Colors.teal.shade50, borderRadius: BorderRadius.circular(14)),
                                        child: Center(child: Text((p['nama'] ?? '?').toString().substring(0, 1).toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: adaHutang ? Colors.red.shade700 : Colors.teal.shade800))),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                                            const SizedBox(height: 3),
                                            if (telp.isNotEmpty || rek.isNotEmpty)
                                              Wrap(spacing: 6, runSpacing: 3, children: [
                                                if (telp.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.phone_rounded, size: 11, color: Colors.green.shade600), const SizedBox(width: 3), Text(telp, style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600))]),
                                                if (rek.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.account_balance_rounded, size: 11, color: Colors.indigo.shade600), const SizedBox(width: 3), Text(rek, style: TextStyle(fontSize: 11, color: Colors.indigo.shade700, fontWeight: FontWeight.w600))]),
                                              ])
                                            else
                                              Text('Belum ada kontak', style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
                                            if (adaHutang) ...[
                                              const SizedBox(height: 3),
                                              Text('Hutang: ${formatRp(kasbon)}', style: TextStyle(fontSize: 11, color: Colors.red.shade600, fontWeight: FontWeight.w700)),
                                            ],
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _konfirmasiHapus(p),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                                          child: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red.shade600),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.chevron_right_rounded, size: 22, color: Colors.grey.shade300),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DETAIL PROFIL PETANI — info + stats + riwayat nota + riwayat kasbon
// ============================================================================
class DetailPetaniScreen extends StatefulWidget {
  final String pelangganId;
  final String nama;
  const DetailPetaniScreen({super.key, required this.pelangganId, required this.nama});
  @override
  State<DetailPetaniScreen> createState() => _DetailPetaniScreenState();
}

class _DetailPetaniScreenState extends State<DetailPetaniScreen> with SingleTickerProviderStateMixin {
  Map? info;
  Map? stats;
  List notaHistory = [];
  List kasbonHistory = [];
  List rekeningList = [];
  bool isLoading = false;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    fetchProfil();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> fetchProfil() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/petani/profil/${widget.pelangganId}/?_t=${DateTime.now().millisecondsSinceEpoch}'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          info = data['info'];
          stats = data['stats'];
          notaHistory = data['nota_history'] ?? [];
          kasbonHistory = data['kasbon_history'] ?? [];
          rekeningList = data['rekening_list'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Gagal memuat profil!', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _statBox(String label, String value, IconData icon, {bool highlight = false, Color accent = const Color(0xFF00897B)}) {
    final valueColor = highlight ? accent : Colors.grey.shade800;
    final iconColor = highlight ? accent : Colors.grey.shade400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlight ? accent.withOpacity(0.35) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 7),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: valueColor))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final telp = (info?['no_telp'] ?? '').toString();
    final rek = (info?['no_rekening'] ?? '').toString();
    final kasbon = double.tryParse((info?['total_kasbon'] ?? 0).toString()) ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : NestedScrollView(
            headerSliverBuilder: (ctx, inner) => [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.only(top: 56, left: 16, right: 16, bottom: 16),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal.shade800, Colors.teal.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22), onPressed: () => Navigator.pop(context)),
                        Expanded(child: Text(info?['nama'] ?? widget.nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, overflow: TextOverflow.ellipsis))),
                        IconButton(icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20), tooltip: 'Edit Info Petani', onPressed: _dialogEditInfo),
                      ]),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Wrap(spacing: 8, runSpacing: 6, children: [
                          if (telp.isNotEmpty) _kontakChip(Icons.phone_rounded, telp),
                          if (rek.isNotEmpty) _kontakChip(Icons.account_balance_rounded, rek),
                          if (telp.isEmpty && rek.isEmpty) Text('Belum ada kontak', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontStyle: FontStyle.italic)),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      // Stats grid
                      Row(children: [
                        Expanded(child: _statBoxLight('Hutang Kasbon', formatRp(kasbon), kasbon > 0 ? Colors.red.shade100 : Colors.white)),
                        const SizedBox(width: 8),
                        Expanded(child: _statBoxLight('Jumlah Nota', '${stats?['jumlah_nota'] ?? 0}', Colors.white)),
                        const SizedBox(width: 8),
                        Expanded(child: _statBoxLight('Total Tonase', '${(double.tryParse((stats?['total_tonase'] ?? 0).toString()) ?? 0).toStringAsFixed(0)} Kg', Colors.white)),
                      ]),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.3, crossAxisSpacing: 12, mainAxisSpacing: 12,
                    children: [
                      _statBox('Total Nilai Beli', formatRp(stats?['total_nilai'] ?? 0), Icons.payments_rounded),
                      _statBox('Rata Harga/Kg', formatRp(stats?['rata_harga_per_kg'] ?? 0), Icons.trending_up_rounded),
                      _statBox('BB Aktif', '${stats?['bb_aktif'] ?? 0} nota', Icons.warning_amber_rounded,
                        highlight: (int.tryParse('${stats?['bb_aktif'] ?? 0}') ?? 0) > 0, accent: Colors.red.shade600),
                      _statBox('TF Pending', '${stats?['tf_pending'] ?? 0} transfer', Icons.account_balance_rounded,
                        highlight: (int.tryParse('${stats?['tf_pending'] ?? 0}') ?? 0) > 0, accent: Colors.orange.shade700),
                      _statBox('Total Setor', formatRp(stats?['total_setor'] ?? 0), Icons.savings_rounded),
                      _statBox('Transaksi Terakhir', (stats?['transaksi_terakhir'] ?? '-').toString(), Icons.event_rounded),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _rekeningCard()),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                  child: TabBar(
                    controller: _tab,
                    labelColor: Colors.teal.shade800, unselectedLabelColor: Colors.grey.shade500,
                    indicatorColor: Colors.teal.shade700, indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    tabs: [
                      Tab(text: 'Nota (${notaHistory.length})'),
                      Tab(text: 'Kasbon (${kasbonHistory.length})'),
                    ],
                  ),
                ),
              ),
            ],
            body: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildNotaList(),
                  _buildKasbonList(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _kontakChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: Colors.white), const SizedBox(width: 5), Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))]),
    );
  }

  Widget _statBoxLight(String label, String value, Color bg) {
    final isWhite = bg == Colors.white;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg.withOpacity(isWhite ? 0.18 : 1), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 9, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Future<void> _dialogEditInfo() async {
    final namaCtrl = TextEditingController(text: (info?['nama'] ?? widget.nama).toString());
    final telpCtrl = TextEditingController(text: (info?['no_telp'] ?? '').toString());
    bool saving = false;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setD) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Edit Info Petani', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: namaCtrl, textCapitalization: TextCapitalization.words, decoration: InputDecoration(isDense: true, labelText: 'Nama Petani', prefixIcon: const Icon(Icons.person_rounded, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 10),
            TextField(controller: telpCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(isDense: true, labelText: 'No. Telepon (opsional)', prefixIcon: const Icon(Icons.phone_rounded, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 6),
            Text('Rekening dikelola di bagian "Rekening Bank" di bawah.', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
          ]),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: saving ? null : () async {
                final nama = namaCtrl.text.trim();
                if (nama.isEmpty) { showCustomSnackbar(context, 'Nama wajib diisi!', isError: true); return; }
                setD(() => saving = true);
                try {
                  final prefs = await SharedPreferences.getInstance();
                  final username = prefs.getString('username') ?? 'Sistem';
                  final res = await http.post(
                    Uri.parse('${AppConfig.baseUrl}/api/pelanggan/edit/'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      'pelanggan_id': widget.pelangganId,
                      'nama': nama,
                      'no_telp': telpCtrl.text.trim(),
                      'no_rekening': (info?['no_rekening'] ?? '').toString(),
                      'username': username,
                    }),
                  );
                  final d = json.decode(res.body);
                  if (res.statusCode == 200 && d['status'] == 'sukses') {
                    if (ctx.mounted) Navigator.pop(ctx);
                    await fetchProfil();
                    if (mounted) showCustomSnackbar(context, 'Info petani diperbarui.');
                  } else {
                    setD(() => saving = false);
                    if (mounted) showCustomSnackbar(context, d['pesan'] ?? 'Gagal memperbarui.', isError: true);
                  }
                } catch (_) {
                  setD(() => saving = false);
                  if (mounted) showCustomSnackbar(context, 'Gagal terhubung server!', isError: true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, elevation: 0),
              child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan'),
            ),
          ],
        );
      }),
    );
  }

  Widget _rekeningCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.account_balance_rounded, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 6),
              const Text('Rekening Bank', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _dialogRekening(),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Tambah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                style: TextButton.styleFrom(foregroundColor: Colors.blue.shade700, padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 32)),
              ),
            ]),
            if (rekeningList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('Belum ada rekening. Tap "Tambah" untuk menambah.', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
              )
            else
              ...rekeningList.map((r) {
                final nama = (r['atas_nama'] ?? '').toString().trim();
                final nomor = (r['nomor'] ?? '').toString().trim();
                return Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.4), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.shade100)),
                  child: Row(children: [
                    Icon(Icons.credit_card_rounded, size: 15, color: Colors.blue.shade400),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(nomor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black87)),
                      if (nama.isNotEmpty) Text('a.n. $nama', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ])),
                    InkWell(onTap: () => _dialogRekening(existing: r), borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.edit_rounded, size: 16, color: Colors.grey.shade600))),
                    const SizedBox(width: 2),
                    InkWell(onTap: () => _hapusRekening(r), borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade400))),
                  ]),
                );
              }),
          ],
        ),
      ),
    );
  }

  // Input bergaya app (kotak abu-abu rounded) biar dialog rekening serasi
  Widget _rekInput({required TextEditingController controller, required String hint, TextInputType type = TextInputType.text, TextCapitalization cap = TextCapitalization.none, IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        controller: controller,
        keyboardType: type,
        textCapitalization: cap,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.normal, fontSize: 13),
          prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.grey.shade400) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _dialogRekening({Map? existing}) async {
    final nomorCtrl = TextEditingController(text: existing?['nomor']?.toString() ?? '');
    final namaCtrl = TextEditingController(text: existing?['atas_nama']?.toString() ?? '');
    bool saving = false;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setD) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          title: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.account_balance_rounded, color: Colors.teal.shade700, size: 18)),
            const SizedBox(width: 10),
            Text(existing == null ? 'Tambah Rekening' : 'Edit Rekening', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.black87)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _rekInput(controller: nomorCtrl, hint: 'Nomor Rekening', type: TextInputType.number, icon: Icons.tag_rounded),
            _rekInput(controller: namaCtrl, hint: 'Atas Nama (opsional)', cap: TextCapitalization.words, icon: Icons.person_rounded),
          ]),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: Text('Batal', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold))),
            ElevatedButton(
              onPressed: saving ? null : () async {
                final nomor = nomorCtrl.text.trim();
                if (nomor.isEmpty) { showCustomSnackbar(context, 'Nomor rekening wajib diisi!', isError: true); return; }
                setD(() => saving = true);
                final ok = await _simpanRekening(existing?['id'], nomor, namaCtrl.text.trim());
                if (ok && ctx.mounted) { Navigator.pop(ctx); }
                else { setD(() => saving = false); }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }),
    );
  }

  Future<bool> _simpanRekening(dynamic rekId, String nomor, String atasNama) async {
    try {
      final isEdit = rekId != null;
      final url = isEdit ? '${AppConfig.baseUrl}/api/rekening/edit/' : '${AppConfig.baseUrl}/api/rekening/tambah/';
      final body = isEdit
        ? {'rekening_id': rekId, 'nomor': nomor, 'atas_nama': atasNama}
        : {'pelanggan_id': widget.pelangganId, 'nomor': nomor, 'atas_nama': atasNama};
      final res = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: json.encode(body));
      final data = json.decode(res.body);
      if (res.statusCode == 200 && data['status'] == 'sukses') {
        await fetchProfil();
        if (mounted) showCustomSnackbar(context, isEdit ? 'Rekening diperbarui.' : 'Rekening ditambahkan.');
        return true;
      } else {
        if (mounted) showCustomSnackbar(context, data['pesan'] ?? 'Gagal menyimpan rekening.', isError: true);
        return false;
      }
    } catch (_) {
      if (mounted) showCustomSnackbar(context, 'Gagal menyimpan rekening!', isError: true);
      return false;
    }
  }

  Future<void> _hapusRekening(Map r) async {
    final konfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Rekening?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Text('Hapus rekening ${(r['nomor'] ?? '').toString()}${(r['atas_nama'] ?? '').toString().trim().isEmpty ? '' : ' (a.n. ${r['atas_nama']})'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, elevation: 0), child: const Text('Hapus')),
        ],
      ),
    );
    if (konfirm != true) return;
    try {
      final res = await http.post(Uri.parse('${AppConfig.baseUrl}/api/rekening/hapus/'), headers: {'Content-Type': 'application/json'}, body: json.encode({'rekening_id': r['id']}));
      if (res.statusCode == 200) { await fetchProfil(); if (mounted) showCustomSnackbar(context, 'Rekening dihapus.'); }
      else { if (mounted) showCustomSnackbar(context, 'Gagal menghapus rekening.', isError: true); }
    } catch (_) {
      if (mounted) showCustomSnackbar(context, 'Gagal menghapus rekening!', isError: true);
    }
  }

  Widget _buildNotaList() {
    if (notaHistory.isEmpty) return Center(child: Text('Belum ada nota.', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)));
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: notaHistory.length,
      itemBuilder: (ctx, i) {
        final n = notaHistory[i];
        final bool isBB = n['status_bayar'] == 'BB';
        final Color c = isBB ? Colors.red.shade600 : Colors.teal.shade700;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.receipt_rounded, size: 16, color: c)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('#${n['id']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey.shade600)),
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(n['status_bayar'] ?? '-', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: c))),
              ]),
              const SizedBox(height: 3),
              Text('${n['tanggal']}  •  ${(double.tryParse(n['berat_kg'].toString()) ?? 0).toStringAsFixed(0)} Kg × ${formatRp(n['harga_per_kg'])}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ])),
            Text(formatRp(n['total_bersih']), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: c)),
          ]),
        );
      },
    );
  }

  Widget _buildKasbonList() {
    if (kasbonHistory.isEmpty) return Center(child: Text('Belum ada riwayat kasbon.', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)));
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: kasbonHistory.length,
      itemBuilder: (ctx, i) {
        final h = kasbonHistory[i];
        final bool isPinjam = h['tipe'] == 'PINJAM';
        final Color c = isPinjam ? Colors.red.shade600 : Colors.teal.shade700;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(isPinjam ? Icons.south_west_rounded : Icons.north_east_rounded, size: 16, color: c)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(h['tipe'] ?? '-', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: c))),
                const SizedBox(width: 6),
                Text(h['tanggal'] ?? '-', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 3),
              Text(h['keterangan'] ?? '-', style: TextStyle(fontSize: 10, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text((isPinjam ? '+ ' : '- ') + formatRp(h['nominal']), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: c)),
              Text('Saldo: ${formatRp(h['saldo_setelah'])}', style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            ]),
          ]),
        );
      },
    );
  }
}
