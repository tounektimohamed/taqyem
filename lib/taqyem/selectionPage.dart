import 'dart:convert';
import 'package:Taqyem/taqyem/AddStudentPage.dart';
import 'package:Taqyem/taqyem/listedeselection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Taqyem/taqyem/tableau.dart';

// Classe utilitaire pour la traduction et la détection de langue
class DataTranslator {
  static final Map<String, String> _classTranslations = {
    "السنة الأولى ابتدائي": "1ère année primaire",
    "السنة الأولى ابتدائي أ": "1ère année primaire A",
    "السنة الأولى ابتدائي ب": "1ère année primaire B",
    "السنة الأولى ابتدائي ج": "1ère année primaire C",
    "السنة الأولى ابتدائي د": "1ère année primaire D",
    "السنة الثانية ابتدائي": "2ème année primaire",
    "السنة الثانية ابتدائي أ": "2ème année primaire A",
    "السنة الثانية ابتدائي ب": "2ème année primaire B",
    "السنة الثانية ابتدائي ج": "2ème année primaire C",
    "السنة الثانية ابتدائي د": "2ème année primaire D",
    "السنة الثالثة ابتدائي": "3ème année primaire",
    "السنة الثالثة ابتدائي أ": "3ème année primaire A",
    "السنة الثالثة ابتدائي ب": "3ème année primaire B",
    "السنة الثالثة ابتدائي ج": "3ème année primaire C",
    "السنة الثالثة ابتدائي د": "3ème année primaire D",
    "السنة الرابعة ابتدائي": "4ème année primaire",
    "السنة الرابعة ابتدائي أ": "4ème année primaire A",
    "السنة الرابعة ابتدائي ب": "4ème année primaire B",
    "السنة الرابعة ابتدائي ج": "4ème année primaire C",
    "السنة الرابعة ابتدائي د": "4ème année primaire D",
    "السنة الخامسة ابتدائي": "5ème année primaire",
    "السنة الخامسة ابتدائي أ": "5ème année primaire A",
    "السنة الخامسة ابتدائي ب": "5ème année primaire B",
    "السنة الخامسة ابتدائي ج": "5ème année primaire C",
    "السنة الخامسة ابتدائي د": "5ème année primaire D",
    "السنة السادسة ابتدائي": "6ème année primaire",
    "السنة السادسة ابتدائي أ": "6ème année primaire A",
    "السنة السادسة ابتدائي ب": "6ème année primaire B",
    "السنة السادسة ابتدائي ج": "6ème année primaire C",
    "السنة السادسة ابتدائي د": "6ème année primaire D"
  };

  static final Map<String, String> _matiereTranslations = {
    "التواصل الشفوي": "Communication orale",
    "قراءة": "Lecture",
    "انتاج كتابي": "Production écrite",
    "رياضيات": "Mathématiques",
    "ايقاظ علمي": "Éveil scientifique",
    "تربية اسلامية": "Éducation islamique",
    "تربية تكنولوجية": "Éducation technologique",
    "تربية موسيقية": "Éducation musicale",
    "تربية تشكيلية": "Éducation artistique",
    "تربية بدنية": "Éducation physique",
    "قواعد لغة": "Grammaire",
    "Expression orale et récitation": "Expression orale et récitation",
    "Lecture": "Lecture",
    "Production écrite": "Production écrite",
    "écriture": "Écriture",
    "dictée": "Dictée",
    "langue": "Langue",
    "لغة انقليزية": "Anglais",
    "التاريخ": "Histoire",
    "الجغرافيا": "Géographie",
    "التربية المدنية": "Éducation civique"
  };

  static final Map<String, String> _baremeTranslations = {
    "مع 1": "C1",
    "مع 2": "C2",
    "مع 3": "C3",
    "مع 4": "C4",
    "مع 5": "C5",
    "مع 1.1": "C1.1",
    "مع 1.2": "C1.2",
    "مع 1.3": "C1.3",
    "مع 2.1": "C2.1",
    "مع 2.2": "C2.2",
    "مع 2.3": "C2.3",
    "مع 3.1": "C3.1",
    "مع 3.2": "C3.2",
    "مع 3.3": "C3.3",
    "مع 4.1": "C4.1",
    "مع 4.2": "C4.2",
    "مع 4.3": "C4.3",
    "مع 5.1": "C5.1",
    "مع 5.2": "C5.2",
    "مع 5.3": "C5.3"
  };

  // Liste des matières considérées comme étrangères (doivent être en français)
  static final List<String> _foreignMatieres = [
    "Expression orale et récitation",
    "Lecture",
    "Production écrite",
    "écriture",
    "dictée",
    "langue",
    "لغة انقليزية"
  ];

  // Détecter si une matière est étrangère
  static bool isForeignMatiere(String matiereName) {
    return _foreignMatieres.contains(matiereName);
  }

  // Traduire le nom d'une classe
  static String translateClass(String arabicName) {
    return _classTranslations[arabicName] ?? arabicName;
  }

