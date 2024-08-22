import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubdivisionPlanPage extends StatefulWidget {
  final String shapeType;
  final double area;

  SubdivisionPlanPage({required this.shapeType, required this.area});

  @override
  _SubdivisionPlanPageState createState() => _SubdivisionPlanPageState();
}

class _SubdivisionPlanPageState extends State<SubdivisionPlanPage> {
  final _formKey = GlobalKey<FormState>();
  final _subdivisionRequesterNameController = TextEditingController();
  final _municipalityController = TextEditingController();
  String? _selectedRegion;
  String? _selectedMunicipality;

  final List<String> _regions = [
    'Délégation de Dhehiba', 'Délégation de Smar', 'Délégation de Bir Lahmar', 
    'Délégation de Tataouine Sud', 'Délégation de Tataouine Nord', 'Délégation de Remada', 
    'Délégation de Ghomrassen', 'ben mhira'
  ];

  final List<String> _municipalities = [
    'Dhehiba', 'Smar', 'Bir Lahjar', 'Tataouine Sud', 'Tataouine Nord', 
    'Remada', 'Ghomrassen', 'ben mhira'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subdivision Plan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Text('Type de Forme : ${widget.shapeType}', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              TextFormField(
                controller: _subdivisionRequesterNameController,
                decoration: InputDecoration(labelText: 'Nom du demandeur de subdivision'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                decoration: InputDecoration(labelText: 'Région'),
                items: _regions.map((region) {
                  return DropdownMenuItem(
                    value: region,
                    child: Text(region),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRegion = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner une région';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMunicipality,
                decoration: InputDecoration(labelText: 'Municipalité'),
                items: _municipalities.map((municipality) {
                  return DropdownMenuItem(
                    value: municipality,
                    child: Text(municipality),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMunicipality = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner une municipalité';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _saveShapeData();
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveShapeData() async {
    final shapeData = {
      'shapeType': widget.shapeType,
      'area': widget.area,
      'requesterName': _subdivisionRequesterNameController.text,
      'region': _selectedRegion,
      'municipality': _selectedMunicipality,
    };

    // Save shapeData to Firestore
    await FirebaseFirestore.instance.collection('shapes').add(shapeData);

    Navigator.pop(context);
  }
}
