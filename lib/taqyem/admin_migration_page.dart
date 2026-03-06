// admin_migration_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMigrationPage extends StatefulWidget {
  @override
  _AdminMigrationPageState createState() => _AdminMigrationPageState();
}

class _AdminMigrationPageState extends State<AdminMigrationPage> {
  bool _isMigrating = false;
  String _migrationLog = '';
  int _totalUsers = 0;
  int _usersWithLimit = 0;
  int _usersWithoutLimit = 0;

  @override
  void initState() {
    super.initState();
    _checkUsersStatus();
  }

  Future<void> _checkUsersStatus() async {
    try {
      QuerySnapshot usersSnapshot = 
          await FirebaseFirestore.instance.collection('users').get();
      
      int withLimit = 0;
      int withoutLimit = 0;

      for (var doc in usersSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('classLimit')) {
          withLimit++;
        } else {
          withoutLimit++;
        }
      }

      setState(() {
        _totalUsers = usersSnapshot.docs.length;
        _usersWithLimit = withLimit;
        _usersWithoutLimit = withoutLimit;
      });

    } catch (e) {
      print('Erreur: $e');
    }
  }

  Future<void> _runMigration() async {
    setState(() {
      _isMigrating = true;
      _migrationLog = '';
    });

    try {
      // Créer un StringBuffer pour collecter les logs
      StringBuffer logBuffer = StringBuffer();
      
      // Fonction pour ajouter des logs
      void addToLog(String message) {
        logBuffer.writeln(message);
        setState(() {
          _migrationLog = logBuffer.toString();
        });
      }

      addToLog('🚀 Début de la migration des utilisateurs...');
      
      final firestore = FirebaseFirestore.instance;
      
      // Récupérer tous les utilisateurs
      QuerySnapshot usersSnapshot = await firestore.collection('users').get();
      
      int totalUsers = usersSnapshot.docs.length;
      int updatedUsers = 0;
      int skippedUsers = 0;

      addToLog('📊 Total utilisateurs trouvés: $totalUsers');

      for (var doc in usersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        
        if (!userData.containsKey('classLimit')) {
          // Ajouter le champ classLimit avec la valeur par défaut (4)
          await firestore.collection('users').doc(doc.id).update({
            'classLimit': 4,
            'classLimitUpdatedAt': FieldValue.serverTimestamp(),
            'classLimitSource': 'migration',
          });
          
          updatedUsers++;
          addToLog('✅ Utilisateur ${doc.id}: classLimit ajouté');
        } else {
          skippedUsers++;
          addToLog('⏭️ Utilisateur ${doc.id}: déjà configuré (${userData['classLimit']})');
        }
        
        // Petite pause pour éviter de surcharger Firestore
        await Future.delayed(Duration(milliseconds: 100));
      }

      addToLog('\n📊 Résumé de la migration:');
      addToLog('   Total utilisateurs: $totalUsers');
      addToLog('   Mis à jour: $updatedUsers');
      addToLog('   Ignorés: $skippedUsers');
      addToLog('✅ Migration terminée avec succès!');

      // Mettre à jour les statistiques
      await _checkUsersStatus();

    } catch (e) {
      setState(() {
        _migrationLog += '\n❌ Erreur: $e';
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة قاعدة البيانات - إضافة classLimit'),
        backgroundColor: Color.fromRGBO(7, 82, 96, 1),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte d'information
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 50,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 10),
                    Text(
                      '⚠️ عملية مرة واحدة فقط',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Cette migration va ajouter le champ "classLimit" '
                      'à tous les utilisateurs qui n\'en ont pas.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Valeur par défaut: 4 classes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 20),
                    Divider(),
                    SizedBox(height: 10),
                    // Statistiques
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'Total',
                          _totalUsers.toString(),
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Avec limite',
                          _usersWithLimit.toString(),
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Sans limite',
                          _usersWithoutLimit.toString(),
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Bouton de migration
            ElevatedButton(
              onPressed: _isMigrating || _usersWithoutLimit == 0 
                  ? null 
                  : _runMigration,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: _usersWithoutLimit > 0 
                    ? Colors.green 
                    : Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _isMigrating 
                    ? 'جاري الترحيل...' 
                    : _usersWithoutLimit == 0
                        ? '✅ جميع المستخدمين محدثين'
                        : '🚀 بدء الترحيل (${_usersWithoutLimit} مستخدم)',
                style: TextStyle(fontSize: 18),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Logs de la migration
            if (_migrationLog.isNotEmpty)
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 Journal de migration:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _migrationLog,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}