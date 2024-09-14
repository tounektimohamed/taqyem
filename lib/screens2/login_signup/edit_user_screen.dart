import 'package:DREHATT_app/components/text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum Genders { homme, femme }

class EditUserScreen extends StatefulWidget {
  final DocumentSnapshot user;

  EditUserScreen({required this.user});

  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _nicController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  bool isLoading = false;

  Genders _genderSelected = Genders.homme; // Sélection par défaut du genre
  bool _isAgent = false; // Statut du rôle d'agent

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user['name'];
    _dobController.text = widget.user['dob'] ?? '';
    _genderController.text = widget.user['gender'] ?? '';
    _nicController.text = widget.user['nic'] ?? '';
    _addressController.text = widget.user['address'] ?? '';
    _mobileController.text = widget.user['mobile'] ?? '';
    _isAgent = widget.user['isAgent'] ?? false;

    if (widget.user['gender'] != null) {
      _genderSelected = _genderFromString(widget.user['gender']);
    }
  }

  Genders _genderFromString(String genderString) {
    switch (genderString.toLowerCase()) {
      case 'homme':
        return Genders.homme;
      case 'femme':
        return Genders.femme;
     
      default:
        return Genders.homme; // Par défaut, si le genre n'est pas reconnu
    }
  }
  
  
  Future<void> update() async {
  setState(() {
    isLoading = true;
  });

  try {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.user.id)
        .update({
      'name': _nameController.text,
      'dob': _dobController.text,
      'gender': _genderSelected == Genders.homme ? 'Homme' : 'Femme',
      'nic': _nicController.text,
      'address': _addressController.text,
      'mobile': _mobileController.text,
      'isAgent': _isAgent,
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('User updated successfully')));
  } catch (e) {
    print('Error updating user: $e');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Failed to update user')));
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 5,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(35, 0, 35, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.surface,
              child: Icon(Icons.person_outline),
            ),
            SizedBox(height: 20),
            Text(
              'Informations de base',
              style: TextStyle(
                  fontSize: 15, color: Color.fromARGB(255, 16, 15, 15)),
            ),
            SizedBox(height: 10),
            Text_Field(
              label: 'Nom',
              hint: 'Prénom Nom',
              isPassword: false,
              keyboard: TextInputType.text,
              txtEditController: _nameController,
              focusNode: FocusNode(),
            ),
            SizedBox(height: 15),
            TextField(
              onTap: () async {
                var datePicked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2099),
                );
                if (datePicked != null) {
                  setState(() {
                    _dobController.text =
                        '${datePicked.day}-${datePicked.month}-${datePicked.year}';
                  });
                }
              },
              controller: _dobController,
              readOnly: true,
              style:
                  TextStyle(height: 2, color: Color.fromARGB(255, 16, 15, 15)),
              cursorColor: Color.fromARGB(255, 7, 82, 96),
              decoration: InputDecoration(
                hintText: 'JJ-MM-AAAA',
                labelText: 'Date de naissance',
                labelStyle: TextStyle(color: Color.fromARGB(255, 16, 15, 15)),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  borderSide: BorderSide(color: Color.fromARGB(255, 7, 82, 96)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              onTap: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Sélectionnez le genre',
                  ),
                  content: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          RadioListTile(
                            value: Genders.homme,
                            title: Text('Homme'),
                            groupValue: _genderSelected,
                            onChanged: (value) {
                              setState(() {
                                _genderSelected = value as Genders;
                                _genderController.text = 'Homme';
                                Navigator.of(context).pop();
                              });
                            },
                          ),
                          RadioListTile(
                            value: Genders.femme,
                            title: Text('Femme'),
                            groupValue: _genderSelected,
                            onChanged: (value) {
                              setState(() {
                                _genderSelected = value as Genders;
                                _genderController.text = 'Femme';
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
              style:
                  TextStyle(height: 2, color: Color.fromARGB(255, 16, 15, 15)),
              cursorColor: Color.fromARGB(255, 7, 82, 96),
              decoration: InputDecoration(
                labelText: 'Genre',
                labelStyle: TextStyle(color: Color.fromARGB(255, 16, 15, 15)),
                hintText: 'Genre',
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  borderSide: BorderSide(color: Color.fromARGB(255, 7, 82, 96)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
              ),
            ),
            SizedBox(height: 15),
            Text_Field(
              label: 'CIN',
              hint: '123456789V',
              isPassword: false,
              keyboard: TextInputType.text,
              txtEditController: _nicController,
              focusNode: FocusNode(),
            ),
            SizedBox(height: 15),
            Text_Field(
              label: 'Adresse',
              hint: 'No, Rue, Ville',
              isPassword: false,
              keyboard: TextInputType.text,
              txtEditController: _addressController,
              focusNode: FocusNode(),
            ),
            SizedBox(height: 15),
            Text_Field(
              label: 'Numéro de portable',
              hint: '07XXXXXXXX',
              isPassword: false,
              keyboard: TextInputType.text,
              txtEditController: _mobileController,
              focusNode: FocusNode(),
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Text('Rôle d\'agent :'),
                Switch(
                  value: _isAgent,
                  onChanged: (value) {
                    setState(() {
                      _isAgent = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 30),
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
              ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
              : Theme.of(context).colorScheme.primary;
        },
      ),
    ),
    child: !isLoading
        ? Text(
            'Save',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w600,
              color: Colors.white,  // Set text color to white
            ),
          )
        : CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
  ),
),

          ],
        ),
      ),
    );
  }
}
