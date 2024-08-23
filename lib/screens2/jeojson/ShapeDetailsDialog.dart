import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShapeDetailsPage extends StatefulWidget {
  final String shapeType;
  final double area;

  ShapeDetailsPage({required this.shapeType, required this.area});

  @override
  _ShapeDetailsPageState createState() => _ShapeDetailsPageState();
}

class _ShapeDetailsPageState extends State<ShapeDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _cinController = TextEditingController();
  final _ownershipProofController = TextEditingController();
  final _areaController = TextEditingController();
  String? _selectedRegion;
  String? _selectedMunicipality;
  final _urbanPlanningModelController = TextEditingController();
  final _requestDateController = TextEditingController();

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
    _nameController.dispose();
    _firstNameController.dispose();
    _cinController.dispose();
    _ownershipProofController.dispose();
    _areaController.dispose();
    _urbanPlanningModelController.dispose();
    _requestDateController.dispose();
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
          'name': _nameController.text,
          'firstName': _firstNameController.text,
          'cin': _cinController.text,
          'ownershipProof': _ownershipProofController.text,
          'area': area,
          'region': _selectedRegion,
          'municipality': _selectedMunicipality,
          'urbanPlanningModel': _urbanPlanningModelController.text,
          'requestDate': _requestDateController.text,
          'shapeType': widget.shapeType,
          'coordinates': [], // Assurez-vous que ce champ est correctement rempli
        };

        await FirebaseFirestore.instance.collection('shapes').add(data);

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
        title: Text('Permis de Bâtiment Enregistrement '),
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
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Nom'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(labelText: 'Prénom'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un prénom';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _cinController,
                  decoration: InputDecoration(labelText: 'Numéro de carte d\'identité'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le numéro de carte d\'identité';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _ownershipProofController,
                  decoration: InputDecoration(labelText: 'Type de preuve de propriété'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le type de preuve de propriété';
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
                // Wrap DropdownButtonFormField in a Container with a maxWidth
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
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _urbanPlanningModelController,
                  decoration: InputDecoration(labelText: 'plans d\'amenagement urbain'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le plan d\'aménagement urbain';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _requestDateController,
                  decoration: InputDecoration(labelText: 'Date de la demande'),
                  keyboardType: TextInputType.datetime,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer la date de la demande';
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
