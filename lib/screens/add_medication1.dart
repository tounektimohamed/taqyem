// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/text_field.dart';

import 'add_medication2.dart';
// import 'package:time_picker_spinner/time_picker_spinner.dart';
// import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
// import 'package:show_time_picker/show_time_picker.dart';

class AddMedication1 extends StatefulWidget {
  const AddMedication1({Key? key}) : super(key: key);

  @override
  _AddMedication1State createState() => _AddMedication1State();
}

enum Units {
  mg,
  mcg,
  g,
  ml,
  percentage, // Instead of %
  IU,
  oz,
  tsp,
  tbsp,
  cup,
  pt,
  qt,
  gal,
  lb,
  mg_per_ml // Instead of mg/mL
}

String unitToString(Units unit) {
  switch (unit) {
    case Units.mg:
      return 'mg';
    case Units.mcg:
      return 'mcg';
    case Units.g:
      return 'g';
    case Units.ml:
      return 'ml';
    case Units.percentage:
      return '%';
    case Units.IU:
      return 'IU';
    case Units.oz:
      return 'oz';
    case Units.tsp:
      return 'tsp';
    case Units.tbsp:
      return 'tbsp';
    case Units.cup:
      return 'cup';
    case Units.pt:
      return 'pt';
    case Units.qt:
      return 'qt';
    case Units.gal:
      return 'gal';
    case Units.lb:
      return 'lb';
    case Units.mg_per_ml:
      return 'mg/mL';
    default:
      return ''; // Handle any unexpected cases
  }
}

Units? _units;

class _AddMedication1State extends State<AddMedication1> {
  final user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  final _medicationNameController = TextEditingController();
  final _medicationTypeController = TextEditingController();
  final _medicationStrengthController = TextEditingController();
  final _medicationQuantityController = TextEditingController();
  final _medicationDosageController = TextEditingController();
  final _medicationFrequencyController = TextEditingController();
  var _medicationTimeOfDayController = TextEditingController();
  final _medicationStrengthValueController = TextEditingController();
  final _medicationNoteController = TextEditingController();
  final _medicationPhotoController = TextEditingController();

  // var time = DateTime.now();

  void _openImagePicker() {
    // Implement your image picker logic here
    // This function will be called when the image is clicked
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Medication',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          padding: const EdgeInsets.only(left: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              GestureDetector(
                onTap: _openImagePicker,
                child: Container(
                  margin: const EdgeInsets.only(
                      left: 80, right: 80, top: 16, bottom: 16),
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add_a_photo, size: 50),
                ),
              ),
              SizedBox(height: 16),
              Text_Field(
                label: 'Medication Name',
                hint: 'Medicine',
                isPassword: false,
                keyboard: TextInputType.text,
                txtEditController: _medicationNameController,
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _medicationStrengthValueController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the medication strength';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                      cursorColor: const Color.fromARGB(255, 7, 82, 96),
                      decoration: InputDecoration(
                        hintText: '0.0',
                        labelText: 'Medication Strength',
                        labelStyle: GoogleFonts.poppins(
                          color: const Color.fromARGB(255, 16, 15, 15),
                        ),
                        filled: true,
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(20),
                          ),
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 7, 82, 96),
                          ),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(20),
                          ),
                          borderSide: BorderSide(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8), // Add spacing between the two text fields
                  Expanded(
                    child: TextFormField(
                      onTap: () => showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(
                              'Select the Medication Strength',
                              style: GoogleFonts.poppins(
                                color: const Color.fromARGB(255, 16, 15, 15),
                              ),
                            ),
                            content: StatefulBuilder(
                              builder: (BuildContext context,
                                  void Function(void Function()) setState) {
                                return SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      for (Units unit in Units.values)
                                        RadioListTile<Units>(
                                          title: Text(
                                            unitToString(unit),
                                            style: GoogleFonts.poppins(
                                              color: const Color.fromARGB(
                                                  255, 16, 15, 15),
                                            ),
                                          ),
                                          value: unit,
                                          groupValue: _units,
                                          onChanged: (Units? value) {
                                            setState(() {
                                              _units = value;
                                              _medicationStrengthController
                                                  .text = unitToString(value!);
                                              Navigator.pop(
                                                  context); // Close the dialog
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            actions: [
                              // ... OK and Cancel buttons ...
                              //by clicking on the cancel button the dialog will be closed and the selected value should be cleared

                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    color:
                                        const Color.fromARGB(255, 16, 15, 15),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Ok',
                                  style: GoogleFonts.poppins(
                                    color:
                                        const Color.fromARGB(255, 16, 15, 15),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      controller: _medicationStrengthController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the medication strength';
                        }
                        return null;
                      },
                      readOnly: true, // Prevent direct input
                      cursorColor: const Color.fromARGB(255, 7, 82, 96),
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        labelStyle: GoogleFonts.poppins(
                          color: const Color.fromARGB(255, 16, 15, 15),
                        ),
                        filled: true,
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(20),
                          ),
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 7, 82, 96),
                          ),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(20),
                          ),
                          borderSide: BorderSide(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _medicationNoteController,
                decoration: InputDecoration(labelText: 'Medication Note'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the medication note';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  // if (_formKey.currentState!.validate()) {
                  //   await FirebaseFirestore.instance
                  //       .collection('users')
                  //       .doc(user!.uid)
                  //       .collection('medications')
                  //       .add({
                  //     'medicationName': _medicationNameController.text,
                  //     'medicationType': _medicationTypeController.text,
                  //     'medicationQuantity': _medicationQuantityController.text,
                  //     'medicationDosage': _medicationDosageController.text,
                  //     'medicationFrequency':
                  //         _medicationFrequencyController.text,
                  //     'medicationTimeOfDay':
                  //         _medicationTimeOfDayController.text,
                  //     'medicationReminder': _medicationReminderController.text,
                  //     'medicationNote': _medicationNoteController.text,
                  //     'medicationPhoto': _medicationPhotoController.text,
                  //   });
                  //   //navigate to add_medicine2
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => AddMedication2(),
                  //     ),
                  //   );
                  // }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMedication2(),
                    ),
                  );
                },
                child: Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
