import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/helpers.dart';
import '../utils/constants.dart';

class MenuKasbonScreen extends StatefulWidget { 
  const MenuKasbonScreen({super.key}); 
  @override State<MenuKasbonScreen> createState() => _MenuKasbonScreenState(); 
}

class _MenuKasbonScreenState extends State<MenuKasbonScreen> { 
  List pelanggan = []; 
  List filteredPelanggan = []; 
  final searchController = TextEditingController();
  bool isLoading = false;
  
  Future<void> fetchPelanggan() async { 
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/api/pelanggan/')); 
      if (response.statusCode == 200) { 
        setState(() { 
          pelanggan = json.decode(response.body); 
          filterList(searchController.text); 
        }); 
      } 
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Koneksi ke server gagal!', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  } 
  
  void filterList(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredPelanggan = pelanggan;
      } else {
        filteredPelanggan = pelanggan.where((p) => p['nama'].toString().toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  Widget _petaniField(TextEditingController ctrl, String label, String hint, IconData icon, {TextInputType? type, TextCapitalization cap = TextCapitalization.none}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        textCapitalization: cap,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, size: 18, color: Colors.teal.shade700),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  // Dialog form petani — dipakai untuk TAMBAH (existing=null) maupun EDIT
  void _dialogFormPetani({Map? existing}) {
    final bool isEdit = existing != null;
    final namaCtrl = TextEditingController(text: isEdit ? (existing['nama'] ?? '') : '');
    final telpCtrl = TextEditingController(text: isEdit ? (existing['no_telp'] ?? '') : '');
    final rekCtrl = TextEditingController(text: isEdit ? (existing['no_rekening'] ?? '') : '');

    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(isEdit ? 'Edit Info Petani' : 'Tambah Petani Baru', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _petaniField(namaCtrl, 'Nama Petani *', 'Nama lengkap', Icons.person_rounded, cap: TextCapitalization.words),
            _petaniField(telpCtrl, 'No. Telepon (opsional)', 'Cth: 0812xxxx', Icons.phone_rounded, type: TextInputType.phone),
            _petaniField(rekCtrl, 'No. Rekening (opsional)', 'Cth: BCA 1234567', Icons.account_balance_rounded),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('* Nama wajib diisi. Telp & rekening boleh dikosongkan.', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () async {
            final nama = namaCtrl.text.trim();
            if (nama.isEmpty) {
              showCustomSnackbar(context, 'Nama tidak boleh kosong!', isError: true);
              return;
            }
            try {
              final prefs = await SharedPreferences.getInstance();
              final username = prefs.getString('username') ?? 'Sistem';
              final url = isEdit ? '${AppConfig.baseUrl}/api/pelanggan/edit/' : '${AppConfig.baseUrl}/api/pelanggan/tambah/';
              final payload = isEdit
                ? {'pelanggan_id': existing['id'], 'nama': nama, 'no_telp': telpCtrl.text.trim(), 'no_rekening': rekCtrl.text.trim(), 'username': username}
                : {'nama': nama, 'no_telp': telpCtrl.text.trim(), 'no_rekening': rekCtrl.text.trim()};
              final res = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: json.encode(payload));
              if (!mounted) return;
              final body = json.decode(res.body);
              if (res.statusCode == 200) {
                Navigator.pop(context);
                showCustomSnackbar(context, body['pesan'] ?? (isEdit ? 'Info petani diperbarui!' : 'Petani ditambahkan!'));
                fetchPelanggan();
              } else {
                showCustomSnackbar(context, body['pesan'] ?? 'Gagal menyimpan!', isError: true);
              }
            } catch (e) {
              if (mounted) showCustomSnackbar(context, 'Koneksi ke server gagal!', isError: true);
            }
          },
          child: Text(isEdit ? 'Update' : 'Simpan', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  void _dialogTambahPelangganBaru() => _dialogFormPetani();

  Future<void> _kirimHapusPelanggan(dynamic pelangganId, String nama, bool force) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/pelanggan/hapus/'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'pelanggan_id': pelangganId, 'force': force}),
      );
      if (!mounted) return;
      final body = json.decode(res.body);
      if (res.statusCode == 200) {
        showCustomSnackbar(context, body['pesan'] ?? 'Petani $nama dihapus.');
        fetchPelanggan();
      } else if (res.statusCode == 409) {
        // Butuh konfirmasi force
        _dialogForceHapus(pelangganId, nama, body['pesan'] ?? 'Data terkait masih ada.');
      } else {
        showCustomSnackbar(context, body['pesan'] ?? 'Gagal hapus petani.', isError: true);
      }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Koneksi ke server gagal!', isError: true);
    }
  }

  void _konfirmasiHapusPelanggan(dynamic pelangganId, String nama, double kasbonAktif) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 22),
          const SizedBox(width: 8),
          const Expanded(child: Text('Hapus Petani?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Yakin ingin menghapus petani:', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
            child: Text(nama, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.red.shade900)),
          ),
          if (kasbonAktif > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.orange.shade700, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text('Petani ini masih punya kasbon ${formatRp(kasbonAktif)}', style: TextStyle(fontSize: 11, color: Colors.orange.shade900, fontWeight: FontWeight.w600))),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text('Aksi ini permanen dan tidak bisa dibatalkan.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
        ],
      ),
      actionsPadding: const EdgeInsets.only(bottom: 12, right: 12, left: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600, foregroundColor: Colors.white,
            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.delete_outline_rounded, size: 16),
          label: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () {
            Navigator.pop(ctx);
            _kirimHapusPelanggan(pelangganId, nama, false);
          },
        ),
      ],
    ));
  }

  void _dialogForceHapus(dynamic pelangganId, String nama, String warningMsg) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 8),
          const Expanded(child: Text('Petani Punya Data Aktif', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
            child: Text(warningMsg, style: TextStyle(fontSize: 12, color: Colors.red.shade900, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          Text('Tetap hapus akan menghilangkan semua data terkait (nota, kasbon, item pengiriman).', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
        ],
      ),
      actionsPadding: const EdgeInsets.only(bottom: 12, right: 12, left: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700, foregroundColor: Colors.white,
            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.delete_forever_rounded, size: 16),
          label: const Text('Tetap Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () {
            Navigator.pop(ctx);
            _kirimHapusPelanggan(pelangganId, nama, true);
          },
        ),
      ],
    ));
  }

  @override
  void initState() {
    super.initState();
    fetchPelanggan();
  }
  
  @override 
  Widget build(BuildContext context) { 
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _dialogTambahPelangganBaru,
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: const Text('Tambah Petani', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: Colors.teal.shade50.withOpacity(0.5),
            ),
          ),

          Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 60, left: 16, right: 24, bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Buku Kasbon',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: fetchPelanggan,
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

              // --- SEARCH BAR iOS STYLE ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: searchController, 
                    onChanged: filterList, 
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration( 
                      hintText: 'Cari nama petani...', 
                      hintStyle: TextStyle(color: Colors.grey.shade400), 
                      icon: Icon(Icons.search_rounded, color: Colors.teal.shade700), 
                      border: InputBorder.none, 
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : filteredPelanggan.isEmpty
                    ? Center(child: Text('Petani tidak ditemukan', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), 
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredPelanggan.length, 
                        itemBuilder: (context, index) { 
                          final p = filteredPelanggan[index]; 
                          final kasbon = double.parse(p['total_kasbon'].toString()); 
                          bool adaHutang = kasbon > 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white, 
                              borderRadius: BorderRadius.circular(20), 
                              border: Border.all(color: Colors.grey.shade100), 
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => Navigator.push(
                                  context, MaterialPageRoute(builder: (context) => FormKasbonScreen(pelangganId: p['id'].toString(), nama: p['nama'], kasbonAwal: kasbon))
                                ).then((value) => fetchPelanggan()),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      // Avatar Initial
                                      Container(
                                        width: 50, height: 50,
                                        decoration: BoxDecoration(
                                          color: adaHutang ? Colors.red.shade50 : Colors.teal.shade50,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Center(
                                          child: Text(
                                            p['nama'].toString().substring(0, 1).toUpperCase(),
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: adaHutang ? Colors.red.shade700 : Colors.teal.shade800),
                                          )
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Teks Nama & Hutang
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)), 
                                            const SizedBox(height: 4),
                                            Text(
                                              adaHutang ? 'Sisa Hutang: ${formatRp(kasbon)}' : 'Lunas / Tidak ada hutang', 
                                              style: TextStyle(fontSize: 13, color: adaHutang ? Colors.red.shade600 : Colors.grey.shade500, fontWeight: adaHutang ? FontWeight.w700 : FontWeight.w500)
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey.shade500),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _dialogFormPetani(existing: p);
                                          } else if (value == 'hapus') {
                                            _konfirmasiHapusPelanggan(p['id'], p['nama'], kasbon);
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_rounded, color: Colors.teal.shade700, size: 18),
                                                const SizedBox(width: 8),
                                                Text('Edit Info Petani', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.w600, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'hapus',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline_rounded, color: Colors.red.shade600, size: 18),
                                                const SizedBox(width: 8),
                                                Text('Hapus Petani', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Icon(Icons.chevron_right_rounded, size: 24, color: Colors.grey.shade300),
                                    ],
                                  ),
                                ),
                              )
                            )
                          );
                        }
                      ),
              ),
            ],
          )
        ],
      )
    ); 
  } 
}


