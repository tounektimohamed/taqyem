// Supprimez ces imports :
// import 'dart:io';
// import 'dart:html' as html;

// Ajoutez/modifiez ces imports :
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:cross_file/cross_file.dart';

// Imports conditionnels pour le web
import 'dart:html' as html if (dart.library.html) 'dart:html';

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
    required Map<String, List<Map<String, dynamic>>> aiExercises,
    required bool isFrenchInterface,
    required bool isCompleteReport,
    String? singleGroupName,
    String? singleGroupKey,
  }) async {
    try {
      // Afficher le dialogue de sélection du template
      final selectedTemplate = await _showTemplateSelectionDialog(
        context: context,
        isFrenchInterface: isFrenchInterface,
      );

      // Si l'utilisateur annule, ne pas générer le PDF
      if (selectedTemplate == null) {
        return;
      }

      // Afficher le dialogue de sélection des pages
      final selectedPages = await _showPageSelectionDialog(
        context: context,
        profName: profName,
        matiereName: matiereName,
        className: className,
        schoolName: schoolName,
        baremeName: baremeName,
        sousBaremeName: sousBaremeName,
        groupedStudents: groupedStudents,
        groupSelections: groupSelections,
        aiExercises: aiExercises,
        isFrenchInterface: isFrenchInterface,
        isCompleteReport: isCompleteReport,
      );

      // Si l'utilisateur annule, ne pas générer le PDF
      if (selectedPages == null) {
        return;
      }

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

      // Générer le contenu HTML avec les pages sélectionnées
      final htmlContent = _buildCompleteClassificationHTMLContent(
        profName: profName,
        matiereName: matiereName,
        className: className,
        schoolName: schoolName,
        baremeName: baremeName,
        sousBaremeName: sousBaremeName,
        groupedStudents: groupedStudents,
        groupSelections: groupSelections,
        aiExercises: aiExercises,
        isFrenchInterface: isFrenchInterface,
        isCompleteReport: isCompleteReport,
        singleGroupName: singleGroupName,
        singleGroupKey: singleGroupKey,
        logoBase64: logoBase64,
        selectedPages: selectedPages,
        selectedTemplate: selectedTemplate,
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
    required Map<String, List<Map<String, dynamic>>> aiExercises,
    required bool isFrenchInterface,
    required bool isCompleteReport,
    String? singleGroupName,
    String? singleGroupKey,
    required String logoBase64,
    required Map<String, bool> selectedPages,
    required String selectedTemplate,
  }) {
    final direction = isFrenchInterface ? 'ltr' : 'rtl';
    final textAlign = isFrenchInterface ? 'left' : 'right';
    final now = DateTime.now();

    // Traductions
    final t = _getTranslations(isFrenchInterface);

    // Styles CSS selon le template
    final templateStyles = _getTemplateStyles(selectedTemplate);

    String pagesHTML = '';

    // Page de garde (si sélectionnée)
    if (selectedPages['cover'] == true) {
      pagesHTML += _buildCoverPageHTML(
        profName: profName,
        matiereName: matiereName,
        className: className,
        schoolName: schoolName,
        baremeName: baremeName,
        sousBaremeName: sousBaremeName,
        logoBase64: logoBase64,
        isFrenchInterface: isFrenchInterface,
        isCompleteReport: isCompleteReport,
        singleGroupName: singleGroupName,
        now: now,
      );
    }

    // Page des informations générales (si sélectionnée)
    if (selectedPages['general'] == true) {
      pagesHTML += _buildGeneralInfoPageHTML(
        profName: profName,
        matiereName: matiereName,
        className: className,
        schoolName: schoolName,
        baremeName: baremeName,
        sousBaremeName: sousBaremeName,
        isFrenchInterface: isFrenchInterface,
        groupedStudents: groupedStudents,
        now: now,
      );
    }

    // Pages des groupes (selon les sélections)
    pagesHTML += _buildGroupsPagesHTML(
      groupedStudents: groupedStudents,
      groupSelections: groupSelections,
      aiExercises: aiExercises,
      isFrenchInterface: isFrenchInterface,
      isCompleteReport: isCompleteReport,
      singleGroupKey: singleGroupKey,
      selectedPages: selectedPages, // NOUVEAU PARAMÈTRE
    );

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
            --ai-color: #9C27B0;
            --light-bg: #f8f9fa;
            --white: #ffffff;
            --text-color: #333333;
            --border-radius: 8px;
            --box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
            
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
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            gap: 15px;
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
        
        /* Styles pour les sections AI */
        .ai-section {
            margin-top: 30px;
            margin-bottom: 30px;
            background: linear-gradient(135deg, #f3e5f5 0%, #e1bee7 100%);
            border-radius: var(--border-radius);
            padding: 20px;
            border: 2px solid var(--ai-color);
        }
        
        .ai-header {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 20px;
            color: var(--ai-color);
            font-size: 18px;
            font-weight: bold;
        }
        
        .ai-exercise-card {
            background: white;
            border-radius: var(--border-radius);
            padding: 20px;
            margin-bottom: 20px;
            border: 1px solid #e0e0e0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .ai-exercise-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid var(--ai-color);
        }
        
        .ai-badge {
            background: var(--ai-color);
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
        }
        
        .ai-exercise-content {
            font-size: 14px;
            line-height: 1.8;
            white-space: pre-wrap;
            background: #fafafa;
            padding: 15px;
            border-radius: var(--border-radius);
            border: 1px solid #e0e0e0;
        }
        
        .ai-metadata {
            margin-top: 10px;
            font-size: 11px;
            color: #666;
            font-style: italic;
            text-align: right;
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
        
        .students-list-container {
            margin: 15px 0;
        }
        
        .list-item {
            padding: 10px 15px;
            border-bottom: 1px solid #e0e0e0;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .item-number {
            width: 30px;
            height: 30px;
            background: var(--primary-color);
            color: white;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 12px;
            font-weight: bold;
        }
        
        .item-name {
            font-weight: 500;
        }
        
        .students-section, .solutions-section, .problems-section, .ai-exercises-section {
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
        
        .ai-exercises-section .section-subtitle {
            border-color: var(--ai-color);
            color: var(--ai-color);
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
            transition: all 0.3s ease;
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
        
        .report-footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #e0e0e0;
            color: #666;
            font-size: 14px;
        }
    </style>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Arabic:wght@400;500;600;700&display=swap" rel="stylesheet">
</head>
<body>
    <div class="report-container">
        $pagesHTML
    </div>
</body>
</html>
    ''';
  }

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
        <h2 class="section-title">${t['general_info']!} $baremeName $matiereName</h2>
        
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

  static String _buildGroupsPagesHTML({
    required Map<String, List<Map<String, dynamic>>> groupedStudents,
    required Map<String, List<Map<String, dynamic>>> groupSelections,
    required Map<String, List<Map<String, dynamic>>> aiExercises,
    required bool isFrenchInterface,
    required bool isCompleteReport,
    String? singleGroupKey,
    required Map<String, bool> selectedPages, // NOUVEAU PARAMÈTRE
  }) {
    final t = _getTranslations(isFrenchInterface);
    String pagesHTML = '';

    // Déterminer quels groupes inclure
    List<String> groupsToInclude = [];

    if (isCompleteReport) {
      // N'inclure que les groupes sélectionnés
      if (selectedPages['treatment'] == true) {
        groupsToInclude.add(t['group_treatment']!);
      }
      if (selectedPages['support'] == true) {
        groupsToInclude.add(t['group_support']!);
      }
      if (selectedPages['excellence'] == true) {
        groupsToInclude.add(t['group_excellence']!);
      }
    } else if (singleGroupKey != null) {
      // Pour un rapport simple groupe, n'inclure que le groupe spécifique s'il est sélectionné
      switch (singleGroupKey) {
        case 'treatment':
          if (selectedPages['treatment'] == true) {
            groupsToInclude = [t['group_treatment']!];
          }
          break;
        case 'support':
          if (selectedPages['support'] == true) {
            groupsToInclude = [t['group_support']!];
          }
          break;
        case 'excellence':
          if (selectedPages['excellence'] == true) {
            groupsToInclude = [t['group_excellence']!];
          }
          break;
      }
    }

    for (final groupName in groupsToInclude) {
      final students = groupedStudents[groupName] ?? [];
      final selections =
          _getGroupSelectionsForGroup(groupName, groupSelections, t);

      // Récupérer les exercices AI pour ce groupe
      final groupKey = _getGroupKeyFromName(groupName, t);
      final groupAIExercises = aiExercises[groupKey] ?? [];

      if (students.isEmpty && selections.isEmpty && groupAIExercises.isEmpty) {
        continue;
      }

      // Déterminer la classe CSS selon le groupe
      String groupClass = '';
      String groupIcon = '';

      if (groupName == t['group_treatment']!) {
        groupClass = 'group-treatment';
        groupIcon = '🏥';
      } else if (groupName == t['group_support']!) {
        groupClass = 'group-support';
        groupIcon = '🤝';
      } else {
        groupClass = 'group-excellence';
        groupIcon = '🏆';
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
        
        <!-- Exercices AI -->
        ${groupAIExercises.isNotEmpty ? '''
        <div class="ai-exercises-section">
            <div class="ai-header">
                <span>🤖</span>
                <span>${t['ai_exercises']!}</span>
                <span class="ai-badge">${groupAIExercises.length}</span>
            </div>
            
            ${groupAIExercises.map((exercise) => '''
            <div class="ai-exercise-card">
                <div class="ai-exercise-header">
                    <span>📝 ${exercise['modifiedBaremeName'] ?? t['ai_exercise']!}</span>
                    <span class="ai-badge">${t['ai_generated']!}</span>
                </div>
                <div class="ai-exercise-content">
                    ${exercise['aiResponse']?.replaceAll('\n', '<br>') ?? ''}
                </div>
                <div class="ai-metadata">
                    ${_formatDate(exercise['createdAt'], isFrenchInterface)}
                </div>
            </div>
            ''').join('')}
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

  // Méthode utilitaire pour formater la date
  static String _formatDate(dynamic timestamp, bool isFrenchInterface) {
    if (timestamp == null) return '';
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return isFrenchInterface
            ? 'Généré le: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}'
            : 'تم الإنشاء: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}';
      }
    } catch (e) {}
    return '';
  }

  // Obtenir la clé du groupe à partir du nom
  static String _getGroupKeyFromName(String groupName, Map<String, String> t) {
    if (groupName == t['group_treatment']!) return 'treatment';
    if (groupName == t['group_support']!) return 'support';
    if (groupName == t['group_excellence']!) return 'excellence';
    return '';
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
            'criteria': "Critère d'évaluation",
            'sub_criteria': 'Sous-critère',
            'group': 'Groupe',
            'date': 'Date',
            'generated_on': 'Généré le',
            'complete_report': 'Rapport complet de classification',
            'group_report': 'Rapport de groupe',
            'general_info': 'Classification des erreurs dans',
            'statistics': 'Statistiques',
            'total_students': 'Total des élèves',
            'students': 'élève(s)',
            'group_treatment': 'Groupe de traitement',
            'group_support': 'Groupe de soutien',
            'group_excellence': "Groupe d'excellence",
            'overview': "Vue d'ensemble",
            'students_list': 'Liste des élèves',
            'student_name': "Nom de l'élève",
            'treatment_plan': 'Plan de traitement',
            'error_origin': "Origine de l'erreur",
            'solutions_title': "Origine de l'erreur",
            'problems_title': 'Problèmes identifiés',
            'ai_exercises': 'Exercices générés par IA',
            'ai_exercise': 'Exercice IA',
            'ai_generated': 'Généré par IA',
            'source': 'Source',
            'selected': 'Sélectionné',
            'unknown': 'Inconnu',
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
            'general_info': 'تصنيف الأخطاء في ',
            'statistics': 'إحصائيات',
            'total_students': 'مجموع التلاميذ',
            'students': 'تلميذ(ة)',
            'group_treatment': 'مجموعة العلاج',
            'group_support': 'مجموعة الدعم',
            'group_excellence': 'مجموعة التميز',
            'overview': 'نظرة عامة',
            'students_list': 'قائمة التلاميذ',
            'student_name': 'اسم التلميذ',
            'treatment_plan': 'خطة العلاج',
            'error_origin': 'أصل الخطأ',
            'solutions_title': 'أصل الخطأ',
            'problems_title': 'المشاكل المحددة',
            'ai_exercises': 'تمارين العلاج',
            'ai_exercise': 'تمرين ذكي',
            'ai_generated': ' ',
            'source': 'المصدر',
            'selected': 'محدد',
            'unknown': 'غير معروف',
            'json': 'موصى به',
            'global': 'معتمد',
            'personal': 'شخصي',
            'new': 'جديد',
          };
  }

  // Méthodes de génération de fichier
  static Future<void> _generateAndDownloadPDF(
      String htmlContent, String fileNamePrefix) async {
    try {
      if (kIsWeb) {
        print('Platforme Web détectée - Téléchargement HTML');
        await _downloadHTMLFileWeb(htmlContent, fileNamePrefix);
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

      // Utiliser XFile pour ouvrir le fichier
      final xFile = XFile(generatedPdfFile.path);
      await OpenFile.open(xFile.path);

      print('PDF ouvert avec succès');
    } catch (e) {
      print('Erreur lors de la génération du fichier PDF: $e');
      print('Fallback: téléchargement HTML...');

      if (kIsWeb) {
        await _downloadHTMLFileWeb(htmlContent, fileNamePrefix);
      } else {
        await _downloadHTMLFileMobile(htmlContent, fileNamePrefix);
      }
    }
  }

  // Version web du téléchargement HTML
  static Future<void> _downloadHTMLFileWeb(
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

        print('Fichier HTML téléchargé avec succès sur le web');
      }
    } catch (e) {
      print('Erreur lors du téléchargement HTML web: $e');
      rethrow;
    }
  }

  // Version mobile du téléchargement HTML
  static Future<void> _downloadHTMLFileMobile(
      String htmlContent, String fileNamePrefix) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.html';

      // Utiliser XFile pour écrire le fichier
      final xFile = XFile.fromData(
        Uint8List.fromList(htmlContent.codeUnits),
        name: '${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.html',
        mimeType: 'text/html',
      );

      await xFile.saveTo(filePath);
      await OpenFile.open(filePath);

      print('Fichier HTML généré avec succès sur mobile');
    } catch (e) {
      print('Erreur lors de la génération du fichier HTML mobile: $e');
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

  static Future<Map<String, bool>?> _showPageSelectionDialog({
    required BuildContext context,
    required String profName,
    required String matiereName,
    required String className,
    required String schoolName,
    required String baremeName,
    required String sousBaremeName,
    required Map<String, List<Map<String, dynamic>>> groupedStudents,
    required Map<String, List<Map<String, dynamic>>> groupSelections,
    required Map<String, List<Map<String, dynamic>>> aiExercises,
    required bool isFrenchInterface,
    required bool isCompleteReport,
  }) async {
    return await showDialog<Map<String, bool>>(
      context: context,
      builder: (context) => PageSelectionDialog(
        profName: profName,
        matiereName: matiereName,
        className: className,
        schoolName: schoolName,
        baremeName: baremeName,
        sousBaremeName: sousBaremeName,
        groupedStudents: groupedStudents,
        groupSelections: groupSelections,
        aiExercises: aiExercises,
        isFrenchInterface: isFrenchInterface,
        isCompleteReport: isCompleteReport,
      ),
    );
  }

  static Future<String?> _showTemplateSelectionDialog({
    required BuildContext context,
    required bool isFrenchInterface,
  }) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => TemplateSelectionDialog(
        isFrenchInterface: isFrenchInterface,
      ),
    );
  }

  static Map<String, String> _getTemplateStyles(String template) {
    switch (template) {
      case 'modern':
        return {
          'primaryColor': '#1a237e',
          'secondaryColor': '#3949ab',
          'accentColor': '#7986cb',
          'backgroundColor': '#ffffff',
          'headerBg': '#e8eaf6',
          'borderRadius': '8px',
          'boxShadow': '0 2px 8px rgba(0,0,0,0.1)',
          'fontFamily': 'Arial, sans-serif',
          'fontSize': '14px',
        };
      case 'minimal':
        return {
          'primaryColor': '#212121',
          'secondaryColor': '#616161',
          'accentColor': '#9e9e9e',
          'backgroundColor': '#ffffff',
          'headerBg': '#f5f5f5',
          'borderRadius': '0px',
          'boxShadow': 'none',
          'fontFamily': 'Helvetica, sans-serif',
          'fontSize': '13px',
        };
      case 'colorful':
        return {
          'primaryColor': '#e91e63',
          'secondaryColor': '#9c27b0',
          'accentColor': '#673ab7',
          'backgroundColor': '#fce4ec',
          'headerBg': '#f3e5f5',
          'borderRadius': '12px',
          'boxShadow': '0 4px 12px rgba(233,30,99,0.2)',
          'fontFamily': 'Georgia, serif',
          'fontSize': '15px',
        };
      case 'educational':
        return {
          'primaryColor': '#4caf50',
          'secondaryColor': '#2e7d32',
          'accentColor': '#81c784',
          'backgroundColor': '#e8f5e9',
          'headerBg': '#c8e6c9',
          'borderRadius': '6px',
          'boxShadow': '0 2px 6px rgba(76,175,80,0.15)',
          'fontFamily': 'Verdana, sans-serif',
          'fontSize': '14px',
        };
      default:
        return {
          'primaryColor': '#1565c0',
          'secondaryColor': '#1976d2',
          'accentColor': '#42a5f5',
          'backgroundColor': '#ffffff',
          'headerBg': '#e3f2fd',
          'borderRadius': '10px',
          'boxShadow': '0 2px 10px rgba(21,101,192,0.15)',
          'fontFamily': 'Arial, sans-serif',
          'fontSize': '14px',
        };
    }
  }
}

