import 'package:alarm/alarm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:Taqyem/auth/main_page.dart';
import 'package:Taqyem/components/language_constants.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js; // Pour les fonctionnalités web spécifiques

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
  
  // Ajout du contrôle de version pour le web
  if (kIsWeb) {
    await _registerServiceWorker();
  }

  runApp(
    BetterFeedback(
      child: const MyApp(),
      theme: FeedbackThemeData(
        background: Colors.grey,
        feedbackSheetColor: Colors.white,
        drawColors: [
          Colors.red,
          Colors.green,
          Colors.blue,
          Colors.yellow,
        ],
      ),
    ),
  );
}

// Nouvelle fonction pour gérer le Service Worker sur le web
Future<void> _registerServiceWorker() async {
  try {
    // Version de l'application - changez cette valeur à chaque déploiement
    const appVersion = '1.0.1';
    js.context['serviceWorkerVersion'] = appVersion;
    
    // Stratégie agressive pour les mises à jour
    js.context.callMethod('eval', ['''
      if ('serviceWorker' in navigator) {
        window.addEventListener('load', function() {
          navigator.serviceWorker.register('flutter_service_worker.js?v=$appVersion')
            .then(function(registration) {
              console.log('ServiceWorker registration successful');
              registration.addEventListener('updatefound', function() {
                console.log('New update found!');
                registration.installing.addEventListener('statechange', function() {
                  if (this.state === 'installed') {
                    window.location.reload();
                  }
                });
              });
            })
            .catch(function(err) {
              console.log('ServiceWorker registration failed: ', err);
            });
          
          // Vérification périodique des mises à jour
          setInterval(function() {
            registration.update().catch(err => console.log('Update check failed:', err));
          }, 60 * 60 * 1000); // Toutes les heures
        });
      }
    ''']);
  } catch (e) {
    print('Error setting up service worker: $e');
  }
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