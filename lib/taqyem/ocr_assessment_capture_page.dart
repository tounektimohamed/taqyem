// // ocr_assessment_capture_page.dart
// import 'package:Taqyem/taqyem/ocr_assessment_dialog.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// class OCRAssessmentCapturePage extends StatefulWidget {
//   final String classId;
//   final String matiereId;

//   const OCRAssessmentCapturePage({
//     Key? key,
//     required this.classId,
//     required this.matiereId,
//   }) : super(key: key);

//   @override
//   _OCRAssessmentCapturePageState createState() => _OCRAssessmentCapturePageState();
// }

// class _OCRAssessmentCapturePageState extends State<OCRAssessmentCapturePage> {
//   final ImagePicker _picker = ImagePicker();
//   final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();
//   List<Map<String, dynamic>> _extractedData = [];
//   List<Map<String, dynamic>> _availableBaremes = [];
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadAvailableBaremes();
//   }

//   Future<void> _loadAvailableBaremes() async {
//     try {
//       User? currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser == null) return;

//       final baremesSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(currentUser.uid)
//           .collection('selections')
//           .doc(widget.classId)
//           .collection(widget.matiereId)
//           .get();

//       setState(() {
//         _availableBaremes = baremesSnapshot.docs.map((doc) {
//           return {
//             'id': doc.id,
//             'name': doc['baremeName'] ?? 'غير محدد',
//             'hasSousBaremes': (doc['sousBaremes'] as List<dynamic>?)?.isNotEmpty ?? false,
//           };
//         }).toList();
//       });
//     } catch (e) {
//       print('Erreur lors du chargement des barèmes: $e');
//     }
//   }

//   Future<void> _captureTableImage() async {
//     final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    
//     if (image != null) {
//       setState(() => _isLoading = true);
      
//       try {
//         // 1. Extraire le texte
//         final inputImage = InputImage.fromFilePath(image.path);
//         final recognizedText = await _textRecognizer.processImage(inputImage);
        
//         // 2. Analyser spécifiquement pour les barèmes disponibles
//         final extractedData = await _analyzeForBaremes(recognizedText);
        
//         // 3. Organiser les données par barème et niveau
//         final organizedData = _organizeByBaremeAndLevel(extractedData);
        
//         setState(() {
//           _extractedData = organizedData;
//           _isLoading = false;
//         });
        
//         // 4. Afficher les résultats
//         await _showExtractedResults(organizedData);
        
//       } catch (e) {
//         setState(() => _isLoading = false);
//         print('Erreur OCR: $e');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('حدث خطأ أثناء معالجة الصورة')),
//         );
//       }
//     }
//   }

//   Future<List<Map<String, dynamic>>> _analyzeForBaremes(RecognizedText recognizedText) async {
//     List<Map<String, dynamic>> results = [];
    
//     // Pour chaque barème disponible, chercher ses données dans le texte
//     for (var bareme in _availableBaremes) {
//       final baremeName = bareme['name'];
      
//       // Chercher le nom du barème dans le texte
//       for (var block in recognizedText.blocks) {
//         for (var line in block.lines) {
//           if (line.text.contains(baremeName) || _isSimilar(baremeName, line.text)) {
//             // Trouvé le barème, maintenant chercher ses 4 niveaux
//             final List<String> detectedLevels = _extractFourLevels(block, line);
            
//             if (detectedLevels.length == 4) {
//               results.add({
//                 'baremeId': bareme['id'],
//                 'baremeName': baremeName,
//                 'levels': detectedLevels,
//                 'rawLine': line.text,
//               });
//             }
//           }
//         }
//       }
//     }
    
//     return results;
//   }

//   bool _isSimilar(String text1, String text2) {
//     // Logique de similarité (vous pouvez améliorer cette logique)
//     final clean1 = text1.replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '');
//     final clean2 = text2.replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '');
//     return clean1.contains(clean2) || clean2.contains(clean1);
//   }

//   List<String> _extractFourLevels(TextBlock block, TextLine startLine) {
//     List<String> levels = [];
    
//     // Chercher les 4 lignes suivantes qui pourraient être les niveaux
//     // Cette logique dépend de la structure de votre tableau
//     // Vous devrez peut-être l'adapter selon vos images
    
