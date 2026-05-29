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
          if (rekening.length == 1) selectedIdx = 0; // auto-select kalau cuma 1
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

  // Input bergaya app (kotak abu-abu rounded) — biar serasi sama dialog lain
  Widget _input({required TextEditingController controller, required String hint, TextInputType type = TextInputType.text, TextCapitalization cap = TextCapitalization.none, IconData? icon}) {
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

  @override
  Widget build(BuildContext context) {
    final Color teal = Colors.teal.shade700;
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 6),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rekening Transfer', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(widget.namaPetani, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: isLoading
            ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (rekening.isEmpty && !showFormTambah)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Belum ada rekening tersimpan.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5, fontStyle: FontStyle.italic)),
                      ),
                    // List rekening
                    ...rekening.asMap().entries.map((e) {
                      final i = e.key;
                      final r = e.value as Map;
                      final bool sel = selectedIdx == i;
                      return InkWell(
                        onTap: () => setState(() => selectedIdx = i),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: sel ? teal.withOpacity(0.08) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: sel ? teal : Colors.grey.shade200, width: sel ? 1.5 : 1),
                          ),
                          child: Row(children: [
                            Icon(sel ? Icons.check_circle_rounded : Icons.circle_outlined, size: 20, color: sel ? teal : Colors.grey.shade400),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_labelRek(r), style: TextStyle(fontSize: 13.5, fontWeight: sel ? FontWeight.w900 : FontWeight.w600, color: Colors.black87))),
                          ]),
                        ),
                      );
                    }),
                    // Opsi: rekening belum ada
                    InkWell(
                      onTap: () => setState(() => selectedIdx = -2),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedIdx == -2 ? Colors.orange.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: selectedIdx == -2 ? Colors.orange.shade400 : Colors.grey.shade200, width: selectedIdx == -2 ? 1.5 : 1),
                        ),
                        child: Row(children: [
                          Icon(selectedIdx == -2 ? Icons.check_circle_rounded : Icons.circle_outlined, size: 20, color: selectedIdx == -2 ? Colors.orange.shade700 : Colors.grey.shade400),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Rekening belum ada', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: selectedIdx == -2 ? Colors.orange.shade900 : Colors.black54))),
                        ]),
                      ),
                    ),
                    // Form tambah rekening (toggle)
                    if (showFormTambah) ...[
                      const SizedBox(height: 12),
                      Divider(height: 1, color: Colors.grey.shade200),
                      const SizedBox(height: 12),
                      _input(controller: nomorCtrl, hint: 'Nomor Rekening', type: TextInputType.number, icon: Icons.tag_rounded),
                      _input(controller: atasNamaCtrl, hint: 'Atas Nama (opsional)', cap: TextCapitalization.words, icon: Icons.person_rounded),
                      Row(children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isSaving ? null : () => setState(() { showFormTambah = false; nomorCtrl.clear(); atasNamaCtrl.clear(); }),
                            child: Text('Tutup', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving ? null : simpanRekeningBaru,
                            style: ElevatedButton.styleFrom(backgroundColor: teal, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: isSaving
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ]),
                    ] else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() => showFormTambah = true),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                          label: const Text('Tambah Rekening Baru', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(foregroundColor: teal),
                        ),
                      ),
                  ],
                ),
              ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text('Batal', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
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
          style: ElevatedButton.styleFrom(backgroundColor: teal, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Pilih', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