// Ajoutez cette classe après PDFClassificationGenerator
class PageSelectionDialog extends StatefulWidget {
  final String profName;
  final String matiereName;
  final String className;
  final String schoolName;
  final String baremeName;
  final String sousBaremeName;
  final Map<String, List<Map<String, dynamic>>> groupedStudents;
  final Map<String, List<Map<String, dynamic>>> groupSelections;
  final Map<String, List<Map<String, dynamic>>> aiExercises;
  final bool isFrenchInterface;
  final bool isCompleteReport;

  const PageSelectionDialog({
    Key? key,
    required this.profName,
    required this.matiereName,
    required this.className,
    required this.schoolName,
    required this.baremeName,
    required this.sousBaremeName,
    required this.groupedStudents,
    required this.groupSelections,
    required this.aiExercises,
    required this.isFrenchInterface,
    required this.isCompleteReport,
  }) : super(key: key);

  @override
  _PageSelectionDialogState createState() => _PageSelectionDialogState();
}

class _PageSelectionDialogState extends State<PageSelectionDialog> {
  final Map<String, bool> _selectedPages = {
    'cover': true,
    'general': true,
    'treatment': true,
    'support': true,
    'excellence': true,
  };

  bool _selectAll = true;
  late Map<String, String> _translations;

  @override
  void initState() {
    super.initState();
    _translations = _getPageTranslations(widget.isFrenchInterface);

    // Initialiser les sélections en fonction des groupes disponibles
    if (widget.isCompleteReport) {
      _selectedPages['cover'] = true;
      _selectedPages['general'] = true;

      // Obtenir les noms des groupes selon la langue
      final treatmentName =
          _getGroupNameByKey('treatment', widget.isFrenchInterface);
      final supportName =
          _getGroupNameByKey('support', widget.isFrenchInterface);
      final excellenceName =
          _getGroupNameByKey('excellence', widget.isFrenchInterface);

      _selectedPages['treatment'] =
          widget.groupedStudents.containsKey(treatmentName) ||
              (widget.groupSelections['treatment']?.isNotEmpty ?? false) ||
              (widget.aiExercises['treatment']?.isNotEmpty ?? false);

      _selectedPages['support'] =
          widget.groupedStudents.containsKey(supportName) ||
              (widget.groupSelections['support']?.isNotEmpty ?? false) ||
              (widget.aiExercises['support']?.isNotEmpty ?? false);

      _selectedPages['excellence'] =
          widget.groupedStudents.containsKey(excellenceName) ||
              (widget.groupSelections['excellence']?.isNotEmpty ?? false) ||
              (widget.aiExercises['excellence']?.isNotEmpty ?? false);
    } else {
      // Pour un rapport simple groupe, ne montrer que les pages pertinentes
      _selectedPages['cover'] = true;
      _selectedPages['general'] = true;

      // Le groupe spécifique sera toujours inclus
      if (widget.groupSelections.containsKey('treatment') &&
          widget.groupSelections['treatment']!.isNotEmpty) {
        _selectedPages['treatment'] = true;
        _selectedPages['support'] = false;
        _selectedPages['excellence'] = false;
      } else if (widget.groupSelections.containsKey('support') &&
          widget.groupSelections['support']!.isNotEmpty) {
        _selectedPages['treatment'] = false;
        _selectedPages['support'] = true;
        _selectedPages['excellence'] = false;
      } else {
        _selectedPages['treatment'] = false;
        _selectedPages['support'] = false;
        _selectedPages['excellence'] = true;
      }
    }

    // Mettre à jour selectAll
    _updateSelectAll();
  }

