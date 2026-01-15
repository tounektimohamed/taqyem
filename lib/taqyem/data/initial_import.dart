// import 'dart:convert';
// import 'package:Taqyem/taqyem/data/data_model.dart';
// import 'package:Taqyem/taqyem/data/firebase_data-service.dart';
// import 'package:flutter/services.dart';


// class InitialImport {
//   static Future<void> importJsonData(FirebaseService service) async {
//     try {
//       final jsonString = await rootBundle.loadString('assets/data.json');
//       final List<dynamic> jsonList = json.decode(jsonString);
      
//       final List<EducationalData> dataList = jsonList.map((json) {
//         return EducationalData(
//           classe: json['classe'] ?? '',
//           matiere: json['matiere'] ?? '',
//           bareme: json['bareme'] ?? '',
//           solution: json['solution'] ?? '',
//           probleme: json['probleme'] ?? '',
//         );
//       }).toList();
      
//       await service.uploadData(dataList);
//     } catch (e) {
//       print('Erreur d\'import: $e');
//     }
//   }
// }