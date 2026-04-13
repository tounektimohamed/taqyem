import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/ocr_models.dart';

class OcrException implements Exception {
  final String code;
  final String? detail;

  OcrException(this.code, [this.detail]);

  String get arabicMessage {
    switch (code) {
      case 'image_too_large':
        return 'حجم الصورة كبير جداً (الحد 5MB)';
      case 'rate_limit':
        return 'تجاوزت الحد المسموح، انتظر دقيقة';
      case 'no_baremes_found':
        return 'لم يُعثر على معايير في الصورة';
      case 'json_parse_failed':
        return 'تعذر قراءة الجدول، حاول بصورة أوضح';
      case 'unauthorized':
        return 'انتهت الجلسة، سجل الدخول مجدداً';
      case 'server_error':
        return 'حدث خطأ في الخادم';
      default:
        return 'حدث خطأ غير متوقع';
    }
  }
}

class OcrService {
  static const String _endpoint =
      'https://mohamedtsou-ocr.hf.space/ocr-grading-table';
// Use: https://huggingface.co/spaces/mohamedtsou/OCR
  static const int _timeoutSeconds = 45;

  static Future<Uint8List> _preprocessImage(XFile image) async {
    final bytes = await image.readAsBytes();
    if (kIsWeb) return bytes;
    try {
      final compressed = await _compressImageMobile(bytes);
      return compressed;
    } catch (e) {
      return bytes;
    }
  }

  static Future<Uint8List> _compressImageMobile(Uint8List bytes) async {
    try {
      return bytes;
    } catch (e) {
      return bytes;
    }
  }

  static Future<OcrResult> extractFromImage({
    required XFile image,
    required String firebaseToken,
  }) async {
    final bytes = await _preprocessImage(image);

    if (bytes.length > 5 * 1024 * 1024) {
      throw OcrException('image_too_large');
    }

    final base64Str = base64Encode(bytes);

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $firebaseToken',
          },
          body: jsonEncode({'image': base64Str}),
        )
        .timeout(Duration(seconds: _timeoutSeconds));

    if (response.statusCode == 429) {
      throw OcrException('rate_limit');
    }
    if (response.statusCode == 401) {
      throw OcrException('unauthorized');
    }
    if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      final error = errorBody['error'] ?? 'unknown';
      final detail = errorBody['detail'] ?? '';
      throw OcrException(error, detail);
    }
    if (response.statusCode != 200) {
      throw OcrException('server_error');
    }

    final data = jsonDecode(response.body);
    if (data['success'] != true) {
      throw OcrException(data['error'] ?? 'server_error');
    }

    return OcrResult.fromJson(data['data']);
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
