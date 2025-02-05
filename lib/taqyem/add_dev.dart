import 'package:Taqyem/components/category_model.dart';
import 'package:Taqyem/components/controller_data.dart';
import 'package:Taqyem/components/language_constants.dart';
import 'package:Taqyem/components/text_field.dart';
import 'package:Taqyem/taqyem/add_dev3.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddMedication1 extends StatefulWidget {
  List<CategoryModel> categories = CategoryModel.getCategories();

  AddMedication1({super.key});

  @override
  _AddMedication1State createState() => _AddMedication1State();
}

class _AddMedication1State extends State<AddMedication1> {
  final user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _medicationNameController =
      MedicationControllerData().medicationNameController;
  final TextEditingController _medicationTypeController =
      MedicationControllerData().medicationTypeController;

  late FocusNode focusNode_medName;

  int _selectedCategoryIndex = -1;

  @override
  void initState() {
    super.initState();
    focusNode_medName = FocusNode();
  }

  void goToNextPage() {
    if (_medicationNameController.text.isEmpty) {
      focusNode_medName.requestFocus();
    } else if (_selectedCategoryIndex < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color.fromARGB(255, 7, 83, 96),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Text(
            translation(context).pstMedCategory,
          ),
        ),
      );
    } else {
      print(_medicationNameController.text);
      print(_medicationTypeController.text);
      // Navigate to the next page or perform other actions
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          translation(context).addMed,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 5,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              // Medication name
              Text(
                translation(context).medName,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Text_Field(
                label: translation(context).medName,
                hint: translation(context).vitaminC,
                isPassword: false,
                keyboard: TextInputType.text,
                txtEditController: _medicationNameController,
                focusNode: focusNode_medName,
              ),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.all(10),
                width: double.infinity,
                height: 2,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 20),
              Text(
                translation(context).cat,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  itemCount: widget.categories.length,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 0, right: 20),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (_selectedCategoryIndex == index) {
                              // Deselect if the same category is tapped again
                              _selectedCategoryIndex = -1;
                              _medicationTypeController.text = '';
                            } else {
                              // Deselect the previously selected category
                              if (_selectedCategoryIndex != -1) {
                                widget.categories[_selectedCategoryIndex]
                                        .boxColor =
                                    const Color.fromARGB(255, 158, 158, 158);
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
              const SizedBox(height: 40),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  onPressed: () {
                    goToNextPage();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddMedication3(),
                      ),
                    );
                  },
                  style: const ButtonStyle(
                    elevation: MaterialStatePropertyAll(2),
                    shape: MaterialStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  child: Text(
                    translation(context).next,
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
