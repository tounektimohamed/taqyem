import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_edit_screen.dart';
import 'data_model.dart';
import 'firebase_data-service.dart';

class AddEditWrapper extends StatelessWidget {
  final EducationalData? data;
  final FirebaseService? firebaseService; // Ajoutez ce paramètre
  final Function(Map<String, dynamic>) onSave;
  
  const AddEditWrapper({
    super.key,
    this.data,
    this.firebaseService, // Nouveau paramètre optionnel
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FirebaseService>.value(
      value: firebaseService ?? FirebaseService(),
      child: AddEditScreen(
        data: data,
        onSave: onSave,
      ),
    );
  }
}