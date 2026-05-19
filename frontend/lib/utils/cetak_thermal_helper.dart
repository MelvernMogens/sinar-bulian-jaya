import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';

class CetakThermalHelper {
  static BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  static void tampilkanDialogCetak(
    BuildContext context, {
    required String noNota,
    required String namaPelanggan,
    required String berat,
    required String harga,
    required double totalAwal, 
  }) {
    List<BluetoothDevice> devices = [];
    BluetoothDevice? selectedDevice;
    bool isAdaKasbon = false;
    TextEditingController kasbonCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          
          void getDevices() async {
            devices = await bluetooth.getBondedDevices();
            try {
              selectedDevice = devices.firstWhere((d) => d.name!.contains('RPP02N'));
            } catch (e) {
              if (devices.isNotEmpty) selectedDevice = devices[0];
            }
            setStateDialog(() {});
          }

          if (devices.isEmpty) getDevices();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.print_rounded, color: Colors.teal),
                SizedBox(width: 8),
                Text('Cetak Nota 58mm', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
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
                        onChanged: (val) => setStateDialog(() => selectedDevice = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                    child: CheckboxListTile(
                      title: const Text('Ada Potongan Kasbon?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      value: isAdaKasbon,
                      activeColor: Colors.teal,
                      onChanged: (val) => setStateDialog(() => isAdaKasbon = val!),
                    ),
                  ),
                  if (isAdaKasbon) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: kasbonCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Nominal Kasbon (Rp)',
                        filled: true,
                        fillColor: Colors.amber.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.money_off_rounded),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Batal', style: TextStyle(color: Colors.grey))
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                icon: const Icon(Icons.print, size: 18),
                label: const Text('CETAK SEKARANG'),
                onPressed: () async {
                  if (selectedDevice == null) return;
                  
                  double kasbon = 0;
                  if (isAdaKasbon && kasbonCtrl.text.isNotEmpty) {
                    kasbon = double.tryParse(kasbonCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                  }

                  Navigator.pop(context); // Tutup pop-up
                  _prosesCetak(selectedDevice!, noNota, namaPelanggan, berat, harga, totalAwal, kasbon);
                },
              )
            ],
          );
        }
      ),
    );
  }

  static void _prosesCetak(BluetoothDevice device, String noNota, String namaPelanggan, String berat, String harga, double totalAwal, double kasbon) async {
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected != true) {
      await bluetooth.connect(device);
    }

    final formatRp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    double totalBersih = totalAwal - kasbon;

    bluetooth.printNewLine();
    bluetooth.printCustom("PT SINAR BULIAN JAYA", 2, 1); 
    bluetooth.printCustom("Pembelian Karet Basah", 0, 1);
    bluetooth.printCustom("--------------------------------", 0, 1);
    
    bluetooth.printLeftRight("No Nota:", "#$noNota", 0);
    bluetooth.printLeftRight("Tgl:", DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()), 0);
    bluetooth.printLeftRight("Petani:", namaPelanggan, 0);
    bluetooth.printCustom("--------------------------------", 0, 1);
    
    bluetooth.printLeftRight("Berat", "$berat Kg", 0);
    bluetooth.printLeftRight("Harga/Kg", harga, 0);
    bluetooth.printCustom("--------------------------------", 0, 1);
    
    bluetooth.printLeftRight("Subtotal", formatRp.format(totalAwal), 1); // Size 1 (Agak tebal)
    
    if (kasbon > 0) {
      bluetooth.printLeftRight("Pot. Kasbon", "- ${formatRp.format(kasbon)}", 0);
      bluetooth.printCustom("--------------------------------", 0, 1);
      bluetooth.printLeftRight("TOTAL BERSIH", formatRp.format(totalBersih), 2); // Size 2 (Paling Gede)
    } else {
      bluetooth.printCustom("--------------------------------", 0, 1);
      bluetooth.printLeftRight("TOTAL", formatRp.format(totalAwal), 2);
    }

    bluetooth.printNewLine();
    bluetooth.printCustom("Terima Kasih", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printNewLine();
    bluetooth.printNewLine(); 
  }
}