import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mymeds_app/auth/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mymeds_app/screens/medication.dart';
import 'package:mymeds_app/screens/dashboard.dart';
import 'package:mymeds_app/screens/home.dart';
import 'package:mymeds_app/screens/statistic.dart';

class AddMedication1 extends StatefulWidget {
  const AddMedication1({Key? key}) : super(key: key);

  @override
  _AddMedication1State createState() => _AddMedication1State();
}

class _AddMedication1State extends State<AddMedication1> {
  final user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  final _medicationNameController = TextEditingController();
  final _medicationTypeController = TextEditingController();
  final _medicationQuantityController = TextEditingController();
  final _medicationDosageController = TextEditingController();
  final _medicationFrequencyController = TextEditingController();
  final _medicationTimeOfDayController = TextEditingController();
  final _medicationReminderController = TextEditingController();
  final _medicationNoteController = TextEditingController();
  final _medicationPhotoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _medicationNameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the medication name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _medicationTypeController,
              decoration: const InputDecoration(
                labelText: 'Medication Type',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the medication type';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _medicationQuantityController,
              decoration: const InputDecoration(
                labelText: 'Medication Quantity',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the medication quantity';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _medicationDosageController,
              decoration: const InputDecoration(
                labelText: 'Medication Dosage',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the medication dosage';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _medicationFrequencyController,
              decoration: const InputDecoration(
                labelText: 'Medication Frequency',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the medication frequency';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _medicationTimeOfDayController,
              decoration: const InputDecoration(
                labelText: 'Medication Time of Day',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the medication time of day';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _medicationReminderController,
              decoration: const InputDecoration(
                labelText: 'Medication Reminder',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the medication reminder';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _medicationNoteController,
              decoration: const InputDecoration(
                labelText: 'Medication Note',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the medication note';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _medicationPhotoController,
              decoration: const InputDecoration(
                labelText: 'Medication Photo',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the medication photo';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .collection('medications')
                      .add({
                    'medicationName': _medicationNameController.text,
                    'medicationType': _medicationTypeController.text,
                    'medicationQuantity': _medicationQuantityController.text,
                    'medicationDosage': _medicationDosageController.text,
                    'medicationFrequency': _medicationFrequencyController.text,
                    'medicationTimeOfDay': _medicationTimeOfDayController.text,
                    'medicationReminder': _medicationReminderController.text,
                    'medicationNote': _medicationNoteController.text,
                    'medicationPhoto': _medicationPhotoController.text,
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add Medication'),
            ),
          ],
        ),
      ),
    );
  }
}