  // Traduire le nom d'une matière
  static String translateMatiere(String arabicName) {
    return _matiereTranslations[arabicName] ?? arabicName;
  }

  // Traduire un critère/barème
  static String translateBareme(String arabicName) {
    return _baremeTranslations[arabicName] ?? arabicName;
  }

  // Traduire un sous-critère
  static String translateSousBareme(String arabicName) {
    return _baremeTranslations[arabicName] ?? arabicName;
  }

  // Obtenir le nom original arabe à partir de la traduction française
  static String getArabicClassFromFrench(String frenchName) {
    return _classTranslations.entries
        .firstWhere((entry) => entry.value == frenchName,
            orElse: () => MapEntry(frenchName, frenchName))
        .key;
  }

  static String getArabicMatiereFromFrench(String frenchName) {
    return _matiereTranslations.entries
        .firstWhere((entry) => entry.value == frenchName,
            orElse: () => MapEntry(frenchName, frenchName))
        .key;
  }
}

class BaremesPage extends StatefulWidget {
  final String selectedClass;
  final String selectedMatiere;
  final String matiereName;
    final bool autoNavigateToStudentList; // Nouveau paramètre


  BaremesPage({
    required this.selectedClass,
    required this.selectedMatiere,
    required this.matiereName,
        this.autoNavigateToStudentList = false, // Valeur par défaut

  });

  @override
  _BaremesPageState createState() => _BaremesPageState();
}

