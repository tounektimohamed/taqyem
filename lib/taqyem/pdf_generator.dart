import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

class PDFClassificationGenerator {
  static Future<void> generateAndDownloadClassificationReport({
    required BuildContext context,
    required String profName,
    required String matiereName,
    required String className,
    required String schoolName,
    required String baremeName,
    required String sousBaremeName,
    required Map<String, List<Map<String, dynamic>>> groupedStudents,
    required Map<String, List<Map<String, dynamic>>> groupSelections,
    required bool isFrenchInterface,
    required bool isCompleteReport,
    String? singleGroupName,
    String? singleGroupKey,
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

      // Générer le contenu HTML complet
      final htmlContent = _buildCompleteClassificationHTMLContent(
        profName: profName,
        matiereName: matiereName,
        className: className,
        schoolName: schoolName,
        baremeName: baremeName,
        sousBaremeName: sousBaremeName,
        groupedStudents: groupedStudents,
        groupSelections: groupSelections,
        isFrenchInterface: isFrenchInterface,
        isCompleteReport: isCompleteReport,
        singleGroupName: singleGroupName,
        singleGroupKey: singleGroupKey,
        logoBase64: logoBase64,
      );

      // Générer et télécharger le PDF
      await _generateAndDownloadPDF(htmlContent, 'classification_report');
    } catch (e) {
      print('Erreur génération rapport classification: $e');
      rethrow;
    }
  }

