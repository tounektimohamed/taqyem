import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../components/text_field.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

enum Genders { male, female, other }

class _UserProfileState extends State<UserProfile> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool isLoading = false;

  final _nameController = TextEditingController();
  var _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _nicController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();

  Genders? _genderSelected;

  @override
  void initState() {
    super.initState();
    // Fetch user profile data when widget initializes
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.email)
          .get();

      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;

        setState(() {
          _nameController.text = userData['name'] ?? '';
          _dobController.text = userData['dob'] ?? '';
          _genderController.text = userData['gender'] ?? '';
          _nicController.text = userData['nic'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _mobileController.text = userData['mobile'] ?? '';
        });
      } else {
        // Handle case where document doesn't exist
        print('Document does not exist');
        // Optionally, you can initialize the text controllers with default values
        setState(() {
          _nameController.text = '';
          _dobController.text = '';
          _genderController.text = '';
          _nicController.text = '';
          _addressController.text = '';
          _mobileController.text = '';
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      // Handle error fetching user profile data
    }
  }

  Future<void> update() async {
    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.email)
          .set({
        'name': _nameController.text,
        'dob': _dobController.text,
        'gender': _genderController.text,
        'nic': _nicController.text,
        'address': _addressController.text,
        'mobile': _mobileController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color.fromARGB(255, 7, 83, 96),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          content: Text(
            'Your data updated successfully',
          ),
        ),
      );
    } catch (e) {
      print('Error updating user profile: $e');
      // Handle error updating user profile data
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _nicController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Profile',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(35, 0, 35, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Profile picture (you can customize this as per your needs)
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.surface,
              child: currentUser?.photoURL?.isEmpty ?? true
                  ? const Icon(Icons.person_outline)
                  : Image.network(currentUser!.photoURL!),
            ),
            const SizedBox(height: 10),
            // Email (assuming this is displayed)
            Text(
              '${currentUser!.email}',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 15,
                color: const Color.fromARGB(255, 16, 15, 15),
              ),
            ),
            const SizedBox(height: 20),
            // Basic Info section
            Text(
              'Basic Info',
              style: GoogleFonts.roboto(
                fontSize: 15,
                color: const Color.fromARGB(255, 16, 15, 15),
              ),
            ),
            const SizedBox(height: 10),
            // Name TextField
            Text_Field(
              label: 'Name',
              hint: 'FirstName LastName',
              isPassword: false,
              keyboard: TextInputType.text,
              txtEditController: _nameController,
              focusNode: FocusNode(),
            ),
            const SizedBox(height: 15),
            // Date of Birth TextField
            TextField(
              onTap: () async {
                var datePicked = await DatePicker.showSimpleDatePicker(
                  context,
                  titleText: 'Select your birthday',
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2099),
                  dateFormat: "dd-MMMM-yyyy",
                  locale: DateTimePickerLocale.en_us,
                  looping: true,
                );
                if (datePicked != null) {
                  String date =
                      '${datePicked.day}-${datePicked.month}-${datePicked.year}';
                  setState(() {
                    _dobController.text = date;
                  });
                }
              },
              controller: _dobController,
              readOnly: true,
              style: GoogleFonts.roboto(
                height: 2,
                color: const Color.fromARGB(255, 16, 15, 15),
              ),
              cursorColor: const Color.fromARGB(255, 7, 82, 96),
              decoration: InputDecoration(
                hintText: 'DD-MM-YYYY',
                labelText: 'Date of Birth',
                labelStyle: GoogleFonts.roboto(
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
            const SizedBox(height: 15),
            // Gender TextField (using a dialog for selection)
            TextField(
              onTap: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Select your gender',
                    style: GoogleFonts.roboto(
                      color: const Color.fromARGB(255, 16, 15, 15),
                    ),
                  ),
                  content: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          RadioListTile(
                            value: Genders.male,
                            title: const Text('Male'),
                            groupValue: _genderSelected,
                            onChanged: (value) {
                              setState(() {
                                _genderSelected = value as Genders;
                                _genderController.text = 'Male';
                                Navigator.of(context).pop();
                              });
                            },
                          ),
                          RadioListTile(
                            value: Genders.female,
                            title: const Text('Female'),
                            groupValue: _genderSelected,
                            onChanged: (value) {
                              setState(() {
                                _genderSelected = value as Genders;
                                _genderController.text = 'Female';
                                Navigator.of(context).pop();
                              });
                            },
                          ),
                          RadioListTile(
                            value: Genders.other,
                            title: const Text('Other'),
                            groupValue: _genderSelected,
                            onChanged: (value) {
                              setState(() {
                                _genderSelected = value as Genders;
                                _genderController.text = 'Other';
                                Navigator.of(context).pop();
                              });
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              controller: _genderController,
              readOnly: true,
              style: GoogleFonts.roboto(
                height: 2,
                color: const Color.fromARGB(255, 16, 15, 15),
              ),
              cursorColor: const Color.fromARGB(255, 7, 82, 96),
              decoration: InputDecoration(
                labelText: 'Gender',
                labelStyle: GoogleFonts.roboto(
                  color: const Color.fromARGB(255, 16, 15, 15),
                ),
                hintText: 'Gender',
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
            const SizedBox(height: 15),
            // NIC TextField
            Text_Field(
              label: 'NIC',
              hint: '123456789V',
              isPassword: false,
              keyboard: TextInputType.text,
              txtEditController: _nicController,
              focusNode: FocusNode(),
            ),
            const SizedBox(height: 15),
            // Contact Info section
            Text(
              'Contact Info',
              style: GoogleFonts.roboto(
                fontSize: 15,
                color: const Color.fromARGB(255, 16, 15, 15),
              ),
            ),
            const SizedBox(height: 10),
            // Address TextField
            Text_Field(
              label: 'Address',
              hint: 'No, Street, City',
              isPassword: false,
              keyboard: TextInputType.text,
              txtEditController: _addressController,
              focusNode: FocusNode(),
            ),
            const SizedBox(height: 15),
            // Mobile Number TextField
            Text_Field(
              label: 'Mobile Number',
              hint: '07XXXXXXXX',
              isPassword: false,
              keyboard: TextInputType.text,
              txtEditController: _mobileController,
              focusNode: FocusNode(),
            ),
            const SizedBox(height: 30),
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: update,
                style: ButtonStyle(
                  elevation: MaterialStateProperty.all(2),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      return isLoading
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5)
                          : Theme.of(context).colorScheme.primary;
                    },
                  ),
                ),
                child: !isLoading
                    ? Text(
                        'Save',
                        style: GoogleFonts.roboto(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
