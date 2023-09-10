import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multi_dropdown/multiselect_dropdown.dart';
import 'package:mymeds_app/components/category_model.dart';
import 'package:mymeds_app/components/text_field.dart';
import 'package:mymeds_app/screens/add_medication2.dart';

class AddMedication1 extends StatefulWidget {
  List<CategoryModel> categories = CategoryModel.getCategories();

  @override
  _AddMedication1State createState() => _AddMedication1State();
}

enum Units {
  mg,
  mcg,
  g,
  ml,
  percentage,
  IU,
  oz,
  tsp,
  tbsp,
  cup,
  pt,
  qt,
  gal,
  lb,
  mg_per_ml,
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
      return '';
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

  int _selectedCategoryIndex = -1;

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
                      left: 20, right: 20, top: 16, bottom: 10),
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add_a_photo, size: 50),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 16, left: 10),
                child: Text(
                  'Name',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 8),
              Text_Field(
                label: 'Medication Name',
                hint: 'Medicine',
                isPassword: false,
                keyboard: TextInputType.text,
                txtEditController: _medicationNameController,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 20, left: 10),
                child: Text(
                  'Category',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Container(
                height: 120,
                child: ListView.builder(
                  itemCount: widget.categories.length,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 10, right: 20),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(
                          right: 16), // Adjust the right padding for space
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (_selectedCategoryIndex == index) {
                              // If the same category is tapped again, deselect it
                              _selectedCategoryIndex = -1;
                              _medicationTypeController.text = '';
                            } else {
                              // Deselect the previously selected category
                              if (_selectedCategoryIndex != -1) {
                                widget.categories[_selectedCategoryIndex]
                                    .boxColor = Colors.transparent;
                                widget.categories[_selectedCategoryIndex]
                                    .isSelected = false;
                              }

                              // Select the tapped category
                              _selectedCategoryIndex = index;
                              _medicationTypeController.text =
                                  widget.categories[index].name;
                              widget.categories[index].boxColor =
                                  const Color.fromARGB(255, 7, 82, 96)
                                      .withOpacity(0.3);
                              widget.categories[index].isSelected = true;

                              print(_medicationTypeController.text);
                            }
                          });
                        },
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: widget.categories[index].boxColor
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    widget.categories[index].iconPath,
                                  ),
                                ),
                              ),
                              Text(
                                widget.categories[index].name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 20, left: 10),
                child: Text(
                  'Strength',
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
                          return 'Please enter the medication strength';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                      cursorColor: const Color.fromARGB(255, 7, 82, 96),
                      decoration: InputDecoration(
                        hintText: '0.0',
                        labelText: 'Strength Value',
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
                  SizedBox(width: 8),
                  Expanded(
                    child: MultiSelectDropDown(
                      onOptionSelected: (List<ValueItem> selectedOptions) {},
                      options: const <ValueItem>[
                        ValueItem(label: 'mg', value: 'mg'),
                        ValueItem(label: 'mcg', value: 'mcg'),
                        ValueItem(label: 'g', value: 'g'),
                        ValueItem(label: 'ml', value: 'ml'),
                        ValueItem(label: 'tsp', value: 'tsp'),
                        ValueItem(label: 'tbsp', value: 'tbsp'),
                        ValueItem(label: '%', value: '%'),
                        ValueItem(label: 'cup', value: 'cup'),
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
                      dropdownHeight: 200,
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
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
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