  static String _buildCompleteClassificationHTMLContent({
    required String profName,
    required String matiereName,
    required String className,
    required String schoolName,
    required String baremeName,
    required String sousBaremeName,
    required Map<String, List<Map<String, dynamic>>> groupedStudents,
    required Map<String, List<Map<String, dynamic>>> groupSelections,
    required bool isFrenchInterface,
    required bool isCompleteReport,
    String? singleGroupName,
    String? singleGroupKey,
    required String logoBase64,
  }) {
    final direction = isFrenchInterface ? 'ltr' : 'rtl';
    final textAlign = isFrenchInterface ? 'left' : 'right';
    final now = DateTime.now();

    // Traductions
    final t = _getTranslations(isFrenchInterface);

    return '''
<!DOCTYPE html>
<html lang="${isFrenchInterface ? 'fr' : 'ar'}" dir="$direction">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${t['main_title']}</title>
    <style>
        /* STYLES DE BASE */
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
            
            /* Couleurs des groupes */
            --treatment-color: #e74c3c;
            --support-color: #f39c12;
            --excellence-color: #27ae60;
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
        
        .footer-cover {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #e0e0e0;
            color: #666;
            font-size: 14px;
        }
        
        /* Page des informations générales */
        .general-info-page {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--box-shadow);
            padding: 30px;
            margin-top: 40px;
            page-break-before: always;
        }
        
        .section-title {
            font-size: 22px;
            color: var(--primary-color);
            margin-bottom: 25px;
            padding-bottom: 10px;
            border-bottom: 2px solid var(--primary-color);
            font-weight: bold;
        }
        
        .info-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
            margin-bottom: 30px;
        }
        
        .info-table td {
            padding: 12px 15px;
            border-bottom: 1px solid #e0e0e0;
        }
        
        .info-label-cell {
            width: 25%;
            background-color: var(--light-bg);
            font-weight: bold;
            color: var(--primary-color);
        }
        
        /* Pages des groupes */
        .group-page {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--box-shadow);
            padding: 30px;
            margin-top: 40px;
            page-break-before: always;
        }
        
        .group-header {
            background: linear-gradient(135deg, var(--treatment-color), #c0392b);
            color: white;
            padding: 20px;
            border-radius: var(--border-radius) var(--border-radius) 0 0;
            margin-bottom: 25px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .group-support .group-header {
            background: linear-gradient(135deg, var(--support-color), #e67e22);
        }
        
        .group-excellence .group-header {
            background: linear-gradient(135deg, var(--excellence-color), #219653);
        }
        
        .group-title {
            font-size: 20px;
            font-weight: bold;
        }
        
        .group-stats {
            background: rgba(255, 255, 255, 0.2);
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 14px;
        }
        
        .students-section, .solutions-section, .problems-section {
            margin-bottom: 30px;
        }
        
        .section-subtitle {
            font-size: 18px;
            color: var(--text-color);
            margin-bottom: 15px;
            padding-${isFrenchInterface ? 'left' : 'right'}: 10px;
            border-${isFrenchInterface ? 'left' : 'right'}: 4px solid;
            font-weight: bold;
        }
        
        .students-section .section-subtitle {
            border-color: var(--primary-color);
        }
        
        .solutions-section .section-subtitle {
            border-color: var(--excellence-color);
            color: var(--excellence-color);
        }
        
        .problems-section .section-subtitle {
            border-color: var(--treatment-color);
            color: var(--treatment-color);
        }
        
        .students-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
            margin: 15px 0;
        }
        
        .students-table th {
            background-color: var(--light-bg);
            padding: 12px 10px;
            text-align: center;
            border: 1px solid #ddd;
            font-weight: bold;
        }
        
        .students-table td {
            padding: 10px 8px;
            border: 1px solid #ddd;
            text-align: center;
        }
        
        .students-table tr:nth-child(even) {
            background-color: #fafafa;
        }
        
        .items-list {
            list-style-type: none;
            padding: 0;
        }
        
        .item-card {
            margin-bottom: 15px;
            padding: 15px;
            border-radius: var(--border-radius);
            background: var(--light-bg);
            border-${isFrenchInterface ? 'left' : 'right'}: 4px solid;
            position: relative;
            transition: var(--transition);
        }
        
        .item-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }
        
        .solution-item {
            border-color: var(--excellence-color);
            background-color: #e8f5e9;
        }
        
        .problem-item {
            border-color: var(--treatment-color);
            background-color: #ffebee;
        }
        
        .item-text {
            font-size: 14px;
            line-height: 1.5;
            margin-bottom: 8px;
        }
        
        .item-source {
            font-size: 12px;
            color: #666;
            font-style: italic;
        }
        
        .source-badge {
            display: inline-block;
            padding: 3px 8px;
            background: rgba(0, 0, 0, 0.1);
            border-radius: 12px;
            font-size: 11px;
            margin-top: 5px;
        }
        
        /* Page de vue d'ensemble */
        .overview-page {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--box-shadow);
            padding: 30px;
            margin-top: 40px;
            page-break-before: always;
        }
        
        .overview-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin: 25px 0;
        }
        
        .overview-card {
            padding: 25px;
            border-radius: var(--border-radius);
            color: white;
            text-align: center;
            position: relative;
            overflow: hidden;
        }
        
        .overview-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.1);
        }
        
        .overview-treatment {
            background: linear-gradient(135deg, var(--treatment-color), #c0392b);
        }
        
        .overview-support {
            background: linear-gradient(135deg, var(--support-color), #e67e22);
        }
        
        .overview-excellence {
            background: linear-gradient(135deg, var(--excellence-color), #219653);
        }
        
        .overview-icon {
            font-size: 40px;
            margin-bottom: 15px;
            position: relative;
            z-index: 1;
        }
        
        .overview-title {
            font-size: 20px;
            font-weight: bold;
            margin-bottom: 10px;
            position: relative;
            z-index: 1;
        }
        
        .overview-count {
            font-size: 28px;
            font-weight: bold;
            position: relative;
            z-index: 1;
        }
        
        .report-footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #e0e0e0;
            color: #666;
            font-size: 14px;
        }
        
        /* STYLES D'IMPRESSION */
        @media print {
            * {
                box-shadow: none !important;
                text-shadow: none !important;
            }
            
            body {
                background: white !important;
                color: black !important;
                padding: 0 !important;
                margin: 0 !important;
                font-size: 12pt !important;
                line-height: 1.4 !important;
            }
            
            .report-container {
                max-width: 100% !important;
                margin: 0 !important;
                padding: 0 !important;
            }
            
            .cover-page {
                box-shadow: none !important;
                border: none !important;
                padding: 0 !important;
                margin: 0 !important;
                min-height: auto !important;
                page-break-after: always;
                display: block !important;
            }
            
            .cover-page::before {
                display: none !important;
            }
            
            .cover-header {
                text-align: center !important;
                margin: 50px 0 40px 0 !important;
                border-bottom: 3px solid black !important;
                padding-bottom: 20px !important;
            }
            
            .ministry-title {
                color: black !important;
                font-size: 28pt !important;
                font-weight: bold !important;
                margin-bottom: 15px !important;
                line-height: 1.2 !important;
            }
            
            .delegation-title {
                color: black !important;
                font-size: 16pt !important;
                font-weight: bold !important;
                margin-bottom: 20px !important;
            }
            
            .logo-container {
                display: block !important;
                text-align: center !important;
                margin: 30px 0 40px 0 !important;
            }
            
            .logo {
                height: 120px !important;
                max-width: 250px !important;
                filter: grayscale(100%) !important;
            }
            
            .school-info {
                background: white !important;
                border: 2px solid black !important;
                border-radius: 0 !important;
                padding: 25px !important;
                margin: 40px 0 !important;
                text-align: center !important;
            }
            
            .school-info::before {
                display: none !important;
            }
            
            .info-grid {
                display: block !important;
                margin: 40px 0 !important;
            }
            
            .info-card {
                background: white !important;
                border: 1px solid #ddd !important;
                border-radius: 0 !important;
                padding: 15px !important;
                margin-bottom: 15px !important;
                page-break-inside: avoid;
                display: block !important;
                text-align: ${isFrenchInterface ? 'left' : 'right'} !important;
            }
            
            .info-card:hover {
                transform: none !important;
                box-shadow: none !important;
                border-color: #ddd !important;
            }
            
            .info-icon {
                display: none !important;
            }
            
            .info-content {
                display: block !important;
                text-align: ${isFrenchInterface ? 'left' : 'right'} !important;
            }
            
            .info-label {
                color: black !important;
                font-size: 12pt !important;
                font-weight: bold !important;
                margin-bottom: 5px !important;
                display: inline-block !important;
                width: 120px !important;
            }
            
            .info-value {
                color: black !important;
                font-size: 14pt !important;
                font-weight: normal !important;
                display: inline !important;
                margin-${isFrenchInterface ? 'left' : 'right'}: 10px !important;
            }
            
            .footer-cover {
                text-align: center !important;
                margin-top: 60px !important;
                padding-top: 20px !important;
                border-top: 1px solid black !important;
                color: black !important;
                font-size: 10pt !important;
                font-style: italic !important;
            }
            
            /* Pages de contenu */
            .general-info-page, .group-page, .overview-page {
                box-shadow: none !important;
                border: none !important;
                padding: 0 !important;
                margin: 0 !important;
                page-break-before: always !important;
            }
            
            .section-title {
                color: black !important;
                border-bottom: 2px solid black !important;
                font-size: 18pt !important;
            }
            
            .info-table {
                width: 100% !important;
                border-collapse: collapse !important;
                margin-bottom: 30px !important;
                page-break-inside: avoid;
            }
            
            .info-table td {
                border: 1px solid #999 !important;
                padding: 10px !important;
            }
            
            .info-label-cell {
                background: #f0f0f0 !important;
                color: black !important;
                font-weight: bold !important;
            }
            
            .group-header {
                background: white !important;
                color: black !important;
                border-bottom: 3px solid black !important;
                padding: 15px 0 !important;
                margin-bottom: 20px !important;
            }
            
            .group-title {
                color: black !important;
                font-size: 16pt !important;
            }
            
            .group-stats {
                background: #f0f0f0 !important;
                color: black !important;
                border: 1px solid #999 !important;
            }
            
            .section-subtitle {
                color: black !important;
                border: none !important;
                border-bottom: 2px solid #999 !important;
                padding-${isFrenchInterface ? 'left' : 'right'}: 0 !important;
                font-size: 14pt !important;
            }
            
            .students-table {
                width: 100% !important;
                border-collapse: collapse !important;
                font-size: 10pt !important;
                page-break-inside: auto !important;
            }
            
            .students-table th {
                background: #f0f0f0 !important;
                color: black !important;
                border: 1px solid #999 !important;
                padding: 8px !important;
            }
            
            .students-table td {
                border: 1px solid #999 !important;
                padding: 6px !important;
            }
            
            .items-list {
                page-break-inside: avoid;
            }
            
            .item-card {
                background: white !important;
                border: 1px solid #ddd !important;
                margin-bottom: 10px !important;
                page-break-inside: avoid;
            }
            
            .solution-item {
                border-left: 3px solid #2E7D32 !important;
            }
            
            .problem-item {
                border-left: 3px solid #e74c3c !important;
            }
            
            .item-text {
                color: black !important;
                font-size: 11pt !important;
            }
            
            .item-source {
                color: #666 !important;
                font-size: 9pt !important;
            }
            
            .overview-grid {
                display: block !important;
            }
            
            .overview-card {
                background: white !important;
                color: black !important;
                border: 2px solid black !important;
                margin-bottom: 20px !important;
                page-break-inside: avoid;
            }
            
            .overview-card::before {
                display: none !important;
            }
            
            .overview-title {
                color: black !important;
                font-size: 14pt !important;
            }
            
            .overview-count {
                color: black !important;
                font-size: 16pt !important;
            }
            
            .report-footer {
                text-align: center !important;
                margin-top: 40px !important;
                padding-top: 15px !important;
                border-top: 1px solid black !important;
                color: black !important;
                font-size: 9pt !important;
                font-style: italic !important;
            }
            
            /* Masquer les éléments non nécessaires */
            .no-print,
            .info-card:hover,
            .item-card:hover,
            .school-info::before {
                display: none !important;
            }
            
            /* Paramètres de page */
            @page {
                margin: 15mm !important;
                size: A4 portrait !important;
            }
            
            /* Numérotation des pages */
            body {
                counter-reset: page;
            }
            
            .general-info-page, .group-page, .overview-page {
                counter-increment: page;
            }
            
            /* Éviter les coupures */
            tr {
                page-break-inside: avoid !important;
            }
        }
        
        /* Responsive pour écran */
        @media screen and (max-width: 768px) {
            body {
                padding: 10px;
            }
            
            .cover-page, .general-info-page, .group-page, .overview-page {
                padding: 20px;
            }
            
            .ministry-title {
                font-size: 20px;
            }
            
            .info-grid, .overview-grid {
                grid-template-columns: 1fr;
            }
            
            .section-title {
                font-size: 20px;
            }
        }
    </style>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Arabic:wght@400;500;600;700&display=swap" rel="stylesheet">
</head>
<body>
    <div class="report-container">
        <!-- 1. Page de garde -->
       
        
        <!-- 2. Page des informations générales -->
        ${_buildGeneralInfoPageHTML(
      profName: profName,
      matiereName: matiereName,
      className: className,
      schoolName: schoolName,
      baremeName: baremeName,
      sousBaremeName: sousBaremeName,
      isFrenchInterface: isFrenchInterface,
      groupedStudents: groupedStudents,
      now: now,
    )}
        
        
        
        <!-- 4. Pages des groupes -->
        ${_buildGroupsPagesHTML(
      groupedStudents: groupedStudents,
      groupSelections: groupSelections,
      isFrenchInterface: isFrenchInterface,
      isCompleteReport: isCompleteReport,
      singleGroupKey: singleGroupKey,
    )}
    </div>
</body>
</html>
    ''';
  }

