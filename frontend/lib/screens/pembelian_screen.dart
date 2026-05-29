import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:blue_thermal_printer/blue_thermal_printer.dart'; 

import '../utils/helpers.dart';
import '../utils/constants.dart';
import 'rekening_picker.dart';

// ============================================================================
// 1. HALAMAN PILIH PETANI (KASIR)
// ============================================================================
class PembelianScreen extends StatefulWidget { 
  const PembelianScreen({super.key}); 
  @override State<PembelianScreen> createState() => _PembelianScreenState(); 
}

class _PembelianScreenState extends State<PembelianScreen> { 
  List pelanggan = []; 
  List filteredPelanggan = []; 
  final searchController = TextEditingController();
  bool isLoading = false;
  
  Future<void> fetchPelanggan() async { 
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/api/pelanggan/?_t=${DateTime.now().millisecondsSinceEpoch}')); 
      if (response.statusCode == 200) { 
        setState(() { 
          pelanggan = json.decode(response.body); 
          filterList(searchController.text); 
        }); 
      }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Gagal memuat data pelanggan!', isError: true);
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
  
  Future<void> tambahPetaniDialog() async {
    final namaController = TextEditingController();
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Tambah Petani Baru', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
        content: Container(
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: TextField(
            controller: namaController, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Nama Petani', hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
              border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white,
              elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ), 
            onPressed: () async {
              if (namaController.text.isNotEmpty) { 
                Navigator.pop(context); 
                try {
                  await http.post(
                    Uri.parse('${AppConfig.baseUrl}/api/pelanggan/tambah/'), 
                    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
                    body: json.encode({'nama': namaController.text})
                  ); 
                  fetchPelanggan(); 
                  if (mounted) showCustomSnackbar(context, 'Petani berhasil ditambahkan!');
                } catch (e) {
                  if (mounted) showCustomSnackbar(context, 'Terjadi kesalahan sistem', isError: true);
                }
              }
            }, 
            child: const Text('Simpan Petani', style: TextStyle(fontWeight: FontWeight.bold))
          )
        ]
      )
    );
  }
  
  @override void initState() { 
    super.initState(); 
    fetchPelanggan(); 
  } 
  
  @override 
  Widget build(BuildContext context) { 
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(top: -100, right: -50, child: CircleAvatar(radius: 150, backgroundColor: Colors.teal.shade50.withOpacity(0.5))),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 60, left: 16, right: 24, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22), onPressed: () => Navigator.pop(context)),
                        const Text('Kasir Pembelian', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5)),
                      ],
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: tambahPetaniDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade100)),
                            child: Icon(Icons.person_add_rounded, color: Colors.amber.shade800, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                    )
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: searchController, 
                    onChanged: filterList, 
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    decoration: InputDecoration( 
                      hintText: 'Cari nama petani...', 
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal), 
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.teal.shade700),
                      suffixIcon: searchController.text.isNotEmpty 
                        ? IconButton(icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 20), onPressed: () { searchController.clear(); filterList(''); })
                        : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14), 
                    ),
                  ),
                ),
              ),

              Expanded(
                child: isLoading 
                ? const Center(child: CircularProgressIndicator())
                : filteredPelanggan.isEmpty
                  ? Center(child: Text('Petani tidak ditemukan', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), 
                      itemCount: filteredPelanggan.length, 
                      itemBuilder: (context, index) { 
                        final p = filteredPelanggan[index]; 
                        double kasbon = double.tryParse(p['total_kasbon'].toString()) ?? 0;
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
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FormNotaScreen(pelangganId: p['id'].toString(), nama: p['nama'], kasbonAwal: kasbon, noTelp: (p['no_telp'] ?? '').toString(), noRekening: (p['no_rekening'] ?? '').toString()))).then((_) => fetchPelanggan()),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48, height: 48,
                                      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(14)),
                                      child: Center(
                                        child: Text(p['nama'].toString().substring(0, 1).toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.teal.shade800))
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)), 
                                          const SizedBox(height: 4),
                                          Text(
                                            adaHutang ? 'Ada Kasbon: ${formatRp(kasbon)}' : 'Tidak ada kasbon', 
                                            style: TextStyle(fontSize: 12, color: adaHutang ? Colors.red.shade600 : Colors.grey.shade500, fontWeight: adaHutang ? FontWeight.bold : FontWeight.normal)
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(color: Colors.teal.shade800, borderRadius: BorderRadius.circular(12)),
                                      child: const Text('NOTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          )
                        ); 
                      }
                    ),
              ),
            ]
          )
        ],
      )
    ); 
  } 
}

