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
  static String _darkenColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      final r = int.parse(hexColor.substring(0, 2), radix: 16);
      final g = int.parse(hexColor.substring(2, 4), radix: 16);
      final b = int.parse(hexColor.substring(4, 6), radix: 16);
      final darkenFactor = 0.8;
      final newR = (r * darkenFactor).round().toRadixString(16).padLeft(2, '0');
      final newG = (g * darkenFactor).round().toRadixString(16).padLeft(2, '0');
      final newB = (b * darkenFactor).round().toRadixString(16).padLeft(2, '0');
      return '#$newR$newG$newB';
    }
    return hexColor;
  }

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
        templateStyles: templateStyles,
        selectedTemplate: selectedTemplate,
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
        templateStyles: templateStyles,
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
      selectedPages: selectedPages,
      templateStyles: templateStyles,
    );

    return '''
<!DOCTYPE html>
<html lang="${isFrenchInterface ? 'fr' : 'ar'}" dir="$direction">
${_buildStyledHead(isFrenchInterface, direction, templateStyles, selectedTemplate, t)}
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
    required Map<String, String> templateStyles,
    required String selectedTemplate,
  }) {
    final t = _getTranslations(isFrenchInterface);
    final ts = templateStyles;
    final reportType = isCompleteReport
        ? t['complete_report']!
        : '${t['group_report']!} - ${singleGroupName ?? ''}';

    final primaryColor = ts['primaryColor'] ?? '#1565c0';
    final secondaryColor = ts['secondaryColor'] ?? '#1976d2';
    final accentColor = ts['accentColor'] ?? '#42a5f5';
    final headerBg = ts['headerBg'] ?? '#e3f2fd';
    final borderRadius = ts['borderRadius'] ?? '10px';
    final boxShadow = ts['boxShadow'] ?? '0 4px 15px rgba(21,101,192,0.2)';
    final fontFamily = ts['fontFamily'] ?? 'Arial, sans-serif';
    final coverGradient = ts['coverGradient'] ??
        'linear-gradient(135deg, $primaryColor 0%, $secondaryColor 50%, $accentColor 100%)';

    final svgDecorator =
        _getSVGDecorator(selectedTemplate, primaryColor, accentColor);

    return '''
    <div class="cover-page" style="font-family: $fontFamily; padding: 20px; max-width: 800px; margin: 0 auto;">
        <!-- SVG Decorator -->
        $svgDecorator
        
        <!-- Header avec dégradé -->
        <div class="cover-header" style="background: $coverGradient; padding: 35px 25px; border-radius: $borderRadius; margin-bottom: 30px; position: relative; overflow: hidden;">
            <div style="position: absolute; top: -50px; right: -50px; width: 200px; height: 200px; background: rgba(255,255,255,0.1); border-radius: 50%;"></div>
            <div style="position: absolute; bottom: -30px; left: -30px; width: 100px; height: 100px; background: rgba(255,255,255,0.05); border-radius: 50%;"></div>
            <div style="position: relative; z-index: 1;">
                <h1 style="color: white; font-size: 22px; margin: 0 0 8px 0; font-weight: 700;">${t['ministry_title']!}</h1>
                <div style="color: rgba(255,255,255,0.9); font-size: 14px;">${t['regional_delegation']!}</div>
            </div>
        </div>
        
        <!-- Logo -->
        ${logoBase64.isNotEmpty ? '''
        <div style="text-align: center; margin-bottom: 25px;">
            <img src="data:image/png;base64,$logoBase64" style="max-width: 140px; max-height: 90px; filter: drop-shadow(0 2px 4px rgba(0,0,0,0.1));">
        </div>
        ''' : ''}
        
        <!-- École -->
        <div class="school-card" style="background: $headerBg; padding: 15px 20px; border-radius: $borderRadius; text-align: center; margin-bottom: 25px; ${boxShadow != 'none' ? 'box-shadow: $boxShadow;' : ''}">
            <span style="font-size: 13px; color: #666;">${t['school']!}</span>
            <div style="font-size: 18px; font-weight: 600; color: $primaryColor; margin-top: 5px;">$schoolName</div>
        </div>
        
        <!-- Grille d'informations -->
        <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; margin-bottom: 20px;">
            <div class="info-card" style="background: white; padding: 18px; border-radius: $borderRadius; border-left: 4px solid $primaryColor; ${boxShadow != 'none' ? 'box-shadow: $boxShadow;' : ''}">
                <div style="display: flex; align-items: center; gap: 12px;">
                    <div style="width: 40px; height: 40px; background: $headerBg; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px;">👨‍🏫</div>
                    <div>
                        <div style="font-size: 11px; color: #888; text-transform: uppercase;">${t['professor']!}</div>
                        <div style="font-size: 14px; font-weight: 600; color: #333; margin-top: 2px;">$profName</div>
                    </div>
                </div>
            </div>
            
            <div class="info-card" style="background: white; padding: 18px; border-radius: $borderRadius; border-left: 4px solid $accentColor; ${boxShadow != 'none' ? 'box-shadow: $boxShadow;' : ''}">
                <div style="display: flex; align-items: center; gap: 12px;">
                    <div style="width: 40px; height: 40px; background: $headerBg; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px;">📚</div>
                    <div>
                        <div style="font-size: 11px; color: #888; text-transform: uppercase;">${t['subject']!}</div>
                        <div style="font-size: 14px; font-weight: 600; color: #333; margin-top: 2px;">$matiereName</div>
                    </div>
                </div>
            </div>
            
            <div class="info-card" style="background: white; padding: 18px; border-radius: $borderRadius; border-left: 4px solid $secondaryColor; ${boxShadow != 'none' ? 'box-shadow: $boxShadow;' : ''}">
                <div style="display: flex; align-items: center; gap: 12px;">
                    <div style="width: 40px; height: 40px; background: $headerBg; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px;">👥</div>
                    <div>
                        <div style="font-size: 11px; color: #888; text-transform: uppercase;">${t['class']!}</div>
                        <div style="font-size: 14px; font-weight: 600; color: #333; margin-top: 2px;">$className</div>
                    </div>
                </div>
            </div>
            
            <div class="info-card" style="background: white; padding: 18px; border-radius: $borderRadius; border-left: 4px solid #7b1fa2; ${boxShadow != 'none' ? 'box-shadow: $boxShadow;' : ''}">
                <div style="display: flex; align-items: center; gap: 12px;">
                    <div style="width: 40px; height: 40px; background: $headerBg; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px;">📝</div>
                    <div>
                        <div style="font-size: 11px; color: #888; text-transform: uppercase;">${t['criteria']!}</div>
                        <div style="font-size: 14px; font-weight: 600; color: #333; margin-top: 2px;">$baremeName</div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Sous-critère -->
        ${sousBaremeName.isNotEmpty ? '''
        <div class="sub-criteria-card" style="background: linear-gradient(135deg, $headerBg 0%, white 100%); padding: 18px 20px; border-radius: $borderRadius; margin-bottom: 25px; border: 1px dashed $primaryColor; ${boxShadow != 'none' ? 'box-shadow: $boxShadow;' : ''}">
            <div style="display: flex; align-items: center; gap: 12px;">
                <div style="width: 36px; height: 36px; background: $primaryColor; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px;">📋</div>
                <div>
                    <div style="font-size: 11px; color: #888; text-transform: uppercase;">${t['sub_criteria']!}</div>
                    <div style="font-size: 14px; font-weight: 600; color: $primaryColor; margin-top: 2px;">$sousBaremeName</div>
                </div>
            </div>
        </div>
        ''' : ''}
        
        <!-- Type de rapport -->
        <div class="report-type-card" style="background: $coverGradient; padding: 25px; border-radius: $borderRadius; text-align: center; margin: 25px 0;">
            <div style="font-size: 16px; color: white; font-weight: 600;">$reportType</div>
            ${!isCompleteReport && singleGroupName != null ? '''
            <div style="font-size: 14px; color: rgba(255,255,255,0.9); margin-top: 8px;">
                ${t['group']!}: <strong>$singleGroupName</strong>
            </div>
            ''' : ''}
        </div>
        
        <!-- Footer -->
        <div style="text-align: center; margin-top: 35px; padding-top: 20px; border-top: 2px solid #eee;">
            <div style="font-size: 12px; color: #999;">${t['generated_on']!} ${DateFormat('dd/MM/yyyy').format(now)}</div>
            <div style="font-size: 11px; color: #bbb; margin-top: 5px;">${isFrenchInterface ? 'Pour imprimer: Ctrl+P' : 'للطباعة: Ctrl+P'}</div>
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
    Map<String, String>? templateStyles,
  }) {
    final t = _getTranslations(isFrenchInterface);
    final ts = templateStyles ?? {};
    final primaryColor = ts['primaryColor'] ?? '#1565c0';
    final secondaryColor = ts['secondaryColor'] ?? '#1976d2';
    final borderRadius = ts['borderRadius'] ?? '10px';
    final boxShadow = ts['boxShadow'] ?? '0 4px 15px rgba(0,0,0,0.1)';

    final totalStudents =
        groupedStudents.values.fold(0, (sum, group) => sum + group.length);
    final treatmentCount = groupedStudents[t['group_treatment']!]?.length ?? 0;
    final supportCount = groupedStudents[t['group_support']!]?.length ?? 0;
    final excellenceCount =
        groupedStudents[t['group_excellence']!]?.length ?? 0;

    final groupTreatmentGradient = ts['groupTreatmentGradient'] ??
        'linear-gradient(135deg, #d32f2f, #c62828)';
    final groupSupportGradient = ts['groupSupportGradient'] ??
        'linear-gradient(135deg, #f57c00, #ef6c00)';
    final groupExcellenceGradient = ts['groupExcellenceGradient'] ??
        'linear-gradient(135deg, #388e3c, #2e7d32)';

    return '''
    <div class="general-info-page" style="padding: 20px; max-width: 800px; margin: 0 auto;">
        <div style="background: linear-gradient(135deg, $primaryColor, $secondaryColor); padding: 20px 25px; border-radius: $borderRadius; margin-bottom: 25px;">
            <h2 style="color: white; font-size: 18px; margin: 0;">${t['general_info']!}</h2>
            <div style="color: rgba(255,255,255,0.9); font-size: 14px; margin-top: 5px;">$baremeName - $matiereName</div>
        </div>
        
        <h3 class="section-title" style="color: $primaryColor; margin-bottom: 15px;">${t['statistics']!}</h3>
        
        <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 25px;">
            ${_statBoxHTML('🏥 ${t['group_treatment']!}', treatmentCount, groupTreatmentGradient)}
            ${_statBoxHTML('🤝 ${t['group_support']!}', supportCount, groupSupportGradient)}
            ${_statBoxHTML('🏆 ${t['group_excellence']!}', excellenceCount, groupExcellenceGradient)}
            ${_statBoxHTML('👥 ${t['total_students']!}', totalStudents, 'linear-gradient(135deg, $primaryColor, $secondaryColor)')}
        </div>
        
        <div style="background: white; border-radius: $borderRadius; padding: 20px; ${boxShadow != 'none' ? 'box-shadow: $boxShadow;' : ''} border: 1px solid #eee;">
            <h4 style="color: #333; font-size: 14px; margin: 0 0 15px 0;">${isFrenchInterface ? 'Résumé' : 'ملخص'}</h4>
            <div style="display: flex; gap: 20px; flex-wrap: wrap;">
                <div style="flex: 1; min-width: 150px;">
                    <div style="font-size: 11px; color: #888; text-transform: uppercase;">${t['professor']!}</div>
                    <div style="font-size: 13px; color: #333; font-weight: 500;">$profName</div>
                </div>
                <div style="flex: 1; min-width: 150px;">
                    <div style="font-size: 11px; color: #888; text-transform: uppercase;">${t['subject']!}</div>
                    <div style="font-size: 13px; color: #333; font-weight: 500;">$matiereName</div>
                </div>
                <div style="flex: 1; min-width: 150px;">
                    <div style="font-size: 11px; color: #888; text-transform: uppercase;">${t['class']!}</div>
                    <div style="font-size: 13px; color: #333; font-weight: 500;">$className</div>
                </div>
                <div style="flex: 1; min-width: 150px;">
                    <div style="font-size: 11px; color: #888; text-transform: uppercase;">${t['school']!}</div>
                    <div style="font-size: 13px; color: #333; font-weight: 500;">$schoolName</div>
                </div>
            </div>
        </div>
        
        <div class="report-footer" style="margin-top: 30px; text-align: center;">
            <p style="color: #999; font-size: 11px;">${isFrenchInterface ? 'Page 2' : 'الصفحة 2'}</p>
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
    required Map<String, bool> selectedPages,
    Map<String, String>? templateStyles,
  }) {
    final t = _getTranslations(isFrenchInterface);
    final ts = templateStyles ?? {};
    final primaryColor = ts['primaryColor'] ?? '#1565c0';
    final borderRadius = ts['borderRadius'] ?? '10px';
    final boxShadow = ts['boxShadow'] ?? '0 4px 15px rgba(0,0,0,0.1)';
    final groupTreatmentGradient = ts['groupTreatmentGradient'] ??
        'linear-gradient(135deg, #d32f2f, #c62828)';
    final groupSupportGradient = ts['groupSupportGradient'] ??
        'linear-gradient(135deg, #f57c00, #ef6c00)';
    final groupExcellenceGradient = ts['groupExcellenceGradient'] ??
        'linear-gradient(135deg, #388e3c, #2e7d32)';

    String pagesHTML = '';

    List<String> groupsToInclude = [];

    if (isCompleteReport) {
      if (selectedPages['treatment'] == true)
        groupsToInclude.add(t['group_treatment']!);
      if (selectedPages['support'] == true)
        groupsToInclude.add(t['group_support']!);
      if (selectedPages['excellence'] == true)
        groupsToInclude.add(t['group_excellence']!);
    } else if (singleGroupKey != null) {
      switch (singleGroupKey) {
        case 'treatment':
          if (selectedPages['treatment'] == true)
            groupsToInclude = [t['group_treatment']!];
          break;
        case 'support':
          if (selectedPages['support'] == true)
            groupsToInclude = [t['group_support']!];
          break;
        case 'excellence':
          if (selectedPages['excellence'] == true)
            groupsToInclude = [t['group_excellence']!];
          break;
      }
    }

    for (final groupName in groupsToInclude) {
      final students = groupedStudents[groupName] ?? [];
      final selections =
          _getGroupSelectionsForGroup(groupName, groupSelections, t);
      final groupKey = _getGroupKeyFromName(groupName, t);
      final groupAIExercises = aiExercises[groupKey] ?? [];

      if (students.isEmpty && selections.isEmpty && groupAIExercises.isEmpty)
        continue;

      String groupClass = '';
      String groupIcon = '';
      String groupGradient = primaryColor;

      if (groupName == t['group_treatment']!) {
        groupClass = 'group-treatment';
        groupIcon = '🏥';
        groupGradient = groupTreatmentGradient;
      } else if (groupName == t['group_support']!) {
        groupClass = 'group-support';
        groupIcon = '🤝';
        groupGradient = groupSupportGradient;
      } else {
        groupClass = 'group-excellence';
        groupIcon = '🏆';
        groupGradient = groupExcellenceGradient;
      }

      final solutions =
          selections.where((item) => item['isProblem'] == false).toList();
      final problems =
          selections.where((item) => item['isProblem'] == true).toList();

      pagesHTML += '''
    <div class="group-page $groupClass" style="padding: 20px; max-width: 800px; margin: 0 auto 30px auto; background: white; border-radius: $borderRadius; ${boxShadow != 'none' ? 'box-shadow: $boxShadow;' : ''}">
        <div class="group-header-custom" style="background: $groupGradient; color: white; padding: 20px 25px; border-radius: $borderRadius; margin-bottom: 20px;">
            <div style="display: flex; justify-content: space-between; align-items: center;">
                <div style="display: flex; align-items: center; gap: 12px;">
                    <span style="font-size: 24px;">$groupIcon</span>
                    <span style="font-size: 18px; font-weight: 600;">$groupName</span>
                </div>
                <div style="background: rgba(255,255,255,0.25); padding: 6px 16px; border-radius: 20px; font-size: 13px;">
                    👥 ${students.length} ${t['students']!}
                </div>
            </div>
        </div>
        
        ${students.isNotEmpty ? '''
        <div style="margin-bottom: 25px;">
            <h3 class="section-subtitle" style="color: $primaryColor;">${t['students_list']!}</h3>
            <div style="display: flex; flex-wrap: wrap; gap: 8px;">
                ${students.asMap().entries.map((e) => _studentChipHTML(e.key + 1, e.value, t)).join('')}
            </div>
        </div>
        ''' : ''}
        
        ${problems.isNotEmpty ? '''
        <div style="margin-bottom: 20px;">
            <h3 class="section-subtitle" style="color: #d32f2f;">⚠️ ${t['problems_title']!} (${problems.length})</h3>
            <ul class="items-list">
                ${problems.map((p) => _itemCardHTML(p, true)).join('')}
            </ul>
        </div>
        ''' : ''}
        
        ${solutions.isNotEmpty ? '''
        <div style="margin-bottom: 20px;">
            <h3 class="section-subtitle" style="color: #388e3c;">✨ ${t['solutions_title']!} (${solutions.length})</h3>
            <ul class="items-list">
                ${solutions.map((s) => _itemCardHTML(s, false)).join('')}
            </ul>
        </div>
        ''' : ''}
        
        ${groupAIExercises.isNotEmpty ? '''
        <div style="background: #f3e5f5; padding: 15px; border-radius: $borderRadius; border: 1px solid #e1bee7;">
            <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 15px;">
                <span style="font-size: 20px;">🤖</span>
                <span style="color: #7b1fa2; font-weight: 600; font-size: 14px;">${t['ai_exercises']!}</span>
                <span class="ai-badge">${groupAIExercises.length}</span>
            </div>
            ${groupAIExercises.map((exercise) => '''
            <div style="background: white; padding: 15px; border-radius: 8px; margin-bottom: 10px; border: 1px solid #e1bee7;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                    <span style="color: #7b1fa2; font-weight: 500; font-size: 13px;">📝 ${exercise['modifiedBaremeName'] ?? t['ai_exercise']!}</span>
                    <span class="ai-badge">${t['ai_generated']!}</span>
                </div>
                <div class="ai-exercise-content">${exercise['aiResponse']?.replaceAll('\n', '<br>') ?? ''}</div>
                <div class="ai-metadata">${_formatDate(exercise['createdAt'], isFrenchInterface)}</div>
            </div>
            ''').join('')}
        </div>
        ''' : ''}
        
        <div style="margin-top: 20px; padding-top: 15px; border-top: 1px solid #eee; text-align: center;">
            <span style="color: #999; font-size: 11px;">${isFrenchInterface ? 'Groupe $groupName' : 'مجموعة $groupName'}</span>
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
          'accentColor': '#82b1ff',
          'backgroundColor': '#f0f2ff',
          'headerBg': '#e8eaf6',
          'borderRadius': '4px',
          'boxShadow': '4px 4px 0px rgba(26,35,126,0.15)',
          'fontFamily': '"Trebuchet MS", "Gill Sans", sans-serif',
          'fontSize': '14px',
          'cardBorder': '2px solid #1a237e',
          'sectionTitleStyle':
              'letter-spacing: 2px; text-transform: uppercase; font-size: 13px;',
          'coverGradient':
              'linear-gradient(135deg, #1a237e 0%, #283593 50%, #1565c0 100%)',
          'groupTreatmentGradient':
              'linear-gradient(135deg, #b71c1c 0%, #c62828 100%)',
          'groupSupportGradient':
              'linear-gradient(135deg, #e65100 0%, #ef6c00 100%)',
          'groupExcellenceGradient':
              'linear-gradient(135deg, #1b5e20 0%, #2e7d32 100%)',
          'studentCardBg': '#e8eaf6',
          'badgeBg': '#1a237e',
          'badgeText': '#ffffff',
          'decorativeElement': 'geometric',
        };
      case 'minimal':
        return {
          'primaryColor': '#111111',
          'secondaryColor': '#444444',
          'accentColor': '#111111',
          'backgroundColor': '#ffffff',
          'headerBg': '#f7f7f7',
          'borderRadius': '0px',
          'boxShadow': 'none',
          'fontFamily': '"Palatino Linotype", "Book Antiqua", Georgia, serif',
          'fontSize': '13.5px',
          'cardBorder': '1px solid #e0e0e0',
          'sectionTitleStyle':
              'letter-spacing: 4px; text-transform: uppercase; font-size: 11px; font-weight: 400;',
          'coverGradient': 'linear-gradient(180deg, #111111 0%, #333333 100%)',
          'groupTreatmentGradient':
              'linear-gradient(180deg, #222222 0%, #444444 100%)',
          'groupSupportGradient':
              'linear-gradient(180deg, #444444 0%, #666666 100%)',
          'groupExcellenceGradient':
              'linear-gradient(180deg, #111111 0%, #222222 100%)',
          'studentCardBg': '#f9f9f9',
          'badgeBg': '#111111',
          'badgeText': '#ffffff',
          'decorativeElement': 'line',
        };
      case 'colorful':
        return {
          'primaryColor': '#ad1457',
          'secondaryColor': '#7b1fa2',
          'accentColor': '#ff4081',
          'backgroundColor': '#fce4ec',
          'headerBg': '#f8bbd9',
          'borderRadius': '20px',
          'boxShadow': '0 8px 24px rgba(173,20,87,0.18)',
          'fontFamily': '"Comic Sans MS", "Chalkboard SE", cursive',
          'fontSize': '15px',
          'cardBorder': '2px dashed #ad1457',
          'sectionTitleStyle': 'font-size: 17px; font-weight: 800;',
          'coverGradient':
              'linear-gradient(135deg, #ad1457 0%, #7b1fa2 50%, #4a148c 100%)',
          'groupTreatmentGradient':
              'linear-gradient(135deg, #c62828 0%, #e53935 100%)',
          'groupSupportGradient':
              'linear-gradient(135deg, #e65100 0%, #ff6d00 100%)',
          'groupExcellenceGradient':
              'linear-gradient(135deg, #1b5e20 0%, #43a047 100%)',
          'studentCardBg': '#fce4ec',
          'badgeBg': '#ad1457',
          'badgeText': '#ffffff',
          'decorativeElement': 'dots',
        };
      case 'educational':
        return {
          'primaryColor': '#2e7d32',
          'secondaryColor': '#388e3c',
          'accentColor': '#66bb6a',
          'backgroundColor': '#f1f8e9',
          'headerBg': '#dcedc8',
          'borderRadius': '8px',
          'boxShadow': '0 3px 8px rgba(46,125,50,0.2)',
          'fontFamily': '"Century Gothic", "Gill Sans MT", Verdana, sans-serif',
          'fontSize': '14px',
          'cardBorder': '1px solid #a5d6a7',
          'sectionTitleStyle': 'letter-spacing: 1px; font-size: 15px;',
          'coverGradient':
              'linear-gradient(135deg, #1b5e20 0%, #2e7d32 50%, #388e3c 100%)',
          'groupTreatmentGradient':
              'linear-gradient(135deg, #bf360c 0%, #d84315 100%)',
          'groupSupportGradient':
              'linear-gradient(135deg, #e65100 0%, #f57c00 100%)',
          'groupExcellenceGradient':
              'linear-gradient(135deg, #1b5e20 0%, #2e7d32 100%)',
          'studentCardBg': '#f1f8e9',
          'badgeBg': '#2e7d32',
          'badgeText': '#ffffff',
          'decorativeElement': 'leaf',
        };
      default:
        return {
          'primaryColor': '#01579b',
          'secondaryColor': '#0277bd',
          'accentColor': '#29b6f6',
          'backgroundColor': '#e1f5fe',
          'headerBg': '#b3e5fc',
          'borderRadius': '10px',
          'boxShadow': '0 4px 16px rgba(1,87,155,0.15)',
          'fontFamily': '"Segoe UI", Tahoma, Geneva, sans-serif',
          'fontSize': '14px',
          'cardBorder': '1px solid #b3e5fc',
          'sectionTitleStyle': 'font-size: 15px;',
          'coverGradient':
              'linear-gradient(135deg, #01579b 0%, #0277bd 60%, #0288d1 100%)',
          'groupTreatmentGradient':
              'linear-gradient(135deg, #b71c1c 0%, #d32f2f 100%)',
          'groupSupportGradient':
              'linear-gradient(135deg, #e65100 0%, #f57c00 100%)',
          'groupExcellenceGradient':
              'linear-gradient(135deg, #1b5e20 0%, #388e3c 100%)',
          'studentCardBg': '#e1f5fe',
          'badgeBg': '#01579b',
          'badgeText': '#ffffff',
          'decorativeElement': 'wave',
        };
    }
  }

  static String _getSVGDecorator(
      String template, String primary, String accent) {
    switch (template) {
      case 'modern':
        return '''<svg width="120" height="120" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" style="position:absolute;top:20px;right:20px;opacity:0.07;">
          <polygon points="60,0 120,60 60,120 0,60" fill="$primary"/>
          <polygon points="60,20 100,60 60,100 20,60" fill="$accent"/>
          <polygon points="60,40 80,60 60,80 40,60" fill="$primary"/>
        </svg>''';
      case 'minimal':
        return '''<svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg" style="position:absolute;top:30px;right:30px;opacity:0.06;">
          <circle cx="40" cy="40" r="38" stroke="#111" stroke-width="2" fill="none"/>
          <line x1="40" y1="2" x2="40" y2="78" stroke="#111" stroke-width="1"/>
          <line x1="2" y1="40" x2="78" y2="40" stroke="#111" stroke-width="1"/>
        </svg>''';
      case 'colorful':
        return '''<svg width="140" height="140" viewBox="0 0 140 140" xmlns="http://www.w3.org/2000/svg" style="position:absolute;top:-20px;right:-20px;opacity:0.12;">
          <circle cx="70" cy="70" r="70" fill="$primary"/>
          <circle cx="70" cy="70" r="50" fill="$accent"/>
          <circle cx="70" cy="70" r="30" fill="white"/>
        </svg>''';
      case 'educational':
        return '''<svg width="100" height="80" viewBox="0 0 100 80" xmlns="http://www.w3.org/2000/svg" style="position:absolute;bottom:20px;right:20px;opacity:0.08;">
          <path d="M50 0 L100 25 L100 75 L50 80 L0 75 L0 25 Z" fill="$primary"/>
          <path d="M50 15 L85 32 L85 65 L50 68 L15 65 L15 32 Z" fill="$accent"/>
        </svg>''';
      default:
        return '''<svg width="120" height="60" viewBox="0 0 120 60" xmlns="http://www.w3.org/2000/svg" style="position:absolute;bottom:0;right:0;opacity:0.06;">
          <path d="M0 60 Q30 0 60 30 Q90 60 120 10 L120 60 Z" fill="$primary"/>
        </svg>''';
    }
  }

  static String _getTemplateCSSBlock(
      String template, Map<String, String> ts, bool isFrench) {
    final primary = ts['primaryColor']!;
    final accent = ts['accentColor']!;
    final bg = ts['backgroundColor']!;
    final headerBg = ts['headerBg']!;
    final radius = ts['borderRadius']!;
    final shadow = ts['boxShadow']!;
    final font = ts['fontFamily']!;
    final cardBorder = ts['cardBorder']!;
    final sectionStyle = ts['sectionTitleStyle']!;
    final coverGradient = ts['coverGradient']!;
    final studentCardBg = ts['studentCardBg']!;
    final badgeBg = ts['badgeBg']!;

    switch (template) {
      case 'modern':
        return '''
        body { font-family: $font; background: #f0f2ff; }
        .cover-page { position: relative; border-left: 6px solid $primary; }
        .cover-page::before {
          content: '';
          position: absolute;
          top: 0; right: 0;
          width: 180px; height: 100%;
          background: repeating-linear-gradient(45deg, rgba(26,35,126,0.06) 0px, rgba(26,35,126,0.06) 2px, transparent 2px, transparent 14px);
          pointer-events: none;
        }
        .cover-header { border-radius: 0 !important; }
        .school-card { border-radius: 0 !important; border-left: 3px solid $primary; }
        .info-card { border-radius: 0 !important; border-left-width: 3px !important; }
        .sub-criteria-card { border-radius: 0 !important; border-style: solid !important; }
        .report-type-card { border-radius: 0 !important; }
        .section-title, .section-subtitle {
          $sectionStyle
          border-left: 4px solid $primary;
          padding-left: 14px;
          background: $headerBg;
          padding: 10px 14px;
          border-radius: 0;
        }
        .student-name-chip {
          background: $studentCardBg;
          border: $cardBorder;
          border-radius: 0;
          padding: 10px 14px;
          font-family: $font;
          display: flex; align-items: center; gap: 10px;
          box-shadow: 2px 2px 0 $primary;
          transition: transform 0.15s;
        }
        .student-name-chip:hover { transform: translate(-1px, -1px); }
        .chip-number {
          background: $primary;
          color: white;
          width: 26px; height: 26px;
          display: flex; align-items: center; justify-content: center;
          font-size: 11px; font-weight: 800;
          border-radius: 0;
        }
        .group-header-custom {
          border-radius: 0;
          padding: 22px 28px;
        }
        .item-card-custom {
          border-radius: 0;
          border-left: 5px solid;
          background: $headerBg;
          padding: 14px 18px;
          margin-bottom: 10px;
          box-shadow: 3px 3px 0 rgba(0,0,0,0.08);
        }
        .stat-box {
          border-radius: 0;
          border-top: 4px solid $primary;
          background: white;
          padding: 18px;
          box-shadow: 3px 3px 0 $primary;
        }
        ''';
      case 'minimal':
        return '''
        body { font-family: $font; background: #ffffff; color: #111; letter-spacing: 0.01em; }
        .cover-page { border-top: 8px solid #111; border-bottom: 1px solid #ddd; padding: 60px 50px; }
        .cover-header { border-radius: 0 !important; }
        .school-card { border-radius: 0 !important; border: none; border-bottom: 1px solid #ddd; box-shadow: none !important; }
        .info-card { border-radius: 0 !important; border: none !important; border-bottom: 1px solid #eee; box-shadow: none !important; padding: 14px 0 !important; }
        .sub-criteria-card { border-radius: 0 !important; border: 1px solid #ddd !important; border-style: solid !important; }
        .report-type-card { border-radius: 0 !important; background: #111 !important; }
        .section-title { $sectionStyle border-bottom: 1px solid #111; border-left: none; padding-bottom: 8px; color: #111; margin-bottom: 28px; }
        .section-subtitle { $sectionStyle color: #666; border: none; padding-bottom: 4px; border-bottom: 1px solid #ddd; }
        .student-name-chip { background: transparent; border: none; border-bottom: 1px solid #e0e0e0; border-radius: 0; padding: 12px 4px; display: flex; align-items: baseline; gap: 16px; font-size: 13px; }
        .chip-number { font-size: 10px; color: #999; font-family: $font; min-width: 20px; background: transparent; font-style: italic; }
        .group-header-custom { background: #111 !important; border-radius: 0; padding: 18px 24px; border-bottom: 4px solid #444; }
        .item-card-custom { border-radius: 0; border: none; border-left: 2px solid #bbb; background: #fafafa; padding: 12px 20px; margin-bottom: 8px; font-size: 13px; }
        .stat-box { border-radius: 0; background: transparent; border: 1px solid #ddd; border-top: 3px solid #111; padding: 18px; text-align: left; }
        ''';
      case 'colorful':
        return '''
        body { font-family: $font; background: linear-gradient(135deg, #fce4ec 0%, #f3e5f5 50%, #ede7f6 100%); }
        .cover-page { background: white; border-radius: 24px; border: 3px solid $primary; position: relative; overflow: hidden; }
        .cover-page::before { content: ''; position: absolute; top: -30px; right: -30px; width: 200px; height: 200px; background: radial-gradient(circle at 50% 50%, ${accent}33 0%, transparent 70%); border-radius: 50%; }
        .cover-header { border-radius: 21px 21px 0 0 !important; }
        .school-card { border-radius: 20px !important; }
        .info-card { border-radius: 20px !important; }
        .sub-criteria-card { border-radius: 20px !important; border-style: dashed !important; }
        .report-type-card { border-radius: 20px !important; }
        .section-title { $sectionStyle background: linear-gradient(90deg, $primary, ${ts['secondaryColor']}); color: white; border-radius: 30px; padding: 10px 22px; border: none; display: inline-block; margin-bottom: 22px; }
        .section-subtitle { $sectionStyle color: $primary; border-bottom: 3px dashed $accent; padding-bottom: 6px; border-left: none; }
        .student-name-chip { background: linear-gradient(135deg, ${primary}15, ${accent}20); border: 2px dashed $primary; border-radius: 30px; padding: 10px 18px; display: flex; align-items: center; gap: 10px; transition: transform 0.2s, box-shadow 0.2s; }
        .student-name-chip:hover { transform: scale(1.02); box-shadow: $shadow; }
        .chip-number { background: $primary; color: white; width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 800; border-radius: 50%; }
        .group-header-custom { border-radius: 20px; padding: 22px 28px; box-shadow: 0 6px 20px rgba(0,0,0,0.15); }
        .item-card-custom { border-radius: 16px; border: $cardBorder; padding: 14px 18px; margin-bottom: 12px; box-shadow: $shadow; }
        .stat-box { border-radius: 20px; padding: 20px; box-shadow: $shadow; border: 2px solid ${primary}30; }
        ''';
      case 'educational':
        return '''
        body { font-family: $font; background: linear-gradient(180deg, #f1f8e9 0%, #e8f5e9 100%); }
        .cover-page { border-left: 8px solid $primary; border-radius: 0 $radius $radius 0; background: white; }
        .cover-header { border-radius: 0 $radius $radius 0 !important; }
        .school-card { border-radius: $radius !important; }
        .info-card { border-radius: $radius !important; }
        .sub-criteria-card { border-radius: $radius !important; border-style: solid !important; }
        .report-type-card { border-radius: $radius !important; }
        .section-title { $sectionStyle color: $primary; border-left: 6px solid $primary; padding-left: 14px; background: ${primary}0f; border-radius: 0 $radius $radius 0; padding: 10px 14px; margin-bottom: 22px; }
        .section-subtitle { $sectionStyle color: ${ts['secondaryColor']}; border-left: 4px solid $accent; padding-left: 10px; margin-bottom: 16px; }
        .student-name-chip { background: $studentCardBg; border: $cardBorder; border-radius: $radius; padding: 11px 16px; display: flex; align-items: center; gap: 12px; box-shadow: $shadow; transition: background 0.2s; }
        .student-name-chip:hover { background: $headerBg; }
        .chip-number { background: $primary; color: white; width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 700; border-radius: 50%; flex-shrink: 0; }
        .group-header-custom { border-radius: $radius; padding: 20px 26px; border-bottom: 4px solid rgba(255,255,255,0.3); }
        .item-card-custom { border-radius: $radius; border: $cardBorder; background: $studentCardBg; padding: 14px 18px; margin-bottom: 10px; box-shadow: $shadow; }
        .stat-box { border-radius: $radius; background: white; border: $cardBorder; box-shadow: $shadow; padding: 18px; border-top: 4px solid $primary; }
        ''';
      default:
        return '''
        body { font-family: $font; background: linear-gradient(135deg, #e1f5fe 0%, #b3e5fc 100%); }
        .cover-page { border-radius: $radius; background: white; box-shadow: $shadow; }
        .cover-header { border-radius: $radius $radius 0 0 !important; }
        .school-card { border-radius: $radius !important; }
        .info-card { border-radius: $radius !important; }
        .sub-criteria-card { border-radius: $radius !important; border-style: dashed !important; }
        .report-type-card { border-radius: $radius !important; }
        .section-title { $sectionStyle color: $primary; border-bottom: 3px solid $primary; padding-bottom: 10px; margin-bottom: 22px; }
        .section-subtitle { $sectionStyle color: ${ts['secondaryColor']}; border-left: 4px solid $accent; padding-left: 10px; margin-bottom: 14px; }
        .student-name-chip { background: $studentCardBg; border: $cardBorder; border-radius: $radius; padding: 11px 16px; display: flex; align-items: center; gap: 10px; box-shadow: $shadow; }
        .chip-number { background: $primary; color: white; width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 700; border-radius: 50%; }
        .group-header-custom { border-radius: $radius; padding: 20px 26px; }
        .item-card-custom { border-radius: $radius; border-left: 4px solid; background: $studentCardBg; padding: 14px 18px; margin-bottom: 10px; box-shadow: $shadow; }
        .stat-box { border-radius: $radius; background: white; border: $cardBorder; box-shadow: $shadow; padding: 18px; }
        ''';
    }
  }

  static String _buildStyledHead(
      bool isFrenchInterface,
      String direction,
      Map<String, String> templateStyles,
      String selectedTemplate,
      Map<String, String> t) {
    final templateCSS = _getTemplateCSSBlock(
        selectedTemplate, templateStyles, isFrenchInterface);
    final decorator = _getSVGDecorator(selectedTemplate,
        templateStyles['primaryColor']!, templateStyles['accentColor']!);

    return '''
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${t['main_title']}</title>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Arabic:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        :root {
            --primary-color: ${templateStyles['primaryColor']};
            --secondary-color: ${templateStyles['secondaryColor']};
            --accent-color: ${templateStyles['accentColor']};
            --ai-color: #9C27B0;
            --light-bg: ${templateStyles['headerBg']};
            --white: #ffffff;
            --text-color: #333333;
            --border-radius: ${templateStyles['borderRadius']};
            --box-shadow: ${templateStyles['boxShadow']};
            --treatment-color: #e74c3c;
            --support-color: #f39c12;
            --excellence-color: #27ae60;
        }
        body {
            font-family: ${isFrenchInterface ? templateStyles['fontFamily']! : "'Noto Sans Arabic', " + templateStyles['fontFamily']!};
            color: var(--text-color);
            direction: $direction;
            line-height: 1.7;
            min-height: 100vh;
            padding: 20px;
            font-size: ${templateStyles['fontSize']};
        }
        .report-container { max-width: 1200px; margin: 0 auto; }
        .cover-page, .general-info-page, .group-page {
            background: var(--white);
            border-radius: var(--border-radius);
            box-shadow: var(--box-shadow);
            padding: 40px;
            margin-bottom: 40px;
            position: relative;
            overflow: hidden;
        }
        .cover-page { min-height: 88vh; display: flex; flex-direction: column; justify-content: center; }
        .general-info-page, .group-page { page-break-before: always; }
        .section-title { font-size: 20px; color: var(--primary-color); margin-bottom: 24px; padding-bottom: 10px; border-bottom: 2px solid var(--primary-color); font-weight: bold; }
        .section-subtitle { font-size: 16px; color: var(--text-color); margin-bottom: 14px; padding-${isFrenchInterface ? 'left' : 'right'}: 10px; border-${isFrenchInterface ? 'left' : 'right'}: 4px solid var(--primary-color); font-weight: bold; }
        .report-footer { text-align: center; margin-top: 40px; padding-top: 16px; border-top: 1px solid #e0e0e0; color: #888; font-size: 12px; }
        .items-list { list-style: none; padding: 0; }
        .ai-badge { background: var(--ai-color); color: white; padding: 4px 14px; border-radius: 20px; font-size: 11px; font-weight: bold; }
        .ai-exercise-content { font-size: 13px; line-height: 1.8; white-space: pre-wrap; background: #fafafa; padding: 14px; border-radius: var(--border-radius); border: 1px solid #e0e0e0; }
        .ai-metadata { margin-top: 8px; font-size: 11px; color: #888; font-style: italic; text-align: right; }
        $templateCSS
        $decorator
    </style>
</head>''';
  }

  static String _studentChipHTML(
      int index, Map<String, dynamic> student, Map<String, String> t) {
    return '''
    <div class="student-name-chip">
      <span class="chip-number">$index</span>
      <span style="font-weight:500;">${student['name'] ?? t['unknown']!}</span>
    </div>
    ''';
  }

  static String _itemCardHTML(Map<String, dynamic> item, bool isProblem) {
    final borderColor = isProblem ? '#d32f2f' : '#2e7d32';
    final bgColor = isProblem ? '#ffebee' : '#e8f5e9';
    return '''
    <li class="item-card-custom" style="border-color: $borderColor; background: $bgColor;">
      <div style="font-size:14px; line-height:1.6;">${item['text'] ?? ''}</div>
    </li>
    ''';
  }

  static String _statBoxHTML(String label, int count, String gradient) {
    return '''
    <div class="stat-box" style="background: $gradient; color:white; text-align:center;">
      <div style="font-size:11px; opacity:0.9; margin-bottom:6px;">$label</div>
      <div style="font-size:28px; font-weight:800;">$count</div>
    </div>
    ''';
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
