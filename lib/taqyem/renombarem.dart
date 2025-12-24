import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class JsonNameExtractor {
  // Cache pour les données JSON
  static Map<String, dynamic>? _cachedJsonData;
  
  // Fonction pour charger et parser le JSON (compatible web et mobile)
  static Future<Map<String, dynamic>> loadJsonData() async {
    // Retourner les données en cache si disponibles
    if (_cachedJsonData != null) return _cachedJsonData!;
    
    try {
      // Méthode 1: Essayer avec rootBundle (pour mobile/desktop)
      try {
        String jsonString = await rootBundle.loadString('assets/evaluation_excel.json');
        _cachedJsonData = json.decode(jsonString);
        return _cachedJsonData!;
      } catch (e) {
        print('rootBundle failed: $e');
        
        // Méthode 2: Essayer avec HTTP (pour web)
        try {
          final response = await http.get(
            Uri.parse('assets/evaluation_excel.json')
          );
          
          if (response.statusCode == 200) {
            _cachedJsonData = json.decode(response.body);
            return _cachedJsonData!;
          } else {
            print('HTTP request failed: ${response.statusCode}');
          }
        } catch (e) {
          print('HTTP request failed: $e');
        }
        
        // Méthode 3: JSON intégré en backup (version simplifiée)
        return _getFallbackJsonData();
      }
    } catch (e) {
      print('Erreur chargement JSON: $e');
      return _getFallbackJsonData();
    }
  }

  // JSON de secours minimal
  static Map<String, dynamic> _getFallbackJsonData() {
    return {
      "metadata": {
        "نوع_البيانات": "معايير التقييم البيداغوجي",
        "مصدر_البيانات": "evaluation_excel.csv",
        "عدد_السجلات": 2160,
        "عدد_الصفوف": 6,
        "عدد_المواد": 10,
        "إجمالي_المعايير": 2160
      },
      "تصنيفات": {},
      "بيانات_مفصلة": []
    };
  }

  // Fonction pour obtenir le nom recommandé d'un barème (المحور)
  static Future<String> getRecommendedBaremeName({
    required String className,      // Ex: "السنة الأولى ابتدائي"
    required String matiereName,    // Ex: "التواصل الشفوي"
    required String baremeValue,    // Ex: "الملاءمة", "التنغيم"
  }) async {
    try {
      final jsonData = await loadJsonData();
      final List<dynamic> data = jsonData['بيانات_مفصلة'] ?? [];
      
      print('🔍 Recherche barème:');
      print('  Classe: $className');
      print('  Matière: $matiereName');
      print('  Valeur barème: $baremeValue');
      print('  Total enregistrements: ${data.length}');
      
      // Chercher dans les données
      for (var item in data) {
        final itemClasse = item['الصف']?.toString() ?? '';
        final itemMatiere = item['المادة']?.toString() ?? '';
        final itemBareme = item['المحور']?.toString() ?? '';
        
        if (itemClasse == className &&
            itemMatiere == matiereName &&
            itemBareme == baremeValue) {
          
          // Retourner le nom du المحور comme nom recommandé
          final nomRecommande = itemBareme;
          print('✅ Barème trouvé: $nomRecommande');
          return nomRecommande;
        }
      }
      
      print('❌ Barème non trouvé, utilisation de: $baremeValue');
    } catch (e) {
      print('Erreur extraction nom barème: $e');
    }
    
    return baremeValue; // Retourner la valeur par défaut
  }

  // Fonction pour obtenir le nom recommandé d'un sous-barème (المؤشر)
  static Future<String> getRecommendedSousBaremeName({
    required String className,         // Ex: "السنة الأولى ابتدائي"
    required String matiereName,       // Ex: "التواصل الشفوي"
    required String baremeValue,       // Ex: "الملاءمة" (المحور)
    required String sousBaremeValue,   // Ex: "احترام التعليمة عند الانجاز" (المؤشر)
  }) async {
    try {
      final jsonData = await loadJsonData();
      final List<dynamic> data = jsonData['بيانات_مفصلة'] ?? [];
      
      print('🔍 Recherche sous-barème:');
      print('  Classe: $className');
      print('  Matière: $matiereName');
      print('  Barème: $baremeValue');
      print('  Sous-barème valeur: $sousBaremeValue');
      
      // Chercher dans les données
      for (var item in data) {
        final itemClasse = item['الصف']?.toString() ?? '';
        final itemMatiere = item['المادة']?.toString() ?? '';
        final itemBareme = item['المحور']?.toString() ?? '';
        final itemSousBareme = item['المؤشر']?.toString() ?? '';
        
        if (itemClasse == className &&
            itemMatiere == matiereName &&
            itemBareme == baremeValue &&
            itemSousBareme == sousBaremeValue) {
          
          // Retourner le nom du مؤشر comme nom recommandé
          final nomRecommande = itemSousBareme;
          print('✅ Sous-barème trouvé: $nomRecommande');
          return nomRecommande;
        }
      }
      
      // Si non trouvé exactement, chercher une correspondance partielle
      for (var item in data) {
        final itemClasse = item['الصف']?.toString() ?? '';
        final itemMatiere = item['المادة']?.toString() ?? '';
        final itemBareme = item['المحور']?.toString() ?? '';
        final itemSousBareme = item['المؤشر']?.toString() ?? '';
        
        if (itemClasse == className &&
            itemMatiere == matiereName &&
            itemBareme == baremeValue &&
            itemSousBareme.contains(sousBaremeValue)) {
          
          print('✅ Sous-barème trouvé (correspondance partielle): $itemSousBareme');
          return itemSousBareme;
        }
      }
      
      print('❌ Sous-barème non trouvé, utilisation de: $sousBaremeValue');
    } catch (e) {
      print('Erreur extraction nom sous-barème: $e');
    }
    
    return sousBaremeValue; // Retourner la valeur par défaut
  }

  // Fonction utilitaire pour obtenir toutes les correspondances d'un barème
  static Future<List<String>> getAllSousBaremesForBareme({
    required String className,
    required String matiereName,
    required String baremeValue,
  }) async {
    try {
      final jsonData = await loadJsonData();
      final List<dynamic> data = jsonData['بيانات_مفصلة'] ?? [];
      final List<String> sousBaremes = [];
      
      for (var item in data) {
        final itemClasse = item['الصف']?.toString() ?? '';
        final itemMatiere = item['المادة']?.toString() ?? '';
        final itemBareme = item['المحور']?.toString() ?? '';
        final itemSousBareme = item['المؤشر']?.toString() ?? '';
        
        if (itemClasse == className &&
            itemMatiere == matiereName &&
            itemBareme == baremeValue &&
            itemSousBareme.isNotEmpty) {
          
          if (!sousBaremes.contains(itemSousBareme)) {
            sousBaremes.add(itemSousBareme);
          }
        }
      }
      
      return sousBaremes;
    } catch (e) {
      print('Erreur récupération sous-barèmes: $e');
      return [];
    }
  }

  // Fonction pour obtenir les noms des champs المعيار et المعيار الفرعي
  static Future<Map<String, String>> getStandardAndSubstandardNames({
    required String className,
    required String matiereName,
    required String baremeValue,
    required String sousBaremeValue,
  }) async {
    try {
      final jsonData = await loadJsonData();
      final List<dynamic> data = jsonData['بيانات_مفصلة'] ?? [];
      
      for (var item in data) {
        final itemClasse = item['الصف']?.toString() ?? '';
        final itemMatiere = item['المادة']?.toString() ?? '';
        final itemBareme = item['المحور']?.toString() ?? '';
        final itemSousBareme = item['المؤشر']?.toString() ?? '';
        
        if (itemClasse == className &&
            itemMatiere == matiereName &&
            itemBareme == baremeValue &&
            itemSousBareme == sousBaremeValue) {
          
          return {
            'المعيار': item['المعيار']?.toString() ?? '',
            'المعيار الفرعي': item['المعيار الفرعي']?.toString() ?? '',
            'المحور': itemBareme,
            'المؤشر': itemSousBareme,
          };
        }
      }
    } catch (e) {
      print('Erreur récupération noms standards: $e');
    }
    
    return {
      'المعيار': '',
      'المعيار الفرعي': '',
      'المحور': baremeValue,
      'المؤشر': sousBaremeValue,
    };
  }

  // Fonction pour vider le cache (utile pour les tests ou mises à jour)
  static void clearCache() {
    _cachedJsonData = null;
  }
}