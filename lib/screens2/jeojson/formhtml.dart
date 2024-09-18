import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddHtmlFormPage extends StatefulWidget {
  @override
  _AddHtmlFormPageState createState() => _AddHtmlFormPageState();
}

class _AddHtmlFormPageState extends State<AddHtmlFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _key = '';
  String _tileUrl = '';
  String _geojsonUrl = '';

  // Méthode pour soumettre les données à Flask
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final url = Uri.parse('https://geotiif.vercel.app/add_html'); // URL de l'API Flask
      final response = await http.post(
        url,
        body: {
          'key': _key,
          'tileUrl': _tileUrl,
          'geojsonUrl': _geojsonUrl,
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Page HTML ajoutée avec succès !')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout de la page HTML.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter une page HTML'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Key'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une clé';
                  }
                  return null;
                },
                onSaved: (value) {
                  _key = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Tile URL'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer l\'URL des tuiles';
                  }
                  return null;
                },
                onSaved: (value) {
                  _tileUrl = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'GeoJSON URL'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer l\'URL GeoJSON';
                  }
                  return null;
                },
                onSaved: (value) {
                  _geojsonUrl = value!;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
