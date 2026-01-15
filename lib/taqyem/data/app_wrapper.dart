// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'firebase_data-service.dart';
// import 'addprobsolu.dart';

// class AppWrapper extends StatelessWidget {
//   const AppWrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (context) => FirebaseService(), // Provider local
//       child: MaterialApp(
//         title: 'Système Éducatif',
//         theme: ThemeData(
//           primarySwatch: Colors.blue,
//           appBarTheme: const AppBarTheme(
//             backgroundColor: Colors.blue,
//             foregroundColor: Colors.white,
//           ),
//         ),
//         debugShowCheckedModeBanner: false,
//         home: const _ScaffoldWrapper(), // Utilisez un wrapper
//       ),
//     );
//   }
// }

// class _ScaffoldWrapper extends StatefulWidget {
//   const _ScaffoldWrapper();

//   @override
//   State<_ScaffoldWrapper> createState() => _ScaffoldWrapperState();
// }

// class _ScaffoldWrapperState extends State<_ScaffoldWrapper> {
//   @override
//   void initState() {
//     super.initState();
//     // Chargez les données après un court délai
//     Future.delayed(Duration.zero, () {
//       Provider.of<FirebaseService>(context, listen: false).loadData();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const add_prob(); // Votre écran principal
//   }
// }