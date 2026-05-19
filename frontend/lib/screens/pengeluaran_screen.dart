import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class CatatPengeluaranScreen extends StatefulWidget {
  final double tonaseHarian; 
  const CatatPengeluaranScreen({super.key, required this.tonaseHarian});

  @override
  State<CatatPengeluaranScreen> createState() => _CatatPengeluaranScreenState();
}

class _CatatPengeluaranScreenState extends State<CatatPengeluaranScreen> {
  final _nominalCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();
  final _helperCtrl = TextEditingController(); 
  
  String? _selectedKategori;
  bool _isLoading = false;

  // --- DAFTAR KATEGORI ---
  final List<Map<String, dynamic>> _kategoriList = [
    {'id': 'MAKAN', 'label': 'Uang Makan', 'icon': Icons.restaurant},
    {'id': 'BURUH', 'label': 'Buruh Harian', 'icon': Icons.engineering},
    {'id': 'BURUH_TAMBAHAN', 'label': 'Buruh Tambahan', 'icon': Icons.group_add},
    {'id': 'ONGKIR', 'label': 'Ongkos Kirim', 'icon': Icons.local_shipping},
    {'id': 'UANG_JALAN', 'label': 'Uang Jalan', 'icon': Icons.map},
    {'id': 'MINYAK', 'label': 'Minyak Mobil', 'icon': Icons.local_gas_station},
    {'id': 'SUMBANGAN', 'label': 'Sumbangan', 'icon': Icons.volunteer_activism},
    {'id': 'GAJI', 'label': 'Gaji Bulanan', 'icon': Icons.payments},
    {'id': 'LAIN', 'label': 'Lain-lain', 'icon': Icons.category},
  ];

  @override
  void initState() {
    super.initState();
  }

