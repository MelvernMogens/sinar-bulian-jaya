import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../utils/helpers.dart';

// Hasil pilihan rekening dari popup TF.
//  - null               => user batal (cancel)
//  - belumAda == true   => "rekening belum ada"
//  - selainnya          => rekening terpilih (nomor + atasNama)
class RekeningPilihan {
  final bool belumAda;
  final String nomor;
  final String atasNama;
  const RekeningPilihan({this.belumAda = false, this.nomor = '', this.atasNama = ''});
}

/// Popup pilih rekening tujuan untuk pembayaran TRANSFER.
/// Return null kalau user pencet Batal.
Future<RekeningPilihan?> pilihRekeningTF(BuildContext context, String pelangganId, String namaPetani) {
  return showDialog<RekeningPilihan>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RekeningPickerDialog(pelangganId: pelangganId, namaPetani: namaPetani),
  );
}

class _RekeningPickerDialog extends StatefulWidget {
  final String pelangganId;
  final String namaPetani;
  const _RekeningPickerDialog({required this.pelangganId, required this.namaPetani});
  @override
  State<_RekeningPickerDialog> createState() => _RekeningPickerDialogState();
}

class _RekeningPickerDialogState extends State<_RekeningPickerDialog> {
  List rekening = [];
  bool isLoading = true;
  bool isSaving = false;

  // -1 = belum pilih, -2 = "rekening belum ada", >=0 = index rekening
  int selectedIdx = -1;

  bool showFormTambah = false;
  final nomorCtrl = TextEditingController();
  final atasNamaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRekening();
  }

  @override
  void dispose() {
    nomorCtrl.dispose();
    atasNamaCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchRekening() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/api/rekening/${widget.pelangganId}/?_t=${DateTime.now().millisecondsSinceEpoch}'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          rekening = data['rekening'] ?? [];
          // auto-select kalau cuma 1 rekening
          if (rekening.length == 1) selectedIdx = 0;
        });
      }
    } catch (_) {
      if (mounted) showCustomSnackbar(context, 'Gagal memuat rekening!', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> simpanRekeningBaru() async {
    final nomor = nomorCtrl.text.trim();
    final atasNama = atasNamaCtrl.text.trim();
    if (nomor.isEmpty) {
      showCustomSnackbar(context, 'Nomor rekening wajib diisi!', isError: true);
      return;
    }
    setState(() => isSaving = true);
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/rekening/tambah/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'pelanggan_id': widget.pelangganId, 'nomor': nomor, 'atas_nama': atasNama}),
      );
      final data = json.decode(res.body);
      if (res.statusCode == 200 && data['status'] == 'sukses') {
        nomorCtrl.clear();
        atasNamaCtrl.clear();
        showFormTambah = false;
        await fetchRekening();
        // auto-select rekening yang baru ditambah
        final newIdx = rekening.indexWhere((r) => r['id'] == data['id']);
        setState(() => selectedIdx = newIdx >= 0 ? newIdx : selectedIdx);
      } else {
        if (mounted) showCustomSnackbar(context, data['pesan'] ?? 'Gagal menambah rekening.', isError: true);
      }
    } catch (_) {
      if (mounted) showCustomSnackbar(context, 'Gagal menyimpan rekening!', isError: true);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  String _labelRek(Map r) {
    final nama = (r['atas_nama'] ?? '').toString().trim();
    final nomor = (r['nomor'] ?? '').toString().trim();
    return nama.isEmpty ? nomor : '$nama  •  $nomor';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.account_balance_rounded, color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Rekening Transfer', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Text(widget.namaPetani, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: isLoading
            ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (rekening.isEmpty && !showFormTambah)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text('Belum ada rekening tersimpan.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic)),
                      ),
                    // List rekening
                    ...rekening.asMap().entries.map((e) {
                      final i = e.key;
                      final r = e.value as Map;
                      final bool sel = selectedIdx == i;
                      return InkWell(
                        onTap: () => setState(() => selectedIdx = i),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? Colors.blue.shade50 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: sel ? Colors.blue.shade400 : Colors.grey.shade300, width: sel ? 1.5 : 1),
                          ),
                          child: Row(children: [
                            Icon(sel ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, size: 18, color: sel ? Colors.blue.shade700 : Colors.grey.shade400),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_labelRek(r), style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w800 : FontWeight.w600, color: Colors.black87))),
                          ]),
                        ),
                      );
                    }),
                    // Opsi: rekening belum ada
                    InkWell(
                      onTap: () => setState(() => selectedIdx = -2),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedIdx == -2 ? Colors.orange.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selectedIdx == -2 ? Colors.orange.shade400 : Colors.grey.shade300, width: selectedIdx == -2 ? 1.5 : 1),
                        ),
                        child: Row(children: [
                          Icon(selectedIdx == -2 ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, size: 18, color: selectedIdx == -2 ? Colors.orange.shade700 : Colors.grey.shade400),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Rekening belum ada', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.orange.shade900))),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Form tambah rekening (toggle)
                    if (showFormTambah) ...[
                      const Divider(height: 18),
                      TextField(
                        controller: nomorCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Nomor Rekening',
                          prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: atasNamaCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Atas Nama (opsional)',
                          prefixIcon: const Icon(Icons.person_rounded, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isSaving ? null : () => setState(() { showFormTambah = false; nomorCtrl.clear(); atasNamaCtrl.clear(); }),
                            child: const Text('Tutup'),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving ? null : simpanRekeningBaru,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, elevation: 0),
                            child: isSaving
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Simpan'),
                          ),
                        ),
                      ]),
                    ] else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() => showFormTambah = true),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                          label: const Text('Tambah Rekening Baru'),
                          style: TextButton.styleFrom(foregroundColor: Colors.blue.shade700),
                        ),
                      ),
                  ],
                ),
              ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (selectedIdx == -2) {
              Navigator.pop(context, const RekeningPilihan(belumAda: true));
            } else if (selectedIdx >= 0 && selectedIdx < rekening.length) {
              final r = rekening[selectedIdx] as Map;
              Navigator.pop(context, RekeningPilihan(
                nomor: (r['nomor'] ?? '').toString(),
                atasNama: (r['atas_nama'] ?? '').toString(),
              ));
            } else {
              showCustomSnackbar(context, 'Pilih rekening dulu atau "Rekening belum ada".', isError: true);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Pilih', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
