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
  final _urbanPlanningModelController = TextEditingController();
  final _areaController = TextEditingController();
  final _urbanTypeController = TextEditingController();
  final _lotTypeController = TextEditingController();
  final _lotNumberController = TextEditingController();

  final List<String> _regions = [
    'Délégation de Dhehiba (معتمدية الذهيبة)',
    'Délégation de Smar (معتمدية الصمار)',
    'Délégation de Bir Lahmar (معتمدية بئر الأحمر)',
    'Délégation de Tataouine Sud (معتمدية تطاوين الجنوبية)',
    'Délégation de Tataouine Nord (معتمدية تطاوين الشمالية)',
    'Délégation de Remada (معتمدية رمادة)',
    'Délégation de Ghomrassen (معتمدية غمراسن)',
    'ben mhira',
  ];

  final List<String> _municipalities = [
    'Dhehiba (معتمدية الذهيبة)',
    'Smar (معتمدية الصمار)',
    'Bir Lahjar (معتمدية بئر الأحمر)',
    'Tataouine Sud (معتمدية تطاوين الجنوبية)',
    'Tataouine Nord (معتمدية تطاوين الشمالية)',
    'Remada (معتمدية رمادة)',
    'Ghomrassen (معتمدية غمراسن)',
    'ben mhira',
  ];

  @override
  void initState() {
    super.initState();
    _areaController.text = widget.area.toString();
  }

  @override
  void dispose() {
    _subdivisionRequesterNameController.dispose();
    _municipalityController.dispose();
    _urbanPlanningModelController.dispose();
    _areaController.dispose();
    _urbanTypeController.dispose();
    _lotTypeController.dispose();
    _lotNumberController.dispose();
    super.dispose();
  }

  void _saveToFirestore() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final area = double.tryParse(_areaController.text) ?? 0;

        if (area <= 0) {
          throw Exception('La superficie doit être un nombre valide et supérieur à 0.');
        }

        final data = {
          'subdivisionRequesterName': _subdivisionRequesterNameController.text,
          'municipality': _municipalityController.text,
          'region': _selectedRegion,
          'urbanPlanningModel': _urbanPlanningModelController.text,
          'area': area,
          'urbanType': _urbanTypeController.text,
          'lotType': _lotTypeController.text,
          'lotNumber': int.tryParse(_lotNumberController.text) ?? 0,
          'shapeType': widget.shapeType,
          'coordinates': [], // Assurez-vous que ce champ est correctement rempli
        };

        await FirebaseFirestore.instance.collection('subdivision_plans').add(data);

        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement des données: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suivi de plan de lotissement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Container(
                  width: double.infinity,
                  child: DropdownButtonFormField<String>(
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
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  child: DropdownButtonFormField<String>(
                    value: _municipalityController.text.isNotEmpty ? _municipalityController.text : null,
                    decoration: InputDecoration(labelText: 'Municipalité'),
                    items: _municipalities.map((municipality) {
                      return DropdownMenuItem(
                        value: municipality,
                        child: Text(municipality),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _municipalityController.text = value ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner une municipalité';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _urbanPlanningModelController,
                  decoration: InputDecoration(labelText: 'Modèle d\'aménagement urbain'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un modèle d\'aménagement urbain';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _areaController,
                  decoration: InputDecoration(labelText: 'Superficie (m²)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une superficie';
                    }
                    final number = double.tryParse(value);
                    if (number == null || number <= 0) {
                      return 'Veuillez entrer une superficie valide';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _urbanTypeController,
                  decoration: InputDecoration(labelText: 'Type urbain'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un type urbain';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _lotTypeController,
                  decoration: InputDecoration(labelText: 'Type de lotissement'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un type de lotissement';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _lotNumberController,
                  decoration: InputDecoration(labelText: 'Nombre de lots'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nombre de lots';
                    }
                    final number = int.tryParse(value);
                    if (number == null || number <= 0) {
                      return 'Veuillez entrer un nombre de lots valide';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Annuler'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveToFirestore,
                      child: Text('Enregistrer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
