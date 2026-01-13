import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HTMLReportGenerator {
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
    // Paramètres existants
    String trimestre = 'الأول',
    String periode = '',
    String evaluationType = 'تقييم',
    // Nouveaux paramètres optionnels
    String selectedClass = '',
    List<Map<String, dynamic>> criteria = const [],
    String performanceAttendue = '', // NOUVEAU: Performance attendue
  }) async {
    try {
      // Charger le logo en base64
      String logoBase64 = "";
      try {
        final logoBytes = await _loadImage('lib/assets/icons/me/ministere.png');
        if (logoBytes.isNotEmpty) {
          logoBase64 = base64Encode(logoBytes);
        }
      } catch (e) {
        print('Logo non trouvé: $e');
      }

      // Générer le contenu HTML complet avec performance attendue
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
        performanceAttendue: performanceAttendue, // NOUVEAU
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

  // Méthode pour générer le tableau des critères (similaire à _buildCriteriaHTML mais sans la page complète)
  static String _buildCriteriaTableHTML({
    required List<Map<String, dynamic>> criteria,
    required bool isFrenchInterface,
  }) {
    if (criteria.isEmpty) {
      return '';
    }

    String rows = '';
    int totalIndicators = 0;

    // Trier les critères
    final sortedCriteria = List<Map<String, dynamic>>.from(criteria);

    if (!isFrenchInterface) {
      // Tri arabe
      sortedCriteria.sort((a, b) {
        final nameA = a['name'] as String;
        final nameB = b['name'] as String;
        return _arabicComparatorForHTML(nameA, nameB);
      });
    } else {
      // Tri français
      sortedCriteria.sort((a, b) {
        return (a['name'] as String).compareTo(b['name'] as String);
      });
    }

    for (int i = 0; i < sortedCriteria.length; i++) {
      final critere = sortedCriteria[i];
      final name = critere['name']?.toString() ?? 'معيار ${i + 1}';
      final domaine = critere['domaine']?.toString() ?? '';
      final indicators = critere['indicators'] as List<dynamic>? ?? [];
      totalIndicators += indicators.length;

      // Trier les indicateurs
      final List<String> indicatorStrings =
          indicators.map((e) => e.toString()).toList();

      if (!isFrenchInterface) {
        indicatorStrings.sort(_arabicComparatorForHTML);
      } else {
        indicatorStrings.sort();
      }

      // Ligne principale du critère
      rows += '''
    <tr class="criteria-main-row">
        <td class="criteria-number">${i + 1}</td>
        <td colspan="2">
            <span class="criteria-title">$name</span>
            ${domaine.isNotEmpty ? '<span class="domain-badge">${isFrenchInterface ? 'Domaine' : 'المجال'}: $domaine</span>' : ''}
        </td>
    </tr>
    ''';

      // Lignes des indicateurs
      for (int j = 0; j < indicatorStrings.length; j++) {
        final indicator = indicatorStrings[j];
        rows += '''
      <tr class="indicator-row">
          <td class="indicator-number">${i + 1}.${j + 1}</td>
          <td colspan="2">$indicator</td>
      </tr>
      ''';
      }
    }

    return '''
    <div style="margin-top: 20px;">
      <div style="margin-bottom: 10px; color: #666; font-size: 14px;">
        ${isFrenchInterface ? 'Total des critères' : 'مجموع المعايير'}: ${sortedCriteria.length} | 
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
              $rows
          </tbody>
      </table>
    </div>
  ''';
  }

// NOUVELLE MÉTHODE: Page combinée des données de période et des critères
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
    // Générer le contenu HTML des critères
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
    <h3 style="color: var(--primary-color); margin-bottom: 20px; font-size: 20px;">
        ${isFrenchInterface ? 'Détails de la période' : 'تفاصيل الفترة'}
    </h3>
    
    <div class="period-grid" style="display: flex; flex-direction: row; flex-wrap: wrap; gap: 20px;">
        <div class="period-card" style="flex: 1; min-width: 200px;">
            <div style="display: flex; align-items: center; gap: 15px;">
                <div class="period-icon" style="background: var(--primary-color); width: 50px; height: 50px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 24px;">
                    📅
                </div>
                <div>
                    <div class="period-label">${t['trimestre']}</div>
                    <div class="period-value">${_getTrimestreDisplay(trimestre, isFrenchInterface)}</div>
                </div>
            </div>
        </div>
        
        <div class="period-card" style="flex: 1; min-width: 200px;">
            <div style="display: flex; align-items: center; gap: 15px;">
                <div class="period-icon" style="background: var(--secondary-color); width: 50px; height: 50px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 24px;">
                    📚
                </div>
                <div>
                    <div class="period-label">${t['periode']}</div>
                    <div class="period-value">
                        ${periode.isNotEmpty ? periode : (isFrenchInterface ? 'Non spécifié' : 'غير محدد')}
                    </div>
                </div>
            </div>
        </div>
        
        <div class="period-card" style="flex: 1; min-width: 200px;">
            <div style="display: flex; align-items: center; gap: 15px;">
                <div class="period-icon" style="background: var(--accent-color); width: 50px; height: 50px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 24px;">
                    📝
                </div>
                <div>
                    <div class="period-label">${t['evaluation_type']}</div>
                    <div class="period-value">
                        ${_getEvaluationTypeDisplay(evaluationType, isFrenchInterface)}
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
            <!-- Section Performance Attendue -->
            ${performanceAttendue.isNotEmpty ? '''
            <div class="performance-section">
                <h3 class="performance-title">
                    ${isFrenchInterface ? 'Performance Attendue' : 'الأداء المنتظر'}
                </h3>
                <div class="performance-content">
                    ${performanceAttendue}
                </div>
            </div>
            ''' : ''}
            
            
        </div>
        
        <!-- Section des critères d'évaluation (si disponibles) -->
        ${criteria.isNotEmpty ? '''
        <div class="criteria-section">
            <h3 style="color: var(--secondary-color); margin-bottom: 20px; font-size: 20px;">
                ${t['evaluation_criteria']}
            </h3>
            
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
    // Nouveau paramètre optionnel
    required List<Map<String, dynamic>> criteria,
    required String performanceAttendue, // NOUVEAU
  }) {
    final direction = isFrenchInterface ? 'ltr' : 'rtl';
    final textAlign = isFrenchInterface ? 'left' : 'right';

    // Traductions existantes
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
      // Nouvelles traductions pour les critères
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

    // Date et année scolaire (existant)
    final now = DateTime.now();
    final currentDate = '${now.day}/${now.month}/${now.year}';
    final academicYear = '${now.year}/${now.year + 1}';

    // Déterminer le domaine de la matière (existant)
    final domaine = _getDomaineForMatiere(matiereName, isFrenchInterface);

    // Générer le tableau principal (existant)
    final tableHTML = _buildTableHTML(
      baremes: baremes,
      students: students,
      sumCriteriaMaxPerBareme: sumCriteriaMaxPerBareme,
      totalStudents: totalStudents,
      isFrenchInterface: isFrenchInterface,
      t: t,
    );

    // MODIFICATION: Combiner les données de période et les critères sur une seule page
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
        /* STYLES EXISTANTS - NE PAS MODIFIER */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        :root {
            --primary-color: #075260;
            --secondary-color: #2E7D32;
            --accent-color: #FF9800;
            --light-bg: #f8f9fa;
            --white: #ffffff;
            --text-color: #333333;
            --border-radius: 8px;
            --box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
            --transition: all 0.3s ease;
        }
        
        body {
            font-family: ${isFrenchInterface ? 'Arial, Helvetica, sans-serif' : "'Noto Sans Arabic', 'Segoe UI', Tahoma, sans-serif"};
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            color: var(--text-color);
            direction: $direction;
            line-height: 1.6;
            min-height: 100vh;
            padding: 20px;
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
            padding: 40px;
            margin-bottom: 40px;
            position: relative;
            overflow: hidden;
            min-height: 90vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
        }
        
        .cover-page::before {
            content: '';
            position: absolute;
            top: 0;
            ${isFrenchInterface ? 'left' : 'right'}: 0;
            width: 100%;
            height: 5px;
            background: linear-gradient(90deg, var(--primary-color), var(--secondary-color));
        }
        
        .cover-header {
            text-align: center;
            margin-bottom: 40px;
            border-bottom: 2px solid var(--primary-color);
            padding-bottom: 20px;
        }
        
        .ministry-title {
            color: var(--primary-color);
            font-size: 24px;
            font-weight: bold;
            margin-bottom: 10px;
            line-height: 1.3;
        }
        
        .delegation-title {
            color: var(--secondary-color);
            font-size: 18px;
            font-weight: 600;
            margin-bottom: 15px;
        }
        
        .logo-container {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 20px;
            margin: 30px 0;
        }
        
        .logo {
            height: 100px;
            max-width: 200px;
            object-fit: contain;
        }
        
        .school-info {
            background: var(--light-bg);
            border-radius: var(--border-radius);
            padding: 25px;
            margin: 30px 0;
            border: 2px solid var(--primary-color);
            position: relative;
        }
        
        .school-info::before {
            content: '🏫';
            position: absolute;
            top: -15px;
            ${isFrenchInterface ? 'left' : 'right'}: 20px;
            background: var(--white);
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 20px;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        
        .info-card {
            background: var(--white);
            border-radius: var(--border-radius);
            padding: 20px;
            border: 1px solid #e0e0e0;
            transition: var(--transition);
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .info-card:hover {
            transform: translateY(-5px);
            box-shadow: var(--box-shadow);
            border-color: var(--primary-color);
        }
        
        .info-icon {
            width: 50px;
            height: 50px;
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 20px;
            flex-shrink: 0;
        }
        
        .info-content {
            flex: 1;
        }
        
        .info-label {
            color: #666;
            font-size: 14px;
            margin-bottom: 5px;
        }
        
        .info-value {
            color: var(--text-color);
            font-size: 16px;
            font-weight: 600;
        }
        
        .domaine-section {
            background: linear-gradient(135deg, var(--secondary-color), #4CAF50);
            color: white;
            padding: 20px;
            border-radius: var(--border-radius);
            margin: 30px 0;
            position: relative;
            overflow: hidden;
        }
        
        .domaine-section::before {
            content: '';
            position: absolute;
            top: 0;
            ${isFrenchInterface ? 'left' : 'right'}: 0;
            width: 100%;
            height: 100%;
            background: rgba(255, 255, 255, 0.1);
            clip-path: circle(30% at 10% 10%);
        }
        
        .domaine-title {
            font-size: 22px;
            font-weight: bold;
            margin-bottom: 15px;
            position: relative;
            z-index: 1;
        }
        
        .domaine-content {
            font-size: 18px;
            font-weight: 500;
            position: relative;
            z-index: 1;
        }
        
        .footer-cover {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #e0e0e0;
            color: #666;
            font-size: 14px;
        }
        
        /* Page combinée des données de période et des critères */
        .combined-page {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--box-shadow);
            padding: 30px;
            margin-top: 40px;
            page-break-before: always;
        }
        
        .section-header {
            background: linear-gradient(135deg, var(--primary-color), #0a6b7e);
            color: white;
            padding: 20px;
            border-radius: var(--border-radius) var(--border-radius) 0 0;
            margin-bottom: 20px;
        }
        
        .section-title {
            font-size: 24px;
            font-weight: bold;
            text-align: center;
            margin-bottom: 10px;
        }
        
        .section-subtitle {
            text-align: center;
            opacity: 0.9;
            font-size: 16px;
        }
        
        .period-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin: 40px 0;
        }
        
        .period-card {
            background: var(--light-bg);
            border-radius: var(--border-radius);
            padding: 25px;
            transition: var(--transition);
            border: 2px solid transparent;
        }
        
        .period-card:hover {
            transform: translateY(-5px);
            box-shadow: var(--box-shadow);
        }
        
        .period-card:nth-child(1) {
            border-color: var(--primary-color);
        }
        
        .period-card:nth-child(2) {
            border-color: var(--secondary-color);
        }
        
        .period-card:nth-child(3) {
            border-color: var(--accent-color);
        }
        
        .period-icon {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            margin-bottom: 15px;
        }
        
        .period-icon:nth-child(1) {
            background: var(--primary-color);
            color: white;
        }
        
        .period-icon:nth-child(2) {
            background: var(--secondary-color);
            color: white;
        }
        
        .period-icon:nth-child(3) {
            background: var(--accent-color);
            color: white;
        }
        
        .period-label {
            color: #666;
            font-size: 14px;
            margin-bottom: 5px;
        }
        
        .period-value {
            color: var(--text-color);
            font-size: 18px;
            font-weight: 600;
        }
        
        /* Section Performance Attendue */
        .performance-section {
            margin: 30px 0;
            padding: 20px;
            background: #E8F5E9;
            border-radius: var(--border-radius);
            border-left: 4px solid #4CAF50;
        }
        
        .performance-title {
            color: #2E7D32;
            font-size: 20px;
            font-weight: bold;
            margin-bottom: 15px;
        }
        
        .performance-content {
            color: #333;
            line-height: 1.6;
            white-space: pre-line;
            font-size: 16px;
        }
        
        /* Section des critères */
        .criteria-section {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 2px solid var(--secondary-color);
        }
        
        .criteria-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
            margin: 20px 0;
        }
        
        .criteria-table th {
            background: #4CAF50;
            color: white;
            padding: 12px 8px;
            text-align: center;
            font-weight: 600;
            border: 1px solid #ddd;
        }
        
        .criteria-table td {
            padding: 10px 8px;
            border: 1px solid #ddd;
            vertical-align: top;
        }
        
        .criteria-main-row {
            background: #f1f8e9 !important;
            font-weight: bold;
        }
        
        .indicator-row {
            background: #f9f9f9 !important;
        }
        
        .criteria-number {
            width: 60px;
            text-align: center;
            font-weight: bold;
            color: #2E7D32;
            background: #f1f8e9;
        }
        
        .indicator-number {
            width: 80px;
            text-align: center;
            color: #666;
            background: #f9f9f9;
        }
        
        .domain-badge {
            display: inline-block;
            padding: 4px 10px;
            background: #E8F5E9;
            color: #2E7D32;
            border-radius: 15px;
            font-size: 12px;
            margin-${isFrenchInterface ? 'left' : 'right'}: 10px;
            border: 1px solid #C8E6C9;
        }
        
        .criteria-title {
            font-weight: bold;
            color: #2E7D32;
        }
        
        /* Page du tableau principal */
        .table-page {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--box-shadow);
            padding: 30px;
            margin-top: 40px;
            page-break-before: always;
        }
        
        .table-header {
            background: linear-gradient(135deg, var(--primary-color), #0a6b7e);
            color: white;
            padding: 20px;
            border-radius: var(--border-radius) var(--border-radius) 0 0;
            margin-bottom: 20px;
        }
        
        .table-main-title {
            font-size: 24px;
            font-weight: bold;
            text-align: center;
            margin-bottom: 10px;
        }
        
        .table-subtitle {
            text-align: center;
            opacity: 0.9;
            font-size: 16px;
        }
        
        .table-container {
            overflow-x: auto;
            margin: 20px 0;
            border-radius: var(--border-radius);
            border: 1px solid #e0e0e0;
        }
        
        .results-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }
        
        .results-table th {
            background: var(--primary-color);
            color: white;
            padding: 12px 8px;
            text-align: center;
            font-weight: 600;
            border: 1px solid #ddd;
            white-space: nowrap;
            position: sticky;
            top: 0;
            z-index: 10;
        }
        
        .results-table td {
            padding: 10px 8px;
            text-align: center;
            border: 1px solid #ddd;
            vertical-align: middle;
        }
        
        .student-name-cell {
            background: var(--light-bg);
            font-weight: 600;
            text-align: ${isFrenchInterface ? 'left' : 'right'};
            min-width: 150px;
            position: sticky;
            ${isFrenchInterface ? 'left' : 'right'}: 0;
            z-index: 5;
        }
        
        .mark-excellent { background-color: #d4edda; color: #155724; font-weight: bold; }
        .mark-good { background-color: #fff3cd; color: #856404; font-weight: bold; }
        .mark-average { background-color: #ffeaa7; color: #856404; }
        .mark-poor { background-color: #f8d7da; color: #721c24; }
        
        .stats-row {
            background: #e3f2fd !important;
            font-weight: bold;
        }
        /* Styles pour la hiérarchie des barèmes */
.main-bareme-header {
  background: #075260 !important;
  color: white !important;
  font-weight: bold !important;
  text-align: center !important;
  border-bottom: 2px solid #0a6b7e !important;
}

.sub-bareme-header {
  background: #0a6b7e !important;
  color: white !important;
  font-weight: normal !important;
  font-size: 12px !important;
  border-top: none !important;
}

/* Bordures pour séparer les groupes de barèmes */
.results-table th:not(.student-name-cell) {
  border-right: 1px solid rgba(255, 255, 255, 0.3) !important;
}

.results-table th:last-child {
  border-right: none !important;
}

/
        .percentage-row {
            background: #f3e5f5 !important;
            font-weight: bold;
        }
        
        .percentage-high { color: #2E7D32; }
        .percentage-medium { color: #FF9800; }
        .percentage-low { color: #D32F2F; }
        
        .summary-section {
            background: var(--light-bg);
            padding: 20px;
            border-radius: var(--border-radius);
            margin-top: 30px;
        }
        
        .summary-title {
            color: var(--primary-color);
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 15px;
        }
        
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }
        
        .summary-item {
            background: white;
            padding: 15px;
            border-radius: var(--border-radius);
            border-left: 4px solid var(--primary-color);
        }
        
        .summary-label {
            color: #666;
            font-size: 14px;
            margin-bottom: 5px;
        }
        
        .summary-value {
            color: var(--text-color);
            font-size: 18px;
            font-weight: bold;
        }
        
        .report-footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #e0e0e0;
            color: #666;
            font-size: 14px;
        }
        
        /* STYLES D'IMPRESSION EXISTANTS */
        
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
        // Script existant pour les couleurs
        document.addEventListener('DOMContentLoaded', function() {
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

  // ============ NOUVELLES MÉTHODES POUR LA RÉORGANISATION ============

  // Page des données de période

  static String _buildPeriodDataPageHTML(
    String trimestre,
    String periode,
    String evaluationType,
    Map<String, String> t,
    bool isFrenchInterface,
    String matiereName,
    String className,
    String profName,
    String performanceAttendue, // NOUVEAU
  ) {
    return '''
    <div class="period-page">
        <!-- ... contenu existant ... -->
        
        <!-- NOUVEAU: Section Performance Attendue -->
        ${performanceAttendue.isNotEmpty ? '''
        <div class="performance-section">
            <h3 style="color: var(--secondary-color); margin-top: 20px;">
                ${isFrenchInterface ? 'Performance Attendue' : 'الأداء المنتظر'}
            </h3>
            <div style="background: #F1F8E9; padding: 15px; border-radius: 8px; margin-top: 10px; border: 1px solid #C8E6C9;">
                <p style="color: #333; line-height: 1.6; white-space: pre-line;">
                    ${performanceAttendue}
                </p>
            </div>
        </div>
        ''' : ''}
        
        <div class="report-footer">
            <p class="no-print">${isFrenchInterface ? 'Page 2' : 'الصفحة 2'}</p>
        </div>
    </div>
  ''';
  }

  // Page du tableau d'évaluation
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
    // Déterminer le numéro de page
    final pageNumber = isFrenchInterface ? 'Page 4' : 'الصفحة 4';

    return '''
    <div class="table-page">
        <div class="table-header">
            <h2 class="table-main-title">${t['main_title']}</h2>
            <div class="table-subtitle">
                $matiereName - $className - ${t['trimestre']}: ${_getTrimestreDisplay(trimestre, isFrenchInterface)}
            </div>
        </div>
        
        $tableHTML
        
        
        <div class="report-footer">
            <p>${isFrenchInterface ? 'Établissement' : 'المدرسة'}: $schoolName</p>
            <p class="no-print">$pageNumber</p>
        </div>
    </div>
  ''';
  }

  // ============ MÉTHODES EXISTANTES (inchangées) ============

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
            <div class="info-value" style="text-align: center; font-size: 20px;">
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
                    <div class="info-label">${t['subject']}</div>
                    <div class="info-value">$domaine</div>
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
        
       
    </div>
    ''';
  }

  static String _buildCriteriaHTML({
    required List<Map<String, dynamic>> criteria,
    required Map<String, String> t,
    required bool isFrenchInterface,
  }) {
    if (criteria.isEmpty) {
      return '';
    }

    String rows = '';
    int totalIndicators = 0;

    // Trier les critères
    final sortedCriteria = List<Map<String, dynamic>>.from(criteria);

    if (!isFrenchInterface) {
      // Tri arabe
      sortedCriteria.sort((a, b) {
        final nameA = a['name'] as String;
        final nameB = b['name'] as String;
        return _arabicComparatorForHTML(nameA, nameB);
      });
    } else {
      // Tri français
      sortedCriteria.sort((a, b) {
        return (a['name'] as String).compareTo(b['name'] as String);
      });
    }

    for (int i = 0; i < sortedCriteria.length; i++) {
      final critere = sortedCriteria[i];
      final name = critere['name']?.toString() ?? '${t['criteria']} ${i + 1}';
      final domaine = critere['domaine']?.toString() ?? '';
      final indicators = critere['indicators'] as List<dynamic>? ?? [];
      totalIndicators += indicators.length;

      // Trier les indicateurs
      final List<String> indicatorStrings =
          indicators.map((e) => e.toString()).toList();

      if (!isFrenchInterface) {
        indicatorStrings.sort(_arabicComparatorForHTML);
      } else {
        indicatorStrings.sort();
      }

      // Ligne principale du critère
      rows += '''
      <tr class="criteria-main-row">
          <td class="criteria-number">${i + 1}</td>
          <td colspan="2">
              <span class="criteria-title">$name</span>
              ${domaine.isNotEmpty ? '<span class="domain-badge">${t['domain']}: $domaine</span>' : ''}
          </td>
      </tr>
      ''';

      // Lignes des indicateurs
      for (int j = 0; j < indicatorStrings.length; j++) {
        final indicator = indicatorStrings[j];
        rows += '''
        <tr class="indicator-row">
            <td class="indicator-number">${i + 1}.${j + 1}</td>
            <td colspan="2">$indicator</td>
        </tr>
        ''';
      }
    }

    return '''
      <div class="criteria-page">
          <div class="criteria-header">
              <h2 class="table-main-title">${t['evaluation_criteria']}</h2>
              <div class="table-subtitle">
                  ${t['total_criteria']}: ${sortedCriteria.length} | ${t['total_indicators']}: $totalIndicators
              </div>
          </div>
          
          <table class="criteria-table">
              <thead>
                  <tr>
                      <th style="width: 80px;">#</th>
                      <th colspan="2">${t['criteria']} / ${t['indicators']}</th>
                  </tr>
              </thead>
              <tbody>
                  $rows
              </tbody>
          </table>
          
          <div class="report-footer">
              <p class="no-print">${isFrenchInterface ? 'Page 3' : 'الصفحة 3'}</p>
          </div>
      </div>
    ''';
  }

  // Comparateur arabe pour HTML
  static int _arabicComparatorForHTML(String a, String b) {
    // Table d'ordre des lettres arabes
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

    // Normaliser
    final normalizedA = _normalizeArabicHTML(a);
    final normalizedB = _normalizeArabicHTML(b);

    for (int i = 0; i < math.min(normalizedA.length, normalizedB.length); i++) {
      final charA = normalizedA[i];
      final charB = normalizedB[i];

      final orderA = arabicOrder[charA] ?? charA.codeUnitAt(0);
      final orderB = arabicOrder[charB] ?? charB.codeUnitAt(0);

      if (orderA != orderB) {
        return orderA - orderB;
      }
    }

    return normalizedA.length - normalizedB.length;
  }

  static String _normalizeArabicHTML(String text) {
    // Supprimer les diacritiques
    String normalized = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

    // Normaliser les formes
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

static String _buildTableHTML({
  required List<dynamic> baremes,
  required List<dynamic> students,
  required Map<String, int> sumCriteriaMaxPerBareme,
  required int totalStudents,
  required bool isFrenchInterface,
  required Map<String, String> t,
}) {
  // Étape 1: Organiser les barèmes par hiérarchie
  final List<Map<String, dynamic>> mainBaremes = [];
  
  // D'abord, extraire tous les barèmes parents potentiels des noms des sous-barèmes
  final Map<String, String> parentNamesFromSubBaremes = {};
  
  for (var bareme in baremes) {
    final baremeId = bareme['id'].toString();
    final baremeValue = bareme['value']?.toString() ?? '';
    final parentBaremeId = bareme['parentBaremeId']?.toString();
    
    if (parentBaremeId != null && parentBaremeId.isNotEmpty) {
      // C'est un sous-barème - extraire le nom du parent
      // Rechercher le nom du parent dans le nom du sous-barème
      // Exemple: "مع 3.ا" -> parent = "مع 3"
      String parentName = _extractParentNameFromSubBareme(baremeValue);
      if (parentName.isNotEmpty) {
        parentNamesFromSubBaremes[parentBaremeId] = parentName;
      }
    }
  }
  
  // Maintenant organiser les barèmes
  for (var bareme in baremes) {
    final baremeId = bareme['id'].toString();
    final baremeValue = bareme['value']?.toString() ?? '';
    final parentBaremeId = bareme['parentBaremeId']?.toString();
    
    if (parentBaremeId == null || parentBaremeId.isEmpty) {
      // Barème principal
      final existingIndex = mainBaremes.indexWhere((b) => b['id'] == baremeId);
      if (existingIndex == -1) {
        mainBaremes.add({
          'id': baremeId,
          'value': baremeValue,
          'hasSubBaremes': false,
          'subBaremes': [],
          'isVirtual': false,
        });
      }
    } else {
      // Sous-barème - trouver ou créer son parent
      final parentIndex = mainBaremes.indexWhere((b) => b['id'] == parentBaremeId);
      
      String parentName = baremeValue;
      // Essayer d'extraire le nom du parent
      parentName = _extractParentNameFromSubBareme(baremeValue);
      if (parentName.isEmpty) {
        // Si impossible à extraire, utiliser le nom du sous-barème sans la lettre
        parentName = _removeSubBaremeLetter(baremeValue);
      }
      
      // Utiliser le nom extrait des sous-barèmes s'il existe
      if (parentNamesFromSubBaremes.containsKey(parentBaremeId)) {
        parentName = parentNamesFromSubBaremes[parentBaremeId]!;
      }
      
      if (parentIndex != -1) {
        // Parent existe déjà
        mainBaremes[parentIndex]['hasSubBaremes'] = true;
        if (!mainBaremes[parentIndex].containsKey('subBaremes')) {
          mainBaremes[parentIndex]['subBaremes'] = [];
        }
        
        (mainBaremes[parentIndex]['subBaremes'] as List).add({
          'id': baremeId,
          'value': baremeValue,
        });
      } else {
        // Créer un nouveau parent
        mainBaremes.add({
          'id': parentBaremeId,
          'value': parentName,
          'hasSubBaremes': true,
          'subBaremes': [{
            'id': baremeId,
            'value': baremeValue,
          }],
          'isVirtual': true,
        });
      }
    }
  }

  // ============ TRI DES BARÈMES ============
  print('=== DÉBUT DU TRI DES BARÈMES ===');
  print('Nombre de barèmes principaux avant tri: ${mainBaremes.length}');
  
  // Avant le tri
  print('--- Avant tri des barèmes principaux ---');
  for (var i = 0; i < mainBaremes.length; i++) {
    final bareme = mainBaremes[i];
    print('Barème ${i + 1}: ${bareme['value']} (ID: ${bareme['id']})');
    
    if (bareme['hasSubBaremes'] as bool) {
      final subBaremes = bareme['subBaremes'] as List<dynamic>;
      print('  Nombre de sous-barèmes: ${subBaremes.length}');
      for (var j = 0; j < subBaremes.length; j++) {
        print('    Sous-barème ${j + 1}: ${subBaremes[j]['value']}');
      }
    }
  }

  // Trier les barèmes principaux alphabétiquement
  mainBaremes.sort((a, b) {
    String nameA = a['value'] as String;
    String nameB = b['value'] as String;
    
    // Normaliser les noms pour le tri
    nameA = _normalizeForSorting(nameA);
    nameB = _normalizeForSorting(nameB);
    
    if (!isFrenchInterface) {
      // Tri arabe
      return _arabicComparatorForHTML(nameA, nameB);
    } else {
      // Tri français
      return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    }
  });

  print('--- Après tri des barèmes principaux ---');
  for (var i = 0; i < mainBaremes.length; i++) {
    final bareme = mainBaremes[i];
    print('Barème ${i + 1}: ${bareme['value']} (ID: ${bareme['id']})');
  }

  // Trier les sous-barèmes à l'intérieur de chaque barème principal
  for (var mainBareme in mainBaremes) {
    if (mainBareme['hasSubBaremes'] as bool) {
      final subBaremes = mainBareme['subBaremes'] as List<dynamic>;
      if (subBaremes.isNotEmpty) {
        print('--- Tri des sous-barèmes pour ${mainBareme['value']} ---');
        print('Avant tri:');
        for (var sub in subBaremes) {
          print('  ${sub['value']}');
        }
        
        subBaremes.sort((a, b) {
          String nameA = a['value'] as String;
          String nameB = b['value'] as String;
          
          // Nettoyer les noms pour enlever le préfixe parent
          String cleanNameA = _cleanSubBaremeNameForSorting(nameA, mainBareme['value'] as String);
          String cleanNameB = _cleanSubBaremeNameForSorting(nameB, mainBareme['value'] as String);
          
          // Normaliser pour le tri
          nameA = _normalizeForSorting(cleanNameA.isNotEmpty ? cleanNameA : nameA);
          nameB = _normalizeForSorting(cleanNameB.isNotEmpty ? cleanNameB : nameB);
          
          if (!isFrenchInterface) {
            // Tri arabe pour les sous-barèmes
            // Si ce sont des lettres arabes (ا, ب, ج, ...)
            if (_isArabicLetterOnly(nameA) && _isArabicLetterOnly(nameB)) {
              // Trier par ordre alphabétique arabe
              return _compareArabicLetters(nameA, nameB);
            } else {
              return _arabicComparatorForHTML(nameA, nameB);
            }
          } else {
            // Tri français pour les sous-barèmes
            // Si ce sont des lettres latines (a, b, c, ...)
            if (_isLatinLetterOnly(nameA) && _isLatinLetterOnly(nameB)) {
              return nameA.toLowerCase().compareTo(nameB.toLowerCase());
            } else {
              return nameA.toLowerCase().compareTo(nameB.toLowerCase());
            }
          }
        });
        
        print('Après tri:');
        for (var sub in subBaremes) {
          print('  ${sub['value']}');
        }
        
        // Mettre à jour la liste triée
        mainBareme['subBaremes'] = subBaremes;
      }
    }
  }
  print('=== FIN DU TRI DES BARÈMES ===');
  // ============ FIN DU TRI ============

  // Étape 2: Construire l'en-tête hiérarchique
  String headerHTML = '';
  String mainHeaderRow = '';
  String subHeaderRow = '';
  
  // Colonne pour les noms des étudiants
  mainHeaderRow += '<th rowspan="2" class="student-name-cell">${t['student_name']}</th>';
  
  for (var mainBareme in mainBaremes) {
    final mainBaremeId = mainBareme['id'] as String;
    final mainBaremeValue = mainBareme['value'] as String;
    final hasSubBaremes = mainBareme['hasSubBaremes'] as bool;
    final subBaremes = mainBareme['subBaremes'] as List<dynamic>? ?? [];
    final isVirtual = mainBareme['isVirtual'] as bool? ?? false;
    
    if (hasSubBaremes && subBaremes.isNotEmpty) {
      // Barème avec sous-barèmes
      final colspan = subBaremes.length;
      mainHeaderRow += '''
        <th colspan="$colspan" style="text-align: center; vertical-align: bottom;" class="main-bareme-header">
          $mainBaremeValue
        </th>
      ''';
      
      // Ajouter les sous-en-têtes
      for (var subBareme in subBaremes) {
        final subValue = subBareme['value'] as String;
        final cleanSubValue = _cleanSubBaremeName(subValue, mainBaremeValue);
        subHeaderRow += '''
          <th style="font-size: 12px; font-weight: normal; vertical-align: bottom;" class="sub-bareme-header">
            $cleanSubValue
          </th>
        ''';
      }
    } else {
      // Barème sans sous-barèmes
      mainHeaderRow += '''
        <th colspan="1" style="vertical-align: bottom;" class="main-bareme-header">
          $mainBaremeValue
        </th>
      ''';
      // Ajouter une colonne vide dans la ligne des sous-en-têtes
      subHeaderRow += '<th></th>';
    }
  }

  // Construire l'en-tête HTML complet
  if (subHeaderRow.contains('sub-bareme-header')) {
    // Avec sous-barèmes - deux lignes d'en-tête
    headerHTML = '''
      <thead>
        <tr>
          $mainHeaderRow
        </tr>
        <tr>
          $subHeaderRow
        </tr>
      </thead>
    ''';
  } else {
    // Sans sous-barèmes - une seule ligne d'en-tête
    headerHTML = '''
      <thead>
        <tr>
          <th class="student-name-cell">${t['student_name']}</th>
          ${mainBaremes.map((b) => '''
            <th class="main-bareme-header">${b['value']}</th>
          ''').join('')}
        </tr>
      </thead>
    ''';
  }

  // Étape 3: Construire les lignes des étudiants
  print('=== TRI DES ÉTUDIANTS ===');
  
  // Trier les étudiants par ordre alphabétique
  final List<dynamic> sortedStudents = List.from(students);
  sortedStudents.sort((a, b) {
    final nameA = a['name']?.toString() ?? '';
    final nameB = b['name']?.toString() ?? '';
    
    if (!isFrenchInterface) {
      // Tri arabe pour les noms
      return _arabicComparatorForHTML(nameA, nameB);
    } else {
      // Tri français pour les noms
      return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    }
  });
  
  print('Nombre d\'étudiants: ${sortedStudents.length}');
  print('--- Étudiants triés ---');
  for (var i = 0; i < math.min(5, sortedStudents.length); i++) {
    print('${i + 1}: ${sortedStudents[i]['name']}');
  }
  if (sortedStudents.length > 5) {
    print('... et ${sortedStudents.length - 5} autres');
  }
  
  String studentsRows = '';
  
  for (var student in sortedStudents) {
    String studentRow = '<tr>';
    
    // Colonne nom de l'étudiant
    studentRow += '<td class="student-name-cell">${student['name']}</td>';
    
    // Cellules des notes
    for (var mainBareme in mainBaremes) {
      final mainBaremeId = mainBareme['id'] as String;
      final hasSubBaremes = mainBareme['hasSubBaremes'] as bool;
      final subBaremes = mainBareme['subBaremes'] as List<dynamic>? ?? [];
      
      if (hasSubBaremes && subBaremes.isNotEmpty) {
        // Barème avec sous-barèmes
        for (var subBareme in subBaremes) {
          final subBaremeId = subBareme['id'] as String;
          final fullKey = '$mainBaremeId-$subBaremeId';
          
          // Chercher la note dans différentes clés possibles
          String mark = '( - - - )';
          final studentBaremes = student['baremes'] as Map<String, dynamic>? ?? {};
          
          if (studentBaremes.containsKey(fullKey)) {
            mark = studentBaremes[fullKey]?.toString() ?? '( - - - )';
          } else if (studentBaremes.containsKey(subBaremeId)) {
            mark = studentBaremes[subBaremeId]?.toString() ?? '( - - - )';
          } else if (studentBaremes.containsKey(mainBaremeId)) {
            mark = studentBaremes[mainBaremeId]?.toString() ?? '( - - - )';
          }
          
          studentRow += '<td class="mark-cell">$mark</td>';
        }
      } else {
        // Barème principal simple
        final studentBaremes = student['baremes'] as Map<String, dynamic>? ?? {};
        final mark = studentBaremes[mainBaremeId]?.toString() ?? '( - - - )';
        studentRow += '<td class="mark-cell">$mark</td>';
      }
    }
    
    studentRow += '</tr>';
    studentsRows += studentRow;
  }

  // Étape 4: Construire les lignes de statistiques
  String statsRow = '';
  String percentageRow = '';
  
  // Colonne label
  statsRow += '<td class="student-name-cell"><strong>${t['achieved_students']}</strong></td>';
  percentageRow += '<td class="student-name-cell"><strong>${t['percentage']}</strong></td>';
  
  for (var mainBareme in mainBaremes) {
    final mainBaremeId = mainBareme['id'] as String;
    final hasSubBaremes = mainBareme['hasSubBaremes'] as bool;
    final subBaremes = mainBareme['subBaremes'] as List<dynamic>? ?? [];
    
    if (hasSubBaremes && subBaremes.isNotEmpty) {
      // Barème avec sous-barèmes
      for (var subBareme in subBaremes) {
        final subBaremeId = subBareme['id'] as String;
        final fullKey = '$mainBaremeId-$subBaremeId';
        
        // Chercher le compteur
        int count = sumCriteriaMaxPerBareme[fullKey] ?? 
                    sumCriteriaMaxPerBareme[subBaremeId] ?? 
                    sumCriteriaMaxPerBareme[mainBaremeId] ?? 0;
        
        statsRow += '<td><strong>$count</strong></td>';
        
        if (totalStudents > 0) {
          final percentage = (count / totalStudents * 100).toStringAsFixed(2);
          percentageRow += '<td class="percentage-cell"><strong>${percentage}%</strong></td>';
        } else {
          percentageRow += '<td class="percentage-cell"><strong>0.00%</strong></td>';
        }
      }
    } else {
      // Barème principal simple
      int count = sumCriteriaMaxPerBareme[mainBaremeId] ?? 0;
      statsRow += '<td><strong>$count</strong></td>';
      
      if (totalStudents > 0) {
        final percentage = (count / totalStudents * 100).toStringAsFixed(2);
        percentageRow += '<td class="percentage-cell"><strong>${percentage}%</strong></td>';
      } else {
        percentageRow += '<td class="percentage-cell"><strong>0.00%</strong></td>';
      }
    }
  }

  // Étape 5: Calculer le nombre total de colonnes
  int totalColumns = 1; // Pour la colonne des noms
  for (var mainBareme in mainBaremes) {
    final hasSubBaremes = mainBareme['hasSubBaremes'] as bool;
    final subBaremes = mainBareme['subBaremes'] as List<dynamic>? ?? [];
    
    if (hasSubBaremes && subBaremes.isNotEmpty) {
      totalColumns += subBaremes.length;
    } else {
      totalColumns += 1;
    }
  }

  // Vérifier que nous avons des colonnes pour les barèmes
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
        
        <tr class="stats-row">
          $statsRow
        </tr>
        
        <tr class="percentage-row">
          $percentageRow
        </tr>
        
        <!-- Ligne du nombre total d'étudiants -->
        
      </tbody>
    </table>
    
    <!-- Légende des symboles -->
   
  </div>
  ''';
}
// Nouvelles fonctions d'aide
static String _extractParentNameFromSubBareme(String subBaremeName) {
  if (subBaremeName.isEmpty) return '';
  
  // Patterns pour extraire le nom du parent
  // Exemples: "مع 3.ا" -> "مع 3", "C3.a" -> "C3"
  
  // Pattern 1: Nom avec point et lettre arabe
  final arabicPattern = RegExp(r'^(.+)\.([\u0621-\u064A])$');
  final matchArabic = arabicPattern.firstMatch(subBaremeName);
  if (matchArabic != null) {
    return matchArabic.group(1)!.trim();
  }
  
  // Pattern 2: Nom avec point et lettre latine
  final latinPattern = RegExp(r'^(.+)\.([a-zA-Z])$');
  final matchLatin = latinPattern.firstMatch(subBaremeName);
  if (matchLatin != null) {
    return matchLatin.group(1)!.trim();
  }
  
  // Pattern 3: Nom avec espace et lettre
  final spacePattern = RegExp(r'^(.+)\s+([\u0621-\u064A]|[a-zA-Z])$');
  final matchSpace = spacePattern.firstMatch(subBaremeName);
  if (matchSpace != null) {
    return matchSpace.group(1)!.trim();
  }
  
  return '';
}

static String _removeSubBaremeLetter(String subBaremeName) {
  if (subBaremeName.isEmpty) return '';
  
  // Supprimer la dernière lettre (arabe ou latine)
  // Exemples: "مع 3.ا" -> "مع 3.", puis enlever le point
  // "C3.a" -> "C3.", puis enlever le point
  
  String result = subBaremeName;
  
  // Enlever la dernière lettre arabe
  if (result.isNotEmpty && _isArabicLetter(result[result.length - 1])) {
    result = result.substring(0, result.length - 1);
  }
  
  // Enlever la dernière lettre latine
  if (result.isNotEmpty && _isLatinLetter(result[result.length - 1])) {
    result = result.substring(0, result.length - 1);
  }
  
  // Nettoyer les caractères de ponctuation à la fin
  result = result.replaceAll(RegExp(r'[.\s]+$'), '');
  
  return result.trim();
}

static bool _isArabicLetter(String char) {
  return char.codeUnitAt(0) >= 0x0621 && char.codeUnitAt(0) <= 0x064A;
}

static bool _isLatinLetter(String char) {
  return (char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90) || 
         (char.codeUnitAt(0) >= 97 && char.codeUnitAt(0) <= 122);
}

static String _cleanSubBaremeName(String subName, String parentName) {
  // Nettoyer le nom du sous-barème pour n'afficher que la partie distinctive
  // Exemple: si parent = "مع 3" et sub = "مع 3.ا", afficher seulement "ا"
  
  if (subName.startsWith(parentName)) {
    String remaining = subName.substring(parentName.length).trim();
    
    // Enlever les séparateurs au début
    remaining = remaining.replaceAll(RegExp(r'^[.\s]+'), '');
    
    if (remaining.isNotEmpty) {
      return remaining;
    }
  }
  
  return subName;
}

static String _normalizeForSorting(String text) {
  // Normaliser le texte pour le tri
  String normalized = text.trim();
  // Supprimer les diacritiques arabes
  normalized = normalized.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  return normalized;
}

static String _cleanSubBaremeNameForSorting(String subName, String parentName) {
  // Nettoyer le nom du sous-barème en supprimant le préfixe du parent
  String cleaned = subName;
  
  // Enlever le préfixe du parent s'il existe
  if (cleaned.startsWith(parentName)) {
    cleaned = cleaned.substring(parentName.length).trim();
  }
  
  // Enlever les séparateurs au début
  cleaned = cleaned.replaceAll(RegExp(r'^[.\s]+'), '');
  
  return cleaned;
}

static bool _isArabicLetterOnly(String text) {
  // Vérifier si le texte ne contient que des lettres arabes
  final normalized = text.replaceAll(RegExp(r'[\s.\-]'), '').trim();
  if (normalized.isEmpty) return false;
  
  for (int i = 0; i < normalized.length; i++) {
    final code = normalized.codeUnitAt(i);
    if (!(code >= 0x0621 && code <= 0x064A)) {
      return false;
    }
  }
  return true;
}

static bool _isLatinLetterOnly(String text) {
  // Vérifier si le texte ne contient que des lettres latines
  final normalized = text.replaceAll(RegExp(r'[\s.\-]'), '').trim();
  if (normalized.isEmpty) return false;
  
  for (int i = 0; i < normalized.length; i++) {
    final code = normalized.codeUnitAt(i);
    if (!((code >= 65 && code <= 90) || (code >= 97 && code <= 122))) {
      return false;
    }
  }
  return true;
}

static int _compareArabicLetters(String a, String b) {
  // Comparer deux lettres arabes par ordre alphabétique arabe
  const Map<String, int> arabicLetterOrder = {
    'ا': 1,
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
  };
  
  final orderA = arabicLetterOrder[a.trim()] ?? a.codeUnitAt(0);
  final orderB = arabicLetterOrder[b.trim()] ?? b.codeUnitAt(0);
  
  return orderA - orderB;
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
      'Communication orale': 'Domaine Langue Arabe',
      'Lecture': 'Domaine Langue Arabe',
      'Grammaire': 'Domaine Langue Arabe',
      'Production écrite': 'Domaine Langue Arabe',
      'Écriture': 'Domaine Langue Arabe',
      'Dictée': 'Domaine Langue Arabe',
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
        print('Platforme Web détectée - Téléchargement HTML');
        await _downloadHTMLFile(htmlContent);
        return;
      }

      print('Début de la génération PDF...');

      final directory = await getTemporaryDirectory();
      final targetPath = directory.path;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'rapport_complet_$timestamp.pdf';

      print('Chemin cible: $targetPath');
      print('Nom du fichier: $fileName');

      final generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
        htmlContent,
        targetPath,
        fileName,
      );

      print('PDF généré avec succès: ${generatedPdfFile.path}');
      print('Taille du fichier: ${generatedPdfFile.lengthSync()} bytes');

      await OpenFile.open(generatedPdfFile.path);

      print('PDF ouvert avec succès');
    } catch (e) {
      print('Erreur lors de la génération du fichier PDF: $e');

      print('Fallback: téléchargement HTML...');
      await _downloadHTMLFile(htmlContent);
    }
  }

  static Future<void> _downloadHTMLFile(String htmlContent) async {
    try {
      if (kIsWeb) {
        final blob = html.Blob([htmlContent], 'text/html; charset=utf-8');
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download',
              'rapport_complet_${DateTime.now().millisecondsSinceEpoch}.html')
          ..click();

        Future.delayed(const Duration(seconds: 2), () {
          html.Url.revokeObjectUrl(url);
        });
      } else {
        final directory = await getTemporaryDirectory();
        final file = File(
            '${directory.path}/rapport_complet_${DateTime.now().millisecondsSinceEpoch}.html');
        await file.writeAsString(htmlContent, flush: true);
        await OpenFile.open(file.path);
      }

      print('Fichier généré avec succès');
    } catch (e) {
      print('Erreur lors de la génération du fichier: $e');
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