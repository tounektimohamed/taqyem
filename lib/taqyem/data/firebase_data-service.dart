import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'data_model.dart';

class FirebaseService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _error;

  List<EducationalData> _filteredData = [];
  List<EducationalData> _allData = [];
  
  List<EducationalData> get allData => _allData;
  List<EducationalData> get filteredData => _filteredData;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  FirebaseService() {
    loadData();
  }

  void updateFilteredData(List<EducationalData> data) {
    _filteredData = data;
    notifyListeners();
  }
  
  Future<void> loadData() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('⏳ Chargement des données depuis Firebase...');
      
      final querySnapshot = await _firestore
          .collection('educational_data')
          .orderBy('classe')
          .get();
      
      print('📊 ${querySnapshot.docs.length} documents trouvés');
      
      _allData = querySnapshot.docs.map((doc) {
        try {
          final data = EducationalData.fromJson(doc.data(), doc.id);
          print('📝 Document ${doc.id}: ${data.classe} - ${data.matiere} (master: ${data.isMaster})');
          return data;
        } catch (e) {
          print('⚠️ Erreur de conversion du document ${doc.id}: $e');
          print('📄 Données du document: ${doc.data()}');
          return null;
        }
      }).where((item) => item != null).cast<EducationalData>().toList();
      
      _allData.sort((a, b) => a.classe.compareTo(b.classe));
      _filteredData = List.from(_allData);
      
      print('✅ Données chargées: ${_allData.length} éléments');
      print('🏫 Classes principales: ${_allData.where((d) => d.isMaster).length}');
      
    } catch (e) {
      _error = 'Erreur de chargement: $e';
      _allData = [];
      _filteredData = [];
      print('❌ Erreur Firebase: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadData(List<EducationalData> dataList) async {
    if (dataList.isEmpty) {
      _error = 'Aucune donnée à importer';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    int totalImported = 0;
    int totalErrors = 0;
    const int batchSize = 400;

    try {
      print('⏳ Début de l\'importation de ${dataList.length} données...');
      
      for (int i = 0; i < dataList.length; i += batchSize) {
        final end = (i + batchSize < dataList.length) ? i + batchSize : dataList.length;
        final batchData = dataList.sublist(i, end);
        
        final batch = _firestore.batch();
        int batchSuccess = 0;
        
        for (var data in batchData) {
          try {
            final docRef = _firestore.collection('educational_data').doc();
            
            final dataMap = {
              'classe': data.classe,
              'matiere': data.matiere,
              'bareme': data.bareme,
              'solution': data.solutions,
              'probleme': data.problemes,
              'isMaster': data.isMaster, // Utilise directement la propriété isMaster
              'createdAt': FieldValue.serverTimestamp(),
              'imported': true,
              'batchNumber': (i/batchSize).floor() + 1,
            };
            
            batch.set(docRef, dataMap);
            batchSuccess++;
            
          } catch (e) {
            totalErrors++;
            print('⚠️ Erreur avec l\'élément ${data.classe}: $e');
          }
        }
        
        print('📤 Commit du batch ${(i/batchSize).floor() + 1} ($batchSuccess documents)...');
        await batch.commit();
        
        totalImported += batchSuccess;
        
        if (end < dataList.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      
      print('🔄 Rechargement des données...');
      await loadData();
      
      final message = '✅ $totalImported données importées avec succès';
      if (totalErrors > 0) {
        _error = '$message ($totalErrors erreurs)';
      } else {
        print(message);
      }
      
    } catch (e) {
      _error = 'Erreur d\'importation: $e';
      print('❌ Erreur lors de l\'importation: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Méthode pour corriger toutes les master classes
  Future<void> fixMasterClassesForAllYears(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('⏳ Correction des classes principales pour toutes les années...');
      
      final querySnapshot = await _firestore.collection('educational_data').get();
      final batch = _firestore.batch();
      int updatedCount = 0;
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final classe = data['classe']?.toString() ?? '';
        
        final isMaster = EducationalData.isMasterClassForAllYears(classe);
        final currentIsMaster = data['isMaster'] as bool? ?? false;
        
        if (isMaster != currentIsMaster) {
          batch.update(doc.reference, {
            'isMaster': isMaster,
            'fixedAt': FieldValue.serverTimestamp(),
          });
          updatedCount++;
          
          print('📝 Mise à jour: "$classe" -> isMaster: $isMaster (précédent: $currentIsMaster)');
        }
      }
      
      if (updatedCount > 0) {
        await batch.commit();
        print('✅ $updatedCount documents mis à jour');
        
        await loadData();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$updatedCount classes principales corrigées'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('ℹ️ Aucune mise à jour nécessaire');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Toutes les classes sont déjà correctement configurées'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
      
    } catch (e) {
      _error = 'Erreur lors de la correction: $e';
      print('❌ Erreur: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDataWithSubclasses(
    String masterId, 
    EducationalData masterData, 
    bool applyToSubclasses
  ) async {
    try {
      print('⏳ Mise à jour de la classe principale $masterId...');
      
      // 1. Mettre à jour la classe principale
      await _firestore.collection('educational_data').doc(masterId).update({
        ...masterData.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Classe principale mise à jour');
      
      // 2. Si demandé, propager aux sous-classes
      if (applyToSubclasses && masterData.isMaster) {
        await _updateSubclasses(masterData);
      }
      
      // 3. Recharger les données
      await loadData();
      
    } catch (e) {
      _error = 'Erreur de mise à jour: $e';
      print('❌ Erreur lors de la mise à jour: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _updateSubclasses(EducationalData masterData) async {
    try {
      print('⏳ Recherche des sous-classes...');
      
      final masterClasseBase = masterData.masterClasse;
      print('🏫 Classe de base pour recherche: "$masterClasseBase"');
      
      // Rechercher toutes les classes de la même année et matière
      final querySnapshot = await _firestore
          .collection('educational_data')
          .where('matiere', isEqualTo: masterData.matiere)
          .get();
      
      final batch = _firestore.batch();
      int updatedCount = 0;
      
      for (var doc in querySnapshot.docs) {
        final docData = doc.data();
        final classe = docData['classe'] as String? ?? '';
        
        // Vérifier si c'est une sous-classe de la classe principale
        if (classe != masterData.classe && _isSubclassOf(classe, masterClasseBase)) {
          print('📝 Mise à jour de la sous-classe: "$classe"');
          
          batch.update(doc.reference, {
            'solution': masterData.solutions,
            'probleme': masterData.problemes,
            'updatedFromMaster': true,
            'masterId': masterData.id,
            'lastUpdate': FieldValue.serverTimestamp(),
          });
          updatedCount++;
        }
      }
      
      if (updatedCount > 0) {
        await batch.commit();
        print('✅ $updatedCount sous-classes mises à jour');
      } else {
        print('ℹ️ Aucune sous-classe trouvée pour mise à jour');
      }
      
    } catch (e) {
      print('❌ Erreur lors de la mise à jour des sous-classes: $e');
    }
  }

  bool _isSubclassOf(String classe, String masterClasseBase) {
    // Vérifier si la classe commence par la base de la classe principale
    // et se termine par une lettre arabe ou un point + lettre
    if (!classe.startsWith(masterClasseBase)) {
      return false;
    }
    
    final suffix = classe.substring(masterClasseBase.length).trim();
    
    if (suffix.isEmpty) {
      return false; // C'est la classe principale elle-même
    }
    
    // Vérifier les formats de sous-classes courants
    final arabicLetters = ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز', 'ح', 'ط', 'ي'];
    final suffixPatterns = [
      ...arabicLetters.map((letter) => ' $letter'),
      ...arabicLetters.map((letter) => '  $letter'),
      ...arabicLetters.map((letter) => '. $letter'),
      ...arabicLetters.map((letter) => '. $letter'),
      ' أ', ' ب', ' ج', ' د', ' هـ', ' و', ' ز',
    ];
    
    for (final pattern in suffixPatterns) {
      if (suffix == pattern.trim() || suffix == pattern) {
        return true;
      }
    }
    
    return false;
  }

  Future<void> addData(EducationalData data) async {
    try {
      print('⏳ Ajout de données: ${data.classe} - ${data.matiere}');
      
      await _firestore.collection('educational_data').add({
        ...data.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Données ajoutées avec succès');
      await loadData();
      
    } catch (e) {
      _error = 'Erreur d\'ajout: $e';
      print('❌ Erreur lors de l\'ajout: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateData(String id, EducationalData data) async {
    try {
      print('⏳ Mise à jour du document $id...');
      
      await _firestore.collection('educational_data').doc(id).update({
        ...data.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Document $id mis à jour');
      await loadData();
      
    } catch (e) {
      _error = 'Erreur de mise à jour: $e';
      print('❌ Erreur lors de la mise à jour: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteData(String id) async {
    try {
      print('⏳ Suppression du document $id...');
      
      await _firestore.collection('educational_data').doc(id).delete();
      
      print('✅ Document $id supprimé');
      await loadData();
      
    } catch (e) {
      _error = 'Erreur de suppression: $e';
      print('❌ Erreur lors de la suppression: $e');
      notifyListeners();
      rethrow;
    }
  }

  void filterData(String query) {
    if (query.isEmpty) {
      _filteredData = List.from(_allData);
    } else {
      _filteredData = _allData.where((item) {
        return item.classe.toLowerCase().contains(query.toLowerCase()) ||
               item.matiere.toLowerCase().contains(query.toLowerCase()) ||
               item.bareme.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  Future<bool> checkConnection() async {
    try {
      await _firestore.collection('educational_data').limit(1).get();
      return true;
    } catch (e) {
      _error = 'Connexion Firebase échouée: $e';
      notifyListeners();
      return false;
    }
  }

  Future<int?> countDocuments() async {
    try {
      final snapshot = await _firestore.collection('educational_data').count().get();
      return snapshot.count;
    } catch (e) {
      return 0;
    }
  }

  Future<void> clearAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore.collection('educational_data').get();
      
      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      await loadData();
      
      print('🗑️ Toutes les données ont été supprimées');
    } catch (e) {
      _error = 'Erreur de suppression: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}