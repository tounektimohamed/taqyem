import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class JsonDataManager {
  static Map<String, dynamic> _jsonData = {};
  static bool _isLoaded = false;

  static Future<void> loadJsonData() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString('assets/evaluation_excel.json');
      _jsonData = json.decode(jsonString);
      _isLoaded = true;
    } catch (e) {
      print('Erreur chargement JSON: $e');
      _jsonData = {};
    }
  }

  static Map<String, dynamic> get jsonData => _jsonData;
  
  static List<String> getClasses() {
    if (_jsonData.containsKey('classes')) {
      return _jsonData['classes'].keys.toList();
    }
    return [];
  }

  static List<String> getSubjectsForClass(String className) {
    if (_jsonData.containsKey('classes') && 
        _jsonData['classes'].containsKey(className)) {
      final classData = _jsonData['classes'][className] as Map<String, dynamic>;
      if (classData.containsKey('subjects')) {
        return (classData['subjects'] as Map<String, dynamic>).keys.toList();
      }
    }
    return [];
  }

  static List<Map<String, dynamic>> getCriteriaForSubject(String className, String subjectName) {
    final List<Map<String, dynamic>> criteria = [];
    
    if (_jsonData.containsKey('classes') && 
        _jsonData['classes'].containsKey(className)) {
      
      final classData = _jsonData['classes'][className] as Map<String, dynamic>;
      
      if (classData.containsKey('subjects') && 
          (classData['subjects'] as Map<String, dynamic>).containsKey(subjectName)) {
        
        final subjectData = (classData['subjects'] as Map<String, dynamic>)[subjectName];
        final bool hasCriteria = subjectData['has_criteria'] ?? false;
        
        if (hasCriteria && subjectData['criteria'] != null) {
          final criteriaList = subjectData['criteria'] as List<dynamic>;
          
          for (int i = 0; i < criteriaList.length; i++) {
            final criteriaItem = criteriaList[i] as Map<String, dynamic>;
            final criteriaName = criteriaItem['name']?.toString() ?? 'معيار ${i + 1}';
            
            final Map<String, dynamic> criterion = {
              'id': 'criteria_$i',
              'name': criteriaName,
              'number': 'مع ${i + 1}',
              'indicators': [],
            };
            
            final indicators = criteriaItem['indicators'] as List<dynamic>?;
            if (indicators != null) {
              for (int j = 0; j < indicators.length; j++) {
                final indicatorText = indicators[j]?.toString() ?? '';
                if (indicatorText.isNotEmpty) {
                  criterion['indicators'].add({
                    'id': 'indicator_${i}_$j',
                    'text': indicatorText,
                    'code': '${i + 1}.${j + 1}',
                  });
                }
              }
            }
            
            criteria.add(criterion);
          }
        }
      }
    }
    
    return criteria;
  }

  static List<Map<String, dynamic>> getAllSubjects() {
    final List<Map<String, dynamic>> allSubjects = [];
    final Set<String> subjectNames = <String>{};
    
    if (_jsonData.containsKey('classes')) {
      final classesMap = _jsonData['classes'] as Map<String, dynamic>;
      
      classesMap.forEach((className, classData) {
        if (classData is Map<String, dynamic> && classData.containsKey('subjects')) {
          final subjectsMap = classData['subjects'] as Map<String, dynamic>;
          subjectsMap.forEach((subjectName, subjectData) {
            if (!subjectNames.contains(subjectName)) {
              subjectNames.add(subjectName);
              allSubjects.add({
                'name': subjectName,
                'className': className,
                'data': subjectData,
              });
            }
          });
        }
      });
    }
    
    return allSubjects;
  }
}