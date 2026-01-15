// lib/utils/provider_wrapper.dart
import 'package:Taqyem/taqyem/data/addprobsolu.dart';
import 'package:Taqyem/taqyem/data/firebase_data-service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FirebaseProviderWrapper extends StatelessWidget {
  final Widget child;
  final FirebaseService? customService;
  
  const FirebaseProviderWrapper({
    super.key,
    required this.child,
    this.customService,
  });
  
  @override
  Widget build(BuildContext context) {
    if (customService != null) {
      return Provider<FirebaseService>.value(
        value: customService!,
        child: child,
      );
    }
    
    // Essaie de récupérer le service existant, sinon crée-en un nouveau
    try {
      final existingService = Provider.of<FirebaseService>(context, listen: false);
      return Provider<FirebaseService>.value(
        value: existingService,
        child: child,
      );
    } catch (e) {
      // Si aucun service n'existe, créez-en un
      return ChangeNotifierProvider(
        create: (context) => FirebaseService(),
        child: child,
      );
    }
  }
}

// Version spécifique pour AddProbScreen
class AddProbProviderWrapper extends StatelessWidget {
  const AddProbProviderWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final service = FirebaseService();
        // Optionnel: Charger les données immédiatement
        WidgetsBinding.instance.addPostFrameCallback((_) {
          service.loadData();
        });
        return service;
      },
      child: const AddProbScreen(),
    );
  }
}