  // ============ MÉTHODES DE CONSTRUCTION DES PAGES ============

  // Page de garde
  static String _buildCoverPageHTML({
    required String profName,
    required String matiereName,
    required String className,
    required String schoolName,
    required String baremeName,
    required String sousBaremeName,
    required String logoBase64,
    required bool isFrenchInterface,
    required bool isCompleteReport,
    String? singleGroupName,
    required DateTime now,
  }) {
    final t = _getTranslations(isFrenchInterface);
    final reportType = isCompleteReport
        ? t['complete_report']!
        : '${t['group_report']!} - ${singleGroupName ?? ''}';

    return '''
    <div class="cover-page">
        <div class="cover-header">
            <h1 class="ministry-title">${t['ministry_title']!}</h1>
            <div class="delegation-title">${t['regional_delegation']!}</div>
        </div>
        
        ${logoBase64.isNotEmpty ? '''
        <div class="logo-container">
            <img src="data:image/png;base64,$logoBase64" class="logo" alt="Logo Ministère">
        </div>
        ''' : ''}
        
        <div class="school-info">
            <div class="info-value" style="text-align: center; font-size: 20px;">
                ${t['school']!}: <strong>$schoolName</strong>
            </div>
        </div>
        
        <div class="info-grid">
            <div class="info-card">
                <div class="info-icon">👨‍🏫</div>
                <div class="info-content">
                    <div class="info-label">${t['professor']!}</div>
                    <div class="info-value">$profName</div>
                </div>
            </div>
            
            <div class="info-card">
                <div class="info-icon">📚</div>
                <div class="info-content">
                    <div class="info-label">${t['subject']!}</div>
                    <div class="info-value">$matiereName</div>
                </div>
            </div>
            
            <div class="info-card">
                <div class="info-icon">👥</div>
                <div class="info-content">
                    <div class="info-label">${t['class']!}</div>
                    <div class="info-value">$className</div>
                </div>
            </div>
            
            <div class="info-card">
                <div class="info-icon">📝</div>
                <div class="info-content">
                    <div class="info-label">${t['criteria']!}</div>
                    <div class="info-value">$baremeName</div>
                </div>
            </div>
        </div>
        
        ${sousBaremeName.isNotEmpty ? '''
        <div class="info-grid">
            <div class="info-card" style="grid-column: 1 / -1;">
                <div class="info-icon">📋</div>
                <div class="info-content">
                    <div class="info-label">${t['sub_criteria']!}</div>
                    <div class="info-value">$sousBaremeName</div>
                </div>
            </div>
        </div>
        ''' : ''}
        
        <div class="school-info" style="margin-top: 30px;">
            <div class="info-value" style="text-align: center; font-size: 18px; color: var(--primary-color);">
                <strong>$reportType</strong>
            </div>
            ${!isCompleteReport && singleGroupName != null ? '''
            <div style="text-align: center; margin-top: 10px; font-size: 16px;">
                ${t['group']!}: <strong>$singleGroupName</strong>
            </div>
            ''' : ''}
        </div>
        
        <div class="footer-cover">
            <p>${t['generated_on']!} ${DateFormat('dd/MM/yyyy').format(now)}</p>
            <p class="no-print">${isFrenchInterface ? 'Pour imprimer: Ctrl+P' : 'للطباعة: Ctrl+P'}</p>
        </div>
    </div>
    ''';
  }

  // Page des informations générales
  static String _buildGeneralInfoPageHTML({
    required String profName,
    required String matiereName,
    required String className,
    required String schoolName,
    required String baremeName,
    required String sousBaremeName,
    required bool isFrenchInterface,
    required Map<String, List<Map<String, dynamic>>> groupedStudents,
    required DateTime now,
  }) {
    final t = _getTranslations(isFrenchInterface);

    // Calculer les statistiques
    final totalStudents =
        groupedStudents.values.fold(0, (sum, group) => sum + group.length);

    final treatmentCount = groupedStudents[t['group_treatment']!]?.length ?? 0;
    final supportCount = groupedStudents[t['group_support']!]?.length ?? 0;
    final excellenceCount =
        groupedStudents[t['group_excellence']!]?.length ?? 0;

    return '''
    <div class="general-info-page">
        <h2 class="section-title">${t['general_info']!}</h2>
        
        <table class="info-table">
            <tr>
                <td class="info-label-cell">${t['school']!}</td>
                <td>$schoolName</td>
                <td class="info-label-cell">${t['professor']!}</td>
                <td>$profName</td>
            </tr>
            <tr>
                <td class="info-label-cell">${t['class']!}</td>
                <td>$className</td>
                <td class="info-label-cell">${t['subject']!}</td>
                <td>$matiereName</td>
            </tr>
            <tr>
                <td class="info-label-cell">${t['criteria']!}</td>
                <td>$baremeName</td>
                <td class="info-label-cell">${t['date']!}</td>
                <td>${DateFormat('dd/MM/yyyy').format(now)}</td>
            </tr>
            ${sousBaremeName.isNotEmpty ? '''
            <tr>
                <td class="info-label-cell">${t['sub_criteria']!}</td>
                <td colspan="3">$sousBaremeName</td>
            </tr>
            ''' : ''}
        </table>
        
        <h3 class="section-subtitle" style="margin-top: 30px;">
            ${t['statistics']!}
        </h3>
        
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-top: 20px;">
            <div style="background: var(--treatment-color); color: white; padding: 15px; border-radius: var(--border-radius); text-align: center;">
                <div style="font-size: 12px; opacity: 0.9;">${t['group_treatment']!}</div>
                <div style="font-size: 24px; font-weight: bold;">$treatmentCount</div>
            </div>
            
            <div style="background: var(--support-color); color: white; padding: 15px; border-radius: var(--border-radius); text-align: center;">
                <div style="font-size: 12px; opacity: 0.9;">${t['group_support']!}</div>
                <div style="font-size: 24px; font-weight: bold;">$supportCount</div>
            </div>
            
            <div style="background: var(--excellence-color); color: white; padding: 15px; border-radius: var(--border-radius); text-align: center;">
                <div style="font-size: 12px; opacity: 0.9;">${t['group_excellence']!}</div>
                <div style="font-size: 24px; font-weight: bold;">$excellenceCount</div>
            </div>
            
            <div style="background: var(--primary-color); color: white; padding: 15px; border-radius: var(--border-radius); text-align: center;">
                <div style="font-size: 12px; opacity: 0.9;">${t['total_students']!}</div>
                <div style="font-size: 24px; font-weight: bold;">$totalStudents</div>
            </div>
        </div>
        
        <div class="report-footer">
            <p class="no-print">${isFrenchInterface ? 'Page 2' : 'الصفحة 2'}</p>
        </div>
    </div>
    ''';
  }

