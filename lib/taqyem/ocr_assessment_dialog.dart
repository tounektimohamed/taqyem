// // ocr_assessment_dialog.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class OCRAssessmentDialog extends StatefulWidget {
//   final String classId;
//   final String matiereId;
//   final List<Map<String, dynamic>> extractedData;
//   final String? studentId; // Optionnel pour évaluation directe

//   const OCRAssessmentDialog({
//     Key? key,
//     required this.classId,
//     required this.matiereId,
//     required this.extractedData,
//     this.studentId,
//   }) : super(key: key);

//   @override
//   _OCRAssessmentDialogState createState() => _OCRAssessmentDialogState();
// }

// class _OCRAssessmentDialogState extends State<OCRAssessmentDialog> {
//   // Structure pour stocker les évaluations par barème et niveau
//   Map<String, Map<String, String>> _evaluations = {};
//   String _selectedSystem = 'character';

//   // Method to get color based on value
//   Color _getColorForValue(String value) {
//     switch (value) {
//       case '( - - - )':
//         return Colors.red;
//       case '( + - - )':
//         return Colors.orange;
//       case '( + + - )':
//         return Colors.yellow;
//       case '( + + + )':
//         return Colors.green;
//       default:
//         return Colors.grey;
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _initializeEvaluations();
//   }

//   void _initializeEvaluations() {
//     // Initialiser avec les données extraites
//     for (var bareme in widget.extractedData) {
//       final baremeId = bareme['baremeId'];
//       final evaluations = bareme['evaluations'] as Map<String, dynamic>;
      
//       _evaluations[baremeId] = {};
      
//       evaluations.forEach((levelKey, levelData) {
//         final dataMap = levelData as Map<String, dynamic>;
//         // Utiliser la valeur mappée par défaut
//         _evaluations[baremeId]![levelKey] = dataMap['mappedTo'] ?? '( - - - )';
//       });
//     }
//   }

//   Widget _buildBaremeCard(Map<String, dynamic> bareme) {
//     final baremeId = bareme['baremeId'];
//     final baremeName = bareme['baremeName'];
//     final evaluations = bareme['evaluations'] as Map<String, dynamic>;
    
//     return Card(
//       margin: EdgeInsets.symmetric(vertical: 8),
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // En-tête du barème
//             ListTile(
//               contentPadding: EdgeInsets.zero,
//               leading: Icon(Icons.assessment, color: Colors.blue),
//               title: Text(
//                 baremeName,
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//               ),
//             ),
            
//             Divider(),
            
//             // Les 4 niveaux d'évaluation
//             Column(
//               children: [
//                 _buildLevelRow('المستوى 1 (انعدام التملك)', evaluations['niveau1'], baremeId, 'niveau1'),
//                 _buildLevelRow('المستوى 2 (دون التملك الأدنى)', evaluations['niveau2'], baremeId, 'niveau2'),
//                 _buildLevelRow('المستوى 3 (التملك الأدنى)', evaluations['niveau3'], baremeId, 'niveau3'),
//                 _buildLevelRow('المستوى 4 (التملك الأقصى)', evaluations['niveau4'], baremeId, 'niveau4'),
//               ],
//             ),
            
//             // Aperçu du texte extrait
//             if (bareme['rawLine'] != null)
//               Container(
//                 margin: EdgeInsets.only(top: 12),
//                 padding: EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   'النص المستخرج: ${bareme['rawLine']}',
//                   style: TextStyle(fontSize: 12, color: Colors.grey[700]),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLevelRow(
//     String levelLabel,
//     dynamic levelData,
//     String baremeId,
//     String levelKey,
//   ) {
//     final Map? data = levelData is Map ? levelData : null;
//     final String arabicText = data?['arabicText'] ?? '';
//     final String extractedValue = data?['systemValue'] ?? '';
//     final String currentValue = _evaluations[baremeId]?[levelKey] ?? '( - - - )';
    
//     return Container(
//       margin: EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 2,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   levelLabel,
//                   style: TextStyle(fontWeight: FontWeight.w500),
//                 ),
//                 if (arabicText.isNotEmpty)
//                   Text(
//                     arabicText,
//                     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                   ),
//               ],
//             ),
//           ),
          
//           SizedBox(width: 8),
          
//           // Valeur extraite
//           Expanded(
//             child: Container(
//               padding: EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.blue[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.blue[100]!),
//               ),
//               child: Center(
//                 child: Text(
//                   extractedValue,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: Colors.blue[800],
//                   ),
//                 ),
//               ),
//             ),
//           ),
          
//           SizedBox(width: 8),
          