//     // Exemple: Chercher les motifs des 4 niveaux
//     List<String> levelPatterns = [
//       'انعدام',
//       'دون التملك',
//       'التملك الأدنى',
//       'التملك الأقصى'
//     ];
    
//     // Parcourir les lignes du bloc pour trouver ces motifs
//     for (var line in block.lines) {
//       for (var pattern in levelPatterns) {
//         if (line.text.contains(pattern) && !levels.contains(line.text)) {
//           levels.add(line.text);
//           break;
//         }
//       }
//     }
    
//     // Si on n'a pas trouvé 4 niveaux, essayer une autre approche
//     if (levels.length < 4) {
//       levels = _extractLevelsByPosition(block, startLine);
//     }
    
//     return levels.take(4).toList();
//   }

//   List<String> _extractLevelsByPosition(TextBlock block, TextLine startLine) {
//     // Extraire les niveaux basés sur la position (supposant qu'ils sont alignés)
//     List<TextLine> allLines = block.lines.toList();
//     int startIndex = allLines.indexOf(startLine);
    
//     List<String> levels = [];
//     // Prendre les 4 lignes suivantes (ou moins si pas disponibles)
//     for (int i = startIndex + 1; i < allLines.length && levels.length < 4; i++) {
//       if (allLines[i].text.isNotEmpty) {
//         levels.add(allLines[i].text);
//       }
//     }
    
//     return levels;
//   }

//   List<Map<String, dynamic>> _organizeByBaremeAndLevel(List<Map<String, dynamic>> rawData) {
//     // Organiser les données par barème et mapper chaque niveau à une valeur
//     List<Map<String, dynamic>> organized = [];
    
//     // Mapping des niveaux arabes vers les valeurs système
//     final Map<String, String> levelMapping = {
//       'انعدام': '( - - - )',
//       'دون التملك': '( + - - )',
//       'التملك الأدنى': '( + + - )',
//       'التملك الأقصى': '( + + + )',
//     };
    
//     for (var item in rawData) {
//       Map<String, dynamic> baremeData = {
//         'baremeId': item['baremeId'],
//         'baremeName': item['baremeName'],
//         'evaluations': {},
//       };
      
//       // Pour chaque niveau détecté, extraire la note
//       List<String> levels = List<String>.from(item['levels']);
//       for (int i = 0; i < levels.length && i < 4; i++) {
//         String arabicLevel = levels[i];
//         String systemValue = _extractValueFromLevel(arabicLevel);
        
//         // Mapper au niveau correspondant
//         String levelKey = '';
//         switch (i) {
//           case 0: levelKey = 'niveau1'; break;
//           case 1: levelKey = 'niveau2'; break;
//           case 2: levelKey = 'niveau3'; break;
//           case 3: levelKey = 'niveau4'; break;
//         }
        
//         if (levelKey.isNotEmpty) {
//           baremeData['evaluations'][levelKey] = {
//             'arabicText': arabicLevel,
//             'systemValue': systemValue,
//             'mappedTo': levelMapping.entries
//                 .firstWhere((entry) => arabicLevel.contains(entry.key),
//                     orElse: () => MapEntry('', '( - - - )'))
//                 .value,
//           };
//         }
//       }
      
//       organized.add(baremeData);
//     }
    
//     return organized;
//   }

//   String _extractValueFromLevel(String levelText) {
//     // Extraire les valeurs numériques du texte
//     // Exemple: "0  0.5  1  1.5" ou "0 0.5 1 1.5"
//     RegExp regex = RegExp(r'([0-9]+(?:\.[0-9]+)?)');
//     Iterable<Match> matches = regex.allMatches(levelText);
    
//     if (matches.isNotEmpty) {
//       return matches.first.group(0) ?? '0';
//     }
    
//     // Si pas de nombre, chercher des symboles
//     if (levelText.contains('+++')) return '( + + + )';
//     if (levelText.contains('++-')) return '( + + - )';
//     if (levelText.contains('+--')) return '( + - - )';
//     if (levelText.contains('---')) return '( - - - )';
    
//     return '( - - - )';
//   }

