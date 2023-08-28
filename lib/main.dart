import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mymeds_app/auth/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainPage(),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color.fromRGBO(7, 82, 96, 1),
        snackBarTheme: SnackBarThemeData(
          contentTextStyle: TextStyle(fontSize: 16), // Customize text style
          backgroundColor: Colors.blueGrey, // Customize background color
          elevation: 6, // Customize elevation
          behavior: SnackBarBehavior.floating, // Customize behavior
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Customize border radius
          ),
        ),
      ),
    );
  }
}
