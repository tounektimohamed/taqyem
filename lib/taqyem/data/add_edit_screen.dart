import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_model.dart';
import 'firebase_data-service.dart';

class AddEditScreen extends StatefulWidget {
  final EducationalData? data;
  final Function(Map<String, dynamic>) onSave;

  const AddEditScreen({
    super.key,
    this.data,
    required this.onSave,
  });

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _classeController;
  late TextEditingController _matiereController;
  late TextEditingController _baremeController;
  
  List<TextEditingController> _problemeControllers = [];
  List<TextEditingController> _solutionControllers = [];
  
  bool _applyToAllSubclasses = false;
  bool _isMasterClass = false;

  @override
  void initState() {
    super.initState();
    _classeController = TextEditingController(text: widget.data?.classe ?? '');
    _matiereController = TextEditingController(text: widget.data?.matiere ?? '');
    _baremeController = TextEditingController(text: widget.data?.bareme ?? '');
    
    _isMasterClass = widget.data?.isMaster ?? 
        EducationalData.isMasterClass(_classeController.text.trim());
    _applyToAllSubclasses = _isMasterClass && widget.data != null;
    
    if (widget.data?.problemes != null && widget.data!.problemes.isNotEmpty) {
      _problemeControllers = widget.data!.problemes
          .map((probleme) => TextEditingController(text: probleme))
          .toList();
    } else {
      _problemeControllers = [TextEditingController()];
    }
    
    if (widget.data?.solutions != null && widget.data!.solutions.isNotEmpty) {
      _solutionControllers = widget.data!.solutions
          .map((solution) => TextEditingController(text: solution))
          .toList();
    } else {
      _solutionControllers = [TextEditingController()];
    }

    _classeController.addListener(_checkIfMasterClass);
  }

  @override
  void dispose() {
    _classeController.dispose();
    _matiereController.dispose();
    _baremeController.dispose();
    
    for (var controller in _problemeControllers) {
      controller.dispose();
    }
    for (var controller in _solutionControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  void _checkIfMasterClass() {
    final isMaster = EducationalData.isMasterClass(_classeController.text.trim());
    if (_isMasterClass != isMaster) {
      setState(() {
        _isMasterClass = isMaster;
        _applyToAllSubclasses = isMaster && widget.data != null;
      });
    }
  }

  void _addProblemeField() {
    setState(() {
      _problemeControllers.add(TextEditingController());
    });
  }

  void _removeProblemeField(int index) {
    if (_problemeControllers.length > 1) {
      setState(() {
        _problemeControllers[index].dispose();
        _problemeControllers.removeAt(index);
      });
    }
  }

  void _addSolutionField() {
    setState(() {
      _solutionControllers.add(TextEditingController());
    });
  }

  void _removeSolutionField(int index) {
    if (_solutionControllers.length > 1) {
      setState(() {
        _solutionControllers[index].dispose();
        _solutionControllers.removeAt(index);
      });
    }
  }

  Widget _buildListField({
    required String title,
    required List<TextEditingController> controllers,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    String hintText = 'Saisissez ici...',
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$title (${controllers.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: iconColor ?? Colors.green),
                  onPressed: onAdd,
                  tooltip: 'Ajouter un élément',
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(controllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}.',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: controllers[index],
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: hintText,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          suffixIcon: controllers.length > 1
                              ? IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => onRemove(index),
                                  tooltip: 'Supprimer',
                                )
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ce champ est requis';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubclassOption() {
    if (!_isMasterClass || widget.data == null) return const SizedBox();

    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Classe Principale Détectée',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Cette classe sera appliquée à toutes les sections:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                for (var letter in ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز'])
                  Chip(
                    label: Text(
                      '${_classeController.text.trim()} $letter',
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'NotoKufiArabic', // Police pour l'arabe
                      ),
                    ),
                    backgroundColor: Colors.orange[100],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              title: const Text(
                'Appliquer aux sous-classes',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Les modifications seront automatiquement appliquées à toutes les sections (أ, ب, ج, د...)',
                style: TextStyle(fontSize: 12),
              ),
              value: _applyToAllSubclasses,
              onChanged: widget.data != null
                  ? (value) {
                      setState(() {
                        _applyToAllSubclasses = value;
                      });
                    }
                  : null,
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 4),
            if (_applyToAllSubclasses)
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Les modifications seront propagées à toutes les sous-classes.',
                        style: TextStyle(fontSize: 11, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextFormField(
              controller: _classeController,
              decoration: InputDecoration(
                labelText: 'Classe *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.school),
                suffixIcon: _isMasterClass
                    ? const Tooltip(
                        message: 'Classe principale détectée',
                        child: Icon(Icons.star, color: Colors.orange),
                      )
                    : null,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer la classe';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _matiereController,
              decoration: const InputDecoration(
                labelText: 'Matière *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.menu_book),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer la matière';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _baremeController,
              decoration: const InputDecoration(
                labelText: 'Barème *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.grade),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le barème';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final problemes = _problemeControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      
      final solutions = _solutionControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      
      if (problemes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez ajouter au moins un problème'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (solutions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez ajouter au moins une solution'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = EducationalData(
        id: widget.data?.id,
        classe: _classeController.text.trim(),
        matiere: _matiereController.text.trim(),
        bareme: _baremeController.text.trim(),
        solutions: solutions,
        problemes: problemes,
        isMaster: _isMasterClass,
      );
      
      final saveData = {
        'data': data,
        'applyToSubclasses': _applyToAllSubclasses && widget.data != null,
      };
      
      widget.onSave(saveData);
    }
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _save,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        child: Text(
          widget.data == null ? 'Ajouter' : 'Mettre à jour',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHelpInfo() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ℹ️ Guide d\'utilisation:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              icon: Icons.add_circle,
              color: Colors.green,
              text: 'Utilisez le bouton + pour ajouter plusieurs problèmes/solutions',
            ),
            _buildInfoItem(
              icon: Icons.remove_circle,
              color: Colors.red,
              text: 'Le bouton - supprime un élément (au moins un reste)',
            ),
            _buildInfoItem(
              icon: Icons.star,
              color: Colors.orange,
              text: 'Les classes sans lettre (ex: "السنة الأولى ابتدائي") sont principales',
            ),
            if (_isMasterClass && widget.data != null)
              _buildInfoItem(
                icon: Icons.sync,
                color: Colors.purple,
                text: 'Activez "Appliquer aux sous-classes" pour propager les modifications',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.data == null ? 'Ajouter Données' : 'Modifier Données'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubclassOption(),
              
              const SizedBox(height: 16),
              
              _buildBasicInfoCard(),
              
              const SizedBox(height: 16),
              
              _buildListField(
                title: 'Problèmes',
                controllers: _problemeControllers,
                onAdd: _addProblemeField,
                onRemove: _removeProblemeField,
                hintText: 'Décrivez un problème rencontré...',
                iconColor: Colors.orange,
              ),
              
              const SizedBox(height: 16),
              
              _buildListField(
                title: 'Solutions',
                controllers: _solutionControllers,
                onAdd: _addSolutionField,
                onRemove: _removeSolutionField,
                hintText: 'Proposez une solution ou une activité...',
                iconColor: Colors.green,
              ),
              
              const SizedBox(height: 24),
              
              _buildActionButtons(),
              
              const SizedBox(height: 16),
              
              _buildHelpInfo(),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}