// ============================================================================
// 2. HALAMAN FORM NOTA KASIR
// ============================================================================
// ============================================================================
// 2. HALAMAN FORM NOTA KASIR (DENGAN SPLIT PAYMENT)
// ============================================================================
class FormNotaScreen extends StatefulWidget {
  final String pelangganId;
  final String nama;
  final double kasbonAwal;
  final String noTelp;
  final String noRekening;
  const FormNotaScreen({super.key, required this.pelangganId, required this.nama, required this.kasbonAwal, this.noTelp = '', this.noRekening = ''});
  @override State<FormNotaScreen> createState() => _FormNotaScreenState();
}

class _FormNotaScreenState extends State<FormNotaScreen> { 
  List itemsDariGudang = [];
  List<int> selectedItemIds = [];
  
  final setoranController = TextEditingController(); 
  bool pakaiKomisi = true, pakaiBuruh = true, pakaiMaterai = true, isPotongKasbon = false;
  bool isLoading = true; 
  
  // --- VARIABEL SPLIT PAYMENT ---
  String metodeBayar = 'CASH'; // Metode Utama
  bool isSplitPayment = false;
  final nominalSplitCtrl = TextEditingController();
  String metodeBayar2 = 'BB'; // Metode Kedua (Sisa tagihan)
  // ------------------------------

  // --- Rekening tujuan TF (dipilih lewat popup) ---
  String? rekTfNomor;
  String? rekTfAtasNama;
  bool rekTfBelumAda = false;   // true = user pilih "rekening belum ada"
  bool rekTfSudahPilih = false; // true = popup sudah diisi (biar UI tau)
  // ------------------------------

  DateTime tglTransfer = DateTime.now(); 
  
  double estimasiBeratTotal = 0, estimasiKotor = 0, estimasiKomisi = 0, estimasiBuruh = 0, estimasiMaterai = 0, estimasiBersih = 0, estimasiBayarAkhir = 0; 
  
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  double roundUpRibuan(double value) => (value / 1000).ceil() * 1000.0;
  double roundDownRibuan(double value) => (value / 1000).floor() * 1000.0;

  // Penghitung nilai Split
  double get nominalBayarPertama {
    if (!isSplitPayment || nominalSplitCtrl.text.isEmpty) return estimasiBayarAkhir;
    double val = double.tryParse(nominalSplitCtrl.text.replaceAll('.', '')) ?? 0;
    return val > estimasiBayarAkhir ? estimasiBayarAkhir : val; // Mencegah input lebih besar dari total
  }
  
  double get sisaSplitTagihan => estimasiBayarAkhir - nominalBayarPertama;

