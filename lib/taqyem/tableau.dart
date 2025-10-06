import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:html' as html;
import 'dart:math';
import 'package:Taqyem/taqyem/payment/PaymentPage.dart';
import 'package:http/http.dart' as http;
import 'package:Taqyem/taqyem/da3m_tableau.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class DynamicTablePage extends StatefulWidget {
  final String selectedClass;
  final String selectedMatiere;

  DynamicTablePage({
    required this.selectedClass,
    required this.selectedMatiere,
  });

  @override
  _DynamicTablePageState createState() => _DynamicTablePageState();
}

class _DynamicTablePageState extends State<DynamicTablePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _profName = '';
  String _schoolName = '';
  bool _isDialogCompleted = false;
  String? selectedBaremeId;
  String? baremeName;
  String? sousBaremeName;
  String? selectedSousBaremeId;
  int _remainingPrints = 5;
  Map<String, int> sumCriteriaMaxPerBareme = {};
  int totalStudents = 0;
  Duration _remainingTime = Duration.zero;
  bool _isAccountActive = false;
  bool _isGeneratingReport = false;
  bool _isMounted = false;
  Timer? _accountStatusTimer;
  StreamSubscription? _userSubscription;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _loadUserData();
    fetchMarks();
    _startTimer();
    _setupUserListener();
  }

  @override
  void dispose() {
    _isMounted = false;
    _accountStatusTimer?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }

  // CORRECTION : Méthode sécurisée pour lire les champs Firestore
  dynamic _getFieldSafe(
      DocumentSnapshot doc, String field, dynamic defaultValue) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey(field)) {
        return defaultValue;
      }
      return data[field] ?? defaultValue;
    } catch (e) {
      print('Erreur lecture champ $field: $e');
      return defaultValue;
    }
  }

  void _setupUserListener() {
    if (currentUser == null) return;

    _userSubscription = FirebaseFirestore.instance
        .collection(
            'Users') // CORRECTION : Utiliser 'Users' comme dans votre code original
        .doc(currentUser!.uid)
        .snapshots()
        .listen((snapshot) {
      if (_isMounted && snapshot.exists) {
        setState(() {
          // CORRECTION : Utiliser la méthode sécurisée pour tous les champs
          _remainingPrints = _getFieldSafe(snapshot, 'remainingPrints', 5);
          _isAccountActive = _getFieldSafe(snapshot, 'isActive', false);
          _profName = _getFieldSafe(snapshot, 'profName', '');
          _schoolName = _getFieldSafe(snapshot, 'schoolName', '');

          // Mettre à jour le temps restant seulement si le champ existe
          final expirationDate =
              _getFieldSafe(snapshot, 'accountExpiration', null);
          if (expirationDate != null && expirationDate is Timestamp) {
            _remainingTime = expirationDate.toDate().difference(DateTime.now());
          }
        });
      }
    });
  }

  Future<void> _checkPrintCredit() async {
    if (currentUser == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists && _isMounted) {
        setState(() {
          _remainingPrints = _getFieldSafe(userDoc, 'remainingPrints', 5);
          _isAccountActive = _getFieldSafe(userDoc, 'isActive', false);
        });
      }
    } catch (e) {
      print('Erreur lors de la vérification du crédit: $e');
    }
  }

  void _startTimer() {
    _accountStatusTimer?.cancel();
    _accountStatusTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isMounted) {
        _checkAccountStatus();
      } else {
        timer.cancel();
      }
    });
    _checkAccountStatus();
  }

  Future<void> _checkAccountStatus() async {
    if (currentUser == null || !_isMounted) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.uid)
          .get();

      if (_isMounted && userDoc.exists) {
        // CORRECTION : Utiliser la méthode sécurisée
        final isActive = _getFieldSafe(userDoc, 'isActive', false);
        final expirationDate =
            _getFieldSafe(userDoc, 'accountExpiration', null);

        setState(() {
          _isAccountActive = isActive;
          if (expirationDate != null && expirationDate is Timestamp) {
            _remainingTime = expirationDate.toDate().difference(DateTime.now());
          }
        });
      }
    } catch (e) {
      print('Erreur lors de la vérification du statut du compte: $e');
    }
  }

  // CORRECTION DU SYSTÈME DE CRÉDIT - Version sécurisée
  Future<bool> _checkAndUpdatePrintCredit() async {
    if (currentUser == null) return false;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.uid)
          .get();

      if (!userDoc.exists) return false;

      final bool isActive = _getFieldSafe(userDoc, 'isActive', false);
      final int remainingPrints = _getFieldSafe(userDoc, 'remainingPrints', 5);

      print('Statut compte - Actif: $isActive, Credits: $remainingPrints');

      // Si le compte est actif, pas de déduction de crédit
      if (isActive) {
        print('Compte actif - Pas de déduction de crédit');
        return true;
      }

      // Si le compte n'est pas actif, vérifier qu'il reste des crédits
      if (remainingPrints > 0) {
        print('Crédits suffisants - Restant: $remainingPrints');
        return true;
      }

      // Plus de crédits et compte inactif
      print('Plus de crédits disponibles');
      return false;
    } catch (e) {
      print('Erreur lors de la vérification du crédit: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _getBaremesValues(
      List<QueryDocumentSnapshot> selectedBaremes) async {
    final List<Map<String, dynamic>> result = [];
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    for (final baremeDoc in selectedBaremes) {
      final baremeId = baremeDoc['baremeId'];

      final baremeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .doc(baremeId)
          .get();

      final isBaremeSelected = _getFieldSafe(baremeSnapshot, 'selected', false);

      final sousBaremesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .doc(baremeId)
          .collection('sousBaremes')
          .get();

      final selectedSousBaremes = sousBaremesSnapshot.docs
          .where((doc) => _getFieldSafe(doc, 'selected', false) == true)
          .toList();

      if (isBaremeSelected) {
        final baremeName =
            _getFieldSafe(baremeSnapshot, 'baremeName', 'غير معروف');
        result.add({
          'id': baremeId,
          'value': baremeName,
          'sousBaremes': [],
        });
      } else if (selectedSousBaremes.isNotEmpty) {
        for (final sousBareme in selectedSousBaremes) {
          final sousBaremeName =
              _getFieldSafe(sousBareme, 'sousBaremeName', 'غير معروف');
          result.add({
            'id': sousBareme.id,
            'value': sousBaremeName,
            'parentBaremeId': baremeId,
          });
        }
      }
    }
    return result;
  }

  void _navigateToClassificationPage(String baremeId,
      {String? sousBaremeId}) async {
    try {
      var classAndMatiereNames = await _getClassAndMatiereNames();

      var selectedBaremes = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .get();

      List<Map<String, dynamic>> baremesValues =
          await _getBaremesValues(selectedBaremes.docs);

      var selectedBareme = baremesValues.firstWhere(
        (bareme) => bareme['id'] == baremeId,
        orElse: () => {'id': baremeId, 'value': 'غير معروف'},
      );

      String baremeName = selectedBareme['value'] ?? 'غير معروف';

      String? sousBaremeName;
      if (sousBaremeId != null) {
        var selectedSousBareme = baremesValues.firstWhere(
          (bareme) =>
              bareme['id'] == sousBaremeId &&
              bareme['parentBaremeId'] == baremeId,
          orElse: () => {'id': sousBaremeId, 'value': 'غير معروف'},
        );

        sousBaremeName = selectedSousBareme['value'] ?? 'غير معروف';
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassificationPage(
            selectedClass: widget.selectedClass,
            selectedBaremeId: baremeId,
            selectedSousBaremeId: sousBaremeId,
            currentUser: currentUser!,
            profName: _profName,
            schoolName: _schoolName,
            className: classAndMatiereNames['className'] ?? 'غير معروف',
            matiereName: classAndMatiereNames['matiereName'] ?? 'غير معروف',
            baremeName: baremeName,
            sousBaremeName: sousBaremeName,
          ),
        ),
      );
    } catch (e) {
      print('Erreur lors de la navigation vers la page de classification : $e');
      _showErrorSnackbar('Erreur lors de la navigation');
    }
  }

  Future<void> _deductPrintCredit() async {
    if (currentUser == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.uid)
          .get();

      if (!userDoc.exists) return;

      final bool isActive = _getFieldSafe(userDoc, 'isActive', false);
      final int remainingPrints = _getFieldSafe(userDoc, 'remainingPrints', 5);

      // Ne déduire que si le compte est inactif et qu'il reste des crédits
      if (!isActive && remainingPrints > 0) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser!.uid)
            .update({'remainingPrints': FieldValue.increment(-1)});

        setState(() {
          _remainingPrints = remainingPrints - 1;
        });

        print('✅ Crédit déduit - Nouveau solde: ${remainingPrints - 1}');
      }
    } catch (e) {
      print('Erreur lors de la déduction du crédit: $e');
    }
  }

  Future<void> _generatePDF() async {
    if (!await _checkAndUpdatePrintCredit()) {
      _showCreditErrorDialog();
      return;
    }

    await _generateReport('pdf');
  }

  Future<void> _generateHTMLReport() async {
    if (!await _checkAndUpdatePrintCredit()) {
      _showCreditErrorDialog();
      return;
    }

    await _generateReport('html');
  }

  void _showCreditErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.credit_card_off, color: Colors.orange),
            SizedBox(width: 10),
            Text('Crédit Épuisé'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous n\'avez plus de crédits d\'impression disponibles.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Veuillez activer votre compte pour continuer à générer des rapports.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Crédits restants: $_remainingPrints/5',
                      style: TextStyle(fontSize: 14, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: Text('Activer le compte'),
          ),
        ],
      ),
    );
  }

// MODIFICATION de _generateReport pour déduire après succès
  Future<void> _generateReport(String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackbar('Utilisateur non connecté.');
      return;
    }

    setState(() {
      _isGeneratingReport = true;
    });

    bool success = false;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return _buildLoadingDialog();
        },
      );

      var data = {
        'profName': _profName,
        'matiereName': await _getMatiereName(),
        'className': await _getClassName(),
        'schoolName': _schoolName,
        'baremes': await _getBaremes(),
        'students': await _getStudents(),
        'sumCriteriaMaxPerBareme': sumCriteriaMaxPerBareme,
        'totalStudents': totalStudents,
        'selectedClass': widget.selectedClass,
        'selectedBaremeId': selectedBaremeId,
        'currentUser': currentUser?.uid,
        'baremeName': baremeName,
        'sousBaremeName': sousBaremeName,
        'selectedSousBaremeId': selectedSousBaremeId,
      };

      if (type == 'pdf') {
        success = await _sendDataToFlask(data);
      } else {
        success = await _sendHTMLDataToFlask(data);
      }

      // DÉDUCTION UNIQUEMENT SI RÉUSSITE
      if (success) {
        await _deductPrintCredit();
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la génération du rapport: $e');
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });
      Navigator.of(context).pop();
    }
  }

  Widget _buildLoadingDialog() {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                strokeWidth: 3,
              ),
              Icon(Icons.print, color: Colors.blue, size: 20),
            ],
          ),
          SizedBox(height: 20),
          Text(
            "Génération du rapport en cours...",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 10),
          Text(
            "Veuillez patienter...",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 10),
          if (!_isAccountActive)
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info, size: 16, color: Colors.orange),
                  SizedBox(width: 5),
                  Text(
                    'Crédit utilisé: ${_remainingPrints - 1}/5',
                    style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<bool> _sendDataToFlask(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('https://imprission.onrender.com/generate_pdf');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'tableau_resultats.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);

        _showSuccessSnackbar('PDF généré avec succès');
        return true; // SUCCÈS
      } else {
        _showErrorSnackbar('Erreur lors de la génération du PDF');
        return false; // ÉCHEC
      }
    } on TimeoutException {
      _showErrorSnackbar('Timeout - Le serveur a mis trop de temps à répondre');
      return false;
    } on SocketException {
      _showErrorSnackbar('Erreur de connexion - Vérifiez votre internet');
      return false;
    } catch (e) {
      _showErrorSnackbar('Erreur technique: ${e.toString()}');
      return false;
    }
  }

  Future<bool> _sendHTMLDataToFlask(Map<String, dynamic> data) async {
    try {
      final url =
          Uri.parse('https://imprission.onrender.com/generate-html-report');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final blob = html.Blob([response.bodyBytes], 'text/html');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        html.Url.revokeObjectUrl(url);

        _showSuccessSnackbar('Rapport généré avec succès');
        return true; // SUCCÈS
      } else {
        _showErrorSnackbar(
            'Erreur lors de la génération du rapport HTML: ${response.statusCode}');
        return false; // ÉCHEC
      }
    } on TimeoutException {
      _showErrorSnackbar(
          'Timeout - Le serveur a mis trop de temps à répondre. Veuillez réessayer.');
      return false;
    } on SocketException {
      _showErrorSnackbar(
          'Erreur de connexion - Vérifiez votre connexion internet');
      return false;
    } catch (e) {
      _showErrorSnackbar('Erreur technique: ${e.toString()}');
      return false;
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<String> _getMatiereName() async {
    try {
      var matiereDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .get();

      return _getFieldSafe(matiereDoc, 'name', 'غير معروف');
    } catch (e) {
      return 'غير معروف';
    }
  }

  Future<String> _getClassName() async {
    try {
      var classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .get();

      return _getFieldSafe(classDoc, 'name', 'غير معروف');
    } catch (e) {
      return 'غير معروف';
    }
  }

  Future<List<dynamic>> _getBaremes() async {
    try {
      final baremesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .get();

      final List<dynamic> baremes = [];
      for (final baremeDoc in baremesSnapshot.docs) {
        final baremeId = _getFieldSafe(baremeDoc, 'baremeId', '');
        final baremeName = _getFieldSafe(baremeDoc, 'baremeName', 'غير معروف');
        final isBaremeSelected = _getFieldSafe(baremeDoc, 'selected', false);

        if (isBaremeSelected) {
          baremes.add({
            'id': baremeId,
            'value': baremeName,
            'type': 'bareme',
          });
        }

        final sousBaremesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('selections')
            .doc(widget.selectedClass)
            .collection(widget.selectedMatiere)
            .doc(baremeId)
            .collection('sousBaremes')
            .get();

        for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
          final sousBaremeId = sousBaremeDoc.id;
          final sousBaremeName =
              _getFieldSafe(sousBaremeDoc, 'sousBaremeName', 'غير معروف');
          final isSousBaremeSelected =
              _getFieldSafe(sousBaremeDoc, 'selected', false);

          if (isSousBaremeSelected) {
            baremes.add({
              'id': sousBaremeId,
              'value': sousBaremeName,
              'type': 'sousBareme',
              'parentBaremeId': baremeId,
            });
          }
        }
      }

      return baremes;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> _getStudents() async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(widget.selectedClass)
          .collection('students')
          .get();

      final List<dynamic> students = [];
      for (final studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;
        final studentName = _getFieldSafe(studentDoc, 'name', 'Élève inconnu');

        final baremesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('user_classes')
            .doc(widget.selectedClass)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .get();

        final Map<String, String> baremes = {};
        for (final baremeDoc in baremesSnapshot.docs) {
          final baremeId = baremeDoc.id;
          final marks = _getFieldSafe(baremeDoc, 'Marks', '( - - - )');
          baremes[baremeId] = marks;

          final sousBaremesSnapshot =
              await baremeDoc.reference.collection('sous_baremes').get();

          for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
            final sousBaremeId = sousBaremeDoc.id;
            final sousMarks =
                _getFieldSafe(sousBaremeDoc, 'Marks', '( - - - )');
            baremes['$baremeId-$sousBaremeId'] = sousMarks;
          }
        }

        students.add({
          'id': studentId,
          'name': studentName,
          'baremes': baremes,
        });
      }

      return students;
    } catch (e) {
      return [];
    }
  }

  void _loadUserData() async {
    if (currentUser != null && _isMounted) {
      try {
        var userDoc = await FirebaseFirestore.instance
            .collection(
                'Users') // CORRECTION : Utiliser 'Users' comme dans votre code original
            .doc(currentUser!.uid)
            .get();

        if (_isMounted && userDoc.exists) {
          setState(() {
            // CORRECTION : Utiliser la méthode sécurisée pour tous les champs
            _profName = _getFieldSafe(userDoc, 'profName', '');
            _schoolName = _getFieldSafe(userDoc, 'schoolName', '');
            _remainingPrints = _getFieldSafe(userDoc, 'remainingPrints', 5);
            _isAccountActive = _getFieldSafe(userDoc, 'isActive', false);
            _isDialogCompleted = _profName.isNotEmpty && _schoolName.isNotEmpty;
          });
        }

        if (_isMounted && !_isDialogCompleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_isMounted) {
              _showInputDialog();
            }
          });
        }
      } catch (e) {
        print('Erreur lors du chargement des données utilisateur: $e');
      }
    }
  }

  void _showEditDialog() {
    TextEditingController profController =
        TextEditingController(text: _profName);
    TextEditingController schoolController =
        TextEditingController(text: _schoolName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 8),
              Text('تعديل المعلومات',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: profController,
                decoration: InputDecoration(
                  labelText: 'اسم الأستاذ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: schoolController,
                decoration: InputDecoration(
                  labelText: 'اسم المدرسة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (currentUser != null) {
                  await FirebaseFirestore.instance
                      .collection('Users') // CORRECTION : Utiliser 'Users'
                      .doc(currentUser!.uid)
                      .set(
                    {
                      'profName': profController.text,
                      'schoolName': schoolController.text,
                    },
                    SetOptions(merge: true),
                  );

                  setState(() {
                    _profName = profController.text;
                    _schoolName = schoolController.text;
                  });

                  _showSuccessSnackbar('Informations mises à jour');
                }
                Navigator.of(context).pop();
              },
              child: Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _showInputDialog() {
    TextEditingController profController = TextEditingController();
    TextEditingController schoolController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person_add, color: Colors.blue),
              SizedBox(width: 8),
              Text('معلومات جديدة',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Veuillez compléter vos informations pour continuer',
                  style: TextStyle(color: Colors.grey[600])),
              SizedBox(height: 16),
              TextField(
                controller: profController,
                decoration: InputDecoration(
                  labelText: 'اسم الأستاذ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: schoolController,
                decoration: InputDecoration(
                  labelText: 'اسم المدرسة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (profController.text.isEmpty ||
                    schoolController.text.isEmpty) {
                  _showErrorSnackbar('Veuillez remplir tous les champs');
                  return;
                }

                if (currentUser != null) {
                  await FirebaseFirestore.instance
                      .collection('Users') // CORRECTION : Utiliser 'Users'
                      .doc(currentUser!.uid)
                      .set(
                    {
                      'profName': profController.text,
                      'schoolName': schoolController.text,
                      'remainingPrints': _remainingPrints,
                    },
                    SetOptions(merge: true),
                  );

                  setState(() {
                    _profName = profController.text;
                    _schoolName = schoolController.text;
                    _isDialogCompleted = true;
                  });

                  _showSuccessSnackbar('Informations enregistrées');
                }
                Navigator.of(context).pop();
              },
              child: Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchMarks() async {
    if (!_isMounted) return;

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      var studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('user_classes')
          .doc(widget.selectedClass)
          .collection('students')
          .get();

      if (_isMounted) {
        setState(() {
          totalStudents = studentsSnapshot.docs.length;
        });
      }

      var selectedBaremes = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .get();

      for (var baremeDoc in selectedBaremes.docs) {
        var baremeId = _getFieldSafe(baremeDoc, 'baremeId', '');
        sumCriteriaMaxPerBareme[baremeId] = 0;

        var sousBaremesSnapshot =
            await baremeDoc.reference.collection('sous_baremes').get();
        for (var sousBaremeDoc in sousBaremesSnapshot.docs) {
          var sousBaremeId = _getFieldSafe(sousBaremeDoc, 'sousBaremeId', '');
          sumCriteriaMaxPerBareme['$baremeId-$sousBaremeId'] = 0;
        }
      }

      for (var studentDoc in studentsSnapshot.docs) {
        var studentId = studentDoc.id;

        for (var baremeDoc in selectedBaremes.docs) {
          var baremeId = _getFieldSafe(baremeDoc, 'baremeId', '');

          var baremeSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('user_classes')
              .doc(widget.selectedClass)
              .collection('students')
              .doc(studentId)
              .collection('baremes')
              .doc(baremeId)
              .get();

          if (baremeSnapshot.exists) {
            var value = _getFieldSafe(baremeSnapshot, 'Marks', '');
            if (value == '( + + + )' || value == '( + + - )') {
              sumCriteriaMaxPerBareme[baremeId] =
                  (sumCriteriaMaxPerBareme[baremeId] ?? 0) + 1;
            }
          } else {
            var sousBaremesSnapshot =
                await baremeSnapshot.reference.collection('sous_baremes').get();
            for (var sousBaremeDoc in sousBaremesSnapshot.docs) {
              var value = _getFieldSafe(sousBaremeDoc, 'Marks', '');
              if (value == '( + + + )' || value == '( + + - )') {
                sumCriteriaMaxPerBareme[sousBaremeDoc.id] =
                    (sumCriteriaMaxPerBareme[sousBaremeDoc.id] ?? 0) + 1;
              }
            }
          }
        }
      }

      if (_isMounted) {
        setState(() {});
      }
    } catch (e) {
      print('Erreur lors de la récupération des marques : $e');
    }
  }

  // WIDGETS AMÉLIORÉS POUR L'UI/UX
  Widget _buildPrintCreditWidget() {
    Color backgroundColor;
    if (_remainingPrints == 0) {
      backgroundColor = Colors.red;
    } else if (_remainingPrints <= 2) {
      backgroundColor = Colors.orange;
    } else {
      backgroundColor = Colors.blue;
    }

    return Tooltip(
      message: 'Crédit d\'impression restant',
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.print, size: 16, color: Colors.white),
            SizedBox(width: 6),
            Text(
              '$_remainingPrints/5',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTimeRemaining() {
    if (_remainingTime.isNegative || !_isAccountActive) return SizedBox();

    Color timeColor = _remainingTime.inDays <= 7 ? Colors.orange : Colors.teal;

    return Tooltip(
      message: 'Temps restant avant expiration',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: timeColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.white),
            SizedBox(width: 6),
            Text(
              '${_remainingTime.inDays}j ${_remainingTime.inHours % 24}h',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStatusIndicator() {
    return Tooltip(
      message: _isAccountActive ? 'Compte actif' : 'Compte inactif',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isAccountActive ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 12,
              color: Colors.white,
            ),
            SizedBox(width: 6),
            Text(
              _isAccountActive ? 'Actif' : 'Inactif',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton() {
    return IconButton(
      icon: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Icon(Icons.person, color: Colors.white, size: 20),
      ),
      onPressed: _showEditDialog,
    );
  }

  Widget _buildPrintButton() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Icon(
          Icons.print,
          color: Colors.white,
          size: 20,
        ),
      ),
      onSelected: _isGeneratingReport
          ? null
          : (value) {
              if (value == 'html') {
                _generateHTMLReport();
              } else if (value == 'pdf') {
                _generatePDF();
              }
            },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'html',
          child: Row(
            children: [
              Icon(Icons.description, color: Colors.blue),
              SizedBox(width: 8),
              Text('طباعة الجدول (HTML)'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red),
              SizedBox(width: 8),
              Text('طباعة الجدول (PDF)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeButton() {
    if (_isAccountActive) return SizedBox();

    return Tooltip(
      message: 'Activer votre compte',
      child: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withOpacity(0.9),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Icon(Icons.upgrade, color: Colors.white, size: 20),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PaymentPage()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Utilisateur non connecté.', style: TextStyle(fontSize: 18)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isDialogCompleted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement de vos informations...',
                  style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontFamily: 'ArabicFont', fontSize: 14),
        ),
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('الجدول الجامع للنتائج',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
          elevation: 4,
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            _buildPrintCreditWidget(),
            if (_isAccountActive) _buildAccountTimeRemaining(),
            _buildAccountStatusIndicator(),
            _buildUpgradeButton(),
            _buildProfileButton(),
            _buildPrintButton(),
          ],
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // Header amélioré
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildHeaderInfo(),
                    ),
                    _buildHeaderLogo(),
                  ],
                ),
              ),

              // Contenu principal
              Expanded(
                child: _buildMainContent(),
              ),

              // Footer amélioré
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border(
                    top: BorderSide(color: Colors.blue, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تاريخ الإصدار: ${DateTime.now().toString().substring(0, 10)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    if (!_isAccountActive)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info,
                                size: 16, color: Colors.orange[800]),
                            SizedBox(width: 4),
                            Text(
                              'Compte limité - $_remainingPrints/5 impressions',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return FutureBuilder<Map<String, String>>(
      future: _getClassAndMatiereNames(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(),
              ),
              SizedBox(width: 8),
              Text('Chargement...'),
            ],
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Text('خطأ في تحميل البيانات',
              style: TextStyle(color: Colors.red));
        }

        var classAndMatiereNames = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('الأستاذ:', _profName),
            SizedBox(height: 4),
            _buildInfoRow('المادة:', classAndMatiereNames['matiereName']!),
            SizedBox(height: 4),
            _buildInfoRow('القسم:', classAndMatiereNames['className']!),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderLogo() {
    return Column(
      children: [
        Image.asset(
          'lib/assets/icons/me/ministere.png',
          height: 70,
          errorBuilder: (context, error, stackTrace) {
            print("Erreur chargement image: $error");
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100],
              ),
              child: Icon(Icons.school, size: 40, color: Colors.grey[400]),
            );
          },
        ),
        SizedBox(height: 8),
        Text(
          'مدرسة: $_schoolName',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<Map<String, String>> _getClassAndMatiereNames() async {
    try {
      var classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .get();
      var className = _getFieldSafe(classDoc, 'name', 'غير معروف');

      var matiereDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .get();
      var matiereName = _getFieldSafe(matiereDoc, 'name', 'غير معروف');

      return {
        'className': className,
        'matiereName': matiereName,
      };
    } catch (e) {
      return {
        'className': 'غير معروف',
        'matiereName': 'غير معروف',
      };
    }
  }

  Widget _buildMainContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .snapshots(),
      builder: (context, userClassesSnapshot) {
        if (userClassesSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement des classes...'),
              ],
            ),
          );
        }

        if (userClassesSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text('Erreur de chargement',
                    style: TextStyle(fontSize: 16, color: Colors.red)),
                SizedBox(height: 8),
                Text('${userClassesSnapshot.error}'),
              ],
            ),
          );
        }

        if (!userClassesSnapshot.hasData ||
            userClassesSnapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.class_, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لم يتم العثور على أي قسم.',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('Veuillez ajouter des classes d\'abord.',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          );
        }

        // Recherche de la classe correspondante
        for (var classDoc in userClassesSnapshot.data!.docs) {
          var classData = classDoc.data() as Map<String, dynamic>;
          var classIdFromFirestore = _getFieldSafe(classDoc, 'class_id', '');

          if (widget.selectedClass == classIdFromFirestore) {
            return StudentsTable(
              classDocId: classDoc.id,
              selectedClass: widget.selectedClass,
              selectedMatiere: widget.selectedMatiere,
              currentUser: currentUser!,
              sumCriteriaMaxPerBareme: sumCriteriaMaxPerBareme,
              totalStudents: totalStudents,
              navigateToClassificationPage: _navigateToClassificationPage,
            );
          }
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text('لم يتم العثور على أي قسم مطابق.',
                  style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text('La classe sélectionnée n\'existe pas.',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}

class StudentsTable extends StatefulWidget {
  final String classDocId;
  final String selectedClass;
  final String selectedMatiere;
  final User currentUser;
  final Map<String, int> sumCriteriaMaxPerBareme;
  final int totalStudents;
  final Function(String, {String? sousBaremeId}) navigateToClassificationPage;

  const StudentsTable({
    Key? key,
    required this.classDocId,
    required this.selectedClass,
    required this.selectedMatiere,
    required this.currentUser,
    required this.sumCriteriaMaxPerBareme,
    required this.totalStudents,
    required this.navigateToClassificationPage,
  }) : super(key: key);

  @override
  _StudentsTableState createState() => _StudentsTableState();
}

class _StudentsTableState extends State<StudentsTable> {
  final List<String> _dropdownValues = [
    '( - - - )',
    '( + - - )',
    '( + + - )',
    '( + + + )'
  ];
  final Map<String, Map<String, String>> _selectedValues = {};
  final Map<String, Color> _headerColors = {};

  // États pour gérer le loading des boutons
  final Map<String, bool> _classificationLoadingStates = {};
  final Map<String, bool> _treatmentPlanLoadingStates = {};

  // Variables pour le cache des données
  List<QueryDocumentSnapshot>? _cachedStudents;
  List<QueryDocumentSnapshot>? _cachedSelections;
  bool _isMounted = false;

  // Couleurs modernes pour l'UI
  final Color _primaryColor = const Color(0xFF2E7D32);
  final Color _secondaryColor = const Color(0xFF4CAF50);
  final Color _accentColor = const Color(0xFF8BC34A);
  final Color _backgroundColor = const Color(0xFFF5F5F5);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF333333);
  final Color _borderColor = const Color(0xFFE0E0E0);

  Color _getRandomColor() {
    final List<Color> predefinedColors = [
      Color(0xFF2196F3),
      Color(0xFFFF9800),
      Color(0xFF9C27B0),
      Color(0xFF009688),
      Color(0xFF795548),
      Color(0xFF607D8B),
    ];
    return predefinedColors[Random().nextInt(predefinedColors.length)];
  }

  // Fonction pour trier les barèmes par ordre alphabétique arabe
  List<Map<String, dynamic>> _sortBaremesAlphabetically(
      List<Map<String, dynamic>> baremesValues) {
    baremesValues.sort((a, b) {
      String nameA = a['value'] ?? '';
      String nameB = b['value'] ?? '';
      return nameA.compareTo(nameB);
    });
    return baremesValues;
  }

  // Fonction modifiée pour grouper les barèmes triés
  Map<String, List<Map<String, dynamic>>> groupBaremes(
      List<Map<String, dynamic>> baremesValues) {
    // Trier d'abord les barèmes par ordre alphabétique
    List<Map<String, dynamic>> sortedBaremes =
        _sortBaremesAlphabetically(baremesValues);

    Map<String, List<Map<String, dynamic>>> groupedBaremes = {};

    for (var bareme in sortedBaremes) {
      String key = bareme['value'].substring(0, 4);
      if (!groupedBaremes.containsKey(key)) {
        groupedBaremes[key] = [];
      }
      groupedBaremes[key]!.add(bareme);
    }

    return groupedBaremes;
  }

  // Fonction pour déterminer si c'est un barème principal ou sous-barème
  String _getBaremeDisplayName(
      Map<String, dynamic> bareme, Map<String, dynamic> subEntry) {
    // Si c'est le barème principal (même ID)
    if (bareme['id'] == subEntry['id']) {
      return bareme['value']; // Nom du barème principal
    } else {
      // C'est un sous-barème - retourner seulement le nom du sous-barème
      return subEntry['value'];
    }
  }

  // Générer une clé unique pour chaque bouton
  String _getButtonKey(
      String baremeId, String? sousBaremeId, bool isClassification) {
    return '${baremeId}_${sousBaremeId ?? 'main'}_${isClassification ? 'classification' : 'treatment'}';
  }

  // Fonction pour démarrer le loading d'un bouton
  void _startLoading(String buttonKey, bool isClassification) {
    if (_isMounted) {
      setState(() {
        if (isClassification) {
          _classificationLoadingStates[buttonKey] = true;
        } else {
          _treatmentPlanLoadingStates[buttonKey] = true;
        }
      });
    }
  }

  // Fonction pour arrêter le loading d'un bouton
  void _stopLoading(String buttonKey, bool isClassification) {
    if (_isMounted) {
      setState(() {
        if (isClassification) {
          _classificationLoadingStates[buttonKey] = false;
        } else {
          _treatmentPlanLoadingStates[buttonKey] = false;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _loadStudentsOnce();
    _loadSelectionsOnce();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  // Méthode pour charger les étudiants une fois
  Future<void> _loadStudentsOnce() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('user_classes')
          .doc(widget.classDocId)
          .collection('students')
          .get();

      if (_isMounted) {
        setState(() {
          _cachedStudents = snapshot.docs;
        });
      }
    } catch (e) {
      print('Erreur chargement étudiants: $e');
    }
  }

  // Méthode pour charger les sélections une fois
  Future<void> _loadSelectionsOnce() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .get();

      if (_isMounted) {
        setState(() {
          _cachedSelections = snapshot.docs;
        });
      }
    } catch (e) {
      print('Erreur chargement sélections: $e');
    }
  }

  // Méthode pour rafraîchir les données manuellement
  Future<void> _refreshData() async {
    await _loadStudentsOnce();
    await _loadSelectionsOnce();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_backgroundColor, Colors.white],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          SizedBox(height: 16),
          Expanded(
            child: _buildContentWithCachedData(),
          ),
        ],
      ),
    );
  }

  // Nouvelle méthode pour utiliser les données en cache
  Widget _buildContentWithCachedData() {
    if (_cachedStudents == null) {
      return _buildLoadingIndicator();
    }

    if (_cachedStudents!.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSelectionsTable(_cachedStudents!);
  }

  Future<Map<String, String>> _getClassAndMatiereNames() async {
    try {
      // Récupérer le nom de la classe
      var classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .get();
      var className = classDoc['name'] ?? 'غير معروف';

      // Récupérer le nom de la matière
      var matiereDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .get();
      var matiereName = matiereDoc['name'] ?? 'غير معروف';

      return {
        'className': className,
        'matiereName': matiereName,
      };
    } catch (e) {
      print('Erreur lors de la récupération des noms: $e');
      return {
        'className': 'غير معروف',
        'matiereName': 'غير معروف',
      };
    }
  }

  Widget _buildHeader() {
    return FutureBuilder<Map<String, String>>(
      future: _getClassAndMatiereNames(),
      builder: (context, snapshot) {
        String className = 'غير معروف';
        String matiereName = 'غير معروف';

        if (snapshot.connectionState == ConnectionState.waiting) {
          className = 'جاري التحميل...';
          matiereName = 'جاري التحميل...';
        } else if (snapshot.hasData) {
          className = snapshot.data!['className'] ?? 'غير معروف';
          matiereName = snapshot.data!['matiereName'] ?? 'غير معروف';
        }

        return Card(
          elevation: 3,
          margin: EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _secondaryColor],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white),
                  onPressed: _refreshData,
                  tooltip: 'Rafraîchir les données',
                ),
                SizedBox(width: 12),
                Icon(Icons.school, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'جدول التقييم',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$className - $matiereName',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.totalStudents} طالب',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'جاري تحميل البيانات...',
            style: TextStyle(
              color: _textColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 64),
          SizedBox(height: 16),
          Text(
            error,
            textDirection: TextDirection.rtl,
            style: TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, color: Colors.grey, size: 64),
          SizedBox(height: 16),
          Text(
            'لم يتم العثور على أي طالب.',
            textDirection: TextDirection.rtl,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionsTable(List<QueryDocumentSnapshot> studentsDocs) {
    if (_cachedSelections == null) {
      return _buildLoadingIndicator();
    }

    if (_cachedSelections!.isEmpty) {
      return _buildEmptyStateForCriteria();
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getBaremesValues(_cachedSelections!),
      builder: (context, baremesValuesSnapshot) {
        if (baremesValuesSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }
        if (baremesValuesSnapshot.hasError) {
          return _buildErrorWidget('خطأ: ${baremesValuesSnapshot.error}');
        }
        if (!baremesValuesSnapshot.hasData ||
            baremesValuesSnapshot.data!.isEmpty) {
          return _buildEmptyStateForCriteria();
        }

        return _buildDataTable(studentsDocs, baremesValuesSnapshot.data!);
      },
    );
  }

  Widget _buildEmptyStateForCriteria() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment_outlined, color: Colors.grey, size: 64),
          SizedBox(height: 16),
          Text(
            'لم يتم العثور على أي معيار.',
            textDirection: TextDirection.rtl,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<QueryDocumentSnapshot> studentsDocs,
      List<Map<String, dynamic>> baremesValues) {
    Map<String, List<Map<String, dynamic>>> groupedBaremes =
        groupBaremes(baremesValues);

    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              dataRowColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return _accentColor.withOpacity(0.2);
                  }
                  return Colors.transparent;
                },
              ),
              columns: [
                DataColumn(
                  label: Container(
                    width: 160,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'الاسم واللقب',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                for (var entry in groupedBaremes.entries)
                  for (final bareme in entry.value)
                    for (final subEntry in [
                      {'id': bareme['id'], 'value': bareme['value']},
                      ...(bareme['sousBaremes'] as List<dynamic>? ?? [])
                    ])
                      DataColumn(
                        label: Container(
                          width: 110,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _headerColors.putIfAbsent(
                                    entry.key, () => _getRandomColor()),
                                _headerColors[entry.key]!.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _getBaremeDisplayName(bareme, subEntry),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
              rows: [
                ...studentsDocs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final studentDoc = entry.value;
                  final studentId = studentDoc.id;
                  final studentName = studentDoc['name'] ?? 'غير معروف';

                  return DataRow(
                    color: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        return index.isEven
                            ? _backgroundColor.withOpacity(0.3)
                            : Colors.transparent;
                      },
                    ),
                    cells: [
                      DataCell(
                        Container(
                          width: 160,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  studentName,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    color: _textColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      for (var entry in groupedBaremes.entries)
                        for (final bareme in entry.value)
                          for (final subEntry in [
                            {'id': bareme['id'], 'type': 'bareme'},
                            ...(bareme['sousBaremes'] as List<dynamic>? ?? [])
                                .map((s) =>
                                    {'id': s['id'], 'type': 'sousBareme'})
                          ])
                            DataCell(
                              Container(
                                width: 110,
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: FutureBuilder<String>(
                                  future: _getSelectedValue(
                                      studentId, subEntry['id']),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  _primaryColor),
                                        ),
                                      );
                                    }
                                    final value =
                                        snapshot.data ?? _dropdownValues[0];
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getValueColor(value)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _getValueColor(value)
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          value,
                                          style: TextStyle(
                                            color: _getValueColor(value),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                    ],
                  );
                }).toList(),
                DataRow(
                  cells: [
                    const DataCell(Text('عدد التلاميذ المحققين',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                    for (final bareme in baremesValues)
                      for (final entry in [
                        {'id': bareme['id']},
                        ...(bareme['sousBaremes'] as List<dynamic>? ?? [])
                      ])
                        DataCell(Text(
                          widget.sumCriteriaMaxPerBareme[entry['id']]
                                  ?.toString() ??
                              '0',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                  ],
                ),
                // Ligne des pourcentages
                DataRow(
                  cells: [
                    const DataCell(Text('النسبة المئوية',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                    for (var entry in groupedBaremes.entries)
                      for (final bareme in entry.value)
                        for (final subEntry in [
                          {'id': bareme['id']},
                          ...(bareme['sousBaremes'] as List<dynamic>? ?? [])
                        ])
                          DataCell(Text(
                            widget.totalStudents == 0
                                ? 'لا توجد درجات'
                                : '${((widget.sumCriteriaMaxPerBareme[subEntry['id']] ?? 0) / widget.totalStudents * 100).toStringAsFixed(2)}٪',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors
                                    .black), // Texte en noir pour contraste
                          )),
                  ],
                ),
                // Ligne des boutons "تصنيف"
                DataRow(
                  cells: [
                    DataCell(
                        Container()), // Cellule vide pour la colonne des noms
                    for (var entry in groupedBaremes.entries)
                      for (final bareme in entry.value)
                        for (final subEntry in [
                          {
                            'id': bareme['id'],
                            'type': 'bareme',
                            'name': bareme['value']
                          },
                          ...(bareme['sousBaremes'] as List<dynamic>? ?? [])
                              .map((s) => {
                                    'id': s['id'],
                                    'type': 'sousBareme',
                                    'name': s['value']
                                  })
                        ])
                          DataCell(
                            Container(
                              width: 100,
                              height: 50,
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  _classifyStudentsByBarem(
                                    bareme['id']!,
                                    sousBaremeId:
                                        subEntry['type'] == 'sousBareme'
                                            ? subEntry['id']
                                            : null,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                ),
                                child: Text(
                                  'تصنيف',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.yellow),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
                // Ligne des boutons "خطة العلاج"
                DataRow(
                  cells: [
                    DataCell(Container()),
                    for (var entry in groupedBaremes.entries)
                      for (final bareme in entry.value)
                        for (final subEntry in [
                          {
                            'id': bareme['id'],
                            'type': 'bareme',
                            'name': bareme['value']
                          },
                          ...(bareme['sousBaremes'] as List<dynamic>? ?? [])
                              .map((s) => {
                                    'id': s['id'],
                                    'type': 'sousBareme',
                                    'name': s['value']
                                  })
                        ])
                          DataCell(
                            Container(
                              width: 100,
                              height: 50,
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  widget.navigateToClassificationPage(
                                    bareme['id']!,
                                    sousBaremeId:
                                        subEntry['type'] == 'sousBareme'
                                            ? subEntry['id']
                                            : null,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                ),
                                child: Text(
                                  'خطة العلاج',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ),
                              ),
                            ),
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

  Color _getValueColor(String value) {
    switch (value) {
      case '( + + + )':
        return Colors.green;
      case '( + + - )':
        return Colors.orange;
      case '( + - - )':
        return Colors.orangeAccent;
      case '( - - - )':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  DataRow _buildStatsRow(
      String title, Map<String, List<Map<String, dynamic>>> groupedBaremes,
      {required bool isPercentage}) {
    return DataRow(
      color: MaterialStateProperty.all(_primaryColor.withOpacity(0.05)),
      cells: [
        DataCell(
          Container(
            width: 160,
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ),
        ),
        for (var entry in groupedBaremes.entries)
          for (final bareme in entry.value)
            for (final subEntry in [
              {'id': bareme['id']},
              ...(bareme['sousBaremes'] as List<dynamic>? ?? [])
            ])
              DataCell(
                Container(
                  width: 110,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPercentage
                          ? _secondaryColor.withOpacity(0.1)
                          : _accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        isPercentage
                            ? widget.totalStudents == 0
                                ? 'لا توجد درجات'
                                : '${((widget.sumCriteriaMaxPerBareme[subEntry['id']] ?? 0) / widget.totalStudents * 100).toStringAsFixed(2)}٪'
                            : widget.sumCriteriaMaxPerBareme[subEntry['id']]
                                    ?.toString() ??
                                '0',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPercentage ? _secondaryColor : _accentColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  DataRow _buildButtonRow(String buttonText, Color backgroundColor,
      Color textColor, Map<String, List<Map<String, dynamic>>> groupedBaremes,
      {required bool isClassification}) {
    return DataRow(
      cells: [
        DataCell(Container()),
        for (var entry in groupedBaremes.entries)
          for (final bareme in entry.value)
            for (final subEntry in [
              {'id': bareme['id'], 'type': 'bareme', 'name': bareme['value']},
              ...(bareme['sousBaremes'] as List<dynamic>? ?? []).map((s) =>
                  {'id': s['id'], 'type': 'sousBareme', 'name': s['value']})
            ])
              DataCell(
                Container(
                  width: 110,
                  height: 48,
                  padding: EdgeInsets.all(4),
                  child: _buildLoadingButton(
                    bareme: bareme,
                    subEntry: subEntry,
                    buttonText: buttonText,
                    backgroundColor: backgroundColor,
                    textColor: textColor,
                    isClassification: isClassification,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildLoadingButton({
    required Map<String, dynamic> bareme,
    required Map<String, dynamic> subEntry,
    required String buttonText,
    required Color backgroundColor,
    required Color textColor,
    required bool isClassification,
  }) {
    final String buttonKey = _getButtonKey(
      bareme['id']!,
      subEntry['type'] == 'sousBareme' ? subEntry['id'] : null,
      isClassification,
    );

    final bool isLoading = isClassification
        ? _classificationLoadingStates[buttonKey] ?? false
        : _treatmentPlanLoadingStates[buttonKey] ?? false;

    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () async {
              _startLoading(buttonKey, isClassification);
              try {
                if (isClassification) {
                  await _classifyStudentsByBarem(
                    bareme['id']!,
                    sousBaremeId: subEntry['type'] == 'sousBareme'
                        ? subEntry['id']
                        : null,
                  );
                } else {
                  await widget.navigateToClassificationPage(
                    bareme['id']!,
                    sousBaremeId: subEntry['type'] == 'sousBareme'
                        ? subEntry['id']
                        : null,
                  );
                }
              } catch (e) {
                print('Erreur: $e');
                if (_isMounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                _stopLoading(buttonKey, isClassification);
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: isLoading ? Colors.grey : backgroundColor,
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      child: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            )
          : Text(
              buttonText,
              style: TextStyle(
                fontSize: 11,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
    );
  }

  Future<List<Map<String, dynamic>>> _getBaremesValues(
      List<QueryDocumentSnapshot> selectedBaremes) async {
    final List<Map<String, dynamic>> result = [];
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    for (final baremeDoc in selectedBaremes) {
      final baremeId = baremeDoc['baremeId'];
      final baremeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .doc(baremeId)
          .get();

      final isBaremeSelected = baremeSnapshot['selected'] ?? false;
      final sousBaremesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .doc(baremeId)
          .collection('sousBaremes')
          .get();

      final selectedSousBaremes = sousBaremesSnapshot.docs
          .where((doc) => doc['selected'] == true)
          .toList();

      if (isBaremeSelected) {
        final baremeName = baremeSnapshot['baremeName'] ?? 'غير معروف';
        result.add({
          'id': baremeId,
          'value': baremeName,
          'sousBaremes': [],
        });
      } else if (selectedSousBaremes.isNotEmpty) {
        for (final sousBareme in selectedSousBaremes) {
          final sousBaremeName = sousBareme['sousBaremeName'] ?? 'غير معروف';
          result.add({
            'id': sousBareme.id,
            'value': sousBaremeName,
            'parentBaremeId': baremeId,
          });
        }
      }
    }
    return result;
  }

  Future<String> _getSelectedValue(String studentId, String baremeKey) async {
    try {
      var docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('user_classes')
          .doc(widget.classDocId)
          .collection('students')
          .doc(studentId)
          .collection('baremes')
          .doc(baremeKey);

      final parentDoc = await docRef.get();
      if (!parentDoc.exists) {
        return _dropdownValues[0];
      }

      final haveSoubarem = parentDoc.data()?['haveSoubarem'] ?? false;
      if (haveSoubarem) {
        final sousBaremesSnapshot =
            await docRef.collection('sous_baremes').get();
        if (sousBaremesSnapshot.docs.isNotEmpty) {
          final sousBaremeDocRef = sousBaremesSnapshot.docs.first;
          final sousBaremeData = sousBaremeDocRef.data();
          return sousBaremeData?['Marks']?.toString() ?? _dropdownValues[0];
        }
      }

      return parentDoc.data()?['Marks']?.toString() ?? _dropdownValues[0];
    } catch (e) {
      return _dropdownValues[0];
    }
  }

  Future<void> _classifyStudentsByBarem(String baremeId,
      {String? sousBaremeId}) async {
    try {
      var studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('user_classes')
          .doc(widget.classDocId)
          .collection('students')
          .get();

      Map<String, List<String>> studentGroups = {
        'مجموعة العلاج': [],
        'مجموعة الدعم': [],
        'مجموعة التميز': [],
      };

      for (var studentDoc in studentsSnapshot.docs) {
        var studentId = studentDoc.id;
        var studentName = studentDoc['name'] ?? 'اسم غير معروف';

        var baremeRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUser.uid)
            .collection('user_classes')
            .doc(widget.classDocId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .doc(baremeId);

        var snapshot = sousBaremeId != null
            ? await baremeRef.collection('sous_baremes').doc(sousBaremeId).get()
            : await baremeRef.get();

        if (snapshot.exists) {
          var value = snapshot['Marks'];
          if (value == '( + + + )') {
            studentGroups['مجموعة التميز']!.add(studentName);
          } else if (value == '( + + - )') {
            studentGroups['مجموعة الدعم']!.add(studentName);
          } else if (value == '( + - - )' || value == '( - - - )') {
            studentGroups['مجموعة العلاج']!.add(studentName);
          }
        }
      }

      if (_isMounted) {
        _showClassificationDialog(studentGroups);
      }
    } catch (e) {
      print('Erreur lors de la classification des élèves: $e');
      rethrow;
    }
  }

  void _showClassificationDialog(Map<String, List<String>> studentGroups) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isPortrait =
            MediaQuery.of(context).orientation == Orientation.portrait;

        final dialogWidth = screenWidth * (isPortrait ? 0.9 : 0.7);
        final dialogMaxHeight = screenHeight * 0.8;
        final titleFontSize = screenWidth * 0.045;
        final groupTitleFontSize = screenWidth * 0.035;
        final studentFontSize = screenWidth * 0.03;

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: dialogMaxHeight,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'تصنيف التلاميذ',
                        style: TextStyle(
                          fontSize: titleFontSize.clamp(18, 24),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...['مجموعة التميز', 'مجموعة الدعم', 'مجموعة العلاج']
                              .map((groupName) {
                            return _buildResponsiveGroupCard(
                              groupName,
                              studentGroups[groupName]!,
                              groupTitleFontSize: groupTitleFontSize,
                              studentFontSize: studentFontSize,
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border:
                          Border(top: BorderSide(color: Colors.grey.shade300)),
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(screenWidth * 0.3, 50),
                        ),
                        child: Text(
                          'إغلاق',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize.clamp(16, 20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveGroupCard(
    String groupName,
    List<String> students, {
    required double groupTitleFontSize,
    required double studentFontSize,
  }) {
    Color cardColor;
    Color textColor;

    switch (groupName) {
      case 'مجموعة التميز':
        cardColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      case 'مجموعة الدعم':
        cardColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case 'مجموعة العلاج':
        cardColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      default:
        cardColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          title: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: textColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  groupName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: groupTitleFontSize.clamp(14, 18),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  students.length.toString(),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: groupTitleFontSize.clamp(12, 16),
                  ),
                ),
              ),
            ],
          ),
          children: students.map((student) {
            return ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person,
                    color: textColor.withOpacity(0.7), size: 16),
              ),
              title: Text(
                student,
                style: TextStyle(
                  color: _textColor,
                  fontSize: studentFontSize.clamp(12, 16),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class StudentDropdown extends StatefulWidget {
  final String studentId;
  final String baremeId;
  final String initialValue;
  final List<String> dropdownValues;
  final Function(String, String, String) onChanged;

  const StudentDropdown({
    Key? key,
    required this.studentId,
    required this.baremeId,
    required this.initialValue,
    required this.dropdownValues,
    required this.onChanged,
  }) : super(key: key);

  @override
  _StudentDropdownState createState() => _StudentDropdownState();
}

class _StudentDropdownState extends State<StudentDropdown> {
  late String _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _currentValue,
      alignment: Alignment.center,
      dropdownColor: Colors.white,
      items: widget.dropdownValues
          .map((value) => DropdownMenuItem(
                value: value,
                child: Text(value, textDirection: TextDirection.rtl),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _currentValue = value);
          widget.onChanged(widget.studentId, widget.baremeId, value);
        }
      },
    );
  }
}
