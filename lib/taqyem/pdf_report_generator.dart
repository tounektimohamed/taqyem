// import 'dart:io';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:intl/intl.dart';

// class PdfReportGenerator {
//   static final Map<String, Map<String, String>> TRANSLATIONS = {
//     'ar': {
//       'title': 'تقرير النتائج',
//       'professor': 'الأستاذ',
//       'subject': 'المادة',
//       'class': 'القسم',
//       'school': 'المؤسسة',
//       'main_title': 'الجدول الجامع للنتائج',
//       'student_name': 'الاسم واللقب',
//       'achieved_students': 'عدد التلاميذ المحققين',
//       'percentage': 'النسبة المئوية',
//       'generated_by': 'تم إنشاء التقرير بواسطة نظام تقييم',
//       'unknown': 'غير معروف',
//       'no_data': 'لا توجد بيانات'
//     },
//     'fr': {
//       'title': 'Rapport des Résultats',
//       'professor': 'Professeur',
//       'subject': 'Matière',
//       'class': 'Classe',
//       'school': 'Établissement',
//       'main_title': 'Tableau Global des Résultats',
//       'student_name': 'Nom et Prénom',
//       'achieved_students': 'Nombre d\'élèves ayant atteint',
//       'percentage': 'Pourcentage',
//       'generated_by': 'Rapport généré par le système d\'évaluation',
//       'unknown': 'Inconnu',
//       'no_data': 'Aucune donnée'
//     }
//   };

//   static String detectLanguage(String matiereName) {
//     if (matiereName.isEmpty) return 'ar';
    
//     final matiereLower = matiereName.toLowerCase();
//     final frenchKeywords = [
//       'expression orale', 'lecture', 'production écrite', 'écriture', 
//       'dictée', 'langue', 'anglais', 'français', 'english', 'french',
//       'oral', 'écrit', 'rédaction'
//     ];
    
//     for (final keyword in frenchKeywords) {
//       if (matiereLower.contains(keyword)) return 'fr';
//     }
    
//     final arabicRegex = RegExp(r'[\u0600-\u06FF]');
//     return arabicRegex.hasMatch(matiereName) ? 'ar' : 'fr';
//   }

//   static String getTranslation(String lang, String key) {
//     return TRANSLATIONS[lang]?[key] ?? TRANSLATIONS['ar']![key]!;
//   }

//   static Future<File> generatePDF(Map<String, dynamic> data) async {
//     final pdf = pw.Document();
//     final lang = detectLanguage(data['matiereName'] ?? '');
//     final t = (String key) => getTranslation(lang, key);

//     // Charger les polices avec support Unicode
//     final font = await _loadPdfFont();
    
//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         theme: pw.ThemeData.withFont(
//           base: font,
//           bold: font,
//         ),
//         build: (pw.Context context) => [
//           _buildHeader(data, t, font),
//           pw.SizedBox(height: 20),
//           _buildMainTable(data, t, font),
//           pw.SizedBox(height: 20),
//           _buildFooter(t, font),
//         ],
//       ),
//     );

//     // Sauvegarder le fichier
//     final output = await getTemporaryDirectory();
//     final file = File("${output.path}/rapport_resultats.pdf");
//     await file.writeAsBytes(await pdf.save());

//     return file;
//   }

//   static pw.Widget _buildHeader(Map<String, dynamic> data, Function t, pw.Font font) {
//     return pw.Column(
//       children: [
//         // Titre principal
//         pw.Text(
//           t('main_title'),
//           style: pw.TextStyle(
//             font: font,
//             fontSize: 18,
//             fontWeight: pw.FontWeight.bold,
//             color: PdfColors.blue900,
//           ),
//           textAlign: pw.TextAlign.center,
//         ),
//         pw.SizedBox(height: 10),
        
//         // Informations
//         pw.Row(
//           mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//           children: [
//             pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Text(
//                   '${t('professor')}: ${data['profName'] ?? t('unknown')}',
//                   style: pw.TextStyle(font: font),
//                 ),
//                 pw.Text(
//                   '${t('subject')}: ${data['matiereName'] ?? t('unknown')}',
//                   style: pw.TextStyle(font: font),
//                 ),
//                 pw.Text(
//                   '${t('class')}: ${data['className'] ?? t('unknown')}',
//                   style: pw.TextStyle(font: font),
//                 ),
//               ],
//             ),
//             pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.end,
//               children: [
//                 pw.Text(
//                   '${t('school')}: ${data['schoolName'] ?? t('unknown')}',
//                   style: pw.TextStyle(font: font),
//                 ),
//                 pw.Text(
//                   '${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
//                   style: pw.TextStyle(font: font),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   static pw.Widget _buildMainTable(Map<String, dynamic> data, Function t, pw.Font font) {
//     final baremes = data['baremes'] as List<dynamic>? ?? [];
//     final students = data['students'] as List<dynamic>? ?? [];
//     final sumCriteria = data['sumCriteriaMaxPerBareme'] as Map<String, dynamic>? ?? {};
//     final totalStudents = data['totalStudents'] as int? ?? 0;

