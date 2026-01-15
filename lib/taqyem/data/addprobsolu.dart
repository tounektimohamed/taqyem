// addprobsolu.dart
import 'dart:convert';
import 'package:Taqyem/taqyem/data/add_edit_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'add_edit_screen.dart';
import 'data_card.dart';
import 'data_model.dart';
import 'search_bar.dart';
import 'firebase_data-service.dart';

class AddProbScreen extends StatelessWidget {
  const AddProbScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Veuillez vous connecter'),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Erreur: ${snapshot.error}'),
            ),
          );
        }

        final isAgent = snapshot.data?.get('isAgent') ?? false;
        
        return Scaffold(
          body: _AddProbContent(isAgent: isAgent),
        );
      },
    );
  }
}

class _AddProbContent extends StatefulWidget {
  final bool isAgent;
  
  const _AddProbContent({required this.isAgent});

  @override
  State<_AddProbContent> createState() => __AddProbContentState();
}

class __AddProbContentState extends State<_AddProbContent> {
  final TextEditingController _searchController = TextEditingController();
  bool _isImportingJson = false;
  String _jsonImportStatus = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = context.read<FirebaseService>();
      if (!service.isLoading) {
        service.loadData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<FirebaseService>().filterData(_searchController.text);
  }

  Future<void> _importFromJson() async {
    if (!widget.isAgent) return;
    
    setState(() {
      _isImportingJson = true;
      _jsonImportStatus = 'Chargement du fichier JSON...';
    });

    try {
      final jsonString = await rootBundle.loadString('assets/data.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      final List<EducationalData> dataList = jsonList.map((json) {
        final solutions = json['solution'] is String
            ? [json['solution'] as String]
            : (json['solution'] as List?)?.cast<String>() ?? [];
        
        final problemes = json['probleme'] is String
            ? [json['probleme'] as String]
            : (json['probleme'] as List?)?.cast<String>() ?? [];

        final classe = json['classe']?.toString() ?? '';
        
        return EducationalData(
          classe: classe,
          matiere: json['matiere']?.toString() ?? '',
          bareme: json['bareme']?.toString() ?? '',
          solutions: solutions,
          problemes: problemes,
          isMaster: EducationalData.isMasterClassForAllYears(classe),
        );
      }).toList();
      
      setState(() {
        _jsonImportStatus = '${dataList.length} données chargées. Importation vers Firebase...';
      });

      final service = context.read<FirebaseService>();
      await service.uploadData(dataList);
      
      setState(() {
        _jsonImportStatus = '✅ ${dataList.length} données importées avec succès!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${dataList.length} données importées'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      setState(() {
        _jsonImportStatus = '❌ Erreur: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'importation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isImportingJson = false;
      });
      
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _jsonImportStatus = '';
          });
        }
      });
    }
  }

  Future<void> _fixMasterClasses() async {
    if (!widget.isAgent) return;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Corriger les classes principales'),
        content: const Text(
          'Cette opération va analyser toutes les classes et marquer correctement '
          'les classes principales (années 1 à 6) comme "master".\n\n'
          'Voulez-vous continuer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Corriger', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (result == true) {
      final service = context.read<FirebaseService>();
      await service.fixMasterClassesForAllYears(context);
    }
  }

  void _navigateToAddScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditScreen(
          onSave: (saveData) {
            final educationalData = saveData['data'] as EducationalData;
            context.read<FirebaseService>().addData(educationalData);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _navigateToEditScreen(EducationalData data) {
    final service = context.read<FirebaseService>();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditWrapper(
          data: data,
          firebaseService: service,
          onSave: (saveData) {
            final educationalData = saveData['data'] as EducationalData;
            final applyToSubclasses = saveData['applyToSubclasses'] as bool;
            
            if (applyToSubclasses && data.isMaster) {
              service.updateDataWithSubclasses(data.id!, educationalData, applyToSubclasses);
            } else {
              service.updateData(data.id!, educationalData);
            }
            
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(EducationalData data) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Voulez-vous vraiment supprimer les données pour ${data.classe} - ${data.matiere}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      context.read<FirebaseService>().deleteData(data.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseService>(
      builder: (context, service, child) {
        // Filtrer uniquement les master classes
        final masterClassesOnly = service.allData
            .where((data) => data.isMaster)
            .toList();
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Système Éducatif - Classes Principales'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (widget.isAgent) // Seulement pour les agents
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'fix_master') {
                      _fixMasterClasses();
                    } else if (value == 'import') {
                      _importFromJson();
                    } else if (value == 'refresh') {
                      service.loadData();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'fix_master',
                      child: Row(
                        children: [
                          Icon(Icons.auto_fix_high, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Corriger classes principales'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'import',
                      child: Row(
                        children: [
                          Icon(Icons.cloud_upload, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Importer depuis JSON'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Rafraîchir'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              // Indicateur de statut utilisateur
              Container(
                padding: const EdgeInsets.all(8.0),
                color: widget.isAgent ? Colors.green[50] : Colors.blue[50],
                child: Row(
                  children: [
                    Icon(
                      widget.isAgent ? Icons.admin_panel_settings : Icons.person,
                      color: widget.isAgent ? Colors.green : Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isAgent 
                            ? 'Mode Agent - Toutes les fonctionnalités disponibles'
                            : 'Mode Utilisateur - Fonctions CRUD uniquement',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isAgent ? Colors.green[800] : Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Indicateur que seules les master classes sont affichées
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.orange[50],
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Affichage: Classes principales uniquement',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        '${masterClassesOnly.length} classes',
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.orange[100],
                    ),
                  ],
                ),
              ),
              
              if (_jsonImportStatus.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: _jsonImportStatus.contains('✅')
                      ? Colors.green[50]
                      : _jsonImportStatus.contains('❌')
                          ? Colors.red[50]
                          : Colors.blue[50],
                  child: Row(
                    children: [
                      if (_jsonImportStatus.contains('✅'))
                        const Icon(Icons.check_circle, color: Colors.green, size: 16)
                      else if (_jsonImportStatus.contains('❌'))
                        const Icon(Icons.error, color: Colors.red, size: 16)
                      else
                        const Icon(Icons.info, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _jsonImportStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: _jsonImportStatus.contains('✅')
                                ? Colors.green[800]
                                : _jsonImportStatus.contains('❌')
                                    ? Colors.red[800]
                                    : Colors.blue[800],
                          ),
                        ),
                      ),
                      if (_jsonImportStatus.isNotEmpty && !_isImportingJson)
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            setState(() {
                              _jsonImportStatus = '';
                            });
                          },
                        ),
                    ],
                  ),
                ),
              
              // Statistiques
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${masterClassesOnly.length} classes principales affichées (sur ${service.allData.length} total)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SearchBarWidget(controller: _searchController),
              
              Expanded(
                child: _buildContent(service, masterClassesOnly),
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bouton Import JSON - seulement pour les agents
              if (widget.isAgent && _jsonImportStatus.isEmpty)
                FloatingActionButton.small(
                  heroTag: 'import_json',
                  onPressed: _importFromJson,
                  tooltip: 'Importer depuis JSON',
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.cloud_upload, color: Colors.white),
                ),
              if (widget.isAgent && _jsonImportStatus.isEmpty)
                const SizedBox(height: 10),
              // Bouton Ajouter - pour tous les utilisateurs
              FloatingActionButton(
                heroTag: 'add_data',
                onPressed: _navigateToAddScreen,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(FirebaseService service, List<EducationalData> masterClasses) {
    if (service.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (service.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Erreur: ${service.error}',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => service.loadData(),
              child: const Text('Réessayer'),
            ),
            const SizedBox(height: 10),
            if (widget.isAgent) // Seulement pour les agents
              ElevatedButton(
                onPressed: _importFromJson,
                child: const Text('Importer depuis JSON'),
              ),
          ],
        ),
      );
    }

    // Trier les master classes
    masterClasses.sort((a, b) => a.classe.compareTo(b.classe));

    return masterClasses.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Aucune classe principale disponible',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ajoutez une classe principale (ex: "السنة الأولى ابتدائي")',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une classe principale'),
                  onPressed: _navigateToAddScreen,
                ),
                const SizedBox(height: 10),
                if (widget.isAgent) // Seulement pour les agents
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Importer depuis JSON'),
                    onPressed: _importFromJson,
                  ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: masterClasses.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              final data = masterClasses[index];
              return DataCard(
                data: data,
                onEdit: () => _navigateToEditScreen(data),
                onDelete: () => _confirmDelete(data),
              );
            },
          );
  }
}