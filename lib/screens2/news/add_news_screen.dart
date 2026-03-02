import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // Ajoutez cette dépendance dans pubspec.yaml

class AddNewsScreen extends StatefulWidget {
  const AddNewsScreen({Key? key}) : super(key: key);

  @override
  _AddNewsScreenState createState() => _AddNewsScreenState();
}

class _AddNewsScreenState extends State<AddNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _linkController = TextEditingController(); // Nouveau contrôleur pour le lien
  bool isLoading = false;
  bool _hasLink = false; // Pour afficher/masquer le champ lien

  Future<void> _submitNews() async {
    if (_formKey.currentState!.validate()) {
      String title = _titleController.text;
      String content = _contentController.text;
      String? link = _linkController.text.isNotEmpty ? _linkController.text : null;
      String author = FirebaseAuth.instance.currentUser!.email!;
      String name = FirebaseAuth.instance.currentUser!.displayName ?? '';

      setState(() {
        isLoading = true;
      });

      try {
        await FirebaseFirestore.instance.collection('news').add({
          'title': title,
          'content': content,
          'link': link, // Ajout du lien
          'hasLink': link != null, // Indicateur pour savoir si un lien existe
          'author': author,
          'timestamp': FieldValue.serverTimestamp(),
          'name': name,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color.fromARGB(255, 7, 83, 96),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
            content: Text(
              'News added successfully',
            ),
          ),
        );

        // Clear fields after successful submission
        _titleController.clear();
        _contentController.clear();
        _linkController.clear();
        setState(() {
          _hasLink = false;
        });
      } catch (e) {
        print('Error adding news: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
            content: Text(
              'Failed to add news',
            ),
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add News',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(35, 20, 35, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title TextField
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: GoogleFonts.roboto(
                    color: const Color.fromARGB(255, 16, 15, 15),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              // Content TextField
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Content',
                  labelStyle: GoogleFonts.roboto(
                    color: const Color.fromARGB(255, 16, 15, 15),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the content';
                  }
                  return null;
                },
                maxLines: 5,
              ),
              SizedBox(height: 20),
              
              // Option pour ajouter un lien
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Checkbox(
                      value: _hasLink,
                      onChanged: (value) {
                        setState(() {
                          _hasLink = value ?? false;
                          if (!_hasLink) {
                            _linkController.clear();
                          }
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    Text(
                      'Add a link',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Champ lien (affiché seulement si _hasLink est true)
              if (_hasLink) ...[
                SizedBox(height: 15),
                TextFormField(
                  controller: _linkController,
                  decoration: InputDecoration(
                    labelText: 'Link URL',
                    hintText: 'https://example.com',
                    labelStyle: GoogleFonts.roboto(
                      color: const Color.fromARGB(255, 16, 15, 15),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    prefixIcon: Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (_hasLink && (value == null || value.isEmpty)) {
                      return 'Please enter a link';
                    }
                    if (_hasLink && value!.isNotEmpty) {
                      // Validation basique d'URL
                      if (!value.startsWith('http://') && !value.startsWith('https://')) {
                        return 'Link must start with http:// or https://';
                      }
                    }
                    return null;
                  },
                ),
              ],
              
              SizedBox(height: 30),
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitNews,
                  style: ButtonStyle(
                    elevation: MaterialStateProperty.all(2),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        return Theme.of(context).colorScheme.primary;
                      },
                    ),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          'Submit',
                          style: GoogleFonts.roboto(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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