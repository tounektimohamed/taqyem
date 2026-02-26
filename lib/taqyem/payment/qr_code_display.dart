// import 'package:flutter/material.dart';
// import 'package:qr_flutter/qr_flutter.dart';

// class QRCodeDisplay extends StatelessWidget {
//   final String userId;
//   final String userNom;
//   final String userPrenom;

//   const QRCodeDisplay({
//     Key? key,
//     required this.userId,
//     required this.userNom,
//     required this.userPrenom,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Créer les données du QR code
//     Map<String, dynamic> qrData = {
//       'userId': userId,
//       'nom': userNom,
//       'prenom': userPrenom,
//       'timestamp': DateTime.now().toIso8601String(),
//     };

//     // Convertir en JSON string
//     String qrString = qrData.toString();

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'رمز الاستجابة السريعة (QR Code)',
//           style: TextStyle(fontFamily: 'Tajawal'),
//         ),
//         backgroundColor: Colors.blue.shade700,
//         foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.withOpacity(0.3),
//                         spreadRadius: 5,
//                         blurRadius: 7,
//                         offset: Offset(0, 3),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       Text(
//                         '$userPrenom $userNom',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           fontFamily: 'Tajawal',
//                         ),
//                       ),
//                       SizedBox(height: 10),
//                       Text(
//                         'رمز الدفع الخاص بك',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey[600],
//                           fontFamily: 'Tajawal',
//                         ),
//                       ),
//                       SizedBox(height: 20),
//                       // QR Code
//                       Container(
//                         padding: EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[100],
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: QrImageView(
//                           data: qrString,
//                           version: QrVersions.auto,
//                           size: 250.0,
//                           backgroundColor: Colors.white,
//                           embeddedImageStyle: QrEmbeddedImageStyle(
//                             size: Size(50, 50),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 20),
//                       Container(
//                         padding: EdgeInsets.all(15),
//                         decoration: BoxDecoration(
//                           color: Colors.blue.shade50,
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(color: Colors.blue.shade200),
//                         ),
//                         child: Column(
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(Icons.info, color: Colors.blue, size: 20),
//                                 SizedBox(width: 8),
//                                 Text(
//                                   'معلومات مهمة',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.blue.shade800,
//                                     fontFamily: 'Tajawal',
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             SizedBox(height: 10),
//                             Text(
//                               'احتفظ بهذا الرمز جيداً. ستقوم بمسحه ضوئياً عند الدفع لتأكيد هويتك.',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.blue.shade700,
//                                 fontFamily: 'Tajawal',
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       SizedBox(height: 30),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           ElevatedButton.icon(
//                             icon: Icon(Icons.download),
//                             label: Text(
//                               'تحميل',
//                               style: TextStyle(fontFamily: 'Tajawal'),
//                             ),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.green,
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 20, vertical: 12),
//                             ),
//                             onPressed: () {
//                               // Logique de téléchargement du QR code
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                   content: Text('جاري تحميل رمز QR...'),
//                                   backgroundColor: Colors.green,
//                                 ),
//                               );
//                             },
//                           ),
//                           ElevatedButton.icon(
//                             icon: Icon(Icons.share),
//                             label: Text(
//                               'مشاركة',
//                               style: TextStyle(fontFamily: 'Tajawal'),
//                             ),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blue,
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 20, vertical: 12),
//                             ),
//                             onPressed: () {
//                               // Logique de partage
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                   content: Text('تم نسخ الرمز'),
//                                   backgroundColor: Colors.blue,
//                                 ),
//                               );
//                             },
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 20),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => PaymentFormPage(
//                                 userId: userId,
//                                 userNom: userNom,
//                                 userPrenom: userPrenom,
//                               ),
//                             ),
//                           );
//                         },
//                         child: Text(
//                           'المتابعة إلى نموذج الدفع',
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.blue,
//                             fontFamily: 'Tajawal',
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // نموذج الدفع (يجب أن يكون موجوداً مسبقاً)
// class PaymentFormPage extends StatelessWidget {
//   final String userId;
//   final String userNom;
//   final String userPrenom;

//   const PaymentFormPage({
//     Key? key,
//     required this.userId,
//     required this.userNom,
//     required this.userPrenom,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('نموذج الدفع'),
//       ),
//       body: Center(
//         child: Text('نموذج الدفع هنا'),
//       ),
//     );
//   }
// }