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