class FormKasbonScreen extends StatefulWidget { 
  final String pelangganId; 
  final String nama; 
  final double kasbonAwal; 
  const FormKasbonScreen({super.key, required this.pelangganId, required this.nama, required this.kasbonAwal}); 
  @override State<FormKasbonScreen> createState() => _FormKasbonScreenState(); 
}

class _FormKasbonScreenState extends State<FormKasbonScreen> {
  String tipeTransaksi = 'PINJAM';
  final nominalController = TextEditingController();
  final ketController = TextEditingController();
  bool isLoading = false;

  // History kasbon
  List historyKasbon = [];
  Map<String, dynamic>? historySummary;
  bool isLoadingHistory = false;
  double currentKasbon = 0;

  @override
  void initState() {
    super.initState();
    currentKasbon = widget.kasbonAwal;
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    setState(() => isLoadingHistory = true);
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/kasbon/history/${widget.pelangganId}/?_t=${DateTime.now().millisecondsSinceEpoch}'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          historyKasbon = (data['history'] ?? []).reversed.toList(); // tampilkan terbaru di atas
          historySummary = data['summary'];
          currentKasbon = double.tryParse(data['pelanggan']['total_kasbon_saat_ini'].toString()) ?? widget.kasbonAwal;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => isLoadingHistory = false);
    }
  }

  Future<void> submitKasbon() async {
    if (nominalController.text.isEmpty) {
      showCustomSnackbar(context, 'Nominal tidak boleh kosong!', isError: true);
      return; 
    }
    setState(() => isLoading = true); 
    try { 
      String nominalMurni = nominalController.text.replaceAll('.', '');
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/kasbon/transaksi/'), 
        body: json.encode({'pelanggan_id': widget.pelangganId, 'tipe': tipeTransaksi, 'nominal': nominalMurni, 'keterangan': ketController.text})
      ); 
      final result = json.decode(response.body); 
      
      if (response.statusCode == 200 && result['status'] == 'sukses') {
        if (!mounted) return;
        // Refresh history & saldo, jangan langsung pop biar user liat update
        nominalController.clear();
        ketController.clear();
        await fetchHistory();
        if (mounted) showCustomSnackbar(context, 'Data Kasbon berhasil dicatat!');
      } else {
        if (!mounted) return; 
        showCustomSnackbar(context, result['pesan'], isError: true); 
      } 
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Gagal terhubung ke server!', isError: true);
    } finally { 
      if (mounted) setState(() => isLoading = false); 
    } 
  } 

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: color.withOpacity(0.7), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildHistoryItem(Map h) {
    final bool isPinjam = h['tipe'] == 'PINJAM';
    final Color color = isPinjam ? Colors.red.shade600 : Colors.teal.shade700;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(isPinjam ? Icons.south_west_rounded : Icons.north_east_rounded, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(h['tipe'] ?? '-', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color)),
                    ),
                    const SizedBox(width: 6),
                    Text(h['tanggal'] ?? '-', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(h['keterangan'] ?? '-', style: TextStyle(fontSize: 11, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text((isPinjam ? '+' : '-') + ' ' + formatRp(h['nominal']), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 2),
              Text('Saldo: ${formatRp(h['saldo_setelah'])}', style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _konfirmasiHapusKasbonEntry(h['id'], h['tipe'], h['nominal'], h['keterangan']),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  void _konfirmasiHapusKasbonEntry(dynamic entryId, String tipe, dynamic nominal, String? keterangan) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
          const SizedBox(width: 8),
          const Expanded(child: Text('Hapus Riwayat?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$tipe — ${formatRp(nominal)}', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red.shade900, fontSize: 13)),
                if (keterangan != null && keterangan.isNotEmpty) Text(keterangan, style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('Akan auto-reverse: total_kasbon petani + mutasi kas terkait (kalau ada). Tercatat di audit log.',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
        ],
      ),
      actionsPadding: const EdgeInsets.only(bottom: 12, right: 12, left: 12),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          icon: const Icon(Icons.delete_forever_rounded, size: 16),
          label: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () { Navigator.pop(ctx); _eksekusiHapusKasbonEntry(entryId); },
        ),
      ],
    ));
  }

  Future<void> _eksekusiHapusKasbonEntry(dynamic entryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUsername = prefs.getString('username') ?? 'Sistem';
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/kasbon/hapus_entry/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'entry_id': entryId, 'username': currentUsername}),
      );
      if (!mounted) return;
      final body = json.decode(res.body);
      if (res.statusCode == 200) {
        showCustomSnackbar(context, body['pesan'] ?? 'Riwayat dihapus.');
        await fetchHistory();
      } else {
        showCustomSnackbar(context, body['pesan'] ?? 'Gagal hapus.', isError: true);
      }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Koneksi gagal!', isError: true);
    }
  }

  Widget _buildSultanInput({required TextEditingController controller, required String hint, required IconData icon, bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          icon: Icon(icon, color: Colors.teal.shade700, size: 20),
          border: InputBorder.none,
        ),
      ),
    );
  }
  
  @override 
  Widget build(BuildContext context) { 
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: CircleAvatar(radius: 140, backgroundColor: Colors.teal.shade50.withOpacity(0.6))),
          
          Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 60, left: 16, right: 24, bottom: 20),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22), onPressed: () => Navigator.pop(context)),
                    Expanded(
                      child: Text(
                        'Kasbon ${widget.nama}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, overflow: TextOverflow.ellipsis),
                      ),
                    ),
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
                        padding: const EdgeInsets.all(24.0),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: currentKasbon > 0
                              ? [Colors.red.shade800, Colors.red.shade500]
                              : [Colors.teal.shade800, Colors.teal.shade500],
                            begin: Alignment.topLeft, end: Alignment.bottomRight
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: (currentKasbon > 0 ? Colors.red : Colors.teal).withOpacity(0.3),
                              blurRadius: 20, offset: const Offset(0, 10)
                            )
                          ]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(currentKasbon > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: Colors.white70, size: 20),
                                const SizedBox(width: 8),
                                Text('TOTAL HUTANG SAAT INI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.8), letterSpacing: 1.5))
                              ]
                            ),
                            const SizedBox(height: 16),
                            Text(formatRp(currentKasbon), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                            if (historySummary != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildMiniStat('Total Pinjam', formatRp(historySummary!['total_pinjam'] ?? 0), Colors.white)),
                                  Container(width: 1, height: 32, color: Colors.white24),
                                  Expanded(child: _buildMiniStat('Total Setor', formatRp(historySummary!['total_setor'] ?? 0), Colors.white)),
                                  Container(width: 1, height: 32, color: Colors.white24),
                                  Expanded(child: _buildMiniStat('Transaksi', '${historySummary!['jumlah_transaksi'] ?? 0}x', Colors.white)),
                                ],
                              ),
                            ],
                          ]
                        )
                      ),
                      
                      const SizedBox(height: 36), 
                      
                      const Text('JENIS TRANSAKSI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2, color: Colors.black45)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => tipeTransaksi = 'PINJAM'),
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: tipeTransaksi == 'PINJAM' ? Colors.red.shade700 : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: tipeTransaksi == 'PINJAM' ? Colors.red.shade700 : Colors.grey.shade200),
                                  boxShadow: tipeTransaksi == 'PINJAM' ? [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
                                ),
                                child: Center(
                                  child: Text('PINJAM', style: TextStyle(fontWeight: FontWeight.w900, color: tipeTransaksi == 'PINJAM' ? Colors.white : Colors.grey.shade500, letterSpacing: 1)),
                                ),
                              ),
                            )
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => tipeTransaksi = 'SETOR'),
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: tipeTransaksi == 'SETOR' ? Colors.teal.shade700 : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: tipeTransaksi == 'SETOR' ? Colors.teal.shade700 : Colors.grey.shade200),
                                  boxShadow: tipeTransaksi == 'SETOR' ? [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
                                ),
                                child: Center(
                                  child: Text('SETOR', style: TextStyle(fontWeight: FontWeight.w900, color: tipeTransaksi == 'SETOR' ? Colors.white : Colors.grey.shade500, letterSpacing: 1)),
                                ),
                              ),
                            )
                          ),
                        ]
                      ), 
                      
                      const SizedBox(height: 36), 

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tipeTransaksi == 'PINJAM' ? 'NOMINAL PINJAMAN' : 'NOMINAL SETORAN', style: TextStyle(color: tipeTransaksi == 'PINJAM' ? Colors.red.shade700 : Colors.teal.shade700, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: nominalController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [RibuanFormatter()],
                              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: tipeTransaksi == 'PINJAM' ? Colors.red.shade900 : Colors.teal.shade900, letterSpacing: -1),
                              decoration: InputDecoration(
                                prefixText: 'Rp ',
                                prefixStyle: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: tipeTransaksi == 'PINJAM' ? Colors.red.shade900 : Colors.teal.shade900),
                                border: InputBorder.none,
                                hintText: '0',
                                hintStyle: TextStyle(color: Colors.grey.shade300),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- INPUT KETERANGAN ---
                      const Text('KETERANGAN / CATATAN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2, color: Colors.black45)),
                      const SizedBox(height: 12),
                      _buildSultanInput(controller: ketController, hint: 'Catatan tambahan (Opsional)', icon: Icons.notes_rounded),

                      const SizedBox(height: 32),

                      // --- HISTORY TRANSAKSI KASBON ---
                      Row(
                        children: [
                          Icon(Icons.history_rounded, size: 16, color: Colors.black54),
                          const SizedBox(width: 8),
                          const Text('RIWAYAT TRANSAKSI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2, color: Colors.black45)),
                          const Spacer(),
                          if (historyKasbon.isNotEmpty)
                            Text('${historyKasbon.length} entry', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (isLoadingHistory)
                        const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                      else if (historyKasbon.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                          child: Center(child: Text('Belum ada riwayat transaksi.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600))),
                        )
                      else
                        ...historyKasbon.map((h) => _buildHistoryItem(h)),

                      const SizedBox(height: 120), // Spasi buat dock
                    ]
                  ),
                ),
              ),
            ],
          ),

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
                    backgroundColor: Colors.amber.shade700, 
                    foregroundColor: Colors.white, 
                    padding: const EdgeInsets.symmetric(vertical: 18), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
                    elevation: 0
                  ), 
                  onPressed: isLoading ? null : submitKasbon, 
                  icon: isLoading ? const SizedBox.shrink() : const Icon(Icons.save_rounded, size: 22),
                  label: isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : Text('SIMPAN ${tipeTransaksi == 'PINJAM' ? 'PINJAMAN' : 'SETORAN'}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
              ),
            ),
          )
        ],
      )
    ); 
  } 
}