  String _getGroupNameByKey(String key, bool isFrench) {
    if (isFrench) {
      switch (key) {
        case 'treatment':
          return 'Groupe de traitement';
        case 'support':
          return 'Groupe de soutien';
        case 'excellence':
          return "Groupe d'excellence";
        default:
          return '';
      }
    } else {
      switch (key) {
        case 'treatment':
          return 'مجموعة العلاج';
        case 'support':
          return 'مجموعة الدعم';
        case 'excellence':
          return 'مجموعة التميز';
        default:
          return '';
      }
    }
  }

  void _updateSelectAll() {
    _selectAll = _selectedPages.values.every((selected) => selected);
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? true;
      for (var key in _selectedPages.keys) {
        _selectedPages[key] = _selectAll;
      }
    });
  }

  String _getPageDescription(String pageKey) {
    switch (pageKey) {
      case 'cover':
        return _translations['cover_desc']!;
      case 'general':
        return _translations['general_desc']!;
      case 'treatment':
        return _translations['treatment_desc']!;
      case 'support':
        return _translations['support_desc']!;
      case 'excellence':
        return _translations['excellence_desc']!;
      default:
        return '';
    }
  }

  int _getPageItemCount(String pageKey) {
    switch (pageKey) {
      case 'cover':
        return 1;
      case 'general':
        return 1;
      case 'treatment':
        int count = widget
                .groupedStudents[
                    _getGroupNameByKey('treatment', widget.isFrenchInterface)]
                ?.length ??
            0;
        count += widget.groupSelections['treatment']?.length ?? 0;
        count += widget.aiExercises['treatment']?.length ?? 0;
        return count;
      case 'support':
        int count = widget
                .groupedStudents[
                    _getGroupNameByKey('support', widget.isFrenchInterface)]
                ?.length ??
            0;
        count += widget.groupSelections['support']?.length ?? 0;
        count += widget.aiExercises['support']?.length ?? 0;
        return count;
      case 'excellence':
        int count = widget
                .groupedStudents[
                    _getGroupNameByKey('excellence', widget.isFrenchInterface)]
                ?.length ??
            0;
        count += widget.groupSelections['excellence']?.length ?? 0;
        count += widget.aiExercises['excellence']?.length ?? 0;
        return count;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.purple.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.pages,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _translations['title']!,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      Text(
                        _translations['subtitle']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Option Tout sélectionner
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _selectAll,
                    onChanged: _toggleSelectAll,
                    activeColor: Colors.blue.shade700,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _translations['select_all']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedPages.values.where((v) => v).length}/${_selectedPages.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Liste des pages
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPageOption(
                      key: 'cover',
                      icon: Icons.article,
                      color: Colors.purple,
                    ),
                    _buildPageOption(
                      key: 'general',
                      icon: Icons.info,
                      color: Colors.blue,
                    ),
                    _buildPageOption(
                      key: 'treatment',
                      icon: Icons.medical_services,
                      color: Colors.red,
                    ),
                    _buildPageOption(
                      key: 'support',
                      icon: Icons.support,
                      color: Colors.orange,
                    ),
                    _buildPageOption(
                      key: 'excellence',
                      icon: Icons.emoji_events,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.cancel),
                    label: Text(_translations['cancel']!),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, _selectedPages);
                    },
                    icon: Icon(Icons.check_circle),
                    label: Text(_translations['generate']!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageOption({
    required String key,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedPages[key]! ? color : Colors.grey.shade300,
          width: _selectedPages[key]! ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: _selectedPages[key]! ? color.withOpacity(0.05) : null,
      ),
      child: CheckboxListTile(
        value: _selectedPages[key],
        onChanged: (value) {
          setState(() {
            _selectedPages[key] = value!;
            _updateSelectAll();
          });
        },
        activeColor: color,
        checkboxShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _translations[key]!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          _selectedPages[key]! ? color : Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getPageDescription(key),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_getPageItemCount(key)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  static Map<String, String> _getPageTranslations(bool isFrench) {
    return isFrench
        ? {
            'title': 'Sélectionner les pages à imprimer',
            'subtitle': 'Choisissez les sections à inclure dans le rapport',
            'select_all': 'Tout sélectionner',
            'cancel': 'Annuler',
            'generate': 'Générer le PDF',
            'cover': 'Page de garde',
            'cover_desc': 'Informations générales et en-tête',
            'general': 'Informations générales',
            'general_desc': 'Statistiques et vue d\'ensemble',
            'treatment': 'Groupe de traitement',
            'treatment_desc': 'Élèves, problèmes et exercices',
            'support': 'Groupe de soutien',
            'support_desc': 'Élèves, problèmes et exercices',
            'excellence': "Groupe d'excellence",
            'excellence_desc': 'Élèves, problèmes et exercices',
          }
        : {
            'title': 'اختر الصفحات للطباعة',
            'subtitle': 'اختر الأقسام التي تريد تضمينها في التقرير',
            'select_all': 'تحديد الكل',
            'cancel': 'إلغاء',
            'generate': 'إنشاء PDF',
            'cover': 'صفحة الغلاف',
            'cover_desc': 'معلومات عامة ورأس التقرير',
            'general': 'معلومات عامة',
            'general_desc': 'إحصائيات ونظرة عامة',
            'treatment': 'مجموعة العلاج',
            'treatment_desc': 'التلاميذ، المشاكل والتمارين',
            'support': 'مجموعة الدعم',
            'support_desc': 'التلاميذ، المشاكل والتمارين',
            'excellence': 'مجموعة التميز',
            'excellence_desc': 'التلاميذ، المشاكل والتمارين',
          };
  }
}

class TemplateSelectionDialog extends StatefulWidget {
  final bool isFrenchInterface;

  const TemplateSelectionDialog({
    Key? key,
    required this.isFrenchInterface,
  }) : super(key: key);

  @override
  _TemplateSelectionDialogState createState() =>
      _TemplateSelectionDialogState();
}

class _TemplateSelectionDialogState extends State<TemplateSelectionDialog> {
  String _selectedTemplate = 'default';

  final List<Map<String, dynamic>> _templates = [
    {
      'id': 'default',
      'name_ar': 'القالب الافتراضي',
      'name_fr': 'Template par défaut',
      'description_ar': 'تصميم كلاسيكي مع ألوان احترافية',
      'description_fr': 'Design classique avec couleurs professionnelles',
      'preview': Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Icon(Icons.description, color: Colors.white, size: 40),
        ),
      ),
    },
    {
      'id': 'modern',
      'name_ar': 'تصميم حديث',
      'name_fr': 'Design moderne',
      'description_ar': 'واجهة عصرية وأنيقة',
      'description_fr': 'Interface moderne et élégante',
      'preview': Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(Icons.web, color: Colors.white, size: 40),
        ),
      ),
    },
    {
      'id': 'minimal',
      'name_ar': 'تصميم بسيط',
      'name_fr': 'Design minimaliste',
      'description_ar': 'تصميم نظيف ومبسط',
      'description_fr': 'Design épuré et simplifié',
      'preview': Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(0),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Icon(Icons.article, color: Colors.grey[600], size: 40),
        ),
      ),
    },
    {
      'id': 'colorful',
      'name_ar': 'تصميم ملون',
      'name_fr': 'Design coloré',
      'description_ar': 'تصميم مشرق وجذاب',
      'description_fr': 'Design vivant et attrayant',
      'preview': Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(Icons.palette, color: Colors.white, size: 40),
        ),
      ),
    },
    {
      'id': 'educational',
      'name_ar': 'تصميم تعليمي',
      'name_fr': 'Design éducatif',
      'description_ar': 'تصميم مناسب للبيئة التعليمية',
      'description_fr': 'Design adapté au milieu éducatif',
      'preview': Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Icon(Icons.school, color: Colors.white, size: 40),
        ),
      ),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 500;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 32, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * (isSmallScreen ? 0.95 : 0.7),
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.dashboard_customize,
                    color: Colors.purple.shade700,
                    size: isSmallScreen ? 24 : 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.isFrenchInterface
                        ? 'اختر قالب التصميم'
                        : 'Choisir le template de design',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade800,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 8 : 16),
            Text(
              widget.isFrenchInterface
                  ? 'اختر نمط التصميم الذي يناسبك'
                  : 'Choisissez le style de design qui vous convient',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 20),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: isSmallScreen ? 8 : 12,
                  runSpacing: isSmallScreen ? 8 : 12,
                  children: _templates.map((template) {
                    final isSelected = _selectedTemplate == template['id'];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedTemplate = template['id'];
                        });
                      },
                      child: Container(
                        width: isSmallScreen
                            ? (MediaQuery.of(context).size.width - 48) / 2
                            : 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.purple
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          color:
                              isSelected ? Colors.purple.shade50 : Colors.white,
                        ),
                        child: Column(
                          children: [
                            // Preview
                            Container(
                              height: isSmallScreen ? 60 : 80,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(11),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: template['preview'],
                            ),
                            // Info
                            Padding(
                              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.isFrenchInterface
                                        ? template['name_ar']
                                        : template['name_fr'],
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11 : 13,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.purple
                                          : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    widget.isFrenchInterface
                                        ? template['description_ar']
                                        : template['description_fr'],
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 9 : 10,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    widget.isFrenchInterface ? 'إلغاء' : 'Annuler',
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, _selectedTemplate);
                  },
                  icon: Icon(Icons.check, size: isSmallScreen ? 18 : 20),
                  label: Text(
                    widget.isFrenchInterface ? 'تأكيد' : 'Confirmer',
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 24,
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
