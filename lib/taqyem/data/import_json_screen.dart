// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'firebase_data-service.dart';
// import 'data_model.dart';

// class ImportJsonScreen extends StatefulWidget {
//   const ImportJsonScreen({super.key});

//   @override
//   State<ImportJsonScreen> createState() => _ImportJsonScreenState();
// }

// class _ImportJsonScreenState extends State<ImportJsonScreen> {
//   bool _isImporting = false;
//   String _importStatus = 'Prêt à importer';
//   List<EducationalData> _jsonData = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadJsonData();
//   }

//   Future<void> _loadJsonData() async {
//     try {
//       final jsonString = await rootBundle.loadString('assets/data.json');
//       final jsonList = json.decode(jsonString) as List;
      
//       setState(() {
//         _jsonData = jsonList.map((item) {
//           return EducationalData(
//             classe: item['classe']?.toString() ?? '',
//             matiere: item['matiere']?.toString() ?? '',
//             bareme: item['bareme']?.toString() ?? '',
//             solution: item['solution']?.toString() ?? '',
//             probleme: item['probleme']?.toString() ?? '',
//           );
//         }).toList();
        
//         _importStatus = '${_jsonData.length} enregistrements chargés';
//       });
//     } catch (e) {
//       setState(() {
//         _importStatus = 'Erreur: $e';
//       });
//     }
//   }

//   Future<void> _importToFirebase() async {
//     if (_jsonData.isEmpty) return;

//     setState(() {
//       _isImporting = true;
//       _importStatus = 'Importation...';
//     });

//     try {
//       final service = Provider.of<FirebaseService>(context, listen: false);
//       await service.uploadData(_jsonData);
      
//       setState(() {
//         _importStatus = '✅ ${_jsonData.length} données importées!';
//       });
      
//       // Retour après 2 secondes
//       Future.delayed(const Duration(seconds: 2), () {
//         if (mounted) Navigator.pop(context);
//       });
//     } catch (e) {
//       setState(() {
//         _importStatus = '❌ Erreur: $e';
//       });
//     } finally {
//       setState(() {
//         _isImporting = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Import JSON'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           children: [
//             // Status
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text(
//                   _importStatus,
//                   style: TextStyle(
//                     color: _importStatus.contains('✅') 
//                       ? Colors.green
//                       : _importStatus.contains('❌')
//                         ? Colors.red
//                         : Colors.blue,
//                     fontSize: 16,
//                   ),
//                 ),
//               ),
//             ),
            
//             const SizedBox(height: 20),
            
//             // Preview
//             Expanded(
//               child: Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Aperçu des données:',
//                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 10),
//                       Text('Total: ${_jsonData.length} entrées'),
//                       const SizedBox(height: 20),
//                       if (_jsonData.isNotEmpty) ...[
//                         const Text('Première entrée:'),
//                         const SizedBox(height: 10),
//                         Text('Classe: ${_jsonData.first.classe}'),
//                         Text('Matière: ${_jsonData.first.matiere}'),
//                         Text('Barème: ${_jsonData.first.bareme}'),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//             ),
            
//             const SizedBox(height: 20),
            
//             // Boutons
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _loadJsonData,
//                     child: const Text('Recharger'),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _isImporting || _jsonData.isEmpty 
//                       ? null 
//                       : _importToFirebase,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       foregroundColor: Colors.white,
//                     ),
//                     child: _isImporting
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : const Text('Importer vers Firebase'),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }