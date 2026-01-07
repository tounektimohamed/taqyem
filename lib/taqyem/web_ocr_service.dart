// web_ocr_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker_web/image_picker_web.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

// Déclaration JS interop pour Tesseract
@JS('performOCR')
external Future<String> _performOCR(String base64Image);

@JS('Tesseract.createWorker')
external Future<dynamic> _createTesseractWorker();

@JS()
@anonymous
class TesseractWorker {
  external factory TesseractWorker();
  external Future<void> load();
  external Future<void> setParameters(dynamic params);
  external Future<dynamic> recognize(String image);
  external Future<void> terminate();
}

class SimpleWebOCRService {
  // Option 1: Utiliser l'API OCR.space (recommandé)
  Future<String?> extractTextWithAPI(Uint8List imageBytes) async {
    try {
      final String base64Image = base64Encode(imageBytes);
      
      final response = await http.post(
        Uri.parse('https://api.ocr.space/parse/image'),
        headers: {
          'apikey': 'K89444027788957', // Remplacez par votre clé
        },
        body: {
          'base64Image': 'data:image/jpeg;base64,$base64Image',
          'language': 'ara', // Arabe
          'isTable': 'true',
          'scale': 'true',
          'OCREngine': '2',
          'detectOrientation': 'true',
          'isOverlayRequired': 'false',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);
        
        if (result['IsErroredOnProcessing'] == false) {
          final List<dynamic> parsedResults = result['ParsedResults'];
          if (parsedResults.isNotEmpty) {
            String text = parsedResults[0]['ParsedText'] as String;
            return _cleanArabicText(text);
          }
        } else {
          print('Erreur API OCR: ${result['ErrorMessage']}');
        }
      }
    } catch (e) {
      print('Erreur API OCR: $e');
    }
    
    return null;
  }

  // Option 2: Utiliser Tesseract.js si disponible
  Future<String?> extractTextWithTesseract(Uint8List imageBytes) async {
    try {
      final String base64Image = base64Encode(imageBytes);
      
      // Vérifier si Tesseract est disponible
      if (await _isTesseractAvailable()) {
        return await _callTesseractJS(base64Image);
      }
    } catch (e) {
      print('Erreur Tesseract.js: $e');
    }
    
    return null;
  }

  Future<bool> _isTesseractAvailable() async {
    try {
      // Vérifier si la fonction performOCR existe
      final hasFunction = js_util.hasProperty(js_util.globalThis, 'performOCR');
      return hasFunction;
    } catch (e) {
      return false;
    }
  }

  Future<String?> _callTesseractJS(String base64Image) async {
    try {
      // Appeler la fonction JavaScript
      return await _performOCR(base64Image);
    } catch (e) {
      print('Erreur appel Tesseract: $e');
      return null;
    }
  }

  // Méthode principale - essaie l'API d'abord, puis Tesseract
  Future<String?> extractTextFromImage(Uint8List imageBytes) async {
    // Essayer l'API OCR.space d'abord
    String? result = await extractTextWithAPI(imageBytes);
    
    // Si l'API échoue, essayer Tesseract
    if (result == null || result.isEmpty) {
      result = await extractTextWithTesseract(imageBytes);
    }
    
    return result;
  }

  String _cleanArabicText(String text) {
    // Nettoyer le texte arabe
    String cleaned = text;
    
    // Remplacer les variantes de lettres arabes
    cleaned = cleaned
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('إ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('آ', 'ا');
    
    // Supprimer les caractères non-arabes sauf chiffres et ponctuation
    cleaned = cleaned.replaceAll(RegExp(r'[^\u0600-\u06FF\u0750-\u077F\s0-9.,()+-]'), '');
    
    // Normaliser les espaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned;
  }

  // Sélectionner une image
  Future<Uint8List?> pickImage() async {
    try {
      return await ImagePickerWeb.getImageAsBytes();
    } catch (e) {
      print('Erreur sélection image: $e');
      return null;
    }
  }
}