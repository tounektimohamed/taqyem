import 'dart:convert';
import 'package:flutter/services.dart';

class CriteriaJsonService {
  static List<dynamic>? _data;

  static Future<void> load() async {
    if (_data != null) return;
    final jsonString =
        await rootBundle.loadString('assets/evaluation_excel.json');
    _data = json.decode(jsonString)['بيانات_مفصلة'];
  }

  /// استخراج اقتراحات أسماء حسب (المعيار + المادة + الصف)
 static List<String> getSuggestions({
  required String criterId, // "مع 1"
  required String matiere,  // "التواصل الشفوي"
  required String niveau,   // "السنة الأولى ابتدائي"
}) {
  if (_data == null) return [];

  final cId = criterId.trim();
  final mat = matiere.trim();
  final niv = niveau.trim();

  return _data!
      .where((e) =>
          e['المعيار']?.toString().trim() == cId &&
          e['المادة']?.toString().trim() == mat &&
          e['الصف']?.toString().trim() == niv)
      .map<String>((e) => e['المحور'].toString().trim())
      .toSet() // إزالة التكرار
      .toList()
    ..sort(); // ترتيب أبجدي (اختياري)
}

}
