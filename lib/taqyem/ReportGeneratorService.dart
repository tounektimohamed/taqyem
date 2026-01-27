// import 'package:firebase_functions/firebase_functions.dart';
// import 'package:cloud_functions/cloud_functions.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class ReportGeneratorService {
//   static final FirebaseFunctions functions = FirebaseFunctions.instance;
  
//   // Méthode optimisée avec Cloud Functions
//   static Future<Map<String, dynamic>> generateReportWithCloudFunction({
//     required String userId,
//     required String selectedClass,
//     required String selectedMatiere,
//     required String profName,
//     required String matiereName,
//     required String className,
//     required String schoolName,
//     required String trimestre,
//     required String periode,
//     required String evaluationType,
//     required String performanceAttendue,
//     required bool isFrenchInterface,
//   }) async {
//     try {
//       print('🚀 Appel de la Cloud Function...');
      
//       // Configurer la région si nécessaire
//       functions.useFunctionsEmulator('localhost', 5001); // Pour le développement
      
//       final HttpsCallable callable = functions.httpsCallable(
//         'generateCompleteReport',
//         options: HttpsCallableOptions(
//           timeout: const Duration(seconds: 300),
//         ),
//       );
      
//       final result = await callable.call({
//         'userId': userId,
//         'selectedClass': selectedClass,
//         'selectedMatiere': selectedMatiere,
//         'profName': profName,
//         'matiereName': matiereName,
//         'className': className,
//         'schoolName': schoolName,
//         'trimestre': trimestre,
//         'periode': periode,
//         'evaluationType': evaluationType,
//         'performanceAttendue': performanceAttendue,
//         'isFrenchInterface': isFrenchInterface,
//       });
      
//       print('✅ Cloud Function exécutée avec succès');
      
//       return {
//         'success': true,
//         'pdfBase64': result.data['pdfBase64'],
//         'fileName': result.data['fileName'],
//       };
      
//     } catch (e) {
//       print('❌ Erreur Cloud Function: $e');
//       return {
//         'success': false,
//         'error': e.toString(),
//       };
//     }
//   }
  
//   // Méthode de fallback direct HTTP
//   static Future<Map<String, dynamic>> generateReportDirectHTTP({
//     required String userId,
//     required String selectedClass,
//     required String selectedMatiere,
//     required String profName,
//     required String matiereName,
//     required String className,
//     required String schoolName,
//     required String trimestre,
//     required String periode,
//     required String evaluationType,
//     required String performanceAttendue,
//     required bool isFrenchInterface,
//     required String firebaseToken,
//   }) async {
//     try {
//       final url = Uri.parse(
//         'https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/generateCompleteReport'
//       );
      
//       final response = await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $firebaseToken',
//         },
//         body: json.encode({
//           'data': {
//             'userId': userId,
//             'selectedClass': selectedClass,
//             'selectedMatiere': selectedMatiere,
//             'profName': profName,
//             'matiereName': matiereName,
//             'className': className,
//             'schoolName': schoolName,
//             'trimestre': trimestre,
//             'periode': periode,
//             'evaluationType': evaluationType,
//             'performanceAttendue': performanceAttendue,
//             'isFrenchInterface': isFrenchInterface,
//           },
//         }),
//       );
      
//       if (response.statusCode == 200) {
//         final result = json.decode(response.body);
//         return {
//           'success': true,
//           'pdfBase64': result['result']['pdfBase64'],
//           'fileName': result['result']['fileName'],
//         };
//       } else {
//         throw Exception('Erreur HTTP: ${response.statusCode}');
//       }
//     } catch (e) {
//       return {
//         'success': false,
//         'error': e.toString(),
//       };
//     }
//   }
// }