  String _formatTitik(int value) {
    return value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _onHelperChanged(String val) {
    if (_selectedKategori == null || val.isEmpty) return;
    String label = _kategoriList.firstWhere((k) => k['id'] == _selectedKategori)['label'];

    if (_selectedKategori == 'MAKAN') {
      int qty = int.tryParse(val) ?? 0;
      _nominalCtrl.text = _formatTitik(qty * 20000); 
      _keteranganCtrl.text = '$label untuk $qty orang';
    } 
    else if (_selectedKategori == 'BURUH_TAMBAHAN') {
      _keteranganCtrl.text = '$label untuk $val orang';
    } 
    else if (_selectedKategori == 'UANG_JALAN' || _selectedKategori == 'MINYAK') {
      _keteranganCtrl.text = '$label mobil $val';
    }
  }

  void _onKategoriSelected(String id) {
    setState(() {
      _selectedKategori = id;
      _nominalCtrl.clear();
      _keteranganCtrl.clear();
      _helperCtrl.clear(); 

      if (id == 'BURUH') {
        // --- LOGIKA PEMBULATAN KE BAWAH (ROUND DOWN RIBUAN) ---
        double rawTotal = widget.tonaseHarian * 35;
        int totalBulatBawah = (rawTotal / 1000).floor() * 1000; 
        
        _nominalCtrl.text = _formatTitik(totalBulatBawah);
        _keteranganCtrl.text = 'Ongkos Buruh (${widget.tonaseHarian} Kg x Rp 35)'; 
      } 
      else if (id == 'ONGKIR') {
        _keteranganCtrl.text = 'Ongkos Kirim'; 
      }
    });
  }

  Future<void> _simpanPengeluaran() async {
    if (_selectedKategori == null) {
      showCustomSnackbar(context, 'Pilih kategori pengeluaran dulu!', isError: true);
      return;
    }
    if (_nominalCtrl.text.isEmpty) {
      showCustomSnackbar(context, 'Nominal tidak boleh kosong!', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    String nominalBersih = _nominalCtrl.text.replaceAll('.', '');

    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/pengeluaran/tambah/'),
        body: json.encode({
          'kategori': _selectedKategori,
          'nominal': nominalBersih,
          'keterangan': _keteranganCtrl.text,
        })
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        showCustomSnackbar(context, 'Pengeluaran berhasil dicatat!');
        Navigator.pop(context, true); 
      } else {
        final data = json.decode(res.body);
        showCustomSnackbar(context, data['pesan'] ?? 'Gagal mencatat pengeluaran', isError: true);
      }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Terjadi kesalahan jaringan', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nominalCtrl.dispose();
    _keteranganCtrl.dispose();
    _helperCtrl.dispose();
    super.dispose();
  }

  Widget _buildSultanInput({
    required TextEditingController controller,
    required String hint,
    Function(String)? onChanged,
    TextInputType type = TextInputType.text,
    TextCapitalization cap = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: type,
        textCapitalization: cap,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool butuhJumlahOrang = ['MAKAN', 'BURUH_TAMBAHAN'].contains(_selectedKategori);
    bool butuhPlatMobil = ['UANG_JALAN', 'MINYAK'].contains(_selectedKategori);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: CircleAvatar(
              radius: 140,
              backgroundColor: Colors.teal.shade50.withOpacity(0.6),
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
                          'Catat Pengeluaran',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.scale_rounded, size: 14, color: Colors.teal.shade700),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.tonaseHarian.toInt()} Kg',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pilih Kategori', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2, color: Colors.black45)),
                          const SizedBox(height: 16),
                          
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _kategoriList.map((kat) {
                              bool isSelected = _selectedKategori == kat['id'];
                              return InkWell(
                                onTap: () => _onKategoriSelected(kat['id']),
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.teal.shade800 : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: isSelected ? Colors.teal.shade800 : Colors.grey.shade200),
                                    boxShadow: isSelected 
                                      ? [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))] 
                                      : [],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(kat['icon'], size: 18, color: isSelected ? Colors.white : Colors.teal.shade700),
                                      const SizedBox(width: 8),
                                      Text(
                                        kat['label'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          color: isSelected ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 32),

                          if (butuhJumlahOrang || butuhPlatMobil) ...[
                            Text(butuhJumlahOrang ? 'JUMLAH ORANG' : 'PLAT MOBIL', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2, color: Colors.black45)),
                            const SizedBox(height: 12),
                            _buildSultanInput(
                              controller: _helperCtrl,
                              onChanged: _onHelperChanged,
                              hint: butuhJumlahOrang ? 'Masukkan Angka (Cth: 5)' : 'Cth: B 1234 CD',
                              type: butuhJumlahOrang ? TextInputType.number : TextInputType.text,
                              cap: butuhPlatMobil ? TextCapitalization.characters : TextCapitalization.none,
                            ),
                            if (_selectedKategori == 'MAKAN')
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 4),
                                child: Text('Otomatis dikali Rp 20.000 per orang', style: TextStyle(color: Colors.amber.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            const SizedBox(height: 24),
                          ],
                          
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.teal.shade50.withOpacity(0.3)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.teal.shade100.withOpacity(0.5)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('NOMINAL PENGELUARAN', style: TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _nominalCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [RibuanFormatter()],
                                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.teal.shade900, letterSpacing: -1),
                                  decoration: InputDecoration(
                                    prefixText: 'Rp ',
                                    prefixStyle: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.teal.shade900),
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

                          const SizedBox(height: 32),

                          const Text('KETERANGAN / CATATAN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2, color: Colors.black45)),
                          const SizedBox(height: 12),
                          _buildSultanInput(
                            controller: _keteranganCtrl,
                            hint: 'Catatan otomatis terisi, bisa diedit...',
                            maxLines: 2,
                          ),
                          
                          const SizedBox(height: 120), 
                        ],
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.save_rounded, size: 22),
                      label: const Text('SIMPAN PENGELUARAN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.5)),
                      onPressed: _isLoading ? null : _simpanPengeluaran,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}