//     // Préparer les colonnes
//     final headers = [
//       pw.Container(
//         width: 120,
//         padding: const pw.EdgeInsets.all(8),
//         child: pw.Text(
//           t('student_name'),
//           style: pw.TextStyle(
//             font: font,
//             color: PdfColors.white, 
//             fontWeight: pw.FontWeight.bold
//           ),
//         ),
//       ),
//       for (final bareme in baremes)
//         pw.Container(
//           width: 60,
//           padding: const pw.EdgeInsets.all(8),
//           child: pw.Text(
//             bareme['value'] ?? '',
//             style: pw.TextStyle(
//               font: font,
//               color: PdfColors.white, 
//               fontWeight: pw.FontWeight.bold
//             ),
//             textAlign: pw.TextAlign.center,
//           ),
//         ),
//     ];

//     // Préparer les lignes des étudiants
//     final studentRows = [
//       for (final student in students)
//         pw.TableRow(
//           children: [
//             pw.Container(
//               padding: const pw.EdgeInsets.all(6),
//               child: pw.Text(
//                 student['name'] ?? t('unknown'),
//                 style: pw.TextStyle(font: font),
//               ),
//             ),
//             for (final bareme in baremes)
//               pw.Container(
//                 padding: const pw.EdgeInsets.all(6),
//                 child: pw.Text(
//                   (student['baremes']?[bareme['id']] ?? '( - - - )').toString(),
//                   style: pw.TextStyle(font: font),
//                   textAlign: pw.TextAlign.center,
//                 ),
//               ),
//           ],
//         ),
//     ];

//     // Ligne des statistiques
//     final statsRow = pw.TableRow(
//       decoration: pw.BoxDecoration(color: PdfColors.grey300),
//       children: [
//         pw.Container(
//           padding: const pw.EdgeInsets.all(6),
//           child: pw.Text(
//             t('achieved_students'),
//             style: pw.TextStyle(
//               font: font,
//               fontWeight: pw.FontWeight.bold
//             ),
//           ),
//         ),
//         for (final bareme in baremes)
//           pw.Container(
//             padding: const pw.EdgeInsets.all(6),
//             child: pw.Text(
//               (sumCriteria[bareme['id']] ?? 0).toString(),
//               style: pw.TextStyle(
//                 font: font,
//                 fontWeight: pw.FontWeight.bold
//               ),
//               textAlign: pw.TextAlign.center,
//             ),
//           ),
//       ],
//     );

//     // Ligne des pourcentages
//     final percentageRow = pw.TableRow(
//       decoration: pw.BoxDecoration(color: PdfColors.grey300),
//       children: [
//         pw.Container(
//           padding: const pw.EdgeInsets.all(6),
//           child: pw.Text(
//             t('percentage'),
//             style: pw.TextStyle(
//               font: font,
//               fontWeight: pw.FontWeight.bold
//             ),
//           ),
//         ),
//         for (final bareme in baremes)
//           pw.Container(
//             padding: const pw.EdgeInsets.all(6),
//             child: pw.Text(
//               totalStudents > 0 
//                 ? '${((sumCriteria[bareme['id']] ?? 0) / totalStudents * 100).toStringAsFixed(2)}%'
//                 : '0%',
//               style: pw.TextStyle(
//                 font: font,
//                 fontWeight: pw.FontWeight.bold
//               ),
//               textAlign: pw.TextAlign.center,
//             ),
//           ),
//       ],
//     );

//     return pw.Table(
//       border: pw.TableBorder.all(color: PdfColors.blue800, width: 1),
//       columnWidths: {
//         for (int i = 0; i < headers.length; i++)
//           i: i == 0 ? const pw.FixedColumnWidth(120) : const pw.FixedColumnWidth(60),
//       },
//       children: [
//         // En-tête
//         pw.TableRow(
//           decoration: pw.BoxDecoration(color: PdfColors.blue800),
//           children: headers,
//         ),
//         // Données des étudiants
//         ...studentRows,
//         // Statistiques
//         statsRow,
//         percentageRow,
//       ],
//     );
//   }

//   static pw.Widget _buildFooter(Function t, pw.Font font) {
//     return pw.Column(
//       children: [
//         pw.Divider(),
//         pw.Text(
//           '${t('generated_by')}',
//           style: pw.TextStyle(
//             font: font,
//             fontSize: 10, 
//             color: PdfColors.grey600
//           ),
//           textAlign: pw.TextAlign.center,
//         ),
//       ],
//     );
//   }

//   // Méthode pour charger une police avec support Unicode
//   static Future<pw.Font> _loadPdfFont() async {
//     try {
//       // Essayer de charger une police système qui supporte l'arabe
//       // Pour le web, on utilise les polices par défaut
//       return pw.Font.courier(); // Courier supporte mieux Unicode
//     } catch (e) {
//       // Fallback vers une police basique
//       return pw.Font.helvetica();
//     }
//   }
// }