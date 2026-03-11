import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HTMLReportGenerator {
  // Constantes pour les performances
  static const int MAX_STUDENTS_PER_PAGE = 50;
  static const int MAX_BAREMES_PER_TABLE = 20;

  static Future<void> generateAndDownloadReport({
    required String profName,
    required String matiereName,
    required String className,
    required String schoolName,
    required List<dynamic> baremes,
    required List<dynamic> students,
    required Map<String, int> sumCriteriaMaxPerBareme,
    required int totalStudents,
    required bool isFrenchInterface,
    required bool downloadAsPDF,
    String trimestre = 'الأول',
    String periode = '',
    String evaluationType = 'تقييم',
    String selectedClass = '',
    List<Map<String, dynamic>> criteria = const [],
    String performanceAttendue = '',
  }) async {
    try {
      String logoBase64 = "";
      try {
        final logoBytes = await _loadImage('lib/assets/icons/me/ministere.png');
        if (logoBytes.isNotEmpty) {
          logoBase64 = base64Encode(logoBytes);
        }
      } catch (e) {
        print('Logo non trouvé: $e');
      }

      final htmlContent = _buildCompleteHTMLContent(
        profName: profName,
        matiereName: matiereName,
        className: className,
        schoolName: schoolName,
        baremes: baremes,
        students: students,
        sumCriteriaMaxPerBareme: sumCriteriaMaxPerBareme,
        totalStudents: totalStudents,
        isFrenchInterface: isFrenchInterface,
        logoBase64: logoBase64,
        trimestre: trimestre,
        periode: periode,
        evaluationType: evaluationType,
        criteria: criteria,
        performanceAttendue: performanceAttendue,
      );

      if (downloadAsPDF) {
        await _generateAndDownloadPDF(htmlContent);
      } else {
        await _downloadHTMLFile(htmlContent);
      }
    } catch (e) {
      print('Erreur génération rapport: $e');
      rethrow;
    }
  }
static String _buildCriteriaTableHTML({
  required List<Map<String, dynamic>> criteria,
  required bool isFrenchInterface,
}) {
  if (criteria.isEmpty) {
    return '';
  }

  final StringBuffer rows = StringBuffer();
  int totalIndicators = 0;

  for (int i = 0; i < criteria.length; i++) {
    final critere = criteria[i];
    final name = critere['name']?.toString() ?? 'معيار ${i + 1}';
    final domaine = critere['domaine']?.toString() ?? '';
    final indicators = critere['indicators'] as List<dynamic>? ?? [];
    totalIndicators += indicators.length;

    // Ligne principale du critère
    rows.write('''
  <tr class="criteria-main-row">
      <td class="criteria-number">${i + 1}</td>
      <td colspan="2">
          <span class="criteria-title">$name</span>
       
      </td>
  </tr>
  ''');

    // Lignes des indicateurs (sans tri)
    for (int j = 0; j < indicators.length; j++) {
      final indicator = indicators[j].toString();
      rows.write('''
    <tr class="indicator-row">
        <td class="indicator-number">${i + 1}.${j + 1}</td>
        <td colspan="2">$indicator</td>
    </tr>
    ''');
    }
  }

  return '''
  <div style="margin-top: 20px;">
    <div style="margin-bottom: 10px; color: #666; font-size: 14px;">
      ${isFrenchInterface ? 'Total des critères' : 'مجموع المعايير'}: ${criteria.length} | 
      ${isFrenchInterface ? 'Total des indicateurs' : 'مجموع المؤشرات'}: $totalIndicators
    </div>
    
    <table class="criteria-table">
        <thead>
            <tr>
                <th style="width: 80px;">#</th>
                <th colspan="2">${isFrenchInterface ? 'Critères / Indicateurs' : 'المعايير / المؤشرات'}</th>
            </tr>
        </thead>
        <tbody>
            ${rows.toString()}
        </tbody>
    </table>
  </div>
''';
}
  static String _buildCombinedPeriodAndCriteriaPageHTML({
    required String trimestre,
    required String periode,
    required String evaluationType,
    required Map<String, String> t,
    required bool isFrenchInterface,
    required String matiereName,
    required String className,
    required String profName,
    required String performanceAttendue,
    required List<Map<String, dynamic>> criteria,
  }) {
    final criteriaHTML = _buildCriteriaTableHTML(
      criteria: criteria,
      isFrenchInterface: isFrenchInterface,
    );

    return '''
    <div class="combined-page">
        <div class="section-header">
            <h2 class="section-title">
                $matiereName - $className
            </h2>
        </div>
        
        <!-- Section des données de période -->
        <div class="period-section">
            <h3>${isFrenchInterface ? 'Détails de la période' : 'تفاصيل الفترة'}</h3>
            
            <div class="period-grid">
                <div class="period-card">
                    <div class="period-icon">📅</div>
                    <div>
                        <div class="period-label">${t['trimestre']}</div>
                        <div class="period-value">${_getTrimestreDisplay(trimestre, isFrenchInterface)}</div>
                    </div>
                </div>
                
                <div class="period-card">
                    <div class="period-icon">📚</div>
                    <div>
                        <div class="period-label">${t['periode']}</div>
                        <div class="period-value">
                            ${periode.isNotEmpty ? periode : (isFrenchInterface ? 'Non spécifié' : 'غير محدد')}
                        </div>
                    </div>
                </div>
                
                <div class="period-card">
                    <div class="period-icon">📝</div>
                    <div>
                        <div class="period-label">${t['evaluation_type']}</div>
                        <div class="period-value">
                            ${_getEvaluationTypeDisplay(evaluationType, isFrenchInterface)}
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Section Performance Attendue -->
        ${performanceAttendue.isNotEmpty ? '''
        <div class="performance-section">
            <h3>${isFrenchInterface ? 'Performance Attendue' : 'الأداء المنتظر'}</h3>
            <div class="performance-content">
                ${performanceAttendue}
            </div>
        </div>
        ''' : ''}
        
        <!-- Section des critères d'évaluation -->
        ${criteria.isNotEmpty ? '''
        <div class="criteria-section">
            <h3>${t['evaluation_criteria']}</h3>
            ${criteriaHTML}
        </div>
        ''' : ''}
        
        <div class="report-footer">
            <p class="no-print">${isFrenchInterface ? 'Page 2' : 'الصفحة 2'}</p>
        </div>
    </div>
  ''';
  }

  static String _buildCompleteHTMLContent({
    required String profName,
    required String matiereName,
    required String className,
    required String schoolName,
    required List<dynamic> baremes,
    required List<dynamic> students,
    required Map<String, int> sumCriteriaMaxPerBareme,
    required int totalStudents,
    required bool isFrenchInterface,
    required String logoBase64,
    required String trimestre,
    required String periode,
    required String evaluationType,
    required List<Map<String, dynamic>> criteria,
    required String performanceAttendue,
  }) {
    final direction = isFrenchInterface ? 'ltr' : 'rtl';
    final textAlign = isFrenchInterface ? 'left' : 'right';

    final t = {
      'title': isFrenchInterface ? 'Rapport des Résultats' : 'تقرير النتائج',
      'cover_title': isFrenchInterface
          ? 'République Tunisienne\nMinistère de l\'Éducation'
          : 'الجمهورية التونسية\nوزارة التربية',
      'regional_delegation': isFrenchInterface
          ? 'Délégation Régionale de l\'Éducation à ...................'
          : 'المندوبية الجهوية للتربية ب..............',
      'school': isFrenchInterface ? 'Établissement' : 'المدرسة الابتدائية',
      'subject': isFrenchInterface ? 'Matière' : 'المادة',
      'class': isFrenchInterface ? 'Classe' : 'القسم',
      'academic_year': isFrenchInterface ? 'Année scolaire' : 'السنة الدراسية',
      'professor': isFrenchInterface ? 'Professeur' : 'الأستاذ(ة) ',
      'main_title': isFrenchInterface
          ? 'Tableau Global des Résultats'
          : 'الجدول الجامع للنتائج',
      'student_name': isFrenchInterface ? 'Nom et Prénom' : 'الاسم واللقب',
      'achieved_students': isFrenchInterface
          ? "Nombre d'élèves ayant atteint"
          : 'عدد التلاميذ المحققين',
      'percentage': isFrenchInterface ? 'Pourcentage' : 'النسبة المئوية',
      'total_students':
          isFrenchInterface ? 'Total des élèves' : 'مجموع التلاميذ',
      'trimestre': isFrenchInterface ? 'Trimestre' : 'الثلاثي',
      'periode': isFrenchInterface ? 'Unité/Période' : 'الوحدة/الفترة',
      'evaluation_type':
          isFrenchInterface ? 'Type d\'évaluation' : 'نوع التقييم',
      'generated_on': isFrenchInterface ? 'Généré le' : 'تم الإنشاء في',
      'evaluation_criteria':
          isFrenchInterface ? 'Critères d\'évaluation' : 'معايير التقييم',
      'criteria': isFrenchInterface ? 'Critères' : 'المعايير',
      'indicators': isFrenchInterface ? 'Indicateurs' : 'المؤشرات',
      'domain': isFrenchInterface ? 'Domaine' : 'المجال',
      'total_criteria':
          isFrenchInterface ? 'Total des critères' : 'مجموع المعايير',
      'total_indicators':
          isFrenchInterface ? 'Total des indicateurs' : 'مجموع المؤشرات',
    };

    final now = DateTime.now();
    final currentDate = '${now.day}/${now.month}/${now.year}';
    final academicYear = '${now.year}/${now.year + 1}';
    final domaine = _getDomaineForMatiere(matiereName, isFrenchInterface);

    // Tableau optimisé
    final tableHTML = _buildOptimizedTableHTML(
      baremes: baremes,
      students: students,
      sumCriteriaMaxPerBareme: sumCriteriaMaxPerBareme,
      totalStudents: totalStudents,
      isFrenchInterface: isFrenchInterface,
      t: t,
    );

    final combinedPeriodAndCriteriaHTML =
        _buildCombinedPeriodAndCriteriaPageHTML(
      trimestre: trimestre,
      periode: periode,
      evaluationType: evaluationType,
      t: t,
      isFrenchInterface: isFrenchInterface,
      matiereName: matiereName,
      className: className,
      profName: profName,
      performanceAttendue: performanceAttendue,
      criteria: criteria,
    );

    return '''
<!DOCTYPE html>
<html lang="${isFrenchInterface ? 'fr' : 'ar'}" dir="$direction">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${t['title']}</title>
    <style>
        /* STYLES SIMPLIFIÉS */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        :root {
            --primary-color: #2c3e50;
            --secondary-color: #34495e;
            --accent-color: #7f8c8d;
            --light-bg: #f8f9fa;
            --white: #ffffff;
            --text-color: #333333;
            --border-color: #ddd;
            --border-radius: 5px;
            --box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        
        body {
            font-family: ${isFrenchInterface ? 'Arial, Helvetica, sans-serif' : "'Noto Sans Arabic', Tahoma, sans-serif"};
            background: #f5f5f5;
            color: var(--text-color);
            direction: $direction;
            line-height: 1.5;
            padding: 10px;
        }
        
        .report-container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        /* Page de garde */
        .cover-page {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--box-shadow);
            padding: 30px;
            margin-bottom: 20px;
            border-top: 5px solid var(--primary-color);
        }
        
        .cover-header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 15px;
            border-bottom: 1px solid var(--border-color);
        }
        
        .ministry-title {
            color: var(--primary-color);
            font-size: 22px;
            font-weight: bold;
            margin-bottom: 10px;
            line-height: 1.3;
        }
        
        .delegation-title {
            color: var(--secondary-color);
            font-size: 16px;
            font-weight: 600;
            margin-bottom: 15px;
        }
        
        .logo-container {
            margin: 20px 0;
            text-align: center;
        }
        
        .logo {
            height: 80px;
            max-width: 150px;
            object-fit: contain;
        }
        
        .school-info {
            background: var(--light-bg);
            border-radius: var(--border-radius);
            padding: 20px;
            margin: 20px 0;
            border: 1px solid var(--border-color);
            text-align: center;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        
        .info-card {
            background: var(--white);
            border-radius: var(--border-radius);
            padding: 15px;
            border: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .info-icon {
            width: 40px;
            height: 40px;
            background: var(--primary-color);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 16px;
            flex-shrink: 0;
        }
        
        .info-content {
            flex: 1;
        }
        
        .info-label {
            color: #666;
            font-size: 13px;
            margin-bottom: 3px;
        }
        
        .info-value {
            color: var(--text-color);
            font-size: 14px;
            font-weight: 600;
        }
        
        .domaine-section {
            background: var(--light-bg);
            color: var(--primary-color);
            padding: 15px;
            border-radius: var(--border-radius);
            margin: 20px 0;
            border-left: 4px solid var(--primary-color);
        }
        
        .domaine-title {
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 10px;
        }
        
        .domaine-content {
            font-size: 16px;
        }
        
        .footer-cover {
            text-align: center;
            margin-top: 30px;
            padding-top: 15px;
            border-top: 1px solid var(--border-color);
            color: #666;
            font-size: 13px;
        }
        
        /* Page combinée */
        .combined-page {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--box-shadow);
            padding: 25px;
            margin-top: 20px;
            page-break-before: always;
        }
        
        .section-header {
            background: var(--light-bg);
            padding: 15px;
            border-radius: var(--border-radius);
            margin-bottom: 20px;
            border-bottom: 2px solid var(--primary-color);
        }
        
        .section-title {
            font-size: 20px;
            font-weight: bold;
            text-align: center;
            color: var(--primary-color);
        }
        
        .period-section h3,
        .performance-section h3,
        .criteria-section h3 {
            color: var(--primary-color);
            margin-bottom: 15px;
            font-size: 18px;
            padding-bottom: 8px;
            border-bottom: 1px solid var(--border-color);
        }
        
        .period-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        
        .period-card {
            background: var(--light-bg);
            border-radius: var(--border-radius);
            padding: 20px;
            border: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .period-icon {
            font-size: 20px;
            color: var(--primary-color);
        }
        
        .period-label {
            color: #666;
            font-size: 13px;
            margin-bottom: 5px;
        }
        
        .period-value {
            color: var(--text-color);
            font-size: 16px;
            font-weight: 600;
        }
        
        /* Section Performance Attendue */
        .performance-section {
            margin: 20px 0;
            padding: 15px;
            background: #f0f7f0;
            border-radius: var(--border-radius);
            border-left: 4px solid #4CAF50;
        }
        
        .performance-content {
            color: #333;
            line-height: 1.6;
            white-space: pre-line;
            font-size: 15px;
        }
        
        /* Section des critères */
        .criteria-section {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid var(--border-color);
        }
        
        .criteria-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
            margin: 15px 0;
            border: 1px solid var(--border-color);
        }
        
        .criteria-table th {
            background: var(--primary-color);
            color: white;
            padding: 10px 8px;
            text-align: center;
            font-weight: 600;
            border: 1px solid var(--border-color);
        }
        
        .criteria-table td {
            padding: 8px;
            border: 1px solid var(--border-color);
            vertical-align: top;
        }
        
        .criteria-main-row {
            background: #f8f9fa !important;
            font-weight: bold;
        }
        
        .indicator-row {
            background: var(--white) !important;
        }
        
        .criteria-number {
            width: 50px;
            text-align: center;
            font-weight: bold;
            color: var(--primary-color);
        }
        
        .indicator-number {
            width: 70px;
            text-align: center;
            color: #666;
        }
        
        .domain-badge {
            display: inline-block;
            padding: 3px 8px;
            background: #e8f5e9;
            color: #2E7D32;
            border-radius: 12px;
            font-size: 11px;
            margin-${isFrenchInterface ? 'left' : 'right'}: 8px;
            border: 1px solid #c8e6c9;
        }
        
        .criteria-title {
            font-weight: bold;
            color: var(--primary-color);
        }
        
        /* Page du tableau principal */
        .table-page {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--box-shadow);
            padding: 25px;
            margin-top: 20px;
            page-break-before: always;
        }
        
        .table-header {
            background: var(--light-bg);
            padding: 15px;
            border-radius: var(--border-radius);
            margin-bottom: 20px;
            border-bottom: 2px solid var(--primary-color);
        }
        
        .table-main-title {
            font-size: 20px;
            font-weight: bold;
            text-align: center;
            color: var(--primary-color);
            margin-bottom: 8px;
        }
        
        .table-subtitle {
            text-align: center;
            color: #666;
            font-size: 15px;
        }
        
        .table-container {
            overflow-x: auto;
            margin: 15px 0;
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius);
        }
        
        .results-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
        }
        
        .results-table th {
            background: var(--primary-color);
            color: white;
            padding: 10px 8px;
            text-align: center;
            font-weight: 600;
            border: 1px solid var(--border-color);
            white-space: nowrap;
            position: sticky;
            top: 0;
        }
        
        .results-table td {
            padding: 8px;
            text-align: center;
            border: 1px solid var(--border-color);
            vertical-align: middle;
        }
        
        .student-name-cell {
            background: var(--light-bg);
            font-weight: 600;
            text-align: ${textAlign};
            min-width: 150px;
            position: sticky;
            ${isFrenchInterface ? 'left' : 'right'}: 0;
            z-index: 1;
        }
        
        /* Styles pour la hiérarchie des barèmes */
        .main-bareme-header {
            background: var(--secondary-color) !important;
            color: white !important;
            font-weight: bold !important;
        }
        
        .sub-bareme-header {
            background: var(--accent-color) !important;
            color: white !important;
            font-weight: normal !important;
            font-size: 12px !important;
        }
        
        /* Couleurs des notes */
        .mark-excellent { background-color: #d4edda; color: #155724; font-weight: bold; }
        .mark-good { background-color: #fff3cd; color: #856404; font-weight: bold; }
        .mark-average { background-color: #ffeaa7; color: #856404; }
        .mark-poor { background-color: #f8d7da; color: #721c24; }
        
        /* Lignes de statistiques */
        .stats-row {
            background: #e3f2fd !important;
            font-weight: bold;
        }
        
        .percentage-row {
            background: #f3e5f5 !important;
            font-weight: bold;
        }
        
        .percentage-high { color: #2E7D32; }
        .percentage-medium { color: #FF9800; }
        .percentage-low { color: #D32F2F; }
        
        /* Section résumé */
        .summary-section {
            background: var(--light-bg);
            padding: 15px;
            border-radius: var(--border-radius);
            margin-top: 20px;
        }
        
        .summary-title {
            color: var(--primary-color);
            font-size: 16px;
            font-weight: bold;
            margin-bottom: 10px;
        }
        
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 10px;
        }
        
        .summary-item {
            background: white;
            padding: 12px;
            border-radius: var(--border-radius);
            border-left: 3px solid var(--primary-color);
        }
        
        .summary-label {
            color: #666;
            font-size: 13px;
            margin-bottom: 3px;
        }
        
        .summary-value {
            color: var(--text-color);
            font-size: 15px;
            font-weight: bold;
        }
        
        .report-footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 15px;
            border-top: 1px solid var(--border-color);
            color: #666;
            font-size: 13px;
        }
        
        /* Styles d'impression */
        @media print {
            body {
                background: white;
                padding: 0;
            }
            
            .cover-page, .combined-page, .table-page {
                box-shadow: none;
                border: none;
                page-break-inside: avoid;
            }
            
            .no-print {
                display: none;
            }
            
            .table-container {
                overflow: visible;
            }
        }
        
        
    </style>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Arabic:wght@400;500;600;700&display=swap" rel="stylesheet">
</head>
<body>
    <div class="report-container">
        <!-- 1. Page de garde -->
        ${_buildCoverPageHTML(profName, matiereName, className, schoolName, logoBase64, trimestre, periode, evaluationType, t, now, academicYear, domaine, isFrenchInterface)}
        
        <!-- 2. Page combinée des données de période et des critères -->
        ${combinedPeriodAndCriteriaHTML}
        
        <!-- 3. Page du tableau d'évaluation -->
        ${_buildEvaluationTablePageHTML(matiereName, className, trimestre, t, tableHTML, totalStudents, now, schoolName, isFrenchInterface, evaluationType)}
    </div>
    
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Appliquer les couleurs aux notes
            const cells = document.querySelectorAll('.mark-cell');
            cells.forEach(cell => {
                const mark = cell.textContent.trim();
                if (mark === '( + + + )') {
                    cell.classList.add('mark-excellent');
                } else if (mark === '( + + - )') {
                    cell.classList.add('mark-good');
                } else if (mark === '( + - - )') {
                    cell.classList.add('mark-average');
                } else if (mark === '( - - - )') {
                    cell.classList.add('mark-poor');
                }
            });
            
            // Appliquer les couleurs aux pourcentages
            const percentageCells = document.querySelectorAll('.percentage-cell');
            percentageCells.forEach(cell => {
                const text = cell.textContent.trim();
                if (text.endsWith('%')) {
                    const percentage = parseFloat(text.replace('%', ''));
                    if (percentage >= 80) {
                        cell.classList.add('percentage-high');
                    } else if (percentage >= 50) {
                        cell.classList.add('percentage-medium');
                    } else {
                        cell.classList.add('percentage-low');
                    }
                }
            });
        });
    </script>
</body>
</html>
    ''';
  }

  // ============ MÉTHODES OPTIMISÉES POUR LE TABLEAU ============

  static String _buildOptimizedTableHTML({
    required List<dynamic> baremes,
    required List<dynamic> students,
    required Map<String, int> sumCriteriaMaxPerBareme,
    required int totalStudents,
    required bool isFrenchInterface,
    required Map<String, String> t,
  }) {
    print('=== DÉBUT DE LA CONSTRUCTION DU TABLEAU ===');
    print('Nombre de barèmes: ${baremes.length}');
    print('Nombre d\'étudiants: ${students.length}');

    // Limiter les barèmes si trop nombreux
    final List<dynamic> limitedBaremes = baremes.length > MAX_BAREMES_PER_TABLE
        ? baremes.sublist(0, MAX_BAREMES_PER_TABLE)
        : baremes;

    // Organiser et trier les barèmes alphabétiquement
    final List<Map<String, dynamic>> mainBaremes = _organizeAndSortBaremes(
      limitedBaremes,
      isFrenchInterface,
    );

    // Trier les étudiants alphabétiquement
    final List<Map<String, dynamic>> sortedStudents = _sortStudents(
      students,
      isFrenchInterface,
    );

    // Construire l'en-tête
    final String headerHTML = _buildTableHeader(mainBaremes, t);

    // Construire les lignes des étudiants
    final String studentsRows = _buildStudentRowsOptimized(
      sortedStudents,
      mainBaremes,
    );

    // Construire les statistiques
    final String statsHTML = _buildStatisticsRows(
      mainBaremes,
      sumCriteriaMaxPerBareme,
      totalStudents,
      t,
    );

    // Calculer le nombre total de colonnes
    final int totalColumns = _calculateTotalColumns(mainBaremes);

    print('=== FIN DE LA CONSTRUCTION DU TABLEAU ===');

    return _buildFinalTableHTML(
      headerHTML,
      studentsRows,
      statsHTML,
      totalColumns,
      isFrenchInterface,
    );
  }

  static List<Map<String, dynamic>> _organizeAndSortBaremes(
    List<dynamic> baremes,
    bool isFrenchInterface,
  ) {
    print('=== ORGANISATION DES BARÈMES ===');

    final Map<String, Map<String, dynamic>> baremeMap = {};
    final Map<String, List<Map<String, dynamic>>> subBaremesByParent = {};

    // Premier passage: organiser les barèmes avec leurs valeurs réelles
    for (var bareme in baremes) {
      final baremeId = bareme['id'].toString();
      final baremeValue = bareme['value']?.toString() ?? '';
      final parentBaremeId = bareme['parentBaremeId']?.toString();

      print(
          'Barème trouvé: ID=$baremeId, Valeur="$baremeValue", Parent=$parentBaremeId');

      if (parentBaremeId == null || parentBaremeId.isEmpty) {
        // Barème principal
        baremeMap[baremeId] = {
          'id': baremeId,
          'value': baremeValue,
          'originalValue': baremeValue,
          'hasSubBaremes': false,
          'subBaremes': [],
          'isVirtual': false,
        };
        print('  → Ajouté comme barème principal: $baremeValue');
      } else {
        // Sous-barème
        if (!subBaremesByParent.containsKey(parentBaremeId)) {
          subBaremesByParent[parentBaremeId] = [];
        }
        subBaremesByParent[parentBaremeId]!.add({
          'id': baremeId,
          'value': baremeValue,
          'originalValue': baremeValue,
        });
        print('  → Ajouté comme sous-barème de parent $parentBaremeId');
      }
    }

    print('--- Recherche des noms de parents ---');

    // Deuxième passage: trouver les noms des parents manquants
    for (var parentId in subBaremesByParent.keys) {
      print('Traitement du parent ID: $parentId');

      if (!baremeMap.containsKey(parentId)) {
        // Chercher le vrai nom du parent dans la liste originale
        String parentName = '';

        for (var bareme in baremes) {
          if (bareme['id'].toString() == parentId) {
            parentName = bareme['value']?.toString() ?? '';
            break;
          }
        }

        // Si on ne trouve pas, essayer d'extraire du premier sous-barème
        if (parentName.isEmpty && subBaremesByParent[parentId]!.isNotEmpty) {
          final firstSub = subBaremesByParent[parentId]!.first;
          parentName = _extractParentNameFromSub(firstSub['value'] as String);
        }

        final finalParentName =
            parentName.isNotEmpty ? parentName : 'معیار $parentId';

        baremeMap[parentId] = {
          'id': parentId,
          'value': finalParentName,
          'originalValue': finalParentName,
          'hasSubBaremes': true,
          'subBaremes': subBaremesByParent[parentId]!,
          'isVirtual': true,
        };

        print(
            '  → Créé parent virtuel: $finalParentName avec ${subBaremesByParent[parentId]!.length} sous-barèmes');
      } else {
        // Parent existe déjà, ajouter les sous-barèmes
        baremeMap[parentId]!['hasSubBaremes'] = true;
        baremeMap[parentId]!['subBaremes'] = subBaremesByParent[parentId]!;
        print(
            '  → Ajouté sous-barèmes au parent existant: ${baremeMap[parentId]!['value']}');
      }
    }

    // Trier les barèmes principaux par ordre alphabétique
    final List<Map<String, dynamic>> mainBaremesList =
        baremeMap.values.toList();

    print('--- Tri alphabétique des barèmes principaux ---');
    mainBaremesList.sort((a, b) {
      final nameA = a['value'] as String;
      final nameB = b['value'] as String;

      // Normaliser les noms pour le tri
      final normalizedA = _normalizeForSorting(nameA);
      final normalizedB = _normalizeForSorting(nameB);

      if (!isFrenchInterface) {
        // Tri arabe
        return _arabicComparatorForHTML(normalizedA, normalizedB);
      } else {
        // Tri français
        return normalizedA.toLowerCase().compareTo(normalizedB.toLowerCase());
      }
    });

    // Trier les sous-barèmes alphabétiquement
    print('--- Tri alphabétique des sous-barèmes ---');
    for (var bareme in mainBaremesList) {
      if (bareme['hasSubBaremes'] as bool) {
        final subBaremes = bareme['subBaremes'] as List<Map<String, dynamic>>;

        print('Tri des sous-barèmes de: ${bareme['value']}');

        subBaremes.sort((a, b) {
          final nameA = a['value'] as String;
          final nameB = b['value'] as String;

          // Nettoyer les noms pour le tri (enlever le préfixe parent)
          String cleanA =
              _cleanSubBaremeNameForSorting(nameA, bareme['value'] as String);
          String cleanB =
              _cleanSubBaremeNameForSorting(nameB, bareme['value'] as String);

          if (cleanA.isEmpty) cleanA = nameA;
          if (cleanB.isEmpty) cleanB = nameB;

          final normalizedA = _normalizeForSorting(cleanA);
          final normalizedB = _normalizeForSorting(cleanB);

          if (!isFrenchInterface) {
            return _arabicComparatorForHTML(normalizedA, normalizedB);
          } else {
            return normalizedA
                .toLowerCase()
                .compareTo(normalizedB.toLowerCase());
          }
        });

        bareme['subBaremes'] = subBaremes;

        // Afficher l'ordre final
        for (var i = 0; i < subBaremes.length; i++) {
          print('  ${i + 1}. ${subBaremes[i]['value']}');
        }
      }
    }

    // Afficher l'organisation finale
    _debugBaremes(mainBaremesList);

    return mainBaremesList;
  }

  static String _extractParentNameFromSub(String subBaremeName) {
    if (subBaremeName.isEmpty) return '';

    // Patterns courants pour les sous-barèmes:
    // "مع 2.ب" -> "مع 2"
    // "C3.a" -> "C3"
    // "معيار 1.أ" -> "معيار 1"

    // Pattern 1: Point avec lettre arabe
    final arabicPattern = RegExp(r'^(.+)\.([\u0621-\u064A])$');
    final matchArabic = arabicPattern.firstMatch(subBaremeName);
    if (matchArabic != null) {
      return matchArabic.group(1)!.trim();
    }

    // Pattern 2: Point avec lettre latine
    final latinPattern = RegExp(r'^(.+)\.([a-zA-Z])$');
    final matchLatin = latinPattern.firstMatch(subBaremeName);
    if (matchLatin != null) {
      return matchLatin.group(1)!.trim();
    }

    // Pattern 3: Espace avec lettre
    final spacePattern = RegExp(r'^(.+)\s+([\u0621-\u064A]|[a-zA-Z])$');
    final matchSpace = spacePattern.firstMatch(subBaremeName);
    if (matchSpace != null) {
      return matchSpace.group(1)!.trim();
    }

    // Pattern 4: Numéro entre parenthèses
    final parenPattern = RegExp(r'^(.+)\s*\(([^)]+)\)$');
    final matchParen = parenPattern.firstMatch(subBaremeName);
    if (matchParen != null) {
      return matchParen.group(1)!.trim();
    }

    return subBaremeName;
  }

  static String _normalizeForSorting(String text) {
    if (text.isEmpty) return text;

    String normalized = text.trim();

    // Supprimer les diacritiques arabes
    normalized = normalized.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

    // Normaliser les lettres arabes
    final arabicNormalizations = {
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ؤ': 'و',
      'ئ': 'ي',
      'ة': 'ه',
      'ى': 'ي'
    };

    arabicNormalizations.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    // Convertir les chiffres arabes en latins pour le tri
    final arabicNumbers = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9'
    };

    arabicNumbers.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    return normalized;
  }

  static String _cleanSubBaremeNameForSorting(
      String subName, String parentName) {
    if (subName.isEmpty || parentName.isEmpty) return subName;

    String cleaned = subName;

    // Enlever le nom du parent du début
    if (cleaned.startsWith(parentName)) {
      cleaned = cleaned.substring(parentName.length).trim();
    }

    // Enlever les séparateurs communs au début
    cleaned = cleaned.replaceAll(RegExp(r'^[.\s\-_]+'), '');

    return cleaned;
  }

  static String _cleanSubBaremeNameDisplay(String subName, String parentName) {
    if (subName.isEmpty) return subName;

    // Si le sous-barème commence par le nom du parent
    if (subName.startsWith(parentName)) {
      String remaining = subName.substring(parentName.length).trim();

      // Enlever les séparateurs au début
      remaining = remaining.replaceAll(RegExp(r'^[.\s\-_]+'), '');

      // Si ce qui reste est une seule lettre ou un caractère simple, l'afficher
      if (remaining.isNotEmpty && remaining.length <= 2) {
        return remaining;
      }
    }

    // Sinon, retourner le nom complet
    return subName;
  }

  static void _debugBaremes(List<Map<String, dynamic>> mainBaremes) {
    print('=== ORGANISATION FINALE DES BARÈMES ===');
    for (var i = 0; i < mainBaremes.length; i++) {
      final bareme = mainBaremes[i];
      print(
          '${i + 1}. Barème principal: "${bareme['value']}" (ID: ${bareme['id']})');

      if (bareme['hasSubBaremes'] as bool) {
        final subBaremes = bareme['subBaremes'] as List<dynamic>;
        print('   Sous-barèmes (${subBaremes.length}):');
        for (var j = 0; j < subBaremes.length; j++) {
          final sub = subBaremes[j];
          print('   ${j + 1}. "${sub['value']}" (ID: ${sub['id']})');
        }
      } else {
        print('   (pas de sous-barèmes)');
      }
    }
    print('===============================');
  }

  static List<Map<String, dynamic>> _sortStudents(
    List<dynamic> students,
    bool isFrenchInterface,
  ) {
    final List<Map<String, dynamic>> studentList =
        students.map((s) => s as Map<String, dynamic>).toList();

    studentList.sort((a, b) {
      final nameA = a['name']?.toString() ?? '';
      final nameB = b['name']?.toString() ?? '';

      // Normaliser pour le tri
      final normalizedA = _normalizeForSorting(nameA);
      final normalizedB = _normalizeForSorting(nameB);

      return isFrenchInterface
          ? normalizedA.toLowerCase().compareTo(normalizedB.toLowerCase())
          : _arabicComparatorForHTML(normalizedA, normalizedB);
    });

    return studentList;
  }

  static String _buildTableHeader(
    List<Map<String, dynamic>> mainBaremes,
    Map<String, String> t,
  ) {
    final StringBuffer mainHeader = StringBuffer();
    final StringBuffer subHeader = StringBuffer();

    mainHeader.write(
        '<th rowspan="2" class="student-name-cell">${t['student_name']}</th>');

    for (var mainBareme in mainBaremes) {
      final mainBaremeValue = mainBareme['value'] as String;
      final hasSubBaremes = mainBareme['hasSubBaremes'] as bool;
      final subBaremes = mainBareme['subBaremes'] as List<dynamic>? ?? [];

      if (hasSubBaremes && subBaremes.isNotEmpty) {
        final colspan = subBaremes.length;
        mainHeader.write('''
          <th colspan="$colspan" class="main-bareme-header">
            $mainBaremeValue
          </th>
        ''');

        for (var subBareme in subBaremes) {
          final subValue = subBareme['value'] as String;
          // Utiliser la méthode de nettoyage pour l'affichage
          final cleanSubValue =
              _cleanSubBaremeNameDisplay(subValue, mainBaremeValue);
          subHeader.write('''
            <th class="sub-bareme-header">
              $cleanSubValue
            </th>
          ''');
        }
      } else {
        mainHeader.write('''
          <th colspan="1" class="main-bareme-header">
            $mainBaremeValue
          </th>
        ''');
        subHeader.write('<th></th>');
      }
    }

    if (subHeader.toString().contains('sub-bareme-header')) {
      return '''
        <thead>
          <tr>${mainHeader.toString()}</tr>
          <tr>${subHeader.toString()}</tr>
        </thead>
      ''';
    } else {
      final StringBuffer singleHeader = StringBuffer();
      singleHeader
          .write('<th class="student-name-cell">${t['student_name']}</th>');
      for (var mainBareme in mainBaremes) {
        singleHeader.write(
            '<th class="main-bareme-header">${mainBareme['value']}</th>');
      }
      return '<thead><tr>${singleHeader.toString()}</tr></thead>';
    }
  }

  static String _buildStudentRowsOptimized(
    List<Map<String, dynamic>> students,
    List<Map<String, dynamic>> mainBaremes,
  ) {
    final StringBuffer buffer = StringBuffer();

    for (var student in students) {
      buffer.write('<tr>');
      buffer.write('<td class="student-name-cell">${student['name']}</td>');

      final studentBaremes = student['baremes'] as Map<String, dynamic>? ?? {};

      for (var mainBareme in mainBaremes) {
        final mainBaremeId = mainBareme['id'] as String;
        final hasSubBaremes = mainBareme['hasSubBaremes'] as bool;
        final subBaremes = mainBareme['subBaremes'] as List<dynamic>? ?? [];

        if (hasSubBaremes && subBaremes.isNotEmpty) {
          for (var subBareme in subBaremes) {
            final subBaremeId = subBareme['id'] as String;
            final fullKey = '$mainBaremeId-$subBaremeId';
            final mark = _getStudentMarkOptimized(
                studentBaremes, fullKey, subBaremeId, mainBaremeId);
            buffer.write('<td class="mark-cell">$mark</td>');
          }
        } else {
          final mark = studentBaremes[mainBaremeId]?.toString() ?? '( - - - )';
          buffer.write('<td class="mark-cell">$mark</td>');
        }
      }

      buffer.write('</tr>');
    }

    return buffer.toString();
  }

  static String _getStudentMarkOptimized(
    Map<String, dynamic> studentBaremes,
    String fullKey,
    String subBaremeId,
    String mainBaremeId,
  ) {
    if (studentBaremes.containsKey(fullKey)) {
      return studentBaremes[fullKey]?.toString() ?? '( - - - )';
    }
    if (studentBaremes.containsKey(subBaremeId)) {
      return studentBaremes[subBaremeId]?.toString() ?? '( - - - )';
    }
    if (studentBaremes.containsKey(mainBaremeId)) {
      return studentBaremes[mainBaremeId]?.toString() ?? '( - - - )';
    }
    return '( - - - )';
  }

  static String _buildStatisticsRows(
    List<Map<String, dynamic>> mainBaremes,
    Map<String, int> sumCriteriaMaxPerBareme,
    int totalStudents,
    Map<String, String> t,
  ) {
    final StringBuffer statsRow = StringBuffer();
    final StringBuffer percentageRow = StringBuffer();

    statsRow.write(
        '<td class="student-name-cell"><strong>${t['achieved_students']}</strong></td>');
    percentageRow.write(
        '<td class="student-name-cell"><strong>${t['percentage']}</strong></td>');

    for (var mainBareme in mainBaremes) {
      final mainBaremeId = mainBareme['id'] as String;
      final hasSubBaremes = mainBareme['hasSubBaremes'] as bool;
      final subBaremes = mainBareme['subBaremes'] as List<dynamic>? ?? [];

      if (hasSubBaremes && subBaremes.isNotEmpty) {
        for (var subBareme in subBaremes) {
          final subBaremeId = subBareme['id'] as String;
          final fullKey = '$mainBaremeId-$subBaremeId';
          final count = sumCriteriaMaxPerBareme[fullKey] ??
              sumCriteriaMaxPerBareme[subBaremeId] ??
              sumCriteriaMaxPerBareme[mainBaremeId] ??
              0;

          statsRow.write('<td><strong>$count</strong></td>');

          final percentage = totalStudents > 0
              ? (count / totalStudents * 100).toStringAsFixed(2)
              : '0.00';
          percentageRow.write(
              '<td class="percentage-cell"><strong>${percentage}%</strong></td>');
        }
      } else {
        final count = sumCriteriaMaxPerBareme[mainBaremeId] ?? 0;
        statsRow.write('<td><strong>$count</strong></td>');

        final percentage = totalStudents > 0
            ? (count / totalStudents * 100).toStringAsFixed(2)
            : '0.00';
        percentageRow.write(
            '<td class="percentage-cell"><strong>${percentage}%</strong></td>');
      }
    }

    return '''
      <tr class="stats-row">${statsRow.toString()}</tr>
      <tr class="percentage-row">${percentageRow.toString()}</tr>
    ''';
  }

  static int _calculateTotalColumns(List<Map<String, dynamic>> mainBaremes) {
    int totalColumns = 1; // Pour la colonne des noms
    for (var mainBareme in mainBaremes) {
      final hasSubBaremes = mainBareme['hasSubBaremes'] as bool;
      final subBaremes = mainBareme['subBaremes'] as List<dynamic>? ?? [];
      totalColumns +=
          hasSubBaremes && subBaremes.isNotEmpty ? subBaremes.length : 1;
    }
    return totalColumns;
  }

  static String _buildFinalTableHTML(
    String headerHTML,
    String studentsRows,
    String statsHTML,
    int totalColumns,
    bool isFrenchInterface,
  ) {
    if (totalColumns <= 1) {
      return '''
      <div class="table-container">
        <div style="text-align: center; padding: 40px; color: #666; font-size: 16px;">
          ${isFrenchInterface ? 'Aucun barème sélectionné pour cette évaluation.' : 'لم يتم تحديد أي معايير لهذا التقييم.'}
        </div>
      </div>
      ''';
    }

    return '''
    <div class="table-container">
      <table class="results-table">
        $headerHTML
        <tbody>
          ${studentsRows.isNotEmpty ? studentsRows : '''
          <tr>
            <td colspan="$totalColumns" style="text-align:center; padding:30px; color:#666;">
              ${isFrenchInterface ? 'Aucune donnée disponible' : 'لا توجد بيانات متاحة'}
            </td>
          </tr>
          '''}
          $statsHTML
        </tbody>
      </table>
    </div>
    ''';
  }

  // ============ MÉTHODES EXISTANTES ============

  static String _buildCoverPageHTML(
    String profName,
    String matiereName,
    String className,
    String schoolName,
    String logoBase64,
    String trimestre,
    String periode,
    String evaluationType,
    Map<String, String> t,
    DateTime now,
    String academicYear,
    String domaine,
    bool isFrenchInterface,
  ) {
    return '''
    <div class="cover-page">
        <div class="cover-header">
            <h1 class="ministry-title">${t['cover_title']}</h1>
            <div class="delegation-title">${t['regional_delegation']}</div>
        </div>
        
        ${logoBase64.isNotEmpty ? '''
        <div class="logo-container">
            <img src="data:image/png;base64,$logoBase64" class="logo" alt="Logo Ministère">
        </div>
        ''' : ''}
        
        <div class="school-info">
            <div class="info-value" style="font-size: 18px;">
                ${t['school']}: <strong>$schoolName</strong>
            </div>
        </div>
        
        <div class="info-grid">
            <div class="info-card">
                <div class="info-icon">👨‍🏫</div>
                <div class="info-content">
                    <div class="info-label">${t['professor']}</div>
                    <div class="info-value">$profName</div>
                </div>
            </div>
            
            <div class="info-card">
                <div class="info-icon">📚</div>
                <div class="info-content">
                     <div class="domaine-title">${isFrenchInterface ? 'Domaine' : 'المجال'}</div>
            <div class="domaine-content">$domaine</div>
                </div>
            </div>
            
            <div class="info-card">
                <div class="info-icon">👥</div>
                <div class="info-content">
                    <div class="info-label">${t['class']}</div>
                    <div class="info-value">$className</div>
                </div>
            </div>
            
            <div class="info-card">
                <div class="info-icon">📅</div>
                <div class="info-content">
                    <div class="info-label">${t['academic_year']}</div>
                    <div class="info-value">$academicYear</div>
                </div>
            </div>
        </div>
        
       
        
        <div class="footer-cover">
            <p>${t['generated_on']}: ${now.day}/${now.month}/${now.year}</p>
        </div>
    </div>
    ''';
  }

  static String _buildEvaluationTablePageHTML(
    String matiereName,
    String className,
    String trimestre,
    Map<String, String> t,
    String tableHTML,
    int totalStudents,
    DateTime now,
    String schoolName,
    bool isFrenchInterface,
    String evaluationType,
  ) {
    return '''
    <div class="table-page">
        <div class="table-header">
            <h2 class="table-main-title">${t['main_title']}</h2>
            <div class="table-subtitle">
                $matiereName - $className - ${t['trimestre']}: ${_getTrimestreDisplay(trimestre, isFrenchInterface)}
            </div>
        </div>
        
        $tableHTML
        
        <div class="summary-section">
            <div class="summary-title">${isFrenchInterface ? 'Résumé' : 'ملخص'}</div>
            <div class="summary-grid">
                <div class="summary-item">
                    <div class="summary-label">${t['total_students']}</div>
                    <div class="summary-value">$totalStudents</div>
                </div>
                <div class="summary-item">
                    <div class="summary-label">${t['generated_on']}</div>
                    <div class="summary-value">${now.day}/${now.month}/${now.year}</div>
                </div>
            </div>
        </div>
        
        <div class="report-footer">
            <p>${isFrenchInterface ? 'Établissement' : 'المدرسة'}: $schoolName</p>
            <p class="no-print">${isFrenchInterface ? 'Page 3' : 'الصفحة 3'}</p>
        </div>
    </div>
  ''';
  }

  static int _arabicComparatorForHTML(String a, String b) {
    const Map<String, int> arabicOrder = {
      'ا': 1,
      'أ': 1,
      'إ': 1,
      'آ': 1,
      'ب': 2,
      'ت': 3,
      'ث': 4,
      'ج': 5,
      'ح': 6,
      'خ': 7,
      'د': 8,
      'ذ': 9,
      'ر': 10,
      'ز': 11,
      'س': 12,
      'ش': 13,
      'ص': 14,
      'ض': 15,
      'ط': 16,
      'ظ': 17,
      'ع': 18,
      'غ': 19,
      'ف': 20,
      'ق': 21,
      'ك': 22,
      'ل': 23,
      'م': 24,
      'ن': 25,
      'ه': 26,
      'و': 27,
      'ي': 28,
      'ى': 28,
      'ة': 26,
      'ؤ': 27,
      'ئ': 28,
      'ء': 1
    };

    final normalizedA = _normalizeArabicHTML(a);
    final normalizedB = _normalizeArabicHTML(b);

    for (int i = 0; i < math.min(normalizedA.length, normalizedB.length); i++) {
      final charA = normalizedA[i];
      final charB = normalizedB[i];
      final orderA = arabicOrder[charA] ?? charA.codeUnitAt(0);
      final orderB = arabicOrder[charB] ?? charB.codeUnitAt(0);
      if (orderA != orderB) return orderA - orderB;
    }
    return normalizedA.length - normalizedB.length;
  }

  static String _normalizeArabicHTML(String text) {
    String normalized = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    final replacements = {
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ؤ': 'و',
      'ئ': 'ي',
      'ة': 'ه',
      'ى': 'ي'
    };
    replacements.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });
    return normalized;
  }

  static String _getDomaineForMatiere(
      String matiereName, bool isFrenchInterface) {
    final matieresArabic = {
      'التواصل الشفوي': 'مجال اللغة العربية',
      'قراءة': 'مجال اللغة العربية',
      'قواعد لغة': 'مجال اللغة العربية',
      'إنتاج كتابي': 'مجال اللغة العربية',
      'انتاج كتابي': 'مجال اللغة العربية',
      'الخط و الإملاء': 'مجال اللغة العربية',
      'رياضيات': 'مجال العلوم والتكنولوجيا',
      'ايقاظ علمي': 'مجال العلوم والتكنولوجيا',
      'التربية التكنولوجية': 'مجال العلوم والتكنولوجيا',
      'تاريخ': 'مجال التنشئة',
      'الجغرافيا': 'مجال التنشئة',
      'التربية المدنية': 'مجال التنشئة',
      'التربية التشكيلية': 'مجال التنشئة',
      'التربية الموسيقية': 'مجال التنشئة',
      'تربية بدنية': 'مجال التنشئة',
      'لغة فرنسية': 'مجال اللغة الفرنسية',
      'فرنسية': 'مجال اللغة الفرنسية',
      'لغة انقليزية': 'مجال اللغة الإنجليزية',
      'انجليزي': 'مجال اللغة الإنجليزية',
    };


    final matieresFrench = {
      'Communication orale': 'Domaine Langue Française',
      'Lecture': 'Domaine Langue Française',
      'Grammaire': 'Domaine Langue Française',
      'Production écrite': 'Domaine Langue Française',
      'Écriture': 'Domaine Langue Française',
      'Dictée': 'Domaine Langue Française',
      'Mathématiques': 'Domaine Sciences et Technologie',
      'Éveil scientifique': 'Domaine Sciences et Technologie',
      'Éducation technologique': 'Domaine Sciences et Technologie',
      'Histoire': 'Domaine Socialisation',
      'Géographie': 'Domaine Socialisation',
      'Éducation civique': 'Domaine Socialisation',
      'Éducation artistique': 'Domaine Socialisation',
      'Éducation musicale': 'Domaine Socialisation',
      'Éducation physique': 'Domaine Socialisation',
      'Français': 'Domaine Langue Française',
      'Langue française': 'Domaine Langue Française',
      'Anglais': 'Domaine Langue Anglaise',
      'Langue anglaise': 'Domaine Langue Anglaise',
    };

    final domaines = isFrenchInterface ? matieresFrench : matieresArabic;
    for (var key in domaines.keys) {
      if (matiereName.contains(key) || key.contains(matiereName)) {
        return domaines[key]!;
      }
    }

    return isFrenchInterface ? 'Domaine Général' : 'المجال العام';
  }

  static String _getTrimestreDisplay(String trimestre, bool isFrenchInterface) {
    final translations = {
      'الأول': isFrenchInterface ? 'Premier' : 'الأول',
      'الثاني': isFrenchInterface ? 'Deuxième' : 'الثاني',
      'الثالث': isFrenchInterface ? 'Troisième' : 'الثالث',
    };
    return translations[trimestre] ?? trimestre;
  }

  static String _getEvaluationTypeDisplay(String type, bool isFrenchInterface) {
    final translations = {
      'تقييم': isFrenchInterface ? 'Évaluation' : 'تقييم',
      'امتحان': isFrenchInterface ? 'Examen' : 'امتحان',
    };
    return translations[type] ?? type;
  }

  static String base64Encode(List<int> bytes) {
    final base64Chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final result = StringBuffer();
    int i = 0;

    while (i < bytes.length) {
      int b1 = bytes[i++] & 0xFF;
      int b2 = i < bytes.length ? bytes[i++] & 0xFF : 0;
      int b3 = i < bytes.length ? bytes[i++] & 0xFF : 0;

      int enc1 = b1 >> 2;
      int enc2 = ((b1 & 3) << 4) | (b2 >> 4);
      int enc3 = ((b2 & 15) << 2) | (b3 >> 6);
      int enc4 = b3 & 63;

      result.write(base64Chars[enc1]);
      result.write(base64Chars[enc2]);
      result.write(i - 1 < bytes.length ? base64Chars[enc3] : '=');
      result.write(i < bytes.length ? base64Chars[enc4] : '=');
    }

    return result.toString();
  }

  static Future<void> _generateAndDownloadPDF(String htmlContent) async {
    try {
      if (kIsWeb) {
        await _downloadHTMLFile(htmlContent);
        return;
      }

      print('Début de la génération PDF...');
      final directory = await getTemporaryDirectory();
      final targetPath = directory.path;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'rapport_complet_$timestamp.pdf';

      final generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
        htmlContent,
        targetPath,
        fileName,
      );

      print('PDF généré: ${generatedPdfFile.path}');
      await OpenFile.open(generatedPdfFile.path);
      print('PDF ouvert avec succès');
    } catch (e) {
      print('Erreur PDF: $e');
      print('Fallback: téléchargement HTML...');
      await _downloadHTMLFile(htmlContent);
    }
  }