class _BaremesPageState extends State<BaremesPage> {
  Map<String, bool> _selectedBaremes = {};
  Map<String, Map<String, bool>> _selectedSousBaremes = {};
  bool _isLoading = true;
  bool _isFrenchInterface = false;
@override
void initState() {
  super.initState();
  _detectLanguage();
  _loadExistingSelections();
  _showUtilityDialog();
  
  // Navigation automatique si demandée
  if (widget.autoNavigateToStudentList) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToStudentList();
    });
  }
}

  void _detectLanguage() {
    setState(() {
      _isFrenchInterface = DataTranslator.isForeignMatiere(widget.matiereName);
    });
  }

  Future<void> _showUtilityDialog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastShownDate = prefs.getString('lastShownUtilityDate');
    DateTime now = DateTime.now();
    String today = "${now.year}-${now.month}-${now.day}";

    if (lastShownDate != today) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 48,
                    color: Colors.blue.shade700,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _isFrenchInterface
                        ? 'Informations sur l\'interface'
                        : 'معلومات عن الواجهة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    _isFrenchInterface
                        ? 'Cette interface vous permet de sélectionner les critères et indicateurs pour la classe et la matière choisies. '
                            'Vous pouvez sélectionner les critères et indicateurs et les sauvegarder pour les consulter ultérieurement.'
                        : 'هذه الواجهة تتيح لك اختيار المعايير والمؤشرات للقسم والمادة المحددة. '
                            'يمكنك تحديد المعايير والمؤشرات وحفظها للرجوع إليها لاحقًا.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        _isFrenchInterface ? 'Compris' : 'موافق',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      await prefs.setString('lastShownUtilityDate', today);
    }
  }

  void _toggleBaremeSelection(String baremeId) {
    setState(() {
      if (_selectedBaremes[baremeId] ?? false) {
        _selectedBaremes[baremeId] = false;
        if (_selectedSousBaremes.containsKey(baremeId)) {
          _selectedSousBaremes[baremeId]!.forEach((sousBaremeId, isSelected) {
            _selectedSousBaremes[baremeId]![sousBaremeId] = false;
          });
        }
      } else {
        _selectedBaremes[baremeId] = true;
      }
    });
  }

  Future<void> _loadExistingSelections() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (userId.isEmpty) {
        throw Exception(_isFrenchInterface
            ? 'Utilisateur non connecté'
            : 'المستخدم غير مسجل الدخول');
      }

      var selectionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere);

      var baremesSnapshot = await selectionsRef.get();
      for (var baremeDoc in baremesSnapshot.docs) {
        var baremeId = baremeDoc['baremeId'];
        _selectedBaremes[baremeId] = true;

        var sousBaremesSnapshot =
            await baremeDoc.reference.collection('sousBaremes').get();
        for (var sousBaremeDoc in sousBaremesSnapshot.docs) {
          var sousBaremeId = sousBaremeDoc.id;
          if (!_selectedSousBaremes.containsKey(baremeId)) {
            _selectedSousBaremes[baremeId] = {};
          }
          _selectedSousBaremes[baremeId]![sousBaremeId] = true;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print(
          '${_isFrenchInterface ? 'Erreur lors du chargement des sélections existantes' : 'خطأ في تحميل التحديدات الموجودة'}: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSousBaremeSelection(String baremeId, String sousBaremeId) {
    setState(() {
      if (!_selectedSousBaremes.containsKey(baremeId)) {
        _selectedSousBaremes[baremeId] = {};
      }
      _selectedSousBaremes[baremeId]![sousBaremeId] =
          !(_selectedSousBaremes[baremeId]![sousBaremeId] ?? false);

      if (_selectedSousBaremes[baremeId]![sousBaremeId] ?? false) {
        _selectedBaremes[baremeId] = false;
      } else {
        bool allSousBaremesUnselected = _selectedSousBaremes[baremeId]!
            .values
            .every((isSelected) => !isSelected);
        if (allSousBaremesUnselected) {
          _selectedBaremes[baremeId] = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isFrenchInterface
              ? 'Critères et Indicateurs'
              : 'المعايير و المؤشرات',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () => _navigateToStudentList(),
              icon: Icon(Icons.people_alt, size: 20),
              label: Text(
                _isFrenchInterface ? 'Liste Étudiants' : 'قائمة التلاميذ',
                style: TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600, // Couleur différente
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 3,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _saveSelections,
              icon: Icon(Icons.save, size: 20),
              label: Text(
                _isFrenchInterface ? 'Sauvegarder' : 'حفظ',
                style: TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 3,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: Icon(Icons.table_chart, size: 20),
              label: Text(
                _isFrenchInterface ? 'Afficher le tableau' : 'عرض الجدول',
                style: TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 3,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DynamicTablePage(
                    selectedClass: widget.selectedClass,
                    selectedMatiere: widget.selectedMatiere,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _isFrenchInterface
                        ? 'Chargement des critères...'
                        : 'جاري تحميل المعايير...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.selectedClass)
                  .collection('matieres')
                  .doc(widget.selectedMatiere)
                  .collection('baremes')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _isFrenchInterface
                              ? 'Erreur de chargement des données'
                              : 'خطأ في تحميل البيانات',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _isFrenchInterface
                              ? 'Aucun critère trouvé'
                              : 'لم يتم العثور على أي معايير',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var bareme = snapshot.data!.docs[index];
                    var baremeId = bareme.id;
                    var baremeValue = bareme['value'];

                    // Traduire le nom du critère si l'interface est en français
                    String displayedBareme = _isFrenchInterface
                        ? DataTranslator.translateBareme(baremeValue)
                        : baremeValue;

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ExpansionTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.assessment_outlined,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Transform.scale(
                                scale: 1.2,
                                child: Checkbox(
                                  value: _selectedBaremes[baremeId] ?? false,
                                  onChanged: (_selectedSousBaremes[baremeId]
                                              ?.values
                                              .any(
                                                  (isSelected) => isSelected) ??
                                          false)
                                      ? null
                                      : (bool? value) {
                                          _toggleBaremeSelection(baremeId);
                                        },
                                  activeColor: Colors.blue.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  displayedBareme,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          children: [
                            FutureBuilder<QuerySnapshot>(
                              future: bareme.reference
                                  .collection('sousBaremes')
                                  .get(),
                              builder: (context, sousSnapshot) {
                                if (sousSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.blue.shade700),
                                      ),
                                    ),
                                  );
                                }
                                if (sousSnapshot.hasError) {
                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        _isFrenchInterface
                                            ? 'Erreur de chargement des indicateurs'
                                            : 'خطأ في تحميل المؤشرات',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  );
                                }
                                if (!sousSnapshot.hasData ||
                                    sousSnapshot.data!.docs.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        _isFrenchInterface
                                            ? 'Aucun indicateur'
                                            : 'لا توجد مؤشرات',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: sousSnapshot.data!.docs.length,
                                  itemBuilder: (context, sousIndex) {
                                    var sousBareme =
                                        sousSnapshot.data!.docs[sousIndex];
                                    var sousBaremeId = sousBareme.id;
                                    var sousBaremeName = sousBareme['name'];

                                    // Traduire le nom du sous-critère si l'interface est en français
                                    String displayedSousBareme =
                                        _isFrenchInterface
                                            ? DataTranslator
                                                .translateSousBareme(
                                                    sousBaremeName)
                                            : sousBaremeName;

                                    return Container(
                                      margin: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      child: Card(
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        color: Colors.grey.shade50,
                                        child: ListTile(
                                          leading: Transform.scale(
                                            scale: 1.2,
                                            child: Checkbox(
                                              value:
                                                  _selectedSousBaremes[baremeId]
                                                          ?[sousBaremeId] ??
                                                      false,
                                              onChanged: (bool? value) {
                                                _toggleSousBaremeSelection(
                                                    baremeId, sousBaremeId);
                                              },
                                              activeColor:
                                                  Colors.green.shade600,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            displayedSousBareme,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          trailing: Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 16,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _saveSelections() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (userId.isEmpty) {
        throw Exception('Utilisateur non connecté');
      }

      CollectionReference selectionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere);

      var oldSelections = await selectionsRef.get();
      for (var doc in oldSelections.docs) {
        var sousBaremesRef = doc.reference.collection('sousBaremes');
        var sousBaremesSnapshot = await sousBaremesRef.get();
        for (var sousDoc in sousBaremesSnapshot.docs) {
          await sousDoc.reference.delete();
        }
        await doc.reference.delete();
      }

      _selectedBaremes.forEach((baremeId, isSelected) async {
        if (isSelected) {
          String baremeName = await _getBaremeName(baremeId);
          await selectionsRef.doc(baremeId).set({
            'baremeId': baremeId,
            'baremeName': baremeName,
            'classId': widget.selectedClass,
            'matiereId': widget.selectedMatiere,
            'selected': true,
            'selectedAt': DateTime.now(),
          });
        }
      });

      _selectedSousBaremes.forEach((baremeId, sousBaremesMap) async {
        sousBaremesMap.forEach((sousBaremeId, isSelected) async {
          if (isSelected) {
            DocumentReference baremeDocRef = selectionsRef.doc(baremeId);
            DocumentSnapshot baremeDoc = await baremeDocRef.get();

            if (!baremeDoc.exists) {
              String baremeName = await _getBaremeName(baremeId);
              await baremeDocRef.set({
                'baremeId': baremeId,
                'baremeName': baremeName,
                'classId': widget.selectedClass,
                'matiereId': widget.selectedMatiere,
                'selected': false,
                'selectedAt': DateTime.now(),
              });
            }

            String sousBaremeName =
                await _getSousBaremeName(baremeId, sousBaremeId);
            await baremeDocRef.collection('sousBaremes').doc(sousBaremeId).set({
              'sousBaremeId': sousBaremeId,
              'sousBaremeName': sousBaremeName,
              'selected': true,
              'selectedAt': DateTime.now(),
            });
          }
        });
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectedBaremesPage(
            selectedClass: widget.selectedClass,
            selectedMatiere: widget.selectedMatiere,
            matiereName: widget.matiereName,
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('تم حفظ الاختيارات بنجاح!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('خطأ في الحفظ: $e'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _navigateToStudentList() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (userId.isEmpty) {
        throw Exception(_isFrenchInterface
            ? 'Utilisateur non connecté'
            : 'المستخدم غير مسجل الدخول');
      }

      // 1. Vérifier/Créer la classe dans user_classes
      final classDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('user_classes')
          .doc(widget.selectedClass)
          .get();

      if (!classDoc.exists) {
        // Obtenir le nom de la classe
        final originalClassDoc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.selectedClass)
            .get();

        String className = originalClassDoc.exists
            ? originalClassDoc['name']
            : widget.selectedClass;

        // Créer la classe dans user_classes
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('user_classes')
            .doc(widget.selectedClass)
            .set({
          'class_id': widget.selectedClass,
          'class_name': className,
          'subjects': [],
          'students': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Vérifier/Ajouter la matière
      final classData = classDoc.exists ? classDoc.data() : null;
      List<Map<String, dynamic>> subjects = [];
      if (classData != null && classData['subjects'] != null) {
        subjects = List<Map<String, dynamic>>.from(classData['subjects']);
      }

      // Obtenir le nom de la matière
      final matiereDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .get();

      String matiereName =
          matiereDoc.exists ? matiereDoc['name'] : widget.matiereName;
      String displayedMatiereName = _isFrenchInterface
          ? DataTranslator.translateMatiere(matiereName)
          : matiereName;

      // Vérifier si la matière est déjà dans la liste
      bool subjectExists =
          subjects.any((subject) => subject['id'] == widget.selectedMatiere);

      if (!subjectExists) {
        // Ajouter la matière à la classe
        subjects.add({
          'id': widget.selectedMatiere,
          'name': displayedMatiereName,
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('user_classes')
            .doc(widget.selectedClass)
            .update({
          'subjects': subjects,
        });
      }

      // 3. Naviguer vers ManageClassesPage avec pré-sélection
      ManageClassesPage.navigateToStudentList(
        context,
        classId: widget.selectedClass,
        matiereId: widget.selectedMatiere,
        className: classData?['class_name'] ?? widget.selectedClass,
        matiereName: displayedMatiereName,
      );
    } catch (e) {
      print('Erreur lors de la navigation vers la liste des étudiants: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFrenchInterface
                ? 'Erreur lors de la navigation: $e'
                : 'خطأ في التنقل: $e',
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<String> _getBaremeName(String baremeId) async {
    try {
      var baremeDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .collection('baremes')
          .doc(baremeId)
          .get();
      String arabicName = baremeDoc['value'];
      return _isFrenchInterface
          ? DataTranslator.translateBareme(arabicName)
          : arabicName;
    } catch (e) {
      print(
          '${_isFrenchInterface ? 'Erreur lors de la récupération du nom du critère' : 'خطأ في استرجاع اسم المعيار'}: $e');
      return '';
    }
  }

  Future<String> _getSousBaremeName(
      String baremeId, String sousBaremeId) async {
    try {
      var sousBaremeDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .collection('baremes')
          .doc(baremeId)
          .collection('sousBaremes')
          .doc(sousBaremeId)
          .get();
      String arabicName = sousBaremeDoc['name'];
      return _isFrenchInterface
          ? DataTranslator.translateSousBareme(arabicName)
          : arabicName;
    } catch (e) {
      print(
          '${_isFrenchInterface ? 'Erreur lors de la récupération du nom de l\'indicateur' : 'خطأ في استرجاع اسم المؤشر'}: $e');
      return '';
    }
  }
}

class SelectionPage extends StatefulWidget {
  final String? preSelectedClassId;
  final String? preSelectedMatiereId;

  const SelectionPage({
    Key? key,
    this.preSelectedClassId,
    this.preSelectedMatiereId,
  }) : super(key: key);

  @override
  _SelectionPageState createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  String? selectedClassId;
  String? selectedClassName;
  String? selectedMatiereId;
  String? selectedMatiereName;
  List<Map<String, String>> classes = [];
  List<Map<String, String>> matieres = [];
  List<Map<String, dynamic>> lastAccessList = [];
  bool _isLoading = true;

  final List<Color> groupColors = [
    Colors.blue.shade700,
    Colors.green.shade700,
    Colors.orange.shade700,
    Colors.purple.shade700,
    Colors.red.shade700,
    Colors.teal.shade700,
    Colors.indigo.shade700,
    Colors.amber.shade700,
    Colors.deepPurple.shade700,
    Colors.lightGreen.shade700,
  ];

  @override
  void initState() {
    super.initState();

    // Initialiser avec les valeurs présélectionnées si fournies
    if (widget.preSelectedClassId != null &&
        widget.preSelectedMatiereId != null) {
      selectedClassId = widget.preSelectedClassId;
      selectedMatiereId = widget.preSelectedMatiereId;

      // Charger les données initiales
      _initializeDataWithPreselection();
    } else {
      _initializeData();
    }
  }

  Future<void> _initializeDataWithPreselection() async {
    try {
      // 1. Charger les classes
      await fetchClasses();

      // 2. Trouver la classe correspondante
      if (selectedClassId != null) {
        final classDoc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(selectedClassId!)
            .get();

        if (classDoc.exists) {
          selectedClassName = classDoc['name'];

          // 3. Charger les matières pour cette classe
          await fetchMatieres(selectedClassId!);

          // 4. Trouver la matière correspondante
          if (selectedMatiereId != null) {
            final matiereDoc = await FirebaseFirestore.instance
                .collection('classes')
                .doc(selectedClassId!)
                .collection('matieres')
                .doc(selectedMatiereId!)
                .get();

            if (matiereDoc.exists) {
              selectedMatiereName = matiereDoc['name'];
            }
          }
        }
      }

      // 5. Charger l'historique
      await _loadLastAccessList();

      // 6. Ajouter à l'historique si ce n'est pas déjà fait
      if (selectedClassId != null && selectedMatiereId != null) {
        final exists = lastAccessList.any((access) =>
            access['classId'] == selectedClassId &&
            access['matiereId'] == selectedMatiereId);

        if (!exists) {
          await _saveLastAccess();
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors de l\'initialisation avec présélection: $e');
      // Retourner à l'initialisation normale
      await _initializeData();
    }
  }

  Future<void> _initializeData() async {
    await fetchClasses();
    await _loadLastAccessList();
    await _showIntroDialog();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchClasses() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('classes').get();
      setState(() {
        classes = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['name'] as String,
                  'translatedName':
                      DataTranslator.translateClass(doc['name'] as String)
                })
            .toList()
          ..sort((a, b) => a['name']!
              .toLowerCase()
              .compareTo(b['name']!.toLowerCase())); // Trier par nom arabe
      });
    } catch (e) {
      print('Erreur lors de la récupération des classes: $e');
    }
  }

  Future<void> fetchMatieres(String classId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('matieres')
          .get();
      setState(() {
        matieres = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['name'] as String,
                  'translatedName':
                      DataTranslator.translateMatiere(doc['name'] as String)
                })
            .toList()
          ..sort((a, b) => a['name']!
              .toLowerCase()
              .compareTo(b['name']!.toLowerCase())); // Trier par nom arabe
      });
    } catch (e) {
      print('Erreur lors de la récupération des matières: $e');
    }
  }

  Future<void> _saveLastAccess() async {
    if (selectedClassId == null || selectedMatiereId == null) return;

    final newAccess = {
      'classId': selectedClassId,
      'className': selectedClassName,
      'matiereId': selectedMatiereId,
      'matiereName': selectedMatiereName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final existingIndex = lastAccessList.indexWhere((access) =>
        access['classId'] == selectedClassId &&
        access['matiereId'] == selectedMatiereId);

    setState(() {
      if (existingIndex != -1) {
        lastAccessList[existingIndex] = newAccess;
      } else {
        lastAccessList.insert(0, newAccess);
        if (lastAccessList.length > 5) {
          lastAccessList = lastAccessList.sublist(0, 5);
        }
      }
    });

    await _saveLastAccessList();
  }

  Future<void> _saveLastAccessList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastAccessList', json.encode(lastAccessList));
  }

  Future<void> _loadLastAccessList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('lastAccessList');
    if (data != null) {
      setState(() {
        lastAccessList = List<Map<String, dynamic>>.from(json.decode(data));
      });
    }
  }

  Future<void> _showIntroDialog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastShownDate = prefs.getString('lastShownDate');
    DateTime now = DateTime.now();
    String today = "${now.year}-${now.month}-${now.day}";

    if (lastShownDate != today) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.waving_hand_rounded,
                    size: 48,
                    color: Colors.blue.shade700,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'مرحبًا بك!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'سيتم حفظ آخر 5 اختيارات للوصول السريع تلقائياً.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        'ابدأ الآن',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      await prefs.setString('lastShownDate', today);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double padding = screenWidth > 600 ? 32.0 : 20.0;
    double fontSize = screenWidth > 600 ? 18.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'اختر قسما ومادة',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'جاري التحميل...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (lastAccessList.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.blue.shade50, Colors.grey.shade50],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  color: Colors.blue.shade700,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'آخر الاختيارات',
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            ...lastAccessList.asMap().entries.map((entry) {
                              final index = entry.key;
                              final access = entry.value;
                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                child: Material(
                                  borderRadius: BorderRadius.circular(12),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: groupColors[
                                                index % groupColors.length]
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.school_rounded,
                                        color: groupColors[
                                            index % groupColors.length],
                                      ),
                                    ),
                                    title: Text(
                                      access['className'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      access['matiereName'] ?? '',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: Colors.grey.shade400,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        selectedClassId = access['classId'];
                                        selectedClassName = access['className'];
                                        selectedMatiereId = access['matiereId'];
                                        selectedMatiereName =
                                            access['matiereName'];
                                      });
                                      fetchMatieres(access['classId'])
                                          .then((_) {});
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      Divider(
                        thickness: 1,
                        color: Colors.grey.shade300,
                        height: 20,
                      ),
                      SizedBox(height: 10),
                    ],

                    // Dropdown pour les classes - Afficher les noms arabes
                    Container(
                      margin: EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: 8, right: 4),
                            child: Text(
                              'اختر القسم',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 4.0),
                              child: DropdownButton<String>(
                                value:
                                    selectedClassName, // Utiliser le nom arabe directement
                                hint: Text(
                                  'اختر قسما',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                                items: classes.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  Map<String, String> classe = entry.value;
                                  Color color = groupColors[
                                      (index ~/ 5) % groupColors.length];
                                  return DropdownMenuItem<String>(
                                    value: classe['name'], // Valeur = nom arabe
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: color.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.school_rounded,
                                              color: color),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              classe[
                                                  'name']!, // Afficher le nom arabe
                                              style: TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedClassName = newValue;
                                    selectedClassId = classes.firstWhere(
                                      (classe) => classe['name'] == newValue,
                                      orElse: () => {'id': '', 'name': ''},
                                    )['id'];
                                    selectedMatiereId = null;
                                    selectedMatiereName = null;
                                    matieres.clear();
                                  });
                                  if (selectedClassId != null &&
                                      selectedClassId!.isNotEmpty) {
                                    fetchMatieres(selectedClassId!);
                                  }
                                },
                                isExpanded: true,
                                underline: SizedBox(),
                                icon: Icon(Icons.arrow_drop_down_rounded,
                                    color: Colors.blue.shade700),
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dropdown pour les matières - Afficher les noms arabes
                    Container(
                      margin: EdgeInsets.only(bottom: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: 8, right: 4),
                            child: Text(
                              'اختر المادة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 4.0),
                              child: DropdownButton<String>(
                                value:
                                    selectedMatiereName, // Utiliser le nom arabe directement
                                hint: Text(
                                  'اختر مادة',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                                items:
                                    matieres.map((Map<String, String> matiere) {
                                  return DropdownMenuItem<String>(
                                    value:
                                        matiere['name'], // Valeur = nom arabe
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      child: Text(
                                        matiere[
                                            'name']!, // Afficher le nom arabe
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedMatiereName = newValue;
                                    selectedMatiereId = matieres.firstWhere(
                                      (matiere) => matiere['name'] == newValue,
                                      orElse: () => {'id': '', 'name': ''},
                                    )['id'];
                                  });
                                },
                                isExpanded: true,
                                underline: SizedBox(),
                                icon: Icon(Icons.arrow_drop_down_rounded,
                                    color: Colors.blue.shade700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Boutons d'action - Toujours en arabe
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: screenWidth > 600 ? 20.0 : 12.0,
                      runSpacing: 12.0,
                      children: [
                        _buildActionButton(
                          'عرض المعايير',
                          Icons.list_alt_rounded,
                          Colors.blue.shade700,
                          () async {
                            if (selectedClassId != null &&
                                selectedMatiereId != null) {
                              await _saveLastAccess();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SelectedBaremesPage(
                                    selectedClass: selectedClassId!,
                                    selectedMatiere: selectedMatiereId!,
                                    matiereName: selectedMatiereName!,
                                  ),
                                ),
                              );
                            } else {
                              _showErrorSnackbar('الرجاء اختيار قسم و مادة');
                            }
                          },
                        ),
                        _buildActionButton(
                          'برمجة المعايير',
                          Icons.tune_rounded,
                          Colors.green.shade700,
                          () async {
                            if (selectedClassId != null &&
                                selectedMatiereId != null) {
                              await _saveLastAccess();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BaremesPage(
                                    selectedClass: selectedClassId!,
                                    selectedMatiere: selectedMatiereId!,
                                    matiereName: selectedMatiereName!,
                                  ),
                                ),
                              );
                            } else {
                              _showErrorSnackbar('الرجاء اختيار قسم و مادة');
                            }
                          },
                        ),
                        _buildActionButton(
                          'عرض الجدول',
                          Icons.table_chart_rounded,
                          Colors.orange.shade700,
                          () async {
                            if (selectedClassId != null &&
                                selectedMatiereId != null) {
                              await _saveLastAccess();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DynamicTablePage(
                                    selectedClass: selectedClassId!,
                                    selectedMatiere: selectedMatiereId!,
                                  ),
                                ),
                              );
                            } else {
                              _showErrorSnackbar('الرجاء اختيار قسم و مادة');
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: 160,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: color.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }
}

class SelectedBaremesPage extends StatefulWidget {
  final String selectedClass;
  final String selectedMatiere;
  final String matiereName;

  SelectedBaremesPage({
    required this.selectedClass,
    required this.selectedMatiere,
    required this.matiereName,
  });

  @override
  _SelectedBaremesPageState createState() => _SelectedBaremesPageState();
}

class _SelectedBaremesPageState extends State<SelectedBaremesPage> {
  bool _isLoading = true;
  bool _isFrenchInterface = false;

  @override
  void initState() {
    super.initState();
    _detectLanguage();
    _showUtilityDialog();
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _detectLanguage() {
    setState(() {
      _isFrenchInterface = DataTranslator.isForeignMatiere(widget.matiereName);
    });
  }

  Future<void> _showUtilityDialog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastShownDate = prefs.getString('lastShownUtilityDate');
    DateTime now = DateTime.now();
    String today = "${now.year}-${now.month}-${now.day}";

    if (lastShownDate != today) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_rounded,
                    size: 48,
                    color: Colors.blue.shade700,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _isFrenchInterface
                        ? 'Informations sur l\'interface'
                        : 'معلومات عن الواجهة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildInfoItem(
                      Icons.list_alt_rounded,
                      _isFrenchInterface
                          ? 'Cette interface affiche les critères et indicateurs sélectionnés'
                          : 'هذه الواجهة تعرض المعايير والمؤشرات المحددة'),
                  SizedBox(height: 12),
                  _buildInfoItem(
                      Icons.table_chart_rounded,
                      _isFrenchInterface
                          ? 'Cliquez sur le bouton tableau pour afficher les données sous forme de tableau'
                          : 'اضغط على زر الجدول لعرض البيانات بشكل جدولي'),
                  SizedBox(height: 12),
                  _buildInfoItem(
                      Icons.settings_rounded,
                      _isFrenchInterface
                          ? 'Vous pouvez revenir pour modifier les sélections à tout moment'
                          : 'يمكنك الرجوع لتعديل الاختيارات في أي وقت'),
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        _isFrenchInterface ? 'Compris' : 'فهمت',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      await prefs.setString('lastShownUtilityDate', today);
    }
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _isFrenchInterface ? 'Critères Sélectionnés' : 'المعايير المحددة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue.shade700,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 64, color: Colors.orange.shade600),
              SizedBox(height: 20),
              Text(
                _isFrenchInterface
                    ? 'Vous devez vous connecter pour afficher les critères sélectionnés'
                    : 'يجب تسجيل الدخول لعرض المعايير المحددة',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  _isFrenchInterface ? 'Retour' : 'العودة',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isFrenchInterface ? 'Critères Sélectionnés' : 'المعايير المحددة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () => _navigateToStudentList(),
              icon: Icon(Icons.people_alt, size: 20),
              label: Text(
                _isFrenchInterface ? 'Liste Étudiants' : 'قائمة التلاميذ',
                style: TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600, // Couleur différente
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 3,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: Icon(Icons.table_chart_rounded, size: 20),
              label: Text(
                _isFrenchInterface ? 'Afficher le tableau' : 'عرض الجدول',
                style: TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 3,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DynamicTablePage(
                    selectedClass: widget.selectedClass,
                    selectedMatiere: widget.selectedMatiere,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _isFrenchInterface
                        ? 'Chargement des critères...'
                        : 'جاري تحميل المعايير...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : _buildContent(userId),
      floatingActionButton: Container(
        height: 56,
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          icon: Icon(Icons.table_chart_rounded, size: 24),
          label: Text(
            _isFrenchInterface
                ? 'Afficher le tableau complet'
                : 'عرض الجدول الجامع',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          elevation: 6,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DynamicTablePage(
                selectedClass: widget.selectedClass,
                selectedMatiere: widget.selectedMatiere,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _navigateToStudentList() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (userId.isEmpty) {
        throw Exception(_isFrenchInterface
            ? 'Utilisateur non connecté'
            : 'المستخدم غير مسجل الدخول');
      }

      // 1. Vérifier/Créer la classe dans user_classes
      final classDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('user_classes')
          .doc(widget.selectedClass)
          .get();

      if (!classDoc.exists) {
        // Obtenir le nom de la classe
        final originalClassDoc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.selectedClass)
            .get();

        String className = originalClassDoc.exists
            ? originalClassDoc['name']
            : widget.selectedClass;

        // Créer la classe dans user_classes
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('user_classes')
            .doc(widget.selectedClass)
            .set({
          'class_id': widget.selectedClass,
          'class_name': className,
          'subjects': [],
          'students': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Vérifier/Ajouter la matière
      final classData = classDoc.exists ? classDoc.data() : null;
      List<Map<String, dynamic>> subjects = [];
      if (classData != null && classData['subjects'] != null) {
        subjects = List<Map<String, dynamic>>.from(classData['subjects']);
      }

      // Obtenir le nom de la matière
      final matiereDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .get();

      String matiereName =
          matiereDoc.exists ? matiereDoc['name'] : widget.matiereName;
      String displayedMatiereName = _isFrenchInterface
          ? DataTranslator.translateMatiere(matiereName)
          : matiereName;

      // Vérifier si la matière est déjà dans la liste
      bool subjectExists =
          subjects.any((subject) => subject['id'] == widget.selectedMatiere);

      if (!subjectExists) {
        // Ajouter la matière à la classe
        subjects.add({
          'id': widget.selectedMatiere,
          'name': displayedMatiereName,
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('user_classes')
            .doc(widget.selectedClass)
            .update({
          'subjects': subjects,
        });
      }

      // 3. Naviguer vers ManageClassesPage avec pré-sélection
      ManageClassesPage.navigateToStudentList(
        context,
        classId: widget.selectedClass,
        matiereId: widget.selectedMatiere,
        className: classData?['class_name'] ?? widget.selectedClass,
        matiereName: displayedMatiereName,
      );
    } catch (e) {
      print('Erreur lors de la navigation vers la liste des étudiants: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFrenchInterface
                ? 'Erreur lors de la navigation: $e'
                : 'خطأ في التنقل: $e',
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _buildContent(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 64, color: Colors.red.shade400),
                SizedBox(height: 16),
                Text(
                  _isFrenchInterface
                      ? 'Erreur de chargement des données'
                      : 'حدث خطأ في تحميل البيانات',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined,
                    size: 64, color: Colors.grey.shade400),
                SizedBox(height: 16),
                Text(
                  _isFrenchInterface
                      ? 'Aucun critère sélectionné pour le moment'
                      : 'لم يتم تحديد أي معايير بعد',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    _isFrenchInterface
                        ? 'Sélectionner des critères'
                        : 'تحديد المعايير',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            bool isBaremeSelected = doc['selected'] ?? false;
            String baremeName = doc['baremeName'] ?? '';

            // Traduire le nom du critère si l'interface est en français
            String displayedBaremeName = _isFrenchInterface
                ? DataTranslator.translateBareme(baremeName)
                : baremeName;

            return Column(
              children: [
                if (isBaremeSelected)
                  _buildBaremeCard(displayedBaremeName, true),
                _buildSousBaremesList(
                    doc.reference, displayedBaremeName, isBaremeSelected),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBaremeCard(String baremeName, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star_rounded,
              color: Colors.amber.shade600,
              size: 24,
            ),
          ),
          title: Text(
            baremeName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            _isFrenchInterface ? 'Critère principal' : 'معيار رئيسي',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          trailing: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: Colors.green.shade600,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSousBaremesList(
      DocumentReference docRef, String baremeName, bool isBaremeSelected) {
    return StreamBuilder<QuerySnapshot>(
      stream: docRef.collection('sousBaremes').snapshots(),
      builder: (context, sousSnapshot) {
        if (sousSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              ),
            ),
          );
        }

        if (sousSnapshot.hasError) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _isFrenchInterface
                  ? 'Erreur de chargement des indicateurs'
                  : 'خطأ في تحميل المؤشرات',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        var sousBaremes = sousSnapshot.data?.docs ?? [];
        if (sousBaremes.isEmpty) return SizedBox();

        return Column(
          children: sousBaremes.map((sousDoc) {
            String sousBaremeName = sousDoc['sousBaremeName'] ?? '';

            // Traduire le nom du sous-critère si l'interface est en français
            String displayedSousBaremeName = _isFrenchInterface
                ? DataTranslator.translateSousBareme(sousBaremeName)
                : sousBaremeName;

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.grey.shade50,
                child: ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.green.shade600,
                    ),
                  ),
                  title: Text(
                    displayedSousBaremeName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    isBaremeSelected
                        ? '${_isFrenchInterface ? 'Dépend de' : 'تابع لـ'} $baremeName'
                        : _isFrenchInterface
                            ? 'Indicateur'
                            : 'مؤشر',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green.shade400,
                    size: 20,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
