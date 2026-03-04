// // lib/pages/register_with_code_page.dart
// import 'package:Taqyem/taqyem/payment/PaymentPage.dart';
// import 'package:Taqyem/taqyem/payment/group/GroupCodeService.dart';
// import 'package:flutter/material.dart';

// class RegisterWithCodePage extends StatefulWidget {
//   @override
//   _RegisterWithCodePageState createState() => _RegisterWithCodePageState();
// }

// class _RegisterWithCodePageState extends State<RegisterWithCodePage> {
//   final TextEditingController _codeController = TextEditingController();
//   final GroupCodeService _codeService = GroupCodeService();
//   bool _isLoading = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('انضم إلى مجموعة', style: TextStyle(fontFamily: 'Tajawal')),
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.group_add, size: 80, color: Colors.blue),
//             SizedBox(height: 20),
//             Text(
//               'أدخل كود المجموعة',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 fontFamily: 'Tajawal',
//               ),
//             ),
//             SizedBox(height: 10),
//             Text(
//               'مثال: TOUNEKT-2026-001',
//               style: TextStyle(
//                 color: Colors.grey,
//                 fontFamily: 'Tajawal',
//               ),
//             ),
//             SizedBox(height: 30),
//             TextField(
//               controller: _codeController,
//               decoration: InputDecoration(
//                 labelText: 'كود المجموعة',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 prefixIcon: Icon(Icons.qr_code),
//               ),
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 18, letterSpacing: 2),
//             ),
//             SizedBox(height: 30),
//             _isLoading
//                 ? CircularProgressIndicator()
//                 : ElevatedButton(
//                     onPressed: _joinGroup,
//                     style: ElevatedButton.styleFrom(
//                       padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                     child: Text(
//                       'انضمام',
//                       style: TextStyle(fontSize: 18, fontFamily: 'Tajawal'),
//                     ),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _joinGroup() async {
//     if (_codeController.text.isEmpty) {
//       _showMessage('الرجاء إدخال كود المجموعة', Colors.red);
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       final result = await _codeService.validateAndJoinGroup(_codeController.text.trim());
      
//       if (result['success']) {
//         // Ouvrir la page de paiement avec les infos du groupe
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => PaymentPage(
//               groupCode: _codeController.text.trim(),
//               schoolName: result['school'],
//             ),
//           ),
//         );
//       } else {
//         _showMessage(result['message'], Colors.red);
//       }
//     } catch (e) {
//       _showMessage('حدث خطأ: $e', Colors.red);
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _showMessage(String message, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: TextStyle(fontFamily: 'Tajawal')),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
// }