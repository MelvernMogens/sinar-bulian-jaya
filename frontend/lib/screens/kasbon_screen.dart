import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  
  @override 
  void initState() { 
    super.initState(); 
    fetchPelanggan(); 
  } 
  
  @override 
  Widget build(BuildContext context) { 
    return Scaffold(
      backgroundColor: Colors.white,
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
        Navigator.pop(context); 
        showCustomSnackbar(context, 'Data Kasbon berhasil dicatat!'); 
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
                            colors: widget.kasbonAwal > 0 
                              ? [Colors.red.shade800, Colors.red.shade500] 
                              : [Colors.teal.shade800, Colors.teal.shade500],
                            begin: Alignment.topLeft, end: Alignment.bottomRight
                          ),
                          borderRadius: BorderRadius.circular(24), 
                          boxShadow: [
                            BoxShadow(
                              color: (widget.kasbonAwal > 0 ? Colors.red : Colors.teal).withOpacity(0.3), 
                              blurRadius: 20, offset: const Offset(0, 10)
                            )
                          ]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(widget.kasbonAwal > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: Colors.white70, size: 20), 
                                const SizedBox(width: 8), 
                                Text('TOTAL HUTANG SAAT INI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.8), letterSpacing: 1.5))
                              ]
                            ),
                            const SizedBox(height: 16),
                            Text(formatRp(widget.kasbonAwal), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
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