static Future<void> _downloadHTMLFile(String htmlContent) async {
  try {
    if (kIsWeb) {
      // Version Web
      final blob = html.Blob(
        [utf8.encode(htmlContent)],
        'text/html; charset=utf-8', // Changement du MIME type
      );

      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute(
          'download',
          'rapport_complet_${DateTime.now().millisecondsSinceEpoch}.html',
        )
        ..click();

      Future.delayed(const Duration(seconds: 2), () {
        html.Url.revokeObjectUrl(url);
      });
      
      print('✅ Fichier HTML téléchargé avec succès sur le web');
    } else {
      // Version Mobile/Desktop (Android, iOS, Windows, macOS, Linux)
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/rapport_complet_${DateTime.now().millisecondsSinceEpoch}.html';
      
      // Utiliser XFile pour écrire le fichier (pas de File)
      final xFile = XFile.fromData(
        Uint8List.fromList(utf8.encode(htmlContent)),
        name: 'rapport_complet_${DateTime.now().millisecondsSinceEpoch}.html',
        mimeType: 'text/html',
      );
      
      // Sauvegarder le fichier
      await xFile.saveTo(filePath);
      
      // Ouvrir le fichier
      await OpenFile.open(filePath);
      
      print('✅ Fichier HTML généré avec succès sur mobile/desktop: $filePath');
    }
  } catch (e) {
    print('❌ Erreur génération fichier: $e');
    rethrow;
  }
}
  static Future<Uint8List> _loadImage(String path) async {
    try {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } catch (e) {
      print('Erreur chargement image $path: $e');
      return Uint8List(0);
    }
  }
}