  Future<void> fetchBarangGudang() async {
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/pelanggan/belum_nota/${widget.pelangganId}/'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          itemsDariGudang = data;
          selectedItemIds = itemsDariGudang.map<int>((e) => e['id'] as int).toList(); 
          isLoading = false;
          hitungEstimasi();
        });
      }
    } catch (e) {
      if (mounted) showCustomSnackbar(context, 'Gagal menarik data dari gudang', isError: true);
      setState(() => isLoading = false);
    }
  }
  
  @override void initState() { 
    super.initState(); 
    fetchBarangGudang();
    setoranController.addListener(hitungEstimasi); 
    nominalSplitCtrl.addListener(() => setState(() {})); // Biar Sisa Tagihan update real-time
  } 
  
  @override void dispose() { 
    setoranController.dispose(); 
    nominalSplitCtrl.dispose();
    super.dispose(); 
  } 
  
  void hitungEstimasi() { 
    double tBerat = 0;
    double tKotor = 0;
    for (var item in itemsDariGudang) {
      if (selectedItemIds.contains(item['id'])) {
        tBerat += double.tryParse(item['tonase'].toString()) ?? 0;
        tKotor += ((double.tryParse(item['tonase'].toString()) ?? 0) * (double.tryParse(item['harga'].toString()) ?? 0));
      }
    }
    double setoran = isPotongKasbon ? (double.tryParse(setoranController.text.replaceAll('.', '')) ?? 0) : 0; 
    setState(() { 
      estimasiBeratTotal = tBerat;
      estimasiKotor = tKotor; 
      estimasiKomisi = pakaiKomisi ? roundUpRibuan(estimasiKotor * 0.01) : 0; 
      estimasiBuruh = pakaiBuruh ? roundUpRibuan(estimasiBeratTotal * 35) : 0; 
      estimasiMaterai = (pakaiMaterai && tBerat > 0) ? roundUpRibuan(6000) : 0; 
      estimasiBersih = estimasiKotor - estimasiKomisi - estimasiBuruh - estimasiMaterai; 
      estimasiBayarAkhir = roundDownRibuan(estimasiBersih - setoran); 
    }); 
  } 

  void _persiapanCetak() {
    if (selectedItemIds.isEmpty) {
      showCustomSnackbar(context, 'Pilih minimal 1 barang dari gudang!', isError: true);
      return;
    }
    
    // Validasi Split Payment
    if (isSplitPayment && nominalBayarPertama <= 0) {
      showCustomSnackbar(context, 'Nominal pembayaran pertama tidak boleh kosong/nol!', isError: true);
      return;
    }

    double rataHarga = estimasiBeratTotal > 0 ? (estimasiKotor / estimasiBeratTotal) : 0;
    double nilaiKasbonForm = isPotongKasbon ? (double.tryParse(setoranController.text.replaceAll('.', '')) ?? 0) : 0;

    _tampilkanDialogPrinter(rataHarga, estimasiBersih, nilaiKasbonForm);
  }

  void _tampilkanDialogPrinter(double rataRataHarga, double totalSebelumKasbon, double kasbonForm) {
    List<BluetoothDevice> devices = [];
    BluetoothDevice? selectedDevice;
    bool dialogIsPotongKasbon = kasbonForm > 0;
    TextEditingController dialogKasbonCtrl = TextEditingController(text: kasbonForm > 0 ? formatRp(kasbonForm).replaceAll(RegExp(r'[^0-9]'), '') : '');
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
            if(mounted) setStateDialog(() {});
          }

          if (devices.isEmpty) getDevices();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.print_rounded, color: Colors.teal), SizedBox(width: 8),
                Text('Cetak & Simpan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                    child: CheckboxListTile(
                      title: const Text('Tampilkan Potong Kasbon?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      value: dialogIsPotongKasbon,
                      activeColor: Colors.teal,
                      onChanged: isProcessing ? null : (val) => setStateDialog(() => dialogIsPotongKasbon = val!),
                    ),
                  ),
                  if (dialogIsPotongKasbon) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: dialogKasbonCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [RibuanFormatter()],
                      enabled: !isProcessing,
                      decoration: InputDecoration(
                        labelText: 'Nominal Kasbon',
                        prefixText: 'Rp ',
                        filled: true,
                        fillColor: Colors.amber.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ]
                ],
              ),
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
                    : const Text('SIMPAN & CETAK'),
                onPressed: isProcessing ? null : () async {
                  if (selectedDevice == null) {
                    showCustomSnackbar(context, 'Pilih printer dulu Bos!', isError: true);
                    return;
                  }
                  
                  double kasbonCetak = 0;
                  if (dialogIsPotongKasbon && dialogKasbonCtrl.text.isNotEmpty) {
                    kasbonCetak = double.tryParse(dialogKasbonCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                  }

                  setStateDialog(() => isProcessing = true);

                  // 1. CEK KONEKSI PRINTER
                  bool? isConnected = await bluetooth.isConnected;
                  if (isConnected != true) {
                    try {
                      await bluetooth.connect(selectedDevice!);
                    } catch (e) {
                      setStateDialog(() => isProcessing = false);
                      showCustomSnackbar(context, 'Gagal nyambung ke Printer! Nota Batal Disimpan.', isError: true);
                      return; 
                    }
                  }

                  // 2. TEMBAK API KE DJANGO
                  String formattedDate = "${tglTransfer.year}-${tglTransfer.month.toString().padLeft(2, '0')}-${tglTransfer.day.toString().padLeft(2, '0')}";
                  double finalBayarAkhir = roundDownRibuan(totalSebelumKasbon - kasbonCetak);

                  try { 
                    final response = await http.post(
                      Uri.parse('${AppConfig.baseUrl}/api/nota/buat/'), 
                      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
                      body: json.encode({
                        'pelanggan_id': widget.pelangganId, 
                        'item_ids': selectedItemIds,
                        'pakai_komisi': pakaiKomisi, 
                        'pakai_buruh': pakaiBuruh, 
                        'pakai_materai': pakaiMaterai, 
                        
                        // --- PAYLOAD BARU UNTUK SPLIT PAYMENT ---
                        'metode_bayar': metodeBayar, 
                        'is_split_payment': isSplitPayment,
                        'nominal_bayar_1': nominalBayarPertama,
                        'metode_bayar_2': isSplitPayment ? metodeBayar2 : null,
                        'nominal_bayar_2': isSplitPayment ? sisaSplitTagihan : 0,
                        // ----------------------------------------

                        'tanggal_transfer': formattedDate,
                        'setoran_pinjaman': kasbonCetak.toInt().toString(),
                        'total_bayar_akhir': finalBayarAkhir,
                        // Rekening tujuan TF — cuma dikirim kalau ada porsi TF & bukan "belum ada"
                        'rekening_nomor': ((metodeBayar == 'TF' || (isSplitPayment && metodeBayar2 == 'TF')) && !rekTfBelumAda) ? rekTfNomor : null,
                        'rekening_atas_nama': ((metodeBayar == 'TF' || (isSplitPayment && metodeBayar2 == 'TF')) && !rekTfBelumAda) ? rekTfAtasNama : null,
                      })
                    ); 

                    if (response.statusCode == 200) { 
                      String notaId = "";
                      try {
                        final resBody = json.decode(response.body);
                        notaId = resBody['id_nota']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString().substring(8);
                      } catch(_) {
                        notaId = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
                      }

                      // 3. CETAK PRINTER
                      _cetakSatuLembar(notaId, rataRataHarga, totalSebelumKasbon, kasbonCetak, finalBayarAkhir, "( COPY PETANI )");
                      await Future.delayed(const Duration(seconds: 5));
                      _cetakSatuLembar(notaId, rataRataHarga, totalSebelumKasbon, kasbonCetak, finalBayarAkhir, "( COPY PABRIK )");

                      if(!mounted) return;
                      Navigator.pop(context); 
                      Navigator.pop(context); 
                      showCustomSnackbar(context, 'Sukses! Nota Tersimpan & Tercetak.');
                    } else {
                      String errorMsg = 'Gagal menyimpan ke server.';
                      try {
                        final resBody = json.decode(response.body);
                        if (resBody['pesan'] != null) errorMsg = resBody['pesan']; 
                      } catch (_) {}
                      setStateDialog(() => isProcessing = false);
                      showCustomSnackbar(context, errorMsg, isError: true);
                    }
                  } catch (e) {
                    setStateDialog(() => isProcessing = false);
                    showCustomSnackbar(context, 'Koneksi ke Server Terputus!', isError: true);
                  }
                },
              )
            ],
          );
        }
      ),
    );
  }

  void _cetakSatuLembar(String notaId, double rataHarga, double totalAwal, double kasbon, double bayarAkhir, String labelCopy) {
    DateTime n = DateTime.now();
    String tglStr = "${n.day.toString().padLeft(2,'0')}/${n.month.toString().padLeft(2,'0')}/${n.year} ${n.hour.toString().padLeft(2,'0')}:${n.minute.toString().padLeft(2,'0')}";
    
    String getLabelMetode(String kode) => kode == 'TF' ? 'TRANSFER' : kode == 'BB' ? 'BELUM BAYAR' : 'CASH';

    bluetooth.printNewLine();
    bluetooth.printCustom("PT SINAR BULIAN JAYA", 2, 1);
    bluetooth.printCustom("Pembelian Karet Basah", 0, 1);
    bluetooth.printCustom(labelCopy, 1, 1); 
    bluetooth.printCustom("--------------------------------", 0, 1);
    
    bluetooth.printLeftRight("Nota:", "#$notaId", 0);
    bluetooth.printLeftRight("Tgl:", tglStr, 0);
    bluetooth.printLeftRight("Petani:", widget.nama, 0);

    // --- TELP & REKENING: HANYA DI COPY PABRIK ---
    bool isCopyPabrik = labelCopy.toUpperCase().contains("PABRIK");
    if (isCopyPabrik) {
      if (widget.noTelp.trim().isNotEmpty) {
        bluetooth.printLeftRight("Telp:", widget.noTelp.trim(), 0);
      }
      if (widget.noRekening.trim().isNotEmpty) {
        bluetooth.printLeftRight("Rek:", widget.noRekening.trim(), 0);
      }
    }

    // --- STRUK ADAPTIF: BISA SPLIT ATAU FULL ---
    if (!isSplitPayment) {
      bluetooth.printLeftRight("Metode:", getLabelMetode(metodeBayar), 0); 
    } else {
      bluetooth.printLeftRight("Bayar 1:", "${getLabelMetode(metodeBayar)} (${formatRp(nominalBayarPertama)})", 0); 
      bluetooth.printLeftRight("Bayar 2:", "${getLabelMetode(metodeBayar2)} (${formatRp(sisaSplitTagihan)})", 0); 
    }

    bluetooth.printCustom("--------------------------------", 0, 1);
    
    bluetooth.printLeftRight("Berat:", "${estimasiBeratTotal.toStringAsFixed(1)} Kg", 0);
    bluetooth.printLeftRight("Harga/Kg:", formatRp(rataHarga), 0);
    bluetooth.printCustom("--------------------------------", 0, 1);
    
    bluetooth.printLeftRight("Total Kotor", formatRp(estimasiKotor), 1); 
    
    if (pakaiKomisi) bluetooth.printLeftRight("Pot. Komisi", "- ${formatRp(estimasiKomisi)}", 0);
    if (pakaiBuruh) bluetooth.printLeftRight("Pot. Buruh", "- ${formatRp(estimasiBuruh)}", 0);
    if (pakaiMaterai && estimasiMaterai > 0) bluetooth.printLeftRight("Pot. Materai", "- ${formatRp(estimasiMaterai)}", 0);
    if (kasbon > 0) bluetooth.printLeftRight("Pot. Kasbon", "- ${formatRp(kasbon)}", 0);
    
    bluetooth.printCustom("--------------------------------", 0, 1);
    bluetooth.printLeftRight("TOTAL BERSIH", formatRp(bayarAkhir), 2); 

    bluetooth.printNewLine();
    bluetooth.printCustom("Terima Kasih", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printNewLine();
    bluetooth.printNewLine();
    bluetooth.printNewLine(); 
  }

  Widget _buildToggleSwitch(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                if(subtitle.isNotEmpty) Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.teal.shade600,
            activeTrackColor: Colors.teal.shade100,
            onChanged: onChanged,
          )
        ],
      ),
    );
  }

  // Helper Tombol Dinamis (Bisa buat Metode 1 atau Metode 2)
  Widget _buildPaymentMethodBtn(String id, String label, IconData icon, Color color, bool isMetodeUtama) {
    bool isSelected = isMetodeUtama ? (metodeBayar == id) : (metodeBayar2 == id);
    return Expanded(
      child: InkWell(
        onTap: () async {
          // Kalau pilih TF -> munculin popup pilih rekening dulu.
          if (id == 'TF') {
            final hasil = await pilihRekeningTF(context, widget.pelangganId, widget.nama);
            if (hasil == null) return; // Batal -> jangan ganti metode
            if (!mounted) return;
            setState(() {
              if (isMetodeUtama) {
                metodeBayar = 'TF';
              } else {
                metodeBayar2 = 'TF';
              }
              rekTfBelumAda = hasil.belumAda;
              rekTfNomor = hasil.belumAda ? null : hasil.nomor;
              rekTfAtasNama = hasil.belumAda ? null : hasil.atasNama;
              rekTfSudahPilih = true;
            });
            return;
          }
          setState(() {
            if (isMetodeUtama) {
              metodeBayar = id;
              if (metodeBayar == 'CASH') isSplitPayment = false; // Cash otomatis matiin Split biar gak bingung
            } else {
              metodeBayar2 = id;
            }
            // Kalau sudah gaada porsi TF, reset info rekening
            final adaTf = metodeBayar == 'TF' || (isSplitPayment && metodeBayar2 == 'TF');
            if (!adaTf) {
              rekTfSudahPilih = false;
              rekTfBelumAda = false;
              rekTfNomor = null;
              rekTfAtasNama = null;
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 2),
            boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade500, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isSelected ? Colors.white : Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
  
  @override 
  Widget build(BuildContext context) { 
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.teal.shade900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.teal.shade900.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, -10))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16), 
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                _rowEstimasi('Total Kotor', formatRp(estimasiKotor)),
                if (pakaiKomisi) _rowEstimasi('Komisi (UP)', '- ${formatRp(estimasiKomisi)}', color: Colors.red.shade300),
                if (pakaiBuruh) _rowEstimasi('Buruh (UP)', '- ${formatRp(estimasiBuruh)}', color: Colors.red.shade300),
                if (pakaiMaterai && estimasiMaterai > 0) _rowEstimasi('Materai', '- ${formatRp(estimasiMaterai)}', color: Colors.red.shade300),
                if (isPotongKasbon) _rowEstimasi('Potong Kasbon', '- ${formatRp(setoranController.text.isEmpty ? 0 : double.tryParse(setoranController.text.replaceAll('.', '')) ?? 0)}', color: Colors.red.shade300),
                const Divider(color: Colors.white24, height: 16), 
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL DIBAYAR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white54, letterSpacing: 1.5)), 
                        SizedBox(height: 2),
                        Text('(Pembulatan ke bawah)', style: TextStyle(fontSize: 10, color: Colors.white38)),
                      ],
                    ), 
                    Text(formatRp(estimasiBayarAkhir), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: Colors.amber.shade400, letterSpacing: -1))
                  ]
                ),
                
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(vertical: 18), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0
                    ), 
                    onPressed: (itemsDariGudang.isEmpty || selectedItemIds.isEmpty) ? null : _persiapanCetak, 
                    icon: const Icon(Icons.print_rounded, size: 20),
                    label: const Text('SIMPAN & CETAK NOTA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2))
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Stack(
            children: [
              Positioned(top: -100, right: -50, child: CircleAvatar(radius: 150, backgroundColor: Colors.teal.shade50.withOpacity(0.6))),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 60, left: 16, right: 24, bottom: 20),
                    color: Colors.transparent, 
                    child: Row(
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22), onPressed: () => Navigator.pop(context)),
                        Expanded(child: Text('Kasir: ${widget.nama}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.5), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20), 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DAFTAR TIMBANGAN GUDANG', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black45, fontSize: 11, letterSpacing: 1.2)),
                          const SizedBox(height: 12),
                          if(itemsDariGudang.isEmpty)
                            Container(
                              width: double.infinity, padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                              child: Center(child: Text('Tidak ada timbangan menggantung.', style: TextStyle(color: Colors.grey.shade500))),
                            ),
                          ...itemsDariGudang.map((item) {
                            bool isSelected = selectedItemIds.contains(item['id']);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      selectedItemIds.remove(item['id']);
                                    } else {
                                      selectedItemIds.add(item['id']);
                                    }
                                  });
                                  hitungEstimasi();
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.teal.shade50 : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isSelected ? Colors.teal.shade600 : Colors.grey.shade300, width: isSelected ? 2 : 1),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, color: isSelected ? Colors.teal.shade700 : Colors.grey.shade400, size: 24),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('${item['tonase']} Kg x ${formatRp(item['harga'])}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? Colors.teal.shade900 : Colors.black87)),
                                            const SizedBox(height: 4),
                                            Text('Posisi: ${item['sumber']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                          ],
                                        ),
                                      ),
                                      Text(formatRp((item['tonase'] * item['harga'])), style: TextStyle(fontWeight: FontWeight.w900, color: isSelected ? Colors.teal.shade700 : Colors.black87)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 24), 
                          
                          const Text('POTONGAN TAMBAHAN', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black45, fontSize: 11, letterSpacing: 1.2)),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                            child: Column(
                              children: [
                                _buildToggleSwitch('Potong Komisi', 'Potong 1% dari total kotor', pakaiKomisi, (v) { setState(() => pakaiKomisi = v); hitungEstimasi(); }), 
                                Divider(height: 1, color: Colors.grey.shade200),
                                _buildToggleSwitch('Potong Buruh', 'Rp 35/Kg dari total berat', pakaiBuruh, (v) { setState(() => pakaiBuruh = v); hitungEstimasi(); }), 
                                Divider(height: 1, color: Colors.grey.shade200),
                                _buildToggleSwitch('Potong Materai', 'Klaim biaya Rp 6.000', pakaiMaterai, (v) { setState(() => pakaiMaterai = v); hitungEstimasi(); }),
                              ]
                            ),
                          ),

                          const SizedBox(height: 24), 
                          
                          const Text('POTONGAN KASBON / HUTANG', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black45, fontSize: 11, letterSpacing: 1.2)),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: widget.kasbonAwal > 0 ? Colors.red.shade200 : Colors.grey.shade200)),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Bayar Kasbon (Potong Nota)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), 
                                          const SizedBox(height: 4),
                                          Text('Sisa Hutang: ${formatRp(widget.kasbonAwal)}', style: TextStyle(color: widget.kasbonAwal > 0 ? Colors.red.shade600 : Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 12)), 
                                        ],
                                      ),
                                      Switch(
                                        value: isPotongKasbon, 
                                        activeThumbColor: Colors.red.shade600, activeTrackColor: Colors.red.shade100,
                                        onChanged: widget.kasbonAwal > 0 ? (v) { setState(() => isPotongKasbon = v); hitungEstimasi(); } : null
                                      )
                                    ],
                                  ),
                                ),
                                if (isPotongKasbon) 
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), 
                                    child: TextField(
                                      controller: setoranController, inputFormatters: [RibuanFormatter()], keyboardType: TextInputType.number,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 18),
                                      decoration: InputDecoration(
                                        labelText: 'Nominal Potongan Kasbon', labelStyle: TextStyle(color: Colors.red.shade400, fontSize: 13),
                                        prefixText: 'Rp ', prefixStyle: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                                        filled: true, fillColor: Colors.red.shade50,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                      ),
                                    )
                                  ),
                              ]
                            ),
                          ),

                          const SizedBox(height: 24), 
                          
                          const Text('METODE PEMBAYARAN', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black45, fontSize: 11, letterSpacing: 1.2)), 
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildPaymentMethodBtn('CASH', 'CASH', Icons.payments_rounded, Colors.teal.shade600, true),
                              _buildPaymentMethodBtn('TF', 'TRANSFER', Icons.account_balance_rounded, Colors.blue.shade600, true),
                              _buildPaymentMethodBtn('BB', 'BELUM BAYAR', Icons.warning_rounded, Colors.red.shade600, true),
                            ]
                          ),

                          // --- INFO REKENING TUJUAN TF ---
                          if ((metodeBayar == 'TF' || (isSplitPayment && metodeBayar2 == 'TF')) && rekTfSudahPilih) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: rekTfBelumAda ? Colors.orange.shade50 : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: rekTfBelumAda ? Colors.orange.shade200 : Colors.blue.shade200),
                              ),
                              child: Row(children: [
                                Icon(rekTfBelumAda ? Icons.help_outline_rounded : Icons.account_balance_rounded, size: 16, color: rekTfBelumAda ? Colors.orange.shade800 : Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    rekTfBelumAda
                                      ? 'Transfer ke: rekening belum ada'
                                      : 'Transfer ke: ${(rekTfAtasNama ?? '').trim().isEmpty ? '' : '${rekTfAtasNama!.trim()} • '}${rekTfNomor ?? ''}',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: rekTfBelumAda ? Colors.orange.shade900 : Colors.blue.shade900),
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    final hasil = await pilihRekeningTF(context, widget.pelangganId, widget.nama);
                                    if (hasil == null || !mounted) return;
                                    setState(() {
                                      rekTfBelumAda = hasil.belumAda;
                                      rekTfNomor = hasil.belumAda ? null : hasil.nomor;
                                      rekTfAtasNama = hasil.belumAda ? null : hasil.atasNama;
                                      rekTfSudahPilih = true;
                                    });
                                  },
                                  child: Text('Ubah', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.blue.shade700)),
                                ),
                              ]),
                            ),
                          ],

                          // --- KOTAK SPLIT PAYMENT ---
                          if (metodeBayar == 'TF' || metodeBayar == 'BB') ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.shade100)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildToggleSwitch('Bukan Full Payment?', 'Bayar sebagian dengan metode lain', isSplitPayment, (v) {
                                    setState(() {
                                      isSplitPayment = v;
                                      if (!v) nominalSplitCtrl.clear();
                                    });
                                  }),
                                  if (isSplitPayment) ...[
                                    const Divider(color: Colors.white),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: nominalSplitCtrl,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [RibuanFormatter()],
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 16),
                                      decoration: InputDecoration(
                                        labelText: 'Dibayar via $metodeBayar',
                                        prefixText: 'Rp ',
                                        filled: true, fillColor: Colors.white,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade200)),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text('Sisa Tagihan (${formatRp(sisaSplitTagihan)}) pakai metode apa?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue.shade900)),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        if (metodeBayar != 'CASH') _buildPaymentMethodBtn('CASH', 'CASH', Icons.payments_rounded, Colors.teal.shade600, false),
                                        if (metodeBayar != 'TF') _buildPaymentMethodBtn('TF', 'TRANSFER', Icons.account_balance_rounded, Colors.blue.shade600, false),
                                        if (metodeBayar != 'BB') _buildPaymentMethodBtn('BB', 'BELUM BAYAR', Icons.warning_rounded, Colors.red.shade600, false),
                                      ]
                                    ),
                                  ]
                                ]
                              )
                            )
                          ]
                        ]
                      )
                    ),
                  ),
                ],
              ),
            ],
          )
    ); 
  }

  Widget _rowEstimasi(String label, String value, {Color color = Colors.white70}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)), 
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))
        ],
      ),
    );
  }
}