//   Future<void> _showExtractedResults(List<Map<String, dynamic>> data) async {
//     await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('نتائج التعرف البصري'),
//         content: Container(
//           width: double.maxFinite,
//           height: MediaQuery.of(context).size.height * 0.6,
//           child: SingleChildScrollView(
//             child: Column(
//               children: data.map((bareme) => _buildBaremePreview(bareme)).toList(),
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('إلغاء'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _applyToEvaluationDialog(data);
//             },
//             child: Text('تطبيق على التقييم'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBaremePreview(Map<String, dynamic> bareme) {
//     return Card(
//       margin: EdgeInsets.symmetric(vertical: 8),
//       child: Padding(
//         padding: EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               bareme['baremeName'],
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//             SizedBox(height: 8),
//             if (bareme['evaluations'] != null)
//               ...(bareme['evaluations'] as Map<String, dynamic>).entries.map((entry) {
//                 final levelData = entry.value as Map<String, dynamic>;
//                 return ListTile(
//                   dense: true,
//                   contentPadding: EdgeInsets.zero,
//                   title: Text(levelData['arabicText'] ?? ''),
//                   subtitle: Text('→ ${levelData['mappedTo']}'),
//                   trailing: Chip(
//                     label: Text(levelData['systemValue']),
//                     backgroundColor: _getColorForValue(levelData['systemValue']),
//                   ),
//                 );
//               }).toList(),
//           ],
//         ),
//       ),
//     );
//   }

//   Color _getColorForValue(String value) {
//     switch (value) {
//       case '( + + + )':
//       case '1.5':
//       case '3':
//       case '6':
//         return Colors.green;
//       case '( + + - )':
//       case '1':
//       case '2':
//       case '4':
//         return Colors.amber;
//       case '( + - - )':
//       case '0.5':
//         return Colors.orange;
//       case '( - - - )':
//       case '0':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   Future<void> _applyToEvaluationDialog(List<Map<String, dynamic>> extractedData) async {
//     // Naviguer vers le dialogue d'évaluation avec les données extraites
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => OCRAssessmentDialog(
//           classId: widget.classId,
//           matiereId: widget.matiereId,
//           extractedData: extractedData,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('التعرف البصري على التقييمات'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: _loadAvailableBaremes,
//             tooltip: 'تحديث قائمة المعايير',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Section des barèmes disponibles
//           if (_availableBaremes.isNotEmpty)
//             Expanded(
//               flex: 2,
//               child: Card(
//                 margin: EdgeInsets.all(12),
//                 child: Column(
//                   children: [
//                     ListTile(
//                       leading: Icon(Icons.list, color: Colors.blue),
//                       title: Text('المعايير المتاحة'),
//                       subtitle: Text('سيتم البحث عنها في الصورة'),
//                     ),
//                     Expanded(
//                       child: ListView.builder(
//                         padding: EdgeInsets.all(8),
//                         itemCount: _availableBaremes.length,
//                         itemBuilder: (context, index) {
//                           final bareme = _availableBaremes[index];
//                           return ListTile(
//                             leading: Icon(
//                               Icons.assessment,
//                               color: bareme['hasSousBaremes'] ? Colors.orange : Colors.green,
//                             ),
//                             title: Text(bareme['name']),
//                             subtitle: bareme['hasSousBaremes'] 
//                                 ? Text('يحتوي على معايير فرعية') 
//                                 : null,
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
          
//           // Section de capture
//           Expanded(
//             flex: 3,
//             child: Center(
//               child: _isLoading
//                   ? Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         CircularProgressIndicator(),
//                         SizedBox(height: 16),
//                         Text('جاري تحليل الصورة...'),
//                       ],
//                     )
//                   : Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.table_view, size: 100, color: Colors.blue),
//                         SizedBox(height: 20),
//                         Text(
//                           'التقط صورة للجدول المرفق',
//                           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
//                         SizedBox(height: 10),
//                         Padding(
//                           padding: EdgeInsets.symmetric(horizontal: 32),
//                           child: Text(
//                             'تأكد أن الجدول يحتوي على:\n'
//                             '1. أسماء المعايير\n'
//                             '2. المستويات الأربعة\n'
//                             '3. القيم المقابلة',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(color: Colors.grey[600]),
//                           ),
//                         ),
//                         SizedBox(height: 30),
//                         ElevatedButton.icon(
//                           icon: Icon(Icons.camera_alt),
//                           label: Text('التقاط صورة'),
//                           onPressed: _captureTableImage,
//                           style: ElevatedButton.styleFrom(
//                             padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                           ),
//                         ),
//                       ],
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _textRecognizer.close();
//     super.dispose();
//   }
// }