  // Pages des groupes
  static String _buildGroupsPagesHTML({
    required Map<String, List<Map<String, dynamic>>> groupedStudents,
    required Map<String, List<Map<String, dynamic>>> groupSelections,
    required bool isFrenchInterface,
    required bool isCompleteReport,
    String? singleGroupKey,
  }) {
    final t = _getTranslations(isFrenchInterface);
    String pagesHTML = '';

    // Déterminer quels groupes inclure
    List<String> groupsToInclude = [];

    if (isCompleteReport) {
      // Pour un rapport complet, inclure tous les groupes qui ont des données
      groupsToInclude = [
        t['group_treatment']!,
        t['group_support']!,
        t['group_excellence']!
      ];
    } else if (singleGroupKey != null) {
      // Pour un rapport de groupe unique, inclure seulement ce groupe
      switch (singleGroupKey) {
        case 'treatment':
          groupsToInclude = [t['group_treatment']!];
          break;
        case 'support':
          groupsToInclude = [t['group_support']!];
          break;
        case 'excellence':
          groupsToInclude = [t['group_excellence']!];
          break;
      }
    }

    for (final groupName in groupsToInclude) {
      final students = groupedStudents[groupName] ?? [];
      final selections =
          _getGroupSelectionsForGroup(groupName, groupSelections, t);

      if (students.isEmpty && selections.isEmpty) {
        continue; // Ne pas créer de page pour un groupe vide
      }

      // Déterminer la classe CSS et les icônes selon le groupe
      String groupClass = '';
      String groupIcon = '';
      String groupKey = '';

      if (groupName == t['group_treatment']!) {
        groupClass = 'group-treatment';
        groupIcon = '🏥';
        groupKey = 'treatment';
      } else if (groupName == t['group_support']!) {
        groupClass = 'group-support';
        groupIcon = '🤝';
        groupKey = 'support';
      } else {
        groupClass = 'group-excellence';
        groupIcon = '🏆';
        groupKey = 'excellence';
      }

      final solutions =
          selections.where((item) => item['isProblem'] == false).toList();
      final problems =
          selections.where((item) => item['isProblem'] == true).toList();

      pagesHTML += '''
      <div class="group-page $groupClass">
          <div class="group-header">
              <div>
                  <div class="group-title">$groupIcon $groupName</div>
                
              </div>
              <div class="group-stats">
                  ${students.length} ${t['students']!}
              </div>
          </div>
          
          <!-- Liste des étudiants -->
          ${students.isNotEmpty ? '''
         <div class="students-section">
    <h3 class="section-subtitle">${t['students_list']!}</h3>
    <div class="students-list-container">
        ${students.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final student = entry.value;
              return '''
          <div class="list-item">
              <span class="item-number">$index.</span>
              <span class="item-name">${student['name'] ?? t['unknown']!}</span>
              ${isCompleteReport ? '''
             
              ''' : ''}
          </div>
          ''';
            }).join('')}
    </div>
</div>
          ''' : ''}
           <!-- Problèmes identifiés -->
          ${problems.isNotEmpty ? '''
          <div class="problems-section">
              <h3 class="section-subtitle">${t['problems_title']!} (${problems.length})</h3>
              <ul class="items-list">
                  ${problems.map((problem) => '''
                  <li class="item-card problem-item">
                      <div class="item-text">${problem['text']}</div>
                      
                  </li>
                  ''').join('')}
              </ul>
          </div>
          ''' : ''}
          
          <!-- Solutions proposées -->
          ${solutions.isNotEmpty ? '''
          <div class="solutions-section">
              <h3 class="section-subtitle">${t['solutions_title']!} (${solutions.length})</h3>
              <ul class="items-list">
                  ${solutions.map((solution) => '''
                  <li class="item-card solution-item">
                      <div class="item-text">${solution['text']}</div>
                      
                  </li>
                  ''').join('')}
              </ul>
          </div>
          ''' : ''}
          
         
          <div class="report-footer">
              <p class="no-print">${isFrenchInterface ? 'Page - Groupe $groupName' : 'الصفحة - مجموعة $groupName'}</p>
          </div>
      </div>
      ''';
    }

    return pagesHTML;
  }

  // ============ MÉTHODES UTILITAIRES ============

  // Traductions
  static Map<String, String> _getTranslations(bool isFrenchInterface) {
    return isFrenchInterface
        ? {
            'main_title': 'Rapport de Classification Pédagogique',
            'ministry_title':
                'République Tunisienne\nMinistère de l\'Éducation',
            'regional_delegation':
                'Délégation Régionale de l\'Éducation à ...................',
            'school': 'Établissement',
            'professor': 'Professeur',
            'subject': 'Matière',
            'class': 'Classe',
            'criteria': 'Critère d\'évaluation',
            'sub_criteria': 'Sous-critère',
            'group': 'Groupe',
            'date': 'Date',
            'generated_on': 'Généré le',
            'complete_report': 'Rapport complet de classification',
            'group_report': 'Rapport de groupe',
            'general_info': 'Informations générales',
            'statistics': 'Statistiques',
            'total_students': 'Total des élèves',
            'students': 'élève(s)',
            'group_treatment': 'Groupe de traitement',
            'group_support': 'Groupe de soutien',
            'group_excellence': "Groupe d'excellence",
            'overview': 'Vue d\'ensemble',
            'treatment_description':
                'Élèves nécessitant un traitement pédagogique spécifique',
            'support_description':
                'Élèves bénéficiant d\'un soutien pédagogique',
            'excellence_description': 'Élèves en situation d\'excellence',
            'report_guide': 'Guide du rapport',
            'report_guide_text':
                'Ce rapport présente la classification des élèves selon leurs besoins pédagogiques. Les solutions et problèmes identifiés sont des recommandations pour la différenciation pédagogique.',
            'students_list': 'Liste des élèves',
            'student_name': 'Nom de l\'élève',
            'treatment_plan': 'Plan de traitement',
            'error_origin': 'Origine de l\'erreur',
            'solutions_title': 'Solutions proposées',
            'problems_title': 'Problèmes identifiés',
            'source': 'Source',
            'selected': 'Sélectionné',
            'unknown': 'Inconnu',
            // Clés optionnelles pour les sources
            'json': 'Recommandé',
            'global': 'Approuvé',
            'personal': 'Personnel',
            'new': 'Nouveau',
          }
        : {
            'main_title': 'تقرير التصنيف التربوي',
            'ministry_title': 'الجمهورية التونسية\nوزارة التربية',
            'regional_delegation': 'المندوبية الجهوية للتربية ب..............',
            'school': 'المؤسسة',
            'professor': 'الأستاذ',
            'subject': 'المادة',
            'class': 'القسم',
            'criteria': 'معيار التقويم',
            'sub_criteria': 'المعيار الفرعي',
            'group': 'المجموعة',
            'date': 'التاريخ',
            'generated_on': 'تم الإنشاء في',
            'complete_report': 'تقرير تصنيف شامل',
            'group_report': 'تقرير مجموعة',
            'general_info': 'معلومات عامة',
            'statistics': 'إحصائيات',
            'total_students': 'مجموع التلاميذ',
            'students': 'تلميذ(ة)',
            'group_treatment': 'مجموعة العلاج',
            'group_support': 'مجموعة الدعم',
            'group_excellence': 'مجموعة التميز',
            'overview': 'نظرة عامة',
            'treatment_description': 'تلاميذ يحتاجون إلى علاج تربوي خاص',
            'support_description': 'تلاميذ يستفيدون من دعم تربوي',
            'excellence_description': 'تلاميذ في حالة تميز',
            'report_guide': 'دليل التقرير',
            'report_guide_text':
                'يعرض هذا التقرير تصنيف التلاميذ حسب احتياجاتهم التربوية. الحلول والمشاكل المحددة هي توصيات للتمايز التربوي.',
            'students_list': 'قائمة التلاميذ',
            'student_name': 'اسم التلميذ',
            'treatment_plan': 'خطة العلاج',
            'error_origin': 'أصل الخطأ',
            'solutions_title': 'الحلول المقترحة',
            'problems_title': 'المشاكل المحددة',
            'source': 'المصدر',
            'selected': 'محدد',
            'unknown': 'غير معروف',
            // Clés optionnelles pour les sources
            'json': 'موصى به',
            'global': 'معتمد',
            'personal': 'شخصي',
            'new': 'جديد',
          };
  }

  // Obtenir les sélections pour un groupe spécifique
  static List<Map<String, dynamic>> _getGroupSelectionsForGroup(
    String groupName,
    Map<String, List<Map<String, dynamic>>> groupSelections,
    Map<String, String> t,
  ) {
    if (groupSelections.isEmpty) return [];

    // Déterminer la clé du groupe
    String groupKey = '';
    if (groupName == t['group_treatment']!) {
      groupKey = 'treatment';
    } else if (groupName == t['group_support']!) {
      groupKey = 'support';
    } else if (groupName == t['group_excellence']!) {
      groupKey = 'excellence';
    }

    return groupSelections[groupKey] ?? [];
  }

  // Description du groupe
  // static String _getGroupDescription(String groupName, Map<String, String> t) {
  //   if (groupName == t['group_treatment']!) {
  //     return t['treatment_description']!;
  //   } else if (groupName == t['group_support']!) {
  //     return t['support_description']!;
  //   } else {
  //     return t['excellence_description']!;
  //   }
  // }

  // Affichage de la source
  static String _getSourceDisplay(String source, Map<String, String> t) {
    final sourceMap = {
      'json': t['json'] ?? 'Recommandé',
      'global': t['global'] ?? 'Approuvé',
      'personal': t['personal'] ?? 'Personnel',
      'new': t['new'] ?? 'Nouveau',
    };

    return sourceMap[source] ?? source;
  }

  // ============ MÉTHODES DE GÉNÉRATION DE FICHIER ============

  static Future<void> _generateAndDownloadPDF(
      String htmlContent, String fileNamePrefix) async {
    try {
      if (kIsWeb) {
        print('Platforme Web détectée - Téléchargement HTML');
        await _downloadHTMLFile(htmlContent, fileNamePrefix);
        return;
      }

      print('Début de la génération PDF...');

      final directory = await getTemporaryDirectory();
      final targetPath = directory.path;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${fileNamePrefix}_$timestamp.pdf';

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
      await _downloadHTMLFile(htmlContent, fileNamePrefix);
    }
  }

  static Future<void> _downloadHTMLFile(
      String htmlContent, String fileNamePrefix) async {
    try {
      if (kIsWeb) {
        final blob = html.Blob([htmlContent], 'text/html; charset=utf-8');
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download',
              '${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.html')
          ..click();

        Future.delayed(const Duration(seconds: 2), () {
          html.Url.revokeObjectUrl(url);
        });
      } else {
        final directory = await getTemporaryDirectory();
        final file = File(
            '${directory.path}/${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.html');
        await file.writeAsString(htmlContent, flush: true);
        await OpenFile.open(file.path);
      }

      print('Fichier généré avec succès');
    } catch (e) {
      print('Erreur lors de la génération du fichier: $e');
      rethrow;
    }
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
