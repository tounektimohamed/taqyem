import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddClassPage extends StatefulWidget {
  @override
  _AddClassPageState createState() => _AddClassPageState();
}

class _AddClassPageState extends State<AddClassPage> {
  String? _selectedClassName;
  List<String> _selectedSubjects = [];
  List<Map<String, String>> _subjects = [];
  List<Map<String, String>> _classNames = [];
  List<Map<String, String>> _students = [];
  String? _selectedClassNameDisplay;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _filteredClassNames = [];
  
  // Contrôleurs pour le formulaire de demande
  TextEditingController _nomController = TextEditingController();
  TextEditingController _prenomController = TextEditingController();
  TextEditingController _telephoneController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _ecoleController = TextEditingController();
  TextEditingController _adresseEcoleController = TextEditingController();
  TextEditingController _raisonController = TextEditingController();

  // Variable pour stocker la limite de l'utilisateur
  int _userClassLimit = 4;

  final List<Color> groupColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
    Colors.deepPurple,
    Colors.lightGreen,
  ];

  @override
  void initState() {
    super.initState();
    _loadClassNames();
    _searchController.addListener(_filterClassNames);
    _getUserLimit();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _ecoleController.dispose();
    _adresseEcoleController.dispose();
    _raisonController.dispose();
    super.dispose();
  }

  // Récupérer la limite de l'utilisateur
  Future<void> _getUserLimit() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          setState(() {
            _userClassLimit = userDoc['classLimit'] ?? 4;
          });
        }
      } catch (e) {
        print("Erreur lors de la récupération de la limite: $e");
      }
    }
  }

  Future<int> _getUserClassesCount(String userId) async {
    try {
      final userClasses = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('user_classes')
          .get();
      return userClasses.docs.length;
    } catch (e) {
      print("Erreur lors du comptage des classes : $e");
      return 0;
    }
  }

  Future<Map<String, dynamic>> _checkUserRequestStatus(String userId) async {
    try {
      final requestDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('requests')
          .doc('class_limit_request')
          .get();

      if (requestDoc.exists) {
        return {
          'exists': true,
          'status': requestDoc['status'] ?? '',
          'data': requestDoc.data(),
        };
      }
      return {'exists': false, 'status': '', 'data': null};
    } catch (e) {
      print("Erreur lors de la vérification du statut : $e");
      return {'exists': false, 'status': '', 'data': null};
    }
  }

  Future<void> _showRequestForm() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('طلب زيادة عدد الأقسام'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'لقد وصلت إلى الحد الأقصى المسموح به ($_userClassLimit أقسام). يرجى ملء النموذج التالي لطلب زيادة الحد.',
                  style: TextStyle(color: Colors.blueGrey),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _nomController,
                  decoration: InputDecoration(
                    labelText: 'الاسم',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _prenomController,
                  decoration: InputDecoration(
                    labelText: 'اللقب',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _telephoneController,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _ecoleController,
                  decoration: InputDecoration(
                    labelText: 'اسم المؤسسة التعليمية',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _adresseEcoleController,
                  decoration: InputDecoration(
                    labelText: 'عنوان المؤسسة',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _raisonController,
                  decoration: InputDecoration(
                    labelText: 'سبب الطلب',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: _submitRequest,
              child: Text('إرسال الطلب'),
            ),
          ],
        );
      },
    );
  }
  Future<void> _submitRequest() async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  // Vérifier que tous les champs sont remplis
  if (_nomController.text.isEmpty ||
      _prenomController.text.isEmpty ||
      _telephoneController.text.isEmpty ||
      _emailController.text.isEmpty ||
      _ecoleController.text.isEmpty ||
      _adresseEcoleController.text.isEmpty ||
      _raisonController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('يرجى ملء جميع الحقول'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Afficher un indicateur de chargement
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Center(
        child: CircularProgressIndicator(),
      );
    },
  );

  try {
    // Récupérer les informations actuelles de l'utilisateur
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    
    // Gérer l'absence des champs
    int currentLimit = 4; // Valeur par défaut
    if (userData.containsKey('classLimit')) {
      currentLimit = userData['classLimit'] ?? 4;
    } else {
      // Créer le champ s'il n'existe pas
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'classLimit': 4,
        'classLimitUpdatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Récupérer le nom de l'utilisateur avec gestion d'erreur
    String userName = '';
    if (userData.containsKey('name')) {
      userName = userData['name'] ?? '';
    } else if (userData.containsKey('nom')) {
      userName = userData['nom'] ?? '';
    } else if (userData.containsKey('displayName')) {
      userName = userData['displayName'] ?? '';
    } else {
      // Utiliser l'email comme nom par défaut
      userName = currentUser.email?.split('@').first ?? 'Utilisateur';
    }

    int currentClassCount = await _getUserClassesCount(currentUser.uid);
    
    // Créer un ID unique pour la demande
    String requestId = 'class_limit_request_${DateTime.now().millisecondsSinceEpoch}';

    // Préparer les données de la demande
    Map<String, dynamic> requestData = {
      'userId': currentUser.uid,
      'userEmail': currentUser.email,
      'userName': userName,
      'nom': _nomController.text,
      'prenom': _prenomController.text,
      'telephone': _telephoneController.text,
      'email': _emailController.text,
      'ecole': _ecoleController.text,
      'adresseEcole': _adresseEcoleController.text,
      'raison': _raisonController.text,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'currentClassCount': currentClassCount,
      'currentLimit': currentLimit,
      'requestedLimit': 20,
      'requestId': requestId,
    };

    // Envoyer la demande dans la collection de l'utilisateur
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('requests')
        .doc('class_limit_request')
        .set(requestData);

    // Ajouter aussi dans une collection globale pour l'admin
    await FirebaseFirestore.instance
        .collection('class_limit_requests')
        .add(requestData);

    // Mettre à jour l'utilisateur pour indiquer qu'il a une demande en cours
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({
      'hasPendingRequest': true,
      'lastRequestDate': FieldValue.serverTimestamp(),
      'lastRequestId': requestId,
    });

    // Fermer le dialogue de chargement
    if (Navigator.canPop(context)) {
      Navigator.pop(context); // Fermer le CircularProgressIndicator
    }
    
    // Fermer le formulaire
    Navigator.pop(context);

    // Afficher le message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تم إرسال طلبك بنجاح. سيتم مراجعته من قبل الإدارة'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ),
    );

    // Nettoyer les champs
    _nomController.clear();
    _prenomController.clear();
    _telephoneController.clear();
    _emailController.clear();
    _ecoleController.clear();
    _adresseEcoleController.clear();
    _raisonController.clear();

  } catch (e) {
    // Fermer le dialogue de chargement en cas d'erreur
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    print("Erreur lors de l'envoi de la demande : $e");
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ حدث خطأ أثناء إرسال الطلب: ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }
}
// Méthode pour créer une notification locale (optionnelle)
Future<void> _createLocalNotification(String title, String body) async {
  // Si vous utilisez flutter_local_notifications
  // Vous pouvez implémenter ici la notification locale
  
  // Ou simplement afficher un snackbar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$title: $body'),
      backgroundColor: Colors.blue,
      duration: Duration(seconds: 2),
    ),
  );
}
  Future<void> _loadClassNames() async {
    try {
      final classDocs =
          await FirebaseFirestore.instance.collection('classes').get();
      
      const List<String> classOrder = [
        "السنة الأولى ابتدائي",
        "السنة الأولى ابتدائي أ",
        "السنة الأولى ابتدائي ب", 
        "السنة الأولى ابتدائي ج",
        "السنة الأولى ابتدائي د",
        "السنة الثانية ابتدائي",
        "السنة الثانية ابتدائي أ",
        "السنة الثانية ابتدائي ب",
        "السنة الثانية ابتدائي ج",
        "السنة الثانية ابتدائي د",
        "السنة الثالثة ابتدائي",
        "السنة الثالثة ابتدائي أ",
        "السنة الثالثة ابتدائي ب",
        "السنة الثالثة ابتدائي ج",
        "السنة الثالثة ابتدائي د",
        "السنة الرابعة ابتدائي",
        "السنة الرابعة ابتدائي أ",
        "السنة الرابعة ابتدائي ب",
        "السنة الرابعة ابتدائي ج",
        "السنة الرابعة ابتدائي د",
        "السنة الخامسة ابتدائي",
        "السنة الخامسة ابتدائي أ",
        "السنة الخامسة ابتدائي ب",
        "السنة الخامسة ابتدائي ج",
        "السنة الخامسة ابتدائي د",
        "السنة السادسة ابتدائي",
        "السنة السادسة ابتدائي أ",
        "السنة السادسة ابتدائي ب",
        "السنة السادسة ابتدائي ج",
        "السنة السادسة ابتدائي د",
      ];

      setState(() {
        _classNames = classDocs.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'] as String,
          };
        }).toList();
        
        _classNames.sort((a, b) {
          final indexA = classOrder.indexOf(a['name']!);
          final indexB = classOrder.indexOf(b['name']!);
          
          if (indexA == -1) return 1;
          if (indexB == -1) return -1;
          
          return indexA.compareTo(indexB);
        });
        
        _filteredClassNames = List.from(_classNames);
      });
    } catch (e) {
      print("Erreur lors du chargement des classes : $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des classes')));
    }
  }

  void _filterClassNames() {
    final query = _searchController.text.toLowerCase();
    
    const List<String> classOrder = [
      "السنة الأولى ابتدائي",
      "السنة الأولى ابتدائي أ",
      "السنة الأولى ابتدائي ب", 
      "السنة الأولى ابتدائي ج",
      "السنة الأولى ابتدائي د",
      "السنة الثانية ابتدائي",
      "السنة الثانية ابتدائي أ",
      "السنة الثانية ابتدائي ب",
      "السنة الثانية ابتدائي ج",
      "السنة الثانية ابتدائي د",
      "السنة الثالثة ابتدائي",
      "السنة الثالثة ابتدائي أ",
      "السنة الثالثة ابتدائي ب",
      "السنة الثالثة ابتدائي ج",
      "السنة الثالثة ابتدائي د",
      "السنة الرابعة ابتدائي",
      "السنة الرابعة ابتدائي أ",
      "السنة الرابعة ابتدائي ب",
      "السنة الرابعة ابتدائي ج",
      "السنة الرابعة ابتدائي د",
      "السنة الخامسة ابتدائي",
      "السنة الخامسة ابتدائي أ",
      "السنة الخامسة ابتدائي ب",
      "السنة الخامسة ابتدائي ج",
      "السنة الخامسة ابتدائي د",
      "السنة السادسة ابتدائي",
      "السنة السادسة ابتدائي أ",
      "السنة السادسة ابتدائي ب",
      "السنة السادسة ابتدائي ج",
      "السنة السادسة ابتدائي د",
    ];

    setState(() {
      _filteredClassNames = _classNames.where((classData) {
        return classData['name']!.toLowerCase().contains(query);
      }).toList();
      
      _filteredClassNames.sort((a, b) {
        final indexA = classOrder.indexOf(a['name']!);
        final indexB = classOrder.indexOf(b['name']!);
        
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        
        return indexA.compareTo(indexB);
      });
    });
  }

  Future<void> _saveClassData(String? newClassName) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Mettre à jour la limite
      await _getUserLimit();
      
      // Vérifier le nombre de classes de l'utilisateur
      int userClassesCount = await _getUserClassesCount(currentUser.uid);
      
      if (userClassesCount >= _userClassLimit) {
        // Vérifier si l'utilisateur a une demande en attente
        var requestStatus = await _checkUserRequestStatus(currentUser.uid);
        
        if (requestStatus['exists'] && requestStatus['status'] == 'pending') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لديك طلب قيد المراجعة. يرجى الانتظار حتى يتم الرد عليه.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (requestStatus['exists'] && requestStatus['status'] == 'approved') {
          // La demande a été approuvée, mais la limite n'est pas encore mise à jour
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تمت الموافقة على طلبك. يرجى تحديث الصفحة للمتابعة.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          _showRequestForm();
        }
        return;
      }

      if (_selectedClassName != null && _selectedSubjects.isNotEmpty) {
        try {
          final existingClass = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('user_classes')
              .where('class_id', isEqualTo: _selectedClassName)
              .get();

          if (existingClass.docs.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('هذا القسم مسجل مسبقًا!'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          var userClassesRef = FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('user_classes')
              .doc(_selectedClassName);
          
          await userClassesRef.set({
            'class_id': _selectedClassName,
            'class_name': newClassName ?? _selectedClassNameDisplay,
            'subjects': _selectedSubjects.map((subjectId) {
              var subject = _subjects.firstWhere(
                (s) => s['id'] == subjectId,
                orElse: () => {'name': 'غير معروف'},
              );
              return {
                'id': subjectId,
                'name': subject['name'],
              };
            }).toList(),
            'students': _students.map((student) => student['name']).toList(),
            'timestamp': FieldValue.serverTimestamp(),
          });

          setState(() {
            _students.clear();
            _selectedSubjects.clear();
            _selectedClassName = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم حفظ القسم بنجاح!')),
          );

          Navigator.pop(context);
        } catch (e) {
          print("Erreur lors de l'enregistrement : $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('يرجى ملء جميع الحقول.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('المستخدم غير متصل')),
      );
    }
  }

  Widget _buildSubjectCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('2. اختر المواد',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey)),
        SizedBox(height: 10),
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: _subjects.map((subject) {
                return CheckboxListTile(
                  title: Text(subject['name'] ?? 'غير معروف',
                      style: TextStyle(fontSize: 16)),
                  value: _selectedSubjects.contains(subject['id']),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedSubjects.add(subject['id']!);
                      } else {
                        _selectedSubjects.remove(subject['id']);
                      }
                    });
                  },
                  activeColor: Colors.blueAccent,
                  checkColor: Colors.white,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadSubjects(String classId) async {
    try {
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('matieres')
          .get();

      if (classDoc.docs.isNotEmpty) {
        setState(() {
          _subjects.clear();
          _subjects.addAll(classDoc.docs.map((doc) {
            return {
              'id': doc.id,
              'name': doc['name'] as String,
            };
          }).toList());
        });
      } else {
        setState(() {
          _subjects.clear();
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération des matières : $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la récupération des matières')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة المواد', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
        elevation: 4,
        actions: [
          // Affichage de la limite
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.light, color: Colors.white, size: 18),
                SizedBox(width: 4),
                Text(
                  'الحد: $_userClassLimit',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. اختر القسم',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedClassName,
                      items: _filteredClassNames.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, String> classData = entry.value;
                        Color color =
                            groupColors[(index ~/ 5) % groupColors.length];
                        return DropdownMenuItem<String>(
                          value: classData['id'],
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.school, color: color),
                                SizedBox(width: 10),
                                Text(
                                  classData['name'] ?? 'اسم غير معروف',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setState(() {
                          _selectedClassName = value;
                          _selectedClassNameDisplay = _classNames.firstWhere(
                            (classData) => classData['id'] == value,
                            orElse: () => {'name': 'اسم غير معروف'},
                          )['name'];
                        });
                        if (value != null) {
                          await _loadSubjects(value);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'اختر القسم',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.blue),
                      dropdownColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            if (_selectedClassNameDisplay != null)
              Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: groupColors[(_filteredClassNames.indexWhere(
                                  (classData) =>
                                      classData['id'] == _selectedClassName) ~/
                              5) %
                          groupColors.length]
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: groupColors[(_filteredClassNames.indexWhere(
                                    (classData) =>
                                        classData['id'] ==
                                        _selectedClassName) ~/
                                5) %
                            groupColors.length]
                        .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.school,
                        color: groupColors[(_filteredClassNames.indexWhere(
                                    (classData) =>
                                        classData['id'] ==
                                        _selectedClassName) ~/
                                5) %
                            groupColors.length]),
                    SizedBox(width: 10),
                    Text(
                      _selectedClassNameDisplay!,
                      style: TextStyle(
                        color: groupColors[(_filteredClassNames.indexWhere(
                                    (classData) =>
                                        classData['id'] ==
                                        _selectedClassName) ~/
                                5) %
                            groupColors.length],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 20),
            _buildSubjectCheckboxes(),
          ],
        ),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (_selectedClassName != null && _selectedSubjects.isNotEmpty)
            ? () async {
                await _saveClassData(_selectedClassNameDisplay);
              }
            : null,
        backgroundColor: (_selectedClassName != null && _selectedSubjects.isNotEmpty)
            ? Colors.blueAccent
            : Colors.grey,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: Icon(Icons.check_circle),
        label: Text('تأكيد الإضافة'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}