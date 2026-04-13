import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/student_ocr_models.dart';

class StudentOcrException implements Exception {
  final String code;
  final String? detail;

  StudentOcrException(this.code, [this.detail]);

  String get arabicMessage {
    switch (code) {
      case 'image_too_large':
        return 'حجم الصورة كبير جداً (الحد 5MB)';
      case 'rate_limit':
        return 'تجاوزت الحد المسموح، انتظر دقيقة';
      case 'no_circles_detected':
        return 'لم تُعثر على دوائر في الصورة';
      case 'missing_table_structure':
        return 'يجب استيراد جدول المعايير أولاً';
      case 'unauthorized':
        return 'انتهت الجلسة، سجل الدخول مجدداً';
      default:
        return 'حدث خطأ غير متوقع';
    }
  }
}

class StudentOcrService {
  static const String _endpoint =
      'https://mohamedtsou-ocr.hf.space/ocr-student-evaluation';
  static const int _timeoutSeconds = 45;

  static Future<Map<String, dynamic>> loadTableStructure({
    required String uid,
    required String classId,
    required String matiereId,
  }) async {
    final tableDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('grading_tables')
        .doc('$classId-$matiereId')
        .get();

    if (tableDoc.exists && tableDoc.data() != null) {
      final data = tableDoc.data()!;
      if ((data['baremes'] as List?)?.isNotEmpty ?? false) {
        final baremes = (data['baremes'] as List).map((b) {
          final scores = b['scores'] as Map<String, dynamic>? ?? {};
          return {
            'appBaremeId': b['appBaremeId'] ?? b['id'] ?? '',
            'appBaremeName': b['appBaremeName'] ?? b['name'] ?? '',
            'name': b['name'] ?? b['appBaremeName'] ?? '',
            'scores': {
              '---': (scores['---'] is num)
                  ? (scores['---'] as num).toDouble()
                  : 0.0,
              '+--': (scores['+--'] is num)
                  ? (scores['+--'] as num).toDouble()
                  : 0.0,
              '++-': (scores['++-'] is num)
                  ? (scores['++-'] as num).toDouble()
                  : 0.0,
              '+++': (scores['+++'] is num)
                  ? (scores['+++'] as num).toDouble()
                  : 0.0,
            },
          };
        }).toList();
        return {'baremes': baremes};
      }
    }

    final baremesSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('baremes')
        .doc('$classId-$matiereId')
        .collection('items')
        .orderBy('order')
        .get();

    if (baremesSnap.docs.isNotEmpty) {
      final baremes = baremesSnap.docs.map((doc) {
        final data = doc.data();
        final customNotes = data['customNotes'] as List? ?? [];
        return {
          'appBaremeId': doc.id,
          'appBaremeName': data['name'] ?? '',
          'name': data['ocrSourceName'] ?? data['name'] ?? '',
          'scores': {
            '---': double.tryParse(
                    customNotes.isNotEmpty ? customNotes[0].toString() : '0') ??
                0,
            '+--': double.tryParse(
                    customNotes.length > 1 ? customNotes[1].toString() : '0') ??
                0,
            '++-': double.tryParse(
                    customNotes.length > 2 ? customNotes[2].toString() : '0') ??
                0,
            '+++': double.tryParse(
                    customNotes.length > 3 ? customNotes[3].toString() : '0') ??
                0,
          }
        };
      }).toList();
      return {'baremes': baremes};
    }

    final selectionsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('selections')
        .doc(classId)
        .collection(matiereId)
        .get();

    if (selectionsSnap.docs.isNotEmpty) {
      final baremes = selectionsSnap.docs.asMap().entries.map((entry) {
        final doc = entry.value;
        final idx = entry.key;
        final data = doc.data();
        final customNotes = data['customNotes'] as List? ?? [];
        final name =
            data['baremeName'] as String? ?? data['name'] as String? ?? '';

        double s0 = double.tryParse(
                customNotes.isNotEmpty ? customNotes[0].toString() : '0') ??
            0;
        double s1 = double.tryParse(
                customNotes.length > 1 ? customNotes[1].toString() : '0') ??
            0;
        double s2 = double.tryParse(
                customNotes.length > 2 ? customNotes[2].toString() : '0') ??
            0;
        double s3 = double.tryParse(
                customNotes.length > 3 ? customNotes[3].toString() : '0') ??
            0;

        if (s0 == 0 && s1 == 0 && s2 == 0 && s3 == 0) {
          s0 = 0;
          s1 = 1;
          s2 = 2;
          s3 = 3;
        }

        return {
          'appBaremeId': doc.id,
          'appBaremeName': name.isEmpty ? 'مع ${idx + 1}' : name,
          'name': name.isEmpty ? 'مع ${idx + 1}' : name,
          'scores': {'---': s0, '+--': s1, '++-': s2, '+++': s3}
        };
      }).toList();
      return {'baremes': baremes};
    }

    return {};
  }

  static Future<StudentOcrResult> evaluateFromImage({
    required XFile image,
    required Map<String, dynamic> tableStructure,
    required String firebaseToken,
  }) async {
    final bytes = await _preprocessImage(image);
    if (bytes.length > 5 * 1024 * 1024) {
      throw StudentOcrException('image_too_large');
    }

    final base64Str = base64Encode(bytes);

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $firebaseToken',
          },
          body: jsonEncode({
            'image': base64Str,
            'table_structure': tableStructure,
          }),
        )
        .timeout(Duration(seconds: _timeoutSeconds));

    if (response.statusCode == 400) {
      final errData = jsonDecode(response.body);
      throw StudentOcrException(errData['error'] ?? 'unknown');
    }
    if (response.statusCode == 429) {
      throw StudentOcrException('rate_limit');
    }
    if (response.statusCode == 401) {
      throw StudentOcrException('unauthorized');
    }
    if (response.statusCode != 200) {
      throw StudentOcrException('server_error');
    }

    final data = jsonDecode(response.body);
    if (data['success'] != true) {
      throw StudentOcrException(data['error'] ?? 'server_error');
    }

    return StudentOcrResult.fromJson(data['data']);
  }

  static Future<Uint8List> _preprocessImage(XFile image) async {
    final bytes = await image.readAsBytes();
    if (kIsWeb) return bytes;
    return bytes;
  }

  static Future<XFile?> pickImage({ImageSource? source}) async {
    final picker = ImagePicker();

    if (kIsWeb) {
      return await picker.pickImage(source: ImageSource.gallery);
    }

    if (source != null) {
      return await picker.pickImage(source: source);
    }

    return await picker.pickImage(source: ImageSource.gallery);
  }
}
