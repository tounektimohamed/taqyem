// data_compressor.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:http/http.dart' as http;

class DataCompressor {
  // دالة لضغط البيانات وتحويلها إلى MessagePack
  static Map<String, dynamic> compressReportData({
    required String profName,
    required String matiereName,
    required String className,
    required String schoolName,
    required List<dynamic> baremes,
    required List<dynamic> students,
    required Map<String, int> sumCriteriaMaxPerBareme,
    required int totalStudents,
    required bool isFrenchInterface,
    required String trimestre,
    required String periode,
    required String evaluationType,
    required String selectedClass,
    required List<Map<String, dynamic>> criteria,
    String performanceAttendue = '',
  }) {
    try {
      // 1. تحضير البيانات الأساسية
      final Map<String, dynamic> baseData = {
        'type': 'complete_report',
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      // 2. البيانات الوصفية (مضغوطة)
      final Map<String, dynamic> metadata = {
        'prof_name': profName,
        'matiere_name': matiereName,
        'class_name': className,
        'school_name': schoolName,
        'total_students': totalStudents,
        'is_french': isFrenchInterface,
        'trimestre': trimestre,
        'periode': periode,
        'evaluation_type': evaluationType,
        'selected_class': selectedClass,
        'performance_attendue': performanceAttendue,
      };

      // 3. المعايير (مضغوطة)
      final List<Map<String, dynamic>> compressedCriteria = criteria.map((criterion) {
        return {
          'id': criterion['id'] ?? 0,
          'n': criterion['name'] ?? '', // n = name (مختصر)
          'on': criterion['originalName'] ?? '', // on = originalName
          'd': criterion['domaine'] ?? '', // d = domaine
          'i': (criterion['indicators'] as List<dynamic>?)?.map((i) => i.toString()).toList() ?? [], // i = indicators
          'c': criterion['indicators_count'] ?? 0, // c = count
          'sn': criterion['displayNumber'] ?? 0, // sn = sortNumber
        };
      }).toList();

      // 4. الطلاب (مضغوطة بشدة)
      final List<Map<String, dynamic>> compressedStudents = students.map((student) {
        final baremesMap = student['baremes'] as Map<String, dynamic>? ?? {};
        
        // تحويل العلامات إلى رموز مختصرة
        final Map<String, String> compressedMarks = {};
        baremesMap.forEach((key, value) {
          // تحويل العلامات إلى رموز مختصرة
          String compressedValue;
          if (value == '( + + + )') compressedValue = 'A';
          else if (value == '( + + - )') compressedValue = 'B';
          else if (value == '( + - - )') compressedValue = 'C';
          else if (value == '( - - - )') compressedValue = 'D';
          else if (value == 'غائب') compressedValue = 'X';
          else compressedValue = value.toString();
          
          compressedMarks[key] = compressedValue;
        });

        return {
          'id': student['id'] ?? '',
          'n': student['name'] ?? '', // n = name
          'b': compressedMarks, // b = baremes
        };
      }).toList();

      // 5. المعايير (مضغوطة)
      final List<Map<String, dynamic>> compressedBaremes = baremes.map((bareme) {
        return {
          'id': bareme['id'] ?? '',
          'v': bareme['value'] ?? '', // v = value
          'ov': bareme['originalValue'] ?? '', // ov = originalValue
          't': bareme['type'] ?? 'bareme', // t = type
          'pid': bareme['parentBaremeId'], // pid = parentBaremeId
        };
      }).toList();

      // 6. الإحصائيات (مضغوطة)
      final Map<String, int> compressedStats = {};
      sumCriteriaMaxPerBareme.forEach((key, value) {
        compressedStats[key] = value;
      });

      // 7. تجميع كل البيانات
      final Map<String, dynamic> fullData = {
        ...baseData,
        'meta': metadata,
        'criteria': compressedCriteria,
        'students': compressedStudents,
        'baremes': compressedBaremes,
        'stats': compressedStats,
      };

      print('✅ البيانات المضغوطة جاهزة:');
      print('   - الطلاب: ${compressedStudents.length}');
      print('   - المعايير: ${compressedCriteria.length}');
      print('   - المعايير الفرعية: ${compressedBaremes.length}');
      print('   - حجم JSON التقريبي: ${jsonEncode(fullData).length} bytes');

      return fullData;
    } catch (e) {
      print('❌ خطأ في ضغط البيانات: $e');
      return {};
    }
  }

  // دالة لتحويل البيانات إلى MessagePack
  static Uint8List convertToMessagePack(Map<String, dynamic> data) {
    try {
      final packed = serialize(data);
      print('✅ MessagePack مضغوط: ${packed.length} bytes');
      
      final jsonSize = jsonEncode(data).length;
      if (jsonSize > 0) {
        final compressionRatio = (1 - (packed.length / jsonSize)) * 100;
        print('   نسبة الضغط: ${compressionRatio.toStringAsFixed(2)}%');
      }
      
      return Uint8List.fromList(packed);
    } catch (e) {
      print('❌ خطأ في تحويل MessagePack: $e');
      throw e;
    }
  }

  // دالة لإرسال البيانات إلى Flask API باستخدام http package
  static Future<Map<String, dynamic>> sendToFlaskAPI({
    required Uint8List messagePackData,
    required String flaskUrl,
  }) async {
    try {
      print('📤 جاري إرسال ${messagePackData.length} bytes إلى $flaskUrl');
      
      final response = await http.post(
        Uri.parse(flaskUrl),
        headers: {
          'Content-Type': 'application/msgpack',
          'Accept': 'application/json',
          'X-Data-Type': 'complete_report',
        },
        body: messagePackData,
      );

      if (response.statusCode == 200) {
        print('✅ تم استلام رد من الخادم (${response.body.length} bytes)');
        return jsonDecode(response.body);
      } else {
        throw Exception('فشل الطلب مع حالة: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في إرسال البيانات إلى Flask: $e');
      rethrow;
    }
  }

  // دالة شاملة لمعالجة وإرسال البيانات
  static Future<void> processAndSendReport({
    required String profName,
    required String matiereName,
    required String className,
    required String schoolName,
    required List<dynamic> baremes,
    required List<dynamic> students,
    required Map<String, int> sumCriteriaMaxPerBareme,
    required int totalStudents,
    required bool isFrenchInterface,
    required String trimestre,
    required String periode,
    required String evaluationType,
    required String selectedClass,
    required List<Map<String, dynamic>> criteria,
    String performanceAttendue = '',
    String flaskUrl = 'http://localhost:5000/api/generate-exact-report',
  }) async {
    try {
      print('🚀 بدء عملية ضغط وإرسال البيانات...');

      // 1. ضغط البيانات
      final compressedData = compressReportData(
        profName: profName,
        matiereName: matiereName,
        className: className,
        schoolName: schoolName,
        baremes: baremes,
        students: students,
        sumCriteriaMaxPerBareme: sumCriteriaMaxPerBareme,
        totalStudents: totalStudents,
        isFrenchInterface: isFrenchInterface,
        trimestre: trimestre,
        periode: periode,
        evaluationType: evaluationType,
        selectedClass: selectedClass,
        criteria: criteria,
        performanceAttendue: performanceAttendue,
      );

      if (compressedData.isEmpty) {
        throw Exception('فشل في ضغط البيانات');
      }

      // 2. تحويل إلى MessagePack
      final messagePackData = convertToMessagePack(compressedData);

      // 3. إرسال إلى Flask API
      final response = await sendToFlaskAPI(
        messagePackData: messagePackData,
        flaskUrl: flaskUrl,
      );

      print('✅ تم إرسال البيانات بنجاح!');
      print('📊 استجابة الخادم: $response');

      // 4. معالجة الاستجابة
      if (response['success'] == true) {
        print('🎉 التقرير تم إنشاؤه بنجاح');
        
        // يمكنك إضافة منطق لتنزيل أو عرض التقرير هنا
        // مثل: _showReportDownload(response['html_content']);
      } else {
        print('⚠️ الخادم أبلغ عن خطأ: ${response['error']}');
      }

    } catch (e) {
      print('❌ خطأ في العملية: $e');
      rethrow;
    }
  }

  // دالة بديلة تستخدم JSON بدلاً من MessagePack (للتوافق)
  static Future<void> processAndSendReportJson({
    required String profName,
    required String matiereName,
    required String className,
    required String schoolName,
    required List<dynamic> baremes,
    required List<dynamic> students,
    required Map<String, int> sumCriteriaMaxPerBareme,
    required int totalStudents,
    required bool isFrenchInterface,
    required String trimestre,
    required String periode,
    required String evaluationType,
    required String selectedClass,
    required List<Map<String, dynamic>> criteria,
    String performanceAttendue = '',
    String flaskUrl = 'http://localhost:5000/api/generate-exact-report',
  }) async {
    try {
      print('🚀 بدء عملية إرسال البيانات (JSON)...');

      // إعداد البيانات الكاملة
      final fullData = {
        'profName': profName,
        'matiereName': matiereName,
        'className': className,
        'schoolName': schoolName,
        'baremes': baremes,
        'students': students,
        'sumCriteriaMaxPerBareme': sumCriteriaMaxPerBareme,
        'totalStudents': totalStudents,
        'isFrenchInterface': isFrenchInterface,
        'trimestre': trimestre,
        'periode': periode,
        'evaluationType': evaluationType,
        'selectedClass': selectedClass,
        'criteria': criteria,
        'performanceAttendue': performanceAttendue,
      };

      print('📤 جاري إرسال JSON (${jsonEncode(fullData).length} bytes)...');

      final response = await http.post(
        Uri.parse(flaskUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(fullData),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('✅ تم إرسال البيانات بنجاح!');
        print('📊 استجابة الخادم: $result');
      } else {
        throw Exception('فشل الطلب: ${response.statusCode}');
      }

    } catch (e) {
      print('❌ خطأ في إرسال JSON: $e');
      rethrow;
    }
  }
}