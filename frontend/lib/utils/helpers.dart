import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String formatRp(dynamic number) {
  double value = double.tryParse(number.toString()) ?? 0;
  bool isNegative = value < 0;
  String str = value.abs().toInt().toString();
  String result = '';
  int count = 0;
  for (int i = str.length - 1; i >= 0; i--) {
    if (count != 0 && count % 3 == 0) result = '.$result';
    result = str[i] + result;
    count++;
  }
  return isNegative ? '- Rp $result' : 'Rp $result';
}

// Bulatkan keatas ke kelipatan 1.000 dan return double (bukan string).
// Buat hitung total: tiap item dibulatin dulu baru di-jumlah, biar konsisten sama display.
double ceilRibu(dynamic number) {
  double value = double.tryParse(number.toString()) ?? 0;
  if (value == 0) return 0;
  return (value.abs() / 1000).ceil() * 1000.0 * (value < 0 ? -1 : 1);
}

// Format Rp dengan round UP ke kelipatan 1.000. Contoh: 1100 -> "Rp 2.000", 999 -> "Rp 1.000"
String formatRpUp(dynamic number) {
  double value = double.tryParse(number.toString()) ?? 0;
  bool isNegative = value < 0;
  double rounded = (value.abs() / 1000).ceil() * 1000.0;
  String str = rounded.toInt().toString();
  String result = '';
  int count = 0;
  for (int i = str.length - 1; i >= 0; i--) {
    if (count != 0 && count % 3 == 0) result = '.$result';
    result = str[i] + result;
    count++;
  }
  return isNegative ? '- Rp $result' : 'Rp $result';
}

// Format angka biasa dengan pemisah ribuan (titik), tanpa "Rp". Contoh: 1000 -> 1.000
String formatRibuan(dynamic number) {
  double value = double.tryParse(number.toString()) ?? 0;
  bool isNegative = value < 0;
  String str = value.abs().toInt().toString();
  String result = '';
  int count = 0;
  for (int i = str.length - 1; i >= 0; i--) {
    if (count != 0 && count % 3 == 0) result = '.$result';
    result = str[i] + result;
    count++;
  }
  return isNegative ? '-$result' : result;
}

// Format tonase/Kg: pemisah ribuan (titik) + desimal pakai koma HANYA kalau ada.
// Contoh: 1000.0 -> "1.000", 1234.5 -> "1.234,5", 12500.25 -> "12.500,25"
String formatTonase(dynamic number) {
  double value = double.tryParse(number.toString()) ?? 0;
  bool isNegative = value < 0;
  double absVal = value.abs();
  double rounded = (absVal * 100).roundToDouble() / 100;
  int intPart = rounded.floor();
  int fracInt = ((rounded - intPart) * 100).round(); // 0..99
  String result = formatRibuan(intPart);
  if (fracInt > 0) {
    String f = fracInt.toString().padLeft(2, '0').replaceAll(RegExp(r'0+$'), '');
    result = '$result,$f';
  }
  return isNegative ? '-$result' : result;
}

void showCustomSnackbar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14))),
        ],
      ),
      backgroundColor: isError ? Colors.red.shade700 : Colors.teal.shade800,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(24),
      elevation: 6,
      duration: const Duration(seconds: 3),
    ),
  );
}

class RibuanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    String angka = newValue.text.replaceAll(RegExp(r'[^0-9]'), ''); 
    if (angka.isEmpty) return newValue.copyWith(text: '');
    String hasil = '';
    int count = 0;
    for (int i = angka.length - 1; i >= 0; i--) {
      if (count != 0 && count % 3 == 0) hasil = '.$hasil';
      hasil = angka[i] + hasil;
      count++;
    }
    return TextEditingValue(text: hasil, selection: TextSelection.collapsed(offset: hasil.length));
  }
}

InputDecoration customInputStyle(String label, {String prefix = '', IconData? icon}) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.grey.shade600),
    prefixText: prefix,
    prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
    prefixIcon: icon != null ? Icon(icon, color: Colors.teal.shade600) : null,
    filled: true,
    fillColor: Colors.white,
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.teal.shade800, width: 2)),
  );
}