//           // Sélection de la valeur finale
//           Expanded(
//             child: DropdownButtonFormField<String>(
//               value: currentValue,
//               items: [
//                 '( - - - )',
//                 '( + - - )',
//                 '( + + - )',
//                 '( + + + )',
//               ].map((value) {
//                 return DropdownMenuItem(
//                   value: value,
//                   child: Center(
//                     child: Text(
//                       value,
//                       style: TextStyle(
//                         color: _getColorForValue(value),
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 );
//               }).toList(),
//               onChanged: (newValue) {
//                 setState(() {
//                   _evaluations[baremeId]![levelKey] = newValue!;
//                 });
//               },
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(),
//                 contentPadding: EdgeInsets.symmetric(horizontal: 8),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _saveEvaluations() async {
//     try {
//       User? currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser == null) return;

//       // Préparer le batch pour sauvegarder toutes les évaluations
//       WriteBatch batch = FirebaseFirestore.instance.batch();

//       // Pour chaque barème et niveau
//       for (var baremeEntry in _evaluations.entries) {
//         final baremeId = baremeEntry.key;
//         final levelEvaluations = baremeEntry.value;

//         // Trouver le barème correspondant dans les données extraites
//         final baremeData = widget.extractedData
//             .firstWhere((b) => b['baremeId'] == baremeId, orElse: () => {});

//         if (baremeData.isNotEmpty) {
//           // Si c'est un barème principal (sans sous-barèmes)
//           final bool hasSubBaremes = baremeData['hasSousBaremes'] ?? false;

//           if (!hasSubBaremes) {
//             // Sauvegarder comme barème principal
//             final evaluationDoc = FirebaseFirestore.instance
//                 .collection('users')
//                 .doc(currentUser.uid)
//                 .collection('user_classes')
//                 .doc(widget.classId)
//                 .collection('students')
//                 .doc(widget.studentId)
//                 .collection('baremes')
//                 .doc(baremeId);

//             // Prendre la valeur du niveau sélectionné (par défaut niveau 4)
//             final selectedValue = levelEvaluations['niveau4'] ?? '( - - - )';

//             batch.set(evaluationDoc, {
//               'Marks': selectedValue,
//               'importedFromOCR': true,
//               'ocrData': baremeData,
//               'updatedAt': FieldValue.serverTimestamp(),
//             }, SetOptions(merge: true));
//           } else {
//             // Pour les barèmes avec sous-barèmes, traiter chaque niveau comme sous-barème
//             for (var levelEntry in levelEvaluations.entries) {
//               final sousBaremeId = '${baremeId}_${levelEntry.key}';
//               final sousBaremeDoc = FirebaseFirestore.instance
//                   .collection('users')
//                   .doc(currentUser.uid)
//                   .collection('user_classes')
//                   .doc(widget.classId)
//                   .collection('students')
//                   .doc(widget.studentId)
//                   .collection('baremes')
//                   .doc(sousBaremeId);

//               batch.set(sousBaremeDoc, {
//                 'Marks': levelEntry.value,
//                 'parentBaremeId': baremeId,
//                 'level': levelEntry.key,
//                 'importedFromOCR': true,
//                 'updatedAt': FieldValue.serverTimestamp(),
//               }, SetOptions(merge: true));
//             }
//           }
//         }
//       }

//       // Exécuter le batch
//       await batch.commit();

//       // Afficher un message de succès
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('تم حفظ التقييمات المستخرجة بنجاح'),
//           backgroundColor: Colors.green,
//           duration: Duration(seconds: 2),
//         ),
//       );

//       // Fermer le dialogue
//       Navigator.pop(context);

//     } catch (e) {
//       print('Erreur lors de la sauvegarde: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('حدث خطأ أثناء الحفظ'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('تقييم مستخرج من الصورة'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.save),
//             onPressed: _saveEvaluations,
//             tooltip: 'حفظ التقييمات',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Bannière d'information
//           Container(
//             padding: EdgeInsets.all(16),
//             color: Colors.blue[50],
//             child: Row(
//               children: [
//                 Icon(Icons.info, color: Colors.blue),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     'تم استخراج ${widget.extractedData.length} معيار من الصورة. '
//                     'يرجى مراجعة وتأكيد التقييمات.',
//                     style: TextStyle(color: Colors.blue[800]),
//                   ),
//                 ),
//               ],
//             ),
//           ),
          
//           // Liste des barèmes
//           Expanded(
//             child: ListView.builder(
//               padding: EdgeInsets.all(16),
//               itemCount: widget.extractedData.length,
//               itemBuilder: (context, index) {
//                 return _buildBaremeCard(widget.extractedData[index]);
//               },
//             ),
//           ),
          
//           // Boutons d'action
//           Padding(
//             padding: EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: Text('إلغاء'),
//                     style: TextButton.styleFrom(
//                       padding: EdgeInsets.symmetric(vertical: 16),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     icon: Icon(Icons.cloud_upload),
//                     label: Text('حفظ التقييمات'),
//                     onPressed: _saveEvaluations,
//                     style: ElevatedButton.styleFrom(
//                       padding: EdgeInsets.symmetric(vertical: 16),
//                       backgroundColor: Colors.green,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }