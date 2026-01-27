// import 'dart:io';

// import 'package:cloud_functions/cloud_functions.dart';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';

// class PDFReportGenerator {
//   // Méthode principale pour générer un rapport PDF via Firebase Function
//   static Future<Map<String, dynamic>> generateCompleteReportPDF({
//     required String profName,
//     required String matiereName,
//     required String className,
//     required String schoolName,
//     required List<dynamic> baremes,
//     required List<dynamic> students,
//     required Map<String, int> sumCriteriaMaxPerBareme,
//     required int totalStudents,
//     required bool isFrenchInterface,
//     required String userId,
//     String trimestre = 'الأول',
//     String periode = '',
//     String evaluationType = 'تقييم',
//     List<Map<String, dynamic>> criteria = const [],
//     String performanceAttendue = '',
//   }) async {
//     try {
//       print('🔄 Préparation des données pour la génération PDF...');

//       // Préparer les données pour la Firebase Function
//       final Map<String, dynamic> reportData = {
//         'profName': profName,
//         'matiereName': matiereName,
//         'className': className,
//         'schoolName': schoolName,
//         'baremes': _prepareBaremesData(baremes),
//         'students': _prepareStudentsData(students),
//         'sumCriteriaMaxPerBareme': sumCriteriaMaxPerBareme,
//         'totalStudents': totalStudents,
//         'isFrenchInterface': isFrenchInterface,
//         'trimestre': trimestre,
//         'periode': periode,
//         'evaluationType': evaluationType,
//         'criteria': _prepareCriteriaData(criteria, isFrenchInterface),
//         'performanceAttendue': performanceAttendue,
//         'generatedAt': DateTime.now().toIso8601String(),
//       };

//       // Données pour la Firebase Function
//       final Map<String, dynamic> functionData = {
//         'reportData': reportData,
//         'fileName': 'rapport_complet_${DateTime.now().millisecondsSinceEpoch}.pdf',
//         'folderPath': 'complete_reports',
//       };

//       // Appeler la Firebase Function
//       final HttpsCallable callable = FirebaseFunctions.instance
//           .httpsCallable('generateCompleteReportPDF');

//       print('📡 Appel de la Firebase Function...');
//       final result = await callable.call(functionData);
//       final response = result.data as Map<String, dynamic>;

//       print('✅ PDF généré avec succès via Firebase Function');
//       print('📥 URL: ${response['downloadURL']}');
//       print('📄 Nom du fichier: ${response['fileName']}');
//       print('📏 Taille: ${response['fileSize']} bytes');

//       return {
//         'success': true,
//         'downloadURL': response['downloadURL'],
//         'fileName': response['fileName'],
//         'timestamp': response['timestamp'],
//         'fileSize': response['fileSize'],
//       };

//     } catch (e) {
//       print('❌ Erreur lors de la génération du PDF: $e');
//       return {
//         'success': false,
//         'error': e.toString(),
//         'timestamp': DateTime.now().toIso8601String(),
//       };
//     }
//   }

//   // Préparer les données des barèmes
//   static List<Map<String, dynamic>> _prepareBaremesData(List<dynamic> baremes) {
//     return baremes.map((bareme) {
//       return {
//         'id': bareme['id']?.toString() ?? '',
//         'value': bareme['value']?.toString() ?? '',
//         'type': bareme['type']?.toString() ?? 'bareme',
//         'parentBaremeId': bareme['parentBaremeId']?.toString(),
//       };
//     }).toList();
//   }

//   // Préparer les données des étudiants
//   static List<Map<String, dynamic>> _prepareStudentsData(List<dynamic> students) {
//     return students.map((student) {
//       // Convertir les notes en Map<String, String>
//       Map<String, String> baremesMap = {};
//       if (student['baremes'] is Map<String, dynamic>) {
//         final studentBaremes = student['baremes'] as Map<String, dynamic>;
//         studentBaremes.forEach((key, value) {
//           baremesMap[key] = value.toString();
//         });
//       }

//       return {
//         'id': student['id']?.toString() ?? '',
//         'name': student['name']?.toString() ?? '',
//         'baremes': baremesMap,
//       };
//     }).toList();
//   }

//   // Préparer les données des critères
//   static List<Map<String, dynamic>> _prepareCriteriaData(
//       List<Map<String, dynamic>> criteria, bool isFrenchInterface) {
//     return criteria.map((criterion) {
//       return {
//         'name': isFrenchInterface
//             ? (criterion['frenchName'] ?? criterion['name'] ?? '')
//             : (criterion['arabicName'] ?? criterion['name'] ?? ''),
//         'indicators': (criterion['indicators'] as List<dynamic>? ?? [])
//             .map((indicator) => indicator.toString())
//             .toList(),
//         'domaine': criterion['domaine']?.toString() ?? '',
//       };
//     }).toList();
//   }

//   // Méthode pour télécharger le PDF depuis l'URL
//   static Future<void> downloadPDFFromURL(String downloadURL, String fileName) async {
//     try {
//       if (kIsWeb) {
//         // Pour le web
//       } else {
//         // Pour mobile/desktop
//         final response = await http.get(Uri.parse(downloadURL));
//         final bytes = response.bodyBytes;
        
//         final directory = await getTemporaryDirectory();
//         final file = File('${directory.path}/$fileName');
//         await file.writeAsBytes(bytes);
        
//         await OpenFile.open(file.path);
//       }
      
//       print('✅ PDF téléchargé avec succès');
//     } catch (e) {
//       print('❌ Erreur lors du téléchargement du PDF: $e');
//       rethrow;
//     }
//   }
// }