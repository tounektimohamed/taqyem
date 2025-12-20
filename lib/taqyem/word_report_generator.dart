import 'dart:html' as html;
import 'dart:convert';
import 'package:intl/intl.dart';

class WordReportGenerator {
  static Future<void> generateWordDocument(Map<String, dynamic> data) async {
    final lang = _detectLanguage(data['matiereName'] ?? '');
    final t = (String key) => _getTranslation(lang, key);

    // Générer le contenu HTML pour Word
    final htmlContent = _generateWordHTML(data, t);

    // Pour le web, créer un blob et le télécharger
    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'rapport_resultats.doc')
      ..click();
    
    html.Url.revokeObjectUrl(url);
  }

  static String _generateWordHTML(Map<String, dynamic> data, Function t) {
    final baremes = data['baremes'] as List<dynamic>? ?? [];
    final students = data['students'] as List<dynamic>? ?? [];
    final totalStudents = data['totalStudents'] as int? ?? 0;

    final textDirection = _detectLanguage(data['matiereName'] ?? '') == 'fr' ? 'ltr' : 'rtl';
    final textAlign = _detectLanguage(data['matiereName'] ?? '') == 'fr' ? 'left' : 'right';

    // CORRECTION: Calculer les statistiques correctes pour chaque barème
    final Map<String, Map<String, dynamic>> baremeStats = _calculateBaremeStats(students, baremes);

    StringBuffer html = StringBuffer();
    
    html.write('''
<!DOCTYPE html>
<html dir="$textDirection">
<head>
    <meta charset="UTF-8">
    <title>${t('main_title')}</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 20px;
            direction: $textDirection;
            line-height: 1.6;
        }
        .header {
            text-align: center;
            margin-bottom: 20px;
            border-bottom: 2px solid #075260;
            padding-bottom: 10px;
        }
        .info-section {
            margin-bottom: 20px;
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
        }
        .info-item {
            margin: 8px 0;
            font-size: 14px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            font-size: 12px;
        }
        th, td {
            border: 1px solid #075260;
            padding: 10px 8px;
            text-align: center;
        }
        th {
            background-color: #075260;
            color: white;
            font-weight: bold;
        }
        .stats-row {
            background-color: #e9ecef;
            font-weight: bold;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            font-size: 11px;
            color: #666;
            border-top: 1px solid #ddd;
            padding-top: 10px;
        }
        .student-name {
            text-align: $textAlign;
            font-weight: 500;
        }
        .success-count {
            color: #28a745;
        }
        .percentage {
            color: #007bff;
        }
        .total-with-data {
            color: #6c757d;
            font-size: 11px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1 style="color: #075260; margin: 0;">${t('main_title')}</h1>
        <p style="color: #666; margin: 5px 0;">${DateFormat('yyyy-MM-dd').format(DateTime.now())}</p>
    </div>
    
    <div class="info-section">
        <div class="info-item"><strong>${t('professor')}:</strong> ${data['profName'] ?? t('unknown')}</div>
        <div class="info-item"><strong>${t('subject')}:</strong> ${data['matiereName'] ?? t('unknown')}</div>
        <div class="info-item"><strong>${t('class')}:</strong> ${data['className'] ?? t('unknown')}</div>
        <div class="info-item"><strong>${t('school')}:</strong> ${data['schoolName'] ?? t('unknown')}</div>
    </div>
    
    <table>
        <thead>
            <tr>
                <th style="width: 200px;">${t('student_name')}</th>
''');

    // En-têtes des barèmes
    for (final bareme in baremes) {
      html.write('<th>${bareme['value']}</th>');
    }

    html.write('''
            </tr>
        </thead>
        <tbody>
''');

    // Données des étudiants
    for (final student in students) {
      html.write('<tr>');
      html.write('<td class="student-name">${student['name'] ?? t('unknown')}</td>');
      
      for (final bareme in baremes) {
        final value = student['baremes']?[bareme['id']] ?? '( - - - )';
        final color = _getValueColor(value);
        html.write('<td style="color: $color; font-weight: bold;">$value</td>');
      }
      
      html.write('</tr>');
    }

    // Ligne des statistiques - Nombre d'élèves ayant réussi
    html.write('<tr class="stats-row">');
    html.write('<td>${t('achieved_students')}</td>');
    
    for (final bareme in baremes) {
      final baremeId = bareme['id'];
      final stats = baremeStats[baremeId] ?? {'successCount': 0, 'totalWithData': 0};
      final successCount = stats['successCount'] ?? 0;
      html.write('<td class="success-count">$successCount</td>');
    }
    
    html.write('</tr>');

    // Ligne des pourcentages
    html.write('<tr class="stats-row">');
    html.write('<td>${t('percentage')}</td>');
    
    for (final bareme in baremes) {
      final baremeId = bareme['id'];
      final stats = baremeStats[baremeId] ?? {'successCount': 0, 'totalWithData': 0};
      final successCount = stats['successCount'] ?? 0;
      final totalWithData = stats['totalWithData'] ?? 0;
      
      final percentage = totalWithData > 0 
          ? (successCount / totalWithData * 100).toStringAsFixed(1)
          : '0.0';
      html.write('<td class="percentage">${percentage}%</td>');
    }
    
    html.write('</tr>');

    // Ligne du total des étudiants avec données
    html.write('<tr class="stats-row">');
    html.write('<td>${t('students_with_data')}</td>');
    
    for (final bareme in baremes) {
      final baremeId = bareme['id'];
      final stats = baremeStats[baremeId] ?? {'successCount': 0, 'totalWithData': 0};
      final totalWithData = stats['totalWithData'] ?? 0;
      html.write('<td class="total-with-data">$totalWithData</td>');
    }
    
    html.write('</tr>');

    html.write('''
        </tbody>
    </table>
    
    <div class="footer">
        ${t('generated_by')} - ${DateTime.now().toString().substring(0, 10)}<br>
        <small>${t('total_students')}: $totalStudents</small>
    </div>
</body>
</html>
''');

    return html.toString();
  }

  /// Calcule les statistiques correctes pour chaque barème
  static Map<String, Map<String, dynamic>> _calculateBaremeStats(
      List<dynamic> students, List<dynamic> baremes) {
    
    final Map<String, Map<String, dynamic>> stats = {};

    for (final bareme in baremes) {
      final baremeId = bareme['id'];
      int successCount = 0;
      int totalWithData = 0;

      for (final student in students) {
        final studentBaremes = student['baremes'] as Map<String, dynamic>? ?? {};
        final value = studentBaremes[baremeId];
        
        // Compter seulement les étudiants qui ont une valeur pour ce barème
        if (value != null && value != '( - - - )') {
          totalWithData++;
          
          // Compter comme "réussi" si c'est ( + + + ) ou ( + + - )
          if (value == '( + + + )' || value == '( + + - )') {
            successCount++;
          }
        }
      }

      stats[baremeId] = {
        'successCount': successCount,
        'totalWithData': totalWithData,
      };
    }

    return stats;
  }

  static String _getValueColor(String value) {
    switch (value) {
      case '( + + + )':
        return '#28a745'; // Vert
      case '( + + - )':
        return '#ffc107'; // Orange
      case '( + - - )':
        return '#fd7e14'; // Orange foncé
      case '( - - - )':
        return '#dc3545'; // Rouge
      default:
        return '#6c757d'; // Gris
    }
  }

  static String _detectLanguage(String matiereName) {
    if (matiereName.isEmpty) return 'ar';
    final matiereLower = matiereName.toLowerCase();
    final frenchKeywords = ['expression orale', 'lecture', 'production écrite'];
    for (final keyword in frenchKeywords) {
      if (matiereLower.contains(keyword)) return 'fr';
    }
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(matiereName) ? 'ar' : 'fr';
  }

  static String _getTranslation(String lang, String key) {
    final translations = {
      'ar': {
        'main_title': 'الجدول الجامع للنتائج',
        'professor': 'الأستاذ',
        'subject': 'المادة',
        'class': 'القسم',
        'school': 'المؤسسة',
        'student_name': 'الاسم واللقب',
        'achieved_students': 'عدد التلاميذ المحققين',
        'percentage': 'النسبة المئوية',
        'students_with_data': 'عدد التلاميذ الذين لديهم بيانات',
        'total_students': 'إجمالي عدد التلاميذ',
        'generated_by': 'تم إنشاء التقرير بواسطة نظام تقييم',
        'unknown': 'غير معروف',
      },
      'fr': {
        'main_title': 'Tableau Global des Résultats',
        'professor': 'Professeur',
        'subject': 'Matière',
        'class': 'Classe',
        'school': 'Établissement',
        'student_name': 'Nom et Prénom',
        'achieved_students': 'Nombre d\'élèves ayant atteint',
        'percentage': 'Pourcentage',
        'students_with_data': 'Nombre d\'élèves avec données',
        'total_students': 'Total des élèves',
        'generated_by': 'Rapport généré par le système d\'évaluation',
        'unknown': 'Inconnu',
      }
    };
    return translations[lang]?[key] ?? translations['ar']![key]!;
  }
}