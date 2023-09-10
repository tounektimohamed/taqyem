// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multi_dropdown/multiselect_dropdown.dart';
import 'package:mymeds_app/components/category_model.dart';
import 'package:mymeds_app/components/text_field.dart';
// import 'package:flutter_spinner_picker/flutter_spinner_picker.dart';
// import 'add_medication2.dart';
// import 'package:time_picker_spinner/time_picker_spinner.dart';

import 'package:day_night_time_picker/day_night_time_picker.dart';


// import 'package:show_time_picker/show_time_picker.dart';
import 'package:mymeds_app/screens/add_medication3.dart';


class AddMedication2 extends StatefulWidget {
  List<CategoryModel> categories = [];

  void _getInitialInfo() {
    categories = CategoryModel.getCategories();
  }

  @override
  _AddMedication1State createState() => _AddMedication1State();
}

enum Units {
  pills,
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
    case Units.pills:
      return 'pills';
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
bool isPillCountRequired = false;

class _AddMedication1State extends State<AddMedication2> {
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

  @override
  void initState() {
    super.initState();
    widget._getInitialInfo();
  }

  void _openImagePicker() {
    // Implement your image picker logic here
    // This function will be called when the image is clicked
  }

  @override
  Widget build(BuildContext context) {
    widget._getInitialInfo();
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
              const Padding(
                padding: EdgeInsets.only(top: 20, left: 10),
                child: Text(
                  'Dosage per Intake',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _medicationStrengthValueController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select the dosage per intake';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                      cursorColor: const Color.fromARGB(255, 7, 82, 96),
                      decoration: InputDecoration(
                        hintText: '1',
                        labelText: 'Count',
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
                    child: MultiSelectDropDown(
                      onOptionSelected: (List<ValueItem> selectedOptions) {},
                      options: const <ValueItem>[
                        ValueItem(label: 'pill', value: 'pill'),
                        ValueItem(label: 'tsp', value: 'tsp'),
                        ValueItem(label: 'tbsp', value: 'tbsp'),
                        ValueItem(label: 'cup', value: 'cup'),
                        ValueItem(label: 'mg', value: 'mg'),
                        ValueItem(label: 'mcg', value: 'mcg'),
                        ValueItem(label: 'g', value: 'g'),
                        ValueItem(label: 'ml', value: 'ml'),
                        ValueItem(label: '%', value: '%'),
                        ValueItem(label: 'IU', value: 'IU'),
                        ValueItem(label: 'oz', value: 'oz'),
                        ValueItem(label: 'pt', value: 'pt'),
                        ValueItem(label: 'qt', value: 'qt'),
                        ValueItem(label: 'gal', value: 'gal'),
                        ValueItem(label: 'lb', value: 'lb'),
                        ValueItem(label: 'mg/mL', value: 'mg/mL'),
                      ],
                      selectionType: SelectionType.single,
                      chipConfig: const ChipConfig(wrapType: WrapType.wrap),
                      dropdownHeight: 400,
                      optionTextStyle: const TextStyle(fontSize: 16),
                      selectedOptionIcon: const Icon(Icons.check_circle),
                      backgroundColor: Colors.transparent,
                      focusedBorderWidth: 2,
                      inputDecoration: BoxDecoration(
                        color: const Color.fromARGB(255, 219, 228, 231),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      focusedBorderColor: const Color.fromARGB(255, 7, 82, 96),
                      padding: const EdgeInsets.all(22),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft, // Align to the left
                      child: Checkbox(
                        value: isPillCountRequired,
                        onChanged: (newValue) {
                          setState(() {
                            isPillCountRequired = newValue!;
                          });
                        },
                      ),
                    ),
                    Text(
                      'Available Pill Count (Optional)',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPillCountRequired)
                Text_Field(
                  label: 'Total Pill Count',
                  hint: '30',
                  isPassword: false,
                  keyboard: TextInputType.number,
                  txtEditController: _medicationNameController,
                ),
              SizedBox(height: 24),
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                width: double.infinity,
                height: 3,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: 16),

              const Padding(
                padding: EdgeInsets.only(top: 20, left: 10),
                child: Text(
                  'Takes Notes If Needed',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),

                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _medicationNoteController,
                decoration: InputDecoration(

                  labelText: '   Medication Notes',
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15, horizontal: 12),

                ),
                maxLines:
                    null, // Set this to null to allow unlimited vertical flow
              ),

              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMedication3(),
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
