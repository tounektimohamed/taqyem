import 'package:alarm/alarm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:Taqyem/auth/main_page.dart';
import 'package:Taqyem/components/language_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuration de l'orientation et de l'interface utilisateur
  await _configureSystemUI();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    
    // Mise à jour des utilisateurs existants
    await _updateExistingUsers();
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  await Alarm.init(showDebugLogs: true);
  runApp(const MyApp());
}

Future<void> _configureSystemUI() async {
  // Forcer l'application à s'ouvrir en mode paysage
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Forcer l'interface utilisateur système à rester en mode clair
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

Future<void> _updateExistingUsers() async {
  try {
    final users = await FirebaseFirestore.instance.collection('Users').get();
    
    final batch = FirebaseFirestore.instance.batch();
    int updates = 0;

    for (var doc in users.docs) {
      if (!doc.data().containsKey('accountExpiration')) {
        batch.update(doc.reference, {
          'accountExpiration': null,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        updates++;
      }
    }

    if (updates > 0) {
      await batch.commit();
      print('Mise à jour de $updates documents utilisateur');
    } else {
      print('Aucun utilisateur nécessitant une mise à jour');
    }
  } catch (e) {
    print('Erreur lors de la mise à jour des utilisateurs: $e');
    // Vous pourriez vouloir relancer l'erreur ou la gérer différemment
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    context.findAncestorStateOfType<_MyAppState>()?.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getLocale().then((locale) => setLocale(locale));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainPage(),
      theme: _buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color.fromRGBO(241, 250, 251, 1),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromRGBO(241, 250, 251, 1),
      ),
      colorSchemeSeed: const Color.fromRGBO(7, 82, 96, 1),
    );
  }
}