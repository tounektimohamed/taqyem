import 'dart:convert';

import 'package:Taqyem/screens2/admin/AccessLogsPage.dart';
import 'package:Taqyem/taqyem/AddClassPage.dart';
import 'package:Taqyem/taqyem/SubjectHelper.dart';
import 'package:Taqyem/taqyem/selectionPage.dart';
import 'package:Taqyem/taqyem/tableau.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class ManageClassesPage extends StatefulWidget {
  final String? preSelectedClassId;
  final String? preSelectedMatiereId;
  final bool? showStudentsForMatiere;

  const ManageClassesPage({
    Key? key,
    this.preSelectedClassId,
    this.preSelectedMatiereId,
    this.showStudentsForMatiere = false,
  }) : super(key: key);

  // Méthode statique pour naviguer avec pré-sélection
  static void navigateToStudentList(
    BuildContext context, {
    required String classId,
    required String matiereId,
    String? className,
    String? matiereName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageClassesPage(
          preSelectedClassId: classId,
          preSelectedMatiereId: matiereId,
          showStudentsForMatiere: true,
        ),
      ),
    );
  }

  @override
  _ManageClassesPageState createState() => _ManageClassesPageState();
}

class _ManageClassesPageState extends State<ManageClassesPage> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _subjects = [];
  Uint8List? _imageBytes;
  String? _photoUrl;
  bool _isLoadingSubjects = false;
  bool _isRefreshingSubjects = false;
  bool _isLoadingClasses = false;
  bool _isRefreshingClasses = false;
  String? _selectedSubject;
  List<Map<String, String>> _selectedSubjects = [];
  String? selectedClassId;
  String? selectedSubjectId;
  Map<String, dynamic>? _selectedClass;
  List<Map<String, dynamic>> _students = [];
  bool _showStudentsList = false;
  bool _showHelpSection = true;
  bool _isLoadingStudents = false;
  bool _isRefreshing = false;

  final Map<String, String> subjectImages = {
    'التواصل الشفوي': 'assets/images/oral.png',
    'قراءة': 'assets/images/reading.png',
    'انتاج كتابي': 'assets/images/writing.png',
    'قواعد لغة': 'assets/images/grammar.png',
    'رياضيات': 'assets/images/math.png',
    'ايقاظ علمي': 'assets/images/science.png',
    'تربية اسلامية': 'assets/images/islamic.png',
    'تربية تكنولوجية': 'assets/images/technology.png',
    'تربية موسيقية': 'assets/images/music.png',
    'تربية تشكيلية': 'assets/images/art.png',
    'تربية بدنية': 'assets/images/sport.png',
    'التاريخ': 'assets/images/history.png',
    'الجغرافيا': 'assets/images/geography.png',
    'التربية المدنية': 'assets/images/civics.png',
    'Expression orale et récitation': 'assets/images/french_oral.png',
    'Lecture': 'assets/images/french_reading.png',
    'Production écrite': 'assets/images/french_writing.png',
    'écriture': 'assets/images/french_writing2.png',
    'dictée': 'assets/images/dictation.png',
    'langue': 'assets/images/french_language.png',
    'لغة انقليزية': 'assets/images/english.png',
  };

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _fetchClasses().then((_) {
        // Après avoir chargé les classes, pré-sélectionner si nécessaire
        if (widget.preSelectedClassId != null &&
            widget.preSelectedMatiereId != null &&
            _classes.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _preSelectClassAndMatiere();
          });
        }
      });
    }
  }

  Future<void> _addMultipleStudentsDialog(
      Map<String, dynamic> classData) async {
    TextEditingController _studentsListController = TextEditingController();
    bool _isProcessing = false;
    int _successCount = 0;
    int _duplicateCount = 0;
    int _errorCount = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  if (_isProcessing)
                    Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      'إضافة قائمة تلاميذ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Zone de texte pour coller les noms
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _studentsListController,
                        maxLines: 8,
                        textAlign: TextAlign.right,
                        enabled: !_isProcessing,
                        decoration: InputDecoration(
                          hintText: 'أدخل أسماء التلاميذ\nكل اسم في سطر منفصل',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    // Exemple
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, size: 16, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'مثال:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'أحمد محمد\nفاطمة علي\nيوسف عمر\nسارة خالد',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 12),

                    // Statistiques après traitement
                    if (_successCount > 0 ||
                        _duplicateCount > 0 ||
                        _errorCount > 0)
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            if (_successCount > 0)
                              Text('✅ تمت الإضافة: $_successCount',
                                  style: TextStyle(color: Colors.green)),
                            if (_duplicateCount > 0)
                              Text('⚠️ موجود مسبقاً: $_duplicateCount',
                                  style: TextStyle(color: Colors.orange)),
                            if (_errorCount > 0)
                              Text('❌ خطأ: $_errorCount',
                                  style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      _isProcessing ? null : () => Navigator.pop(context),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                if (!_isProcessing)
                  ElevatedButton.icon(
                    icon: Icon(Icons.paste),
                    label: Text('لصق من الحافظة'),
                    onPressed: () async {
                      // Récupérer le texte du presse-papiers
                      final clipboardData =
                          await Clipboard.getData(Clipboard.kTextPlain);
                      if (clipboardData?.text != null) {
                        setState(() {
                          _studentsListController.text = clipboardData!.text!;
                        });
                      }
                    },
                  ),
                ElevatedButton.icon(
                  icon: _isProcessing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.save),
                  label: Text(_isProcessing ? 'جاري الإضافة...' : 'إضافة الكل'),
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          final text = _studentsListController.text.trim();
                          if (text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('يرجى إدخال أسماء التلاميذ'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          // Diviser le texte en lignes et nettoyer
                          List<String> names = text
                              .split('\n')
                              .map((line) => line.trim())
                              .where((line) => line.isNotEmpty)
                              .toList();

                          if (names.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('لم يتم العثور على أسماء صالحة'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            _isProcessing = true;
                            _successCount = 0;
                            _duplicateCount = 0;
                            _errorCount = 0;
                          });

                          try {
                            final studentsCollection = FirebaseFirestore
                                .instance
                                .collection('users')
                                .doc(currentUser!.uid)
                                .collection('user_classes')
                                .doc(classData['id'])
                                .collection('students');

                            // Récupérer les noms existants pour éviter les doublons
                            final existingStudents =
                                await studentsCollection.get();
                            Set<String> existingNames = existingStudents.docs
                                .map((doc) => doc['name'] as String)
                                .toSet();

                            List<String> updatedStudents =
                                List.from(classData['students']);

                            // Traiter chaque nom
                            for (String name in names) {
                              try {
                                // Ignorer les doublons
                                if (existingNames.contains(name)) {
                                  setState(() {
                                    _duplicateCount++;
                                  });
                                  continue;
                                }

                                // Ajouter l'élève
                                final studentRef =
                                    await studentsCollection.add({
                                  'name': name,
                                  'parentName': '',
                                  'parentPhone': '',
                                  'birthDate': '',
                                  'remarks': '',
                                  'photoBase64': '',
                                  'createdAt': FieldValue.serverTimestamp(),
                                });

                                updatedStudents.add(studentRef.id);
                                existingNames.add(
                                    name); // Ajouter à l'ensemble des noms existants

                                setState(() {
                                  _successCount++;
                                });

                                // Petite pause pour éviter de surcharger
                                await Future.delayed(
                                    Duration(milliseconds: 50));
                              } catch (e) {
                                print('Erreur lors de l\'ajout de $name: $e');
                                setState(() {
                                  _errorCount++;
                                });
                              }
                            }

                            // Mettre à jour la liste des élèves dans le document de classe
                            if (_successCount > 0) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser!.uid)
                                  .collection('user_classes')
                                  .doc(classData['id'])
                                  .update({
                                'students': updatedStudents,
                              });

                              // Mettre à jour localement
                              setState(() {
                                classData['students'] = updatedStudents;
                              });
                            }

                            // Attendre un peu pour montrer les résultats
                            await Future.delayed(Duration(seconds: 1));

                            // Fermer la boîte de dialogue
                            if (mounted) {
                              Navigator.pop(context);
                            }

                            // Recharger les élèves si nécessaire
                            if (_showStudentsList) {
                              await _loadStudentsForClass();
                            }

                            // Afficher le résultat
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تمت الإضافة: $_successCount\nموجود مسبقاً: $_duplicateCount\nأخطاء: $_errorCount',
                                  textDirection: TextDirection.rtl,
                                ),
                                backgroundColor: _successCount > 0
                                    ? Colors.green
                                    : Colors.orange,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          } catch (e) {
                            print('Erreur lors de l\'ajout multiple: $e');
                            setState(() {
                              _isProcessing = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('حدث خطأ أثناء إضافة التلاميذ'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getMappedEvaluation(String displayValue, String system,
      {List<String>? customNotes}) {
    // Vérifier si c'est "غائب"
    if (displayValue == 'غائب') {
      return 'غائب';
    }

    if (system == 'custom' && customNotes != null && customNotes.isNotEmpty) {
      // Pour le système personnalisé, trouver l'index de la valeur affichée
      int index = customNotes.indexOf(displayValue);

      if (index == -1) {
        // Si la valeur n'est pas trouvée, chercher une correspondance partielle
        for (int i = 0; i < customNotes.length; i++) {
          if (customNotes[i].contains(displayValue) ||
              displayValue.contains(customNotes[i])) {
            index = i;
            break;
          }
        }
      }

      if (index == -1) {
        // Si toujours pas trouvé, utiliser la première valeur
        return '( - - - )';
      }

      // Mapper vers les 4 niveaux selon la position dans la liste
      if (customNotes.length == 2) {
        // 2 valeurs : bas = ---, haut = +++
        return index == 0 ? '( - - - )' : '( + + + )';
      } else if (customNotes.length == 3) {
        // 3 valeurs : bas = ---, moyen = ++-, haut = +++
        switch (index) {
          case 0:
            return '( - - - )';
          case 1:
            return '( + + - )';
          case 2:
            return '( + + + )';
          default:
            return '( - - - )';
        }
      } else if (customNotes.length == 4) {
        // 4 valeurs : bas = ---, moyen-bas = +--, moyen-haut = ++-, haut = +++
        switch (index) {
          case 0:
            return '( - - - )';
          case 1:
            return '( + - - )';
          case 2:
            return '( + + - )';
          case 3:
            return '( + + + )';
          default:
            return '( - - - )';
        }
      } else {
        // Pour plus de 4 valeurs, répartir proportionnellement
        final ratio = index / (customNotes.length - 1);
        if (ratio < 0.25) return '( - - - )';
        if (ratio < 0.5) return '( + - - )';
        if (ratio < 0.75) return '( + + - )';
        return '( + + + )';
      }
    }

    // Le reste du code pour les autres systèmes...
    switch (system) {
      case 'character':
        return displayValue;

      case 'note_0_1_5':
        switch (displayValue) {
          case '0':
            return '( - - - )';
          case '0.5':
            return '( + - - )';
          case '1':
            return '( + + - )';
          case '1.5':
            return '( + + + )';
          default:
            return '( - - - )';
        }

      case 'note_0_3':
        switch (displayValue) {
          case '0':
            return '( - - - )';
          case '1':
            return '( + - - )';
          case '2':
            return '( + + - )';
          case '3':
            return '( + + + )';
          default:
            return '( - - - )';
        }

      case 'note_0_6':
        switch (displayValue) {
          case '0':
            return '( - - - )';
          case '2':
            return '( + - - )';
          case '4':
            return '( + + - )';
          case '6':
            return '( + + + )';
          default:
            return '( - - - )';
        }

      default:
        return displayValue;
    }
  }

  Future<void> _navigateAfterSelection(String classId, String matiereId) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));

      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .get();
      final className =
          classDoc.exists ? (classDoc['name'] ?? classId) : classId;

      final matiereDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('matieres')
          .doc(matiereId)
          .get();

      final matiereName = matiereDoc.exists ? matiereDoc['name'] : matiereId;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BaremesPage(
              selectedClass: classId,
              selectedClassName: className,
              selectedMatiere: matiereId,
              matiereName: matiereName,
            ),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la navigation après sélection: $e');
    }
  }

  void _navigateDirectlyToBaremesSelection() async {
    if (selectedClassId == null || selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى اختيار قسم ومادة أولاً'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClassId!)
          .get();
      final className = classDoc.exists
          ? (classDoc['name'] ?? selectedClassId!)
          : selectedClassId!;

      final matiereDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedClassId!)
          .collection('matieres')
          .doc(selectedSubjectId!)
          .get();

      final matiereName =
          matiereDoc.exists ? matiereDoc['name'] : selectedSubjectId!;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BaremesPage(
            selectedClass: selectedClassId!,
            selectedClassName: className,
            selectedMatiere: selectedSubjectId!,
            matiereName: matiereName,
          ),
        ),
      );
    } catch (e) {
      print('Erreur lors de la navigation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء التنقل: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _addDefaultStudentsIfEmpty(
      Map<String, dynamic> classData) async {
    if (_students.isEmpty && widget.showStudentsForMatiere == true) {
      // Demander à l'utilisateur s'il veut ajouter des étudiants
      bool? shouldAdd = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('لا يوجد تلاميذ'),
          content: Text('هل تريد إضافة تلاميذ لهذا القسم؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('لاحقاً'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('نعم'),
            ),
          ],
        ),
      );

      if (shouldAdd == true) {
        await _addStudent(classData);
      }
    }
  }

  Future<void> _preSelectClassAndMatiere() async {
    if (!mounted) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    await Future.delayed(Duration(milliseconds: 500));

    try {
      // Vérifier si des classes sont disponibles
      if (_classes.isEmpty) {
        print("Aucune classe disponible pour la pré-sélection");
        return;
      }

      print("Pré-sélection - Classes disponibles: ${_classes.length}");
      print("Recherche de la classe: ${widget.preSelectedClassId}");
      print("Recherche de la matière: ${widget.preSelectedMatiereId}");

      // ÉVITER firstWhere - Utiliser une boucle for
      Map<String, dynamic>? targetClass;

      for (var classItem in _classes) {
        final classId = classItem['class_id']?.toString();
        final targetClassId = widget.preSelectedClassId?.toString();

        if (classId == targetClassId) {
          targetClass = classItem;
          print("Classe trouvée: ${classItem['class_name']}");
          break;
        }
      }

      // Si non trouvée, prendre la première classe
      if (targetClass == null && _classes.isNotEmpty) {
        targetClass = _classes[0];
        print(
            "Classe non trouvée, utilisation de la première: ${targetClass['class_name']}");
      }

      if (targetClass != null) {
        print("Sélection de la classe: ${targetClass['class_name']}");

        // Sélectionner la classe
        setState(() {
          _selectedClass = targetClass;
          selectedClassId = targetClass?['class_id']?.toString();
        });

        // Charger les matières pour cette classe
        await fetchMatieresForPreSelection(widget.preSelectedClassId!);

        // Chercher la matière
        if (targetClass.containsKey('subjects')) {
          final subjects = targetClass['subjects'];

          if (subjects is List && subjects.isNotEmpty) {
            print("Sujets disponibles: ${subjects.length}");

            // ÉVITER firstWhere pour les matières aussi
            Map<String, dynamic>? targetSubject;

            for (var subject in subjects) {
              if (subject is Map<String, dynamic>) {
                final subjectId = subject['id']?.toString();
                final targetSubjectId = widget.preSelectedMatiereId?.toString();

                if (subjectId == targetSubjectId) {
                  targetSubject = subject;
                  print("Matière trouvée: ${subject['name']}");
                  break;
                }
              }
            }

            // Prendre la première matière si non trouvée
            if (targetSubject == null && subjects.isNotEmpty) {
              final firstSubject = subjects[0];
              if (firstSubject is Map<String, dynamic>) {
                targetSubject = firstSubject;
                print(
                    "Matière non trouvée, utilisation de la première: ${targetSubject['name']}");
              }
            }

            if (targetSubject != null) {
              print("Sélection de la matière: ${targetSubject['name']}");

              setState(() {
                selectedSubjectId = targetSubject!['id']?.toString();
                if (widget.showStudentsForMatiere == true) {
                  _showStudentsList = true;
                }
              });

              // Charger les étudiants
              await _loadStudentsForClass();
            } else {
              print("Aucune matière trouvée dans la classe");
            }
          } else {
            print("La classe n'a pas de sujets ou la liste est vide");
          }
        } else {
          print("La classe ne contient pas de clé 'subjects'");
        }
      }
    } catch (e, stackTrace) {
      print('Erreur lors de la pré-sélection: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la pré-sélection des données'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Fermer l'indicateur de chargement
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> fetchMatieresForPreSelection(String classId) async {
    if (!mounted) return;

    setState(() {
      _isLoadingSubjects = true;
      _subjects = [];
    });

    try {
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('matieres')
          .get();

      if (classDoc.docs.isNotEmpty) {
        List<Map<String, dynamic>> newSubjects = [];

        for (var doc in classDoc.docs) {
          newSubjects.add({
            'id': doc.id,
            'name': doc['name'] as String,
          });
        }

        // Trier les matières par ordre alphabétique
        newSubjects.sort((a, b) => a['name'].compareTo(b['name']));

        if (mounted) {
          setState(() {
            _subjects = newSubjects;
            _isLoadingSubjects = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _subjects = [];
            _isLoadingSubjects = false;
          });
        }
      }
    } catch (e) {
      print("Erreur lors de la récupération des matières: $e");
      if (mounted) {
        setState(() {
          _subjects = [];
          _isLoadingSubjects = false;
        });
      }
    }
  }

  Future<void> _refreshSubjects() async {
    if (_selectedClass == null) return;

    setState(() {
      _isRefreshingSubjects = true;
    });

    try {
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(_selectedClass!['class_id'])
          .collection('matieres')
          .get();

      if (classDoc.docs.isNotEmpty) {
        List<Map<String, dynamic>> newSubjects = [];

        for (var doc in classDoc.docs) {
          newSubjects.add({
            'id': doc.id,
            'name': doc['name'] as String,
          });
        }

        // Trier par ordre alphabétique
        newSubjects.sort((a, b) => a['name'].compareTo(b['name']));

        setState(() {
          _subjects = newSubjects;
          _isRefreshingSubjects = false;
        });
      } else {
        setState(() {
          _subjects = [];
          _isRefreshingSubjects = false;
        });
      }
    } catch (e) {
      print("Erreur lors du rafraîchissement des matières: $e");
      setState(() {
        _isRefreshingSubjects = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du rafraîchissement des matières')),
      );
    }
  }

  void _buildHelpSection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تعليمات الاستخدام',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('كيفية استخدام التطبيق:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                _buildHelpItem(
                    '1. اضغط على أي قسم لرؤية المواد والتلاميذ المرتبطين به'),
                _buildHelpItem(
                    '2. استخدم زر "إضافة تلميذ" لإضافة تلميذ جديد للقسم'),
                _buildHelpItem(
                    '3. استخدم زر "إضافة مادة" لإضافة مواد دراسية للقسم'),
                _buildHelpItem('4. اضغط على أيقونة السلة الحمراء لحذف القسم'),
                _buildHelpItem(
                    '5. اضغط على اسم المادة لرؤية قائمة التلاميذ وتقييمهم'),
                _buildHelpItem(
                    '6. بعد اختيار المادة، اضغط على اسم التلميذ الذي ترغب في تقييمه'),
                SizedBox(height: 8),
                Text('إرشادات سريعة:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                _buildHelpItemWithIcon(
                    Icons.touch_app, 'اضغط على القسم لعرض محتوياته'),
                _buildHelpItemWithIcon(
                    Icons.add, 'استخدم الأزرار الزرقاء للإضافة'),
                _buildHelpItemWithIcon(
                    Icons.delete, 'استخدم الأيقونات الحمراء للحذف'),
                _buildHelpItemWithIcon(
                    Icons.info, 'اضغط على معلومات التلميذ لرؤية التفاصيل'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إغلاق', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildHelpItemWithIcon(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Future<String?> _getEvaluation({
    required String classId,
    required String studentId,
    required String baremeId,
    String? sousBaremeId,
  }) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("Aucun utilisateur connecté");
      }

      var docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .collection('baremes')
          .doc(baremeId);

      if (sousBaremeId != null) {
        docRef = docRef.collection('sous_baremes').doc(sousBaremeId);
      }

      var doc = await docRef.get();

      if (doc.exists && doc.data()?.containsKey('Marks') == true) {
        return doc['Marks'] as String?;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'évaluation: $e');
      return null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _addSubjectDialog(Map<String, dynamic> classData) async {
    await _loadSubjects(classData['class_id']);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                if (_isLoadingSubjects)
                  Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Expanded(
                  child: Text(
                    'إضافة مادة دراسية',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
            content: _isLoadingSubjects
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          "جاري تحميل قائمة المواد...",
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'اختر المادة المطلوبة:',
                          style: TextStyle(color: Colors.grey),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedSubject,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down),
                            hint: const Text(
                              'اختر مادة',
                              textDirection: TextDirection.rtl,
                            ),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedSubject = newValue;
                              });
                            },
                            items: _subjects
                                .map<DropdownMenuItem<String>>((subject) {
                              return DropdownMenuItem<String>(
                                value: subject['id'],
                                child: Text(
                                  subject['name'],
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: TextDirection.rtl,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        if (_subjects.isEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'لا توجد مواد متاحة',
                            style: TextStyle(color: Colors.orange),
                            textDirection: TextDirection.rtl,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: Icon(Icons.refresh),
                            label: Text('إعادة تحميل'),
                            onPressed: () {
                              _loadSubjects(classData['class_id']);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedSubject == null
                      ? Colors.grey.shade300
                      : Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _selectedSubject == null
                    ? null
                    : () async {
                        final selectedSubject = _subjects.firstWhere(
                            (subject) => subject['id'] == _selectedSubject);
                        await _addSubjectToClass(classData,
                            selectedSubject['name']!, selectedSubject['id']!);
                        if (mounted) Navigator.pop(context);
                      },
                child: const Text('إضافة'),
              ),
            ],
            actionsAlignment: MainAxisAlignment.start,
          );
        },
      ),
    );
  }

  Future<void> _addSubjectToClass(Map<String, dynamic> classData,
      String subjectName, String subjectId) async {
    try {
      List<Map<String, String>> updatedSubjects =
          List.from(classData['subjects']);
      if (!updatedSubjects.any((subject) => subject['id'] == subjectId)) {
        updatedSubjects.add({'id': subjectId, 'name': subjectName});

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('user_classes')
            .doc(classData['id'])
            .update({
          'subjects': updatedSubjects,
        });

        setState(() {
          classData['subjects'] = updatedSubjects;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Matière ajoutée avec succès')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cette matière est déjà dans la classe')));
      }
    } catch (e) {
      print("Erreur lors de l'ajout de la matière : $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout de la matière')));
    }
  }

  Future<void> _loadSubjects(String classId) async {
    setState(() {
      _isLoadingSubjects = true;
    });

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

          // Trier par ordre alphabétique
          _subjects.sort((a, b) => a['name'].compareTo(b['name']));
          _isLoadingSubjects = false;
        });
      } else {
        setState(() {
          _subjects.clear();
          _isLoadingSubjects = false;
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération des matières : $e");
      setState(() {
        _isLoadingSubjects = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la récupération des matières')));
    }
  }

  Future<void> _fetchClasses() async {
    if (!mounted) return;

    setState(() {
      _isLoadingClasses = true;
      _classes = [];
    });

    try {
      final classDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .get();

      List<Map<String, dynamic>> loadedClasses = classDocs.docs.map((doc) {
        List<Map<String, String>> subjects = [];
        if (doc['subjects'] != null) {
          subjects = (doc['subjects'] as List).map((subject) {
            return {
              'id': subject['id'].toString(),
              'name': subject['name'].toString(),
            };
          }).toList();
        }

        List<String> students = [];
        if (doc['students'] != null) {
          students = (doc['students'] as List).map((student) {
            return student.toString();
          }).toList();
        }

        return {
          'id': doc.id,
          'class_id': doc['class_id'].toString(),
          'class_name': doc['class_name'].toString(),
          'subjects': subjects,
          'students': students,
        };
      }).toList();

      // Trier les classes par ordre alphabétique
      loadedClasses.sort((a, b) => a['class_name'].compareTo(b['class_name']));

      if (mounted) {
        setState(() {
          _classes = loadedClasses;
          _isLoadingClasses = false;
        });
      }
    } catch (e) {
      print("Erreur lors du chargement des classes : $e");
      if (mounted) {
        setState(() {
          _isLoadingClasses = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur lors du chargement des classes: $e')));
      }
    }
  }

  Future<void> _refreshClasses() async {
    if (!mounted) return;

    setState(() {
      _isRefreshingClasses = true;
    });

    try {
      final classDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .get();

      List<Map<String, dynamic>> loadedClasses = classDocs.docs.map((doc) {
        List<Map<String, String>> subjects = [];
        if (doc['subjects'] != null) {
          subjects = (doc['subjects'] as List).map((subject) {
            return {
              'id': subject['id'].toString(),
              'name': subject['name'].toString(),
            };
          }).toList();
        }

        List<String> students = [];
        if (doc['students'] != null) {
          students = (doc['students'] as List).map((student) {
            return student.toString();
          }).toList();
        }

        return {
          'id': doc.id,
          'class_id': doc['class_id'].toString(),
          'class_name': doc['class_name'].toString(),
          'subjects': subjects,
          'students': students,
        };
      }).toList();

      // Trier par ordre alphabétique
      loadedClasses.sort((a, b) => a['class_name'].compareTo(b['class_name']));

      setState(() {
        _classes = loadedClasses;
        _isRefreshingClasses = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث قائمة الأقسام'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print("Erreur lors du rafraîchissement des classes : $e");
      setState(() {
        _isRefreshingClasses = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تحديث الأقسام'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteClass(String classId) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      final classDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId);

      final studentsSnapshot = await classDocRef.collection('students').get();
      for (var studentDoc in studentsSnapshot.docs) {
        await studentDoc.reference.delete();
      }

      final subjectsSnapshot = await classDocRef.collection('subjects').get();
      for (var subjectDoc in subjectsSnapshot.docs) {
        await subjectDoc.reference.delete();
      }

      await classDocRef.delete();

      // Fermer l'indicateur
      Navigator.pop(context);

      setState(() {
        _classes.removeWhere((classData) => classData['id'] == classId);
        if (_selectedClass != null && _selectedClass!['id'] == classId) {
          _selectedClass = null;
          _showStudentsList = false;
        }
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تم حذف القسم وبياناته')));
    } catch (e) {
      // Fermer l'indicateur en cas d'erreur
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print("خطأ أثناء الحذف: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('حدث خطأ أثناء حذف القسم')));
    }
  }

  Future<void> _confirmDeleteClass(String classId) async {
    final classData =
        _classes.firstWhere((classData) => classData['id'] == classId);

    if (classData['students'].isNotEmpty) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('حذف جميع التلاميذ'),
          content: Text(
              'هذا القسم يحتوي على تلاميذ. هل تريد حذف جميع التلاميذ قبل حذف القسم؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteAllStudents(classData);
                await _deleteClass(classId);
              },
              child: Text('حذف الكل', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      await _deleteClass(classId);
    }
  }

  Future<void> _deleteAllStudents(Map<String, dynamic> classData) async {
    try {
      final classDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classData['id']);

      final studentsSnapshot = await classDocRef.collection('students').get();
      for (var studentDoc in studentsSnapshot.docs) {
        await studentDoc.reference.delete();
      }

      await classDocRef.update({
        'students': [],
      });

      setState(() {
        classData['students'].clear();
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تم حذف جميع التلاميذ')));
    } catch (e) {
      print("خطأ أثناء حذف التلاميذ: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('حدث خطأ أثناء حذف التلاميذ')));
    }
  }

  Future<void> _deleteStudent(
      Map<String, dynamic> classData, String studentId) async {
    try {
      List<String> updatedStudents = List.from(classData['students']);
      updatedStudents.remove(studentId);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classData['id'])
          .update({
        'students': updatedStudents,
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classData['id'])
          .collection('students')
          .doc(studentId)
          .delete();

      setState(() {
        classData['students'] = updatedStudents;
        _students.removeWhere((student) => student['id'] == studentId);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تم حذف التلميذ')));
    } catch (e) {
      print("خطأ أثناء حذف التلميذ: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حذف التلميذ')),
      );
    }
  }

  Future<void> _confirmDeleteStudent(
      Map<String, dynamic> classData, String studentId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من رغبتك في حذف هذا التلميذ؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStudent(classData, studentId);
            },
            child: Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubject(
      Map<String, dynamic> classData, String subjectId) async {
    try {
      List<Map<String, String>> updatedSubjects =
          List.from(classData['subjects']);
      updatedSubjects.removeWhere((subject) => subject['id'] == subjectId);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classData['id'])
          .update({
        'subjects': updatedSubjects,
      });

      setState(() {
        classData['subjects'] = updatedSubjects;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تم حذف المادة')));
    } catch (e) {
      print("خطأ أثناء حذف المادة: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('حدث خطأ أثناء حذف المادة')));
    }
  }

  Future<void> _confirmDeleteSubject(
      Map<String, dynamic> classData, String subjectId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من رغبتك في حذف هذه المادة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSubject(classData, subjectId);
            },
            child: Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _addStudent(Map<String, dynamic> classData) async {
    List<TextEditingController> studentControllers = [TextEditingController()];

    // Variable pour suivre les ajouts en cours
    bool _isAdding = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('إضافة تلاميذ', textDirection: TextDirection.rtl),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 200,
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: studentControllers.length,
                      itemBuilder: (context, index) {
                        return Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            if (studentControllers.length > 1)
                              IconButton(
                                icon: Icon(Icons.remove_circle,
                                    color: Colors.red),
                                onPressed: _isAdding
                                    ? null
                                    : () {
                                        setState(() {
                                          studentControllers.removeAt(index);
                                        });
                                      },
                              ),
                            Expanded(
                              child: TextField(
                                controller: studentControllers[index],
                                textAlign: TextAlign.right,
                                enabled: !_isAdding,
                                decoration: InputDecoration(
                                  labelText: 'اسم التلميذ ${index + 1}',
                                  floatingLabelAlignment:
                                      FloatingLabelAlignment.start,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  if (!_isAdding)
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('إضافة تلميذ آخر'),
                      onPressed: () {
                        setState(() {
                          studentControllers.add(TextEditingController());
                        });
                      },
                    ),
                  if (_isAdding)
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 10),
                          Text('جاري إضافة التلاميذ...'),
                        ],
                      ),
                    ),
                ],
              ),
              actions: [
                if (!_isAdding)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('إلغاء', textDirection: TextDirection.rtl),
                  ),
                if (!_isAdding)
                  ElevatedButton(
                    onPressed: () async {
                      // Vérifier s'il y a des noms vides
                      final validNames = studentControllers
                          .where(
                              (controller) => controller.text.trim().isNotEmpty)
                          .toList();

                      if (validNames.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('يرجى إدخال اسم واحد على الأقل')),
                        );
                        return;
                      }

                      setState(() {
                        _isAdding = true;
                      });

                      try {
                        final studentsCollection = FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser!.uid)
                            .collection('user_classes')
                            .doc(classData['id'])
                            .collection('students');

                        List<String> updatedStudents =
                            List.from(classData['students']);
                        int addedCount = 0;

                        // Ajouter chaque élève individuellement
                        for (var controller in validNames) {
                          try {
                            final studentName = controller.text.trim();

                            // Vérifier si l'élève existe déjà (optionnel)
                            final existingStudents = await studentsCollection
                                .where('name', isEqualTo: studentName)
                                .get();

                            if (existingStudents.docs.isNotEmpty) {
                              // Élève existe déjà, passer au suivant
                              continue;
                            }

                            // Créer le document élève
                            final studentRef = await studentsCollection.add({
                              'name': studentName,
                              'parentName': '',
                              'parentPhone': '',
                              'birthDate': '',
                              'remarks': '',
                              'photoBase64': '',
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            // Ajouter l'ID à la liste des élèves de la classe
                            updatedStudents.add(studentRef.id);
                            addedCount++;

                            // Petite pause pour éviter de surcharger Firebase
                            await Future.delayed(Duration(milliseconds: 100));
                          } catch (e) {
                            print('Erreur lors de l\'ajout d\'un élève: $e');
                            // Continuer avec les autres élèves même en cas d'erreur
                          }
                        }

                        // Mettre à jour la liste des élèves dans le document de classe
                        if (addedCount > 0) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser!.uid)
                              .collection('user_classes')
                              .doc(classData['id'])
                              .update({
                            'students': updatedStudents,
                          });

                          // Mettre à jour localement
                          setState(() {
                            classData['students'] = updatedStudents;
                          });
                        }

                        // Fermer la boîte de dialogue
                        if (mounted) {
                          Navigator.pop(context);
                        }

                        // Recharger les élèves si on est dans la vue des élèves
                        if (_showStudentsList) {
                          await _loadStudentsForClass();
                        }

                        // Afficher le résultat
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              addedCount > 0
                                  ? 'تم إضافة $addedCount تلميذ بنجاح'
                                  : 'لم يتم إضافة أي تلاميذ (قد يكونوا موجودين مسبقاً)',
                              textDirection: TextDirection.rtl,
                            ),
                            backgroundColor:
                                addedCount > 0 ? Colors.green : Colors.orange,
                          ),
                        );
                      } catch (e) {
                        print("خطأ في إضافة التلاميذ: $e");
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('حدث خطأ أثناء إضافة التلاميذ'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: Text('إضافة', textDirection: TextDirection.rtl),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveEvaluation({
    required String classId,
    required String studentId,
    required String baremeId,
    required String? newValue,
    String? sousBaremeId,
  }) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("Aucun utilisateur connecté");

      var baremesCollectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .collection('baremes');

      var baremeRef = baremesCollectionRef.doc(baremeId);

      WriteBatch batch = FirebaseFirestore.instance.batch();

      if (sousBaremeId != null) {
        var sousBaremeDirectRef = baremesCollectionRef.doc(sousBaremeId);
        batch.delete(sousBaremeDirectRef);

        var sousBaremeNestedRef =
            baremeRef.collection('sous_baremes').doc(sousBaremeId);
        batch.delete(sousBaremeNestedRef);
      } else {
        batch.delete(baremeRef);
      }

      if (newValue != null) {
        if (sousBaremeId != null) {
          batch.set(baremesCollectionRef.doc(sousBaremeId), {
            'Marks': newValue,
            'createdAt': FieldValue.serverTimestamp(),
          });

          batch.set(baremeRef.collection('sous_baremes').doc(sousBaremeId), {
            'Marks': newValue,
            'createdAt': FieldValue.serverTimestamp(),
          });

          batch.set(
              baremeRef,
              {
                'haveSoubarem': true,
                'createdAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));
        } else {
          batch.set(
              baremeRef,
              {
                'Marks': newValue,
                'createdAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));
        }
      }

      await batch.commit();

      print('Sauvegarde réussie pour le barème $baremeId');
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la sauvegarde')),
      );
      rethrow;
    }
  }

  Future<void> _showSelectionsDialog(
      String classId, String matiereId, String studentId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Récupérer le système choisi pour cette matière/classe
      String selectedSystem = 'character'; // Par défaut

      try {
        final systemDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('evaluation_systems')
            .doc('$classId-$matiereId')
            .get();

        if (systemDoc.exists) {
          selectedSystem = systemDoc['system'] ?? 'character';
        }
      } catch (e) {
        print('Erreur lors de la récupération du système: $e');
      }

      // Maintenant, charger les données avec le système actuel
      await _showEvaluationDialogWithSystem(
        context,
        classId,
        matiereId,
        studentId,
        selectedSystem,
      );
    } catch (e) {
      Navigator.of(context).pop();
      print('Erreur lors du chargement des sélections: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحميل التقييمات')),
      );
    }
  }

  Widget _buildEvaluationButtons(
    List<String> options,
    Map<String, Color> colors,
    String selectedValue,
    String system,
    Function(String) onTap, {
    List<String>? customNotes,
  }) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: options.map((displayValue) {
        return GestureDetector(
          onTap: () => onTap(displayValue),
          child: Chip(
            label: Text(displayValue,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            backgroundColor: colors[displayValue] ?? Colors.blue,
            side: BorderSide(
              color: selectedValue == displayValue
                  ? Colors.black
                  : Colors.transparent,
              width: 2,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showEvaluationDialogWithSystem(
    BuildContext context,
    String classId,
    String matiereId,
    String studentId,
    String initialSystem,
  ) async {
    // Variables locales pour le dialogue
    String selectedSystem = initialSystem;
    List<Map<String, dynamic>> selections = [];

    // Options d'affichage selon le système
    Map<String, List<String>> displayOptions = {
      'character': ['( - - - )', '( + - - )', '( + + - )', '( + + + )'],
      'note_0_1_5': ['0', '0.5', '1', '1.5'],
      'note_0_3': ['0', '1', '2', '3'],
      'note_0_6': ['0', '2', '4', '6'],
      'custom': [], // Sera rempli dynamiquement pour chaque barème
    };

    // Charger les données initiales
    await _loadSelectionsData(
      classId,
      matiereId,
      studentId,
      selectedSystem,
      (loadedSelections) {
        selections = loadedSelections;
      },
    );

    // Fermer l'indicateur de chargement initial
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    if (selections.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('لا توجد معايير محددة'),
          content: Text('لإجراء التقييم، يجب عليك أولاً برمجة معيار للتقييم'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToDirectEvaluation('');
              },
              child: Text('اذهب إلى صفحة الاختيار'),
            ),
          ],
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) {
            // Fonction pour obtenir les options d'affichage d'un barème spécifique
            List<String> getDisplayOptionsForBareme(
                Map<String, dynamic> bareme) {
              if (selectedSystem == 'custom') {
                final customNotes = bareme['customNotes'] as List<String>?;
                if (customNotes != null && customNotes.isNotEmpty) {
                  return customNotes;
                }
                // Fallback si pas de notes personnalisées
                return ['0', '0.25', '0.5', '1'];
              }

              // Pour les autres systèmes
              switch (selectedSystem) {
                case 'character':
                  return ['( - - - )', '( + - - )', '( + + - )', '( + + + )'];
                case 'note_0_1_5':
                  return ['0', '0.5', '1', '1.5'];
                case 'note_0_3':
                  return ['0', '1', '2', '3'];
                case 'note_0_6':
                  return ['0', '2', '4', '6'];
                default:
                  return ['( - - - )', '( + - - )', '( + + - )', '( + + + )'];
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width > 500
                    ? 460
                    : MediaQuery.of(context).size.width * 0.92,
                padding: EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En-tête avec choix du système
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Titre à gauche
                        Expanded(
                          child: Text(
                            'تقييم المعايير',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Conteneur pour le dropdown et le bouton de rafraîchissement
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Bouton de rafraîchissement
                            Container(
                              margin: EdgeInsets.only(left: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.blue.withOpacity(0.1),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.refresh,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                onPressed: () async {
                                  setStateDialog(() {});
                                  try {
                                    await _loadSelectionsData(
                                      classId,
                                      matiereId,
                                      studentId,
                                      selectedSystem,
                                      (loadedSelections) {
                                        setStateDialog(() {
                                          selections = loadedSelections;
                                        });
                                      },
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('تم تحديث البيانات'),
                                        duration: Duration(seconds: 1),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('حدث خطأ أثناء التحديث'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                tooltip: 'تحديث البيانات',
                                padding: EdgeInsets.all(4),
                                constraints: BoxConstraints(),
                              ),
                            ),

                            // Dropdown du système
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onSelected: (String newSystem) async {
                                try {
                                  if (newSystem == 'custom') {
                                    final bool? useGlobalNotes =
                                        await _askForNotesType(context);

                                    if (useGlobalNotes == null) {
                                      return;
                                    }

                                    if (useGlobalNotes) {
                                      final globalNotes =
                                          await _showCustomNotesDialog(
                                        context,
                                        classId,
                                        matiereId,
                                      );

                                      if (globalNotes == null ||
                                          globalNotes.isEmpty) {
                                        return;
                                      }

                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(currentUser!.uid)
                                          .collection('bareme_custom_notes')
                                          .doc('$classId-$matiereId')
                                          .set({
                                        'notes': globalNotes,
                                        'updatedAt':
                                            FieldValue.serverTimestamp(),
                                      });

                                      setStateDialog(() {
                                        selectedSystem = newSystem;
                                        selections = selections.map((bareme) {
                                          return {
                                            ...bareme,
                                            'customNotes': globalNotes,
                                            'displayEvaluation':
                                                _getDisplayEvaluation(
                                              bareme['storedEvaluation'] ??
                                                  '( - - - )',
                                              newSystem,
                                              customNotes: globalNotes,
                                            ),
                                            'sousBaremes':
                                                (bareme['sousBaremes'] as List)
                                                    .map<Map<String, dynamic>>(
                                                        (sousBareme) {
                                              return {
                                                ...sousBareme,
                                                'displayEvaluation':
                                                    _getDisplayEvaluation(
                                                  sousBareme[
                                                          'storedEvaluation'] ??
                                                      '( - - - )',
                                                  newSystem,
                                                  customNotes: globalNotes,
                                                ),
                                              };
                                            }).toList(),
                                          };
                                        }).toList();
                                      });

                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(currentUser!.uid)
                                          .collection('evaluation_systems')
                                          .doc('$classId-$matiereId')
                                          .set({
                                        'system': newSystem,
                                        'updatedAt':
                                            FieldValue.serverTimestamp(),
                                      });

                                      return;
                                    } else {
                                      setStateDialog(() {
                                        selectedSystem = newSystem;
                                      });
                                      return;
                                    }
                                  }

                                  setStateDialog(() {
                                    selectedSystem = newSystem;
                                    selections = selections.map((bareme) {
                                      return {
                                        ...bareme,
                                        'displayEvaluation':
                                            _getDisplayEvaluation(
                                          bareme['storedEvaluation'] ??
                                              '( - - - )',
                                          newSystem,
                                          customNotes: bareme['customNotes'],
                                        ),
                                        'sousBaremes':
                                            (bareme['sousBaremes'] as List)
                                                .map<Map<String, dynamic>>(
                                                    (sousBareme) {
                                          return {
                                            ...sousBareme,
                                            'displayEvaluation':
                                                _getDisplayEvaluation(
                                              sousBareme['storedEvaluation'] ??
                                                  '( - - - )',
                                              newSystem,
                                              customNotes:
                                                  bareme['customNotes'],
                                            ),
                                          };
                                        }).toList(),
                                      };
                                    }).toList();
                                  });

                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(currentUser!.uid)
                                      .collection('evaluation_systems')
                                      .doc('$classId-$matiereId')
                                      .set({
                                    'system': newSystem,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('حدث خطأ: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return [
                                  PopupMenuItem<String>(
                                    value: 'character',
                                    child: Row(
                                      children: [
                                        Icon(Icons.tag, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text(' نظام الرموز'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'note_0_1_5',
                                    child: Row(
                                      children: [
                                        Icon(Icons.percent,
                                            color: Colors.green),
                                        SizedBox(width: 8),
                                        Text('نظام النقاط (0-1.5)'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'note_0_3',
                                    child: Row(
                                      children: [
                                        Icon(Icons.percent,
                                            color: Colors.orange),
                                        SizedBox(width: 8),
                                        Text('نظام النقاط (0-3)'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'note_0_6',
                                    child: Row(
                                      children: [
                                        Icon(Icons.percent,
                                            color: Colors.purple),
                                        SizedBox(width: 8),
                                        Text('نظام النقاط (0-6)'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'custom',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.pink),
                                        SizedBox(width: 8),
                                        Text('نظام مخصص'),
                                      ],
                                    ),
                                  ),
                                ];
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getSystemColor(selectedSystem)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getSystemColor(selectedSystem),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getSystemIcon(selectedSystem),
                                      size: 12,
                                      color: _getSystemColor(selectedSystem),
                                    ),
                                    SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        _getSystemLabel(selectedSystem),
                                        style: TextStyle(
                                          color:
                                              _getSystemColor(selectedSystem),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: _getSystemColor(selectedSystem),
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Indicateur du système actuel
                    Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      margin: EdgeInsets.only(bottom: 12, top: 8),
                      decoration: BoxDecoration(
                        color:
                            _getSystemColor(selectedSystem).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              _getSystemColor(selectedSystem).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: _getSystemColor(selectedSystem),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _getSystemDescription(selectedSystem),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getSystemColor(selectedSystem),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(),

                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: selections.map((selection) {
                            bool hasSousBaremes =
                                (selection['sousBaremes'] as List).isNotEmpty;
                            final baremeCustomNotes =
                                selection['customNotes'] as List<String>?;
                            final displayEvaluationOptions =
                                getDisplayOptionsForBareme(selection);
                            final evaluationColors = _getEvaluationColors(
                              selectedSystem,
                              customNotes: baremeCustomNotes,
                            );

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    // En-tête du barème avec bouton de configuration personnalisée
                                    ListTile(
                                      title: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              selection['baremeName'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          if (selectedSystem == 'custom')
                                            IconButton(
                                              icon: Icon(Icons.settings,
                                                  size: 20),
                                              onPressed: () async {
                                                // Configurer les notes personnalisées pour ce barème
                                                final customNotes =
                                                    await _showCustomNotesDialog(
                                                  context,
                                                  classId,
                                                  matiereId,
                                                );

                                                if (customNotes != null &&
                                                    customNotes.isNotEmpty) {
                                                  // Sauvegarder les notes pour ce barème
                                                  await _saveBaremeCustomNotes(
                                                    classId,
                                                    matiereId,
                                                    selection['id'],
                                                    customNotes,
                                                  );

                                                  // Mettre à jour l'état local
                                                  setStateDialog(() {
                                                    selection['customNotes'] =
                                                        customNotes;

                                                    // Mettre à jour les valeurs d'affichage
                                                    selection[
                                                            'displayEvaluation'] =
                                                        _getDisplayEvaluation(
                                                      selection[
                                                              'storedEvaluation'] ??
                                                          '( - - - )',
                                                      selectedSystem,
                                                      customNotes: customNotes,
                                                    );

                                                    if (hasSousBaremes) {
                                                      selection[
                                                          'sousBaremes'] = (selection[
                                                                  'sousBaremes']
                                                              as List)
                                                          .map<
                                                                  Map<String,
                                                                      dynamic>>(
                                                              (sousBareme) {
                                                        final sousBaremeCustomNotes =
                                                            sousBareme[
                                                                    'customNotes']
                                                                as List<
                                                                    String>?;

                                                        // Si le sous-barème n'a pas ses propres notes,
                                                        // utiliser les nouvelles notes du barème
                                                        final notesToUse =
                                                            sousBaremeCustomNotes !=
                                                                        null &&
                                                                    sousBaremeCustomNotes
                                                                        .isNotEmpty
                                                                ? sousBaremeCustomNotes
                                                                : customNotes;

                                                        return {
                                                          ...sousBareme,
                                                          'displayEvaluation':
                                                              _getDisplayEvaluation(
                                                            sousBareme[
                                                                    'storedEvaluation'] ??
                                                                '( - - - )',
                                                            selectedSystem,
                                                            customNotes:
                                                                notesToUse,
                                                          ),
                                                        };
                                                      }).toList();
                                                    }
                                                  });
                                                }
                                              },
                                              tooltip:
                                                  'تخصيص النظام لهذا المعيار',
                                            ),
                                        ],
                                      ),
                                      leading: Icon(
                                        Icons.assignment,
                                        color: _getSystemColor(selectedSystem),
                                      ),
                                      contentPadding: EdgeInsets.only(
                                        left: 4,
                                        right: 4,
                                        top: 4,
                                        bottom: 8,
                                      ),
                                    ),

                                    // Afficher les notes personnalisées pour ce barème
                                    if (selectedSystem == 'custom' &&
                                        baremeCustomNotes != null &&
                                        baremeCustomNotes.isNotEmpty)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 16),
                                        // child: Wrap(
                                        //   spacing: 8,
                                        //   runSpacing: 4,
                                        //   alignment: WrapAlignment.center,
                                        //   children:
                                        //       baremeCustomNotes.map((note) {
                                        //     return Container(
                                        //       padding: EdgeInsets.symmetric(
                                        //           horizontal: 12, vertical: 6),
                                        //       // decoration: BoxDecoration(
                                        //       //   color: Colors.pink
                                        //       //       .withOpacity(0.1),
                                        //       //   borderRadius:
                                        //       //       BorderRadius.circular(8),
                                        //       //   border: Border.all(
                                        //       //     color: Colors.pink,
                                        //       //     width: 1,
                                        //       //   ),
                                        //       // ),
                                        //       // child: Text(
                                        //       //   note,
                                        //       //   style: TextStyle(
                                        //       //     color: Colors.pink,
                                        //       //     fontWeight: FontWeight.bold,
                                        //       //     fontSize: 14,
                                        //       //   ),
                                        //       // ),
                                        //     );
                                        //   }).toList(),
                                        // ),
                                      ),

                                    // Légende des valeurs pour ce barème
                                    // Container(
                                    //   padding:
                                    //       EdgeInsets.symmetric(vertical: 8),
                                    //   child: Wrap(
                                    //     spacing: 8,
                                    //     runSpacing: 4,
                                    //     alignment: WrapAlignment.center,
                                    //     children: displayEvaluationOptions
                                    //         .map((value) {
                                    //       return Container(
                                    //         padding: EdgeInsets.symmetric(
                                    //             horizontal: 8, vertical: 4),
                                    //         decoration: BoxDecoration(
                                    //           color: evaluationColors[value]
                                    //                   ?.withOpacity(0.1) ??
                                    //               Colors.grey[100],
                                    //           borderRadius:
                                    //               BorderRadius.circular(6),
                                    //           border: Border.all(
                                    //             color:
                                    //                 evaluationColors[value] ??
                                    //                     Colors.grey,
                                    //             width: 1,
                                    //           ),
                                    //         ),
                                    //         child: Text(
                                    //           value,
                                    //           style: TextStyle(
                                    //             color:
                                    //                 evaluationColors[value] ??
                                    //                     Colors.grey,
                                    //             fontWeight: FontWeight.bold,
                                    //             fontSize: 12,
                                    //           ),
                                    //         ),
                                    //       );
                                    //     }).toList(),
                                    //   ),
                                    // ),

                                    if (hasSousBaremes)
                                      Column(
                                        children: (selection['sousBaremes']
                                                as List<Map<String, dynamic>>)
                                            .map((sousBareme) {
                                          return _buildSousBaremeCard(
                                            sousBareme,
                                            setStateDialog,
                                            displayEvaluationOptions,
                                            evaluationColors,
                                            selectedSystem,
                                            classId: classId,
                                            matiereId: matiereId,
                                            baremeId: selection['id'],
                                          );
                                        }).toList(),
                                      )
                                    else
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 12),
                                        child: _buildEvaluationButtons(
                                          displayEvaluationOptions,
                                          evaluationColors,
                                          selection['displayEvaluation'],
                                          selectedSystem,
                                          (newDisplayValue) {
                                            // Convertir pour le stockage
                                            String storedValue =
                                                _getMappedEvaluation(
                                              newDisplayValue,
                                              selectedSystem,
                                              customNotes: baremeCustomNotes,
                                            );

                                            setStateDialog(() {
                                              selection['displayEvaluation'] =
                                                  newDisplayValue;
                                              selection['storedEvaluation'] =
                                                  storedValue;
                                            });
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Boutons de sauvegarde
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'إلغاء',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            bool confirm = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('تأكيد الحفظ'),
                                content: Text(
                                    'هل أنت متأكد أنك تريد حفظ هذه التقييمات؟'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text('لا'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text('نعم'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: EdgeInsets.all(24),
                                  child: Center(
                                    child: Container(
                                      padding: EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 12,
                                            offset: Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(
                                            color: Colors.purple.shade700,
                                            strokeWidth: 4,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'جاري حفظ التقييمات...',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );

                              try {
                                await _saveEvaluationsSimple(
                                  classId: classId,
                                  studentId: studentId,
                                  selections: selections,
                                );

                                Navigator.of(context).pop();
                                Navigator.of(context).pop();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم حفظ التقييمات بنجاح!'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } catch (e) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('حدث خطأ أثناء الحفظ'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icon(Icons.save, size: 18),
                          label: Text(
                            'حفظ التقييمات',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            backgroundColor: _getSystemColor(selectedSystem),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
  }

  // Fonction pour demander le type de notes personnalisées
  Future<bool?> _askForNotesType(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.tune, color: Colors.purple),
            SizedBox(width: 8),
            Text('تخصيص نظام التقييم'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.help_outline, color: Colors.blue, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'ما هو نظام التقييم المفضل لديك؟',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            _buildOptionCard(
              icon: Icons.check_circle,
              title: 'نظام موحد للجميع',
              description: 'نفس القيم لجميع المعايير',
              color: Colors.blue,
              onTap: () => Navigator.pop(context, true),
            ),
            SizedBox(height: 12),
            _buildOptionCard(
              icon: Icons.layers,
              title: 'نظام مختلف لكل معيار',
              description: 'يمكنك تخصيص كل معيار بشكل منفصل',
              color: Colors.purple,
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  // Fonction pour afficher le dialogue de configuration des notes personnalisées
  Future<List<String>?> _showCustomNotesDialog(
    BuildContext context,
    String classId,
    String matiereId,
  ) async {
    List<String> existingNotes = await _loadCustomNotes(classId, matiereId);
    bool isEditing = existingNotes.isNotEmpty;

    int selectedLevelCount =
        existingNotes.isNotEmpty ? existingNotes.length : 4;

    final Map<int, List<String>> defaultNotes = {
      2: ['0', '1'],
      3: ['0', '0.5', '1'],
      4: ['0', '0.25', '0.5', '1'],
    };

    List<String> currentNotes = isEditing
        ? List.from(existingNotes)
        : List.from(defaultNotes[selectedLevelCount] ?? ['0', '1']);

    return showDialog<List<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  maxWidth: 450,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.edit, color: Colors.purple),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEditing
                                        ? 'تعديل التقييم'
                                        : 'إنشاء نظام تقييم',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'اختر عدد المستويات وعدّلها',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(
                          'عدد المستويات:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLevelButton(
                              count: 2,
                              isSelected: selectedLevelCount == 2,
                              onTap: () {
                                setState(() {
                                  selectedLevelCount = 2;
                                  currentNotes = List.from(defaultNotes[2]!);
                                });
                              },
                            ),
                            SizedBox(width: 12),
                            _buildLevelButton(
                              count: 3,
                              isSelected: selectedLevelCount == 3,
                              onTap: () {
                                setState(() {
                                  selectedLevelCount = 3;
                                  currentNotes = List.from(defaultNotes[3]!);
                                });
                              },
                            ),
                            SizedBox(width: 12),
                            _buildLevelButton(
                              count: 4,
                              isSelected: selectedLevelCount == 4,
                              onTap: () {
                                setState(() {
                                  selectedLevelCount = 4;
                                  currentNotes = List.from(defaultNotes[4]!);
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        Text(
                          'القيم:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: currentNotes.asMap().entries.map((entry) {
                            int idx = entry.key;
                            Color color =
                                _getLevelColor(idx, currentNotes.length);
                            return Container(
                              width:
                                  (MediaQuery.of(context).size.width - 80) / 2,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: color.withOpacity(0.3)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _getLevelLabel(idx),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.edit,
                                      color: Colors.blue, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'عدّل الملاحظات:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              ...List.generate(currentNotes.length, (index) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _getLevelColor(
                                              index, currentNotes.length),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(
                                              text: currentNotes[index]),
                                          onChanged: (value) {
                                            currentNotes[index] = value;
                                          },
                                          decoration: InputDecoration(
                                            hintText: 'ملاحظة ${index + 1}',
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('إلغاء'),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final validNotes = currentNotes
                                      .map((n) => n.trim())
                                      .where((n) => n.isNotEmpty)
                                      .toList();

                                  if (validNotes.length < 2) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('أدخل ملاحظتين على الأقل'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.pop(context, validNotes);
                                },
                                icon: Icon(Icons.check, size: 18),
                                label: Text('تأكيد'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(vertical: 12),
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
          },
        );
      },
    );
  }

  Widget _buildLevelButton({
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
            SizedBox(height: 4),
            Text(
              'مستويات',
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(int index, int total) {
    if (total == 2) {
      return index == 0 ? Colors.red : Colors.green;
    } else if (total == 3) {
      return index == 0
          ? Colors.red
          : index == 1
              ? Colors.orange
              : Colors.green;
    } else {
      return index == 0
          ? Colors.red
          : index == 1
              ? Colors.orange
              : index == 2
                  ? Colors.amber
                  : Colors.green;
    }
  }

  String _getLevelLabel(int index) {
    final labels = ['الأقل', 'ضعيف', 'متوسط', 'الأعلى'];
    return labels[index.clamp(0, 3)];
  }

  // Fonction pour sauvegarder les notes personnalisées
//   Future<void> _saveCustomNotes(
//     String classId,
//     String matiereId,
//     List<String> notes,
//   ) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(currentUser!.uid)
//           .collection('bareme_custom_notes')
//           .doc('$classId-$matiereId')
//           .set({
//         'notes': notes,
//         'createdAt': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       print('Erreur lors de la sauvegarde des notes personnalisées: $e');
//       rethrow;
//     }
//   }

  // Fonction pour charger les notes personnalisées
  Future<List<String>> _loadCustomNotes(
    String classId,
    String matiereId,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('bareme_custom_notes')
          .doc('$classId-$matiereId')
          .get();

      if (doc.exists && doc.data()?['notes'] != null) {
        return List<String>.from(doc.data()!['notes']);
      }
      return [];
    } catch (e) {
      print('Erreur lors du chargement des notes personnalisées: $e');
      return [];
    }
  }

  // Mettre à jour _getSystemColor pour inclure le système personnalisé
  Color _getSystemColor(String system) {
    switch (system) {
      case 'character':
        return Colors.blue;
      case 'note_0_1_5':
        return Colors.green;
      case 'note_0_3':
        return Colors.orange;
      case 'note_0_6':
        return Colors.purple;
      case 'custom':
        return Colors.pink;
      default:
        return Colors.blue;
    }
  }

  // Mettre à jour _getSystemIcon pour inclure le système personnalisé
  IconData _getSystemIcon(String system) {
    switch (system) {
      case 'character':
        return Icons.tag;
      case 'note_0_1_5':
        return Icons.percent;
      case 'note_0_3':
        return Icons.percent;
      case 'note_0_6':
        return Icons.percent;
      case 'custom':
        return Icons.edit;
      default:
        return Icons.tag;
    }
  }

  // Mettre à jour _getSystemLabel pour inclure le système personnalisé
  String _getSystemLabel(String system) {
    switch (system) {
      case 'character':
        return 'نظام الرموز';
      case 'note_0_1_5':
        return '0-1.5';
      case 'note_0_3':
        return '0-3';
      case 'note_0_6':
        return '0-6';
      case 'custom':
        return 'مخصص';
      default:
        return 'نظام الرموز';
    }
  }

  // Mettre à jour _getSystemDescription pour inclure le système personnalisé
  String _getSystemDescription(String system) {
    switch (system) {
      case 'character':
        return 'التقييم باستخدام الرموز: --- / +-- / ++- / +++';
      case 'note_0_1_5':
        return 'التقييم باستخدام النقاط: 0 / 0.5 / 1 / 1.5';
      case 'note_0_3':
        return 'التقييم باستخدام النقاط: 0 / 1 / 2 / 3';
      case 'note_0_6':
        return 'التقييم باستخدام النقاط: 0 / 2 / 4 / 6';
      case 'custom':
        return 'نظام تقييم مخصص حسب اختيارك';
      default:
        return 'نظام التقييم بالرموز';
    }
  }

  // Mettre à jour _getEvaluationColors pour inclure le système personnalisé
  Map<String, Color> _getEvaluationColors(String system,
      {List<String>? customNotes}) {
    if (system == 'character') {
      return {
        '( - - - )': Colors.red,
        '( + - - )': Colors.orange,
        '( + + - )': Colors.amber,
        '( + + + )': Colors.green,
      };
    } else if (system == 'custom' && customNotes != null) {
      // Pour le système personnalisé, utiliser un dégradé
      final Map<String, Color> colors = {};
      final int count = customNotes.length;

      for (int i = 0; i < count; i++) {
        final note = customNotes[i];
        final ratio = i / (count - 1);

        if (ratio < 0.25)
          colors[note] = Colors.red;
        else if (ratio < 0.5)
          colors[note] = Colors.orange;
        else if (ratio < 0.75)
          colors[note] = Colors.amber;
        else
          colors[note] = Colors.green;
      }

      return colors;
    } else {
      // Pour les systèmes de notes
      return {
        '0': Colors.red,
        '0.5': system == 'note_0_1_5' ? Colors.orange : Colors.red,
        '1': system == 'note_0_1_5'
            ? Colors.amber
            : system == 'note_0_3'
                ? Colors.orange
                : Colors.red,
        '1.5': Colors.green,
        '2': system == 'note_0_3' ? Colors.amber : Colors.orange,
        '3': Colors.green,
        '4': Colors.amber,
        '6': Colors.green,
      };
    }
  }

  // Mettre à jour _getDisplayEvaluation pour inclure le système personnalisé
  String _getDisplayEvaluation(String storedValue, String system,
      {List<String>? customNotes, String? baremeId, String? sousBaremeId}) {
    if (storedValue == 'غائب') {
      return 'غائب';
    }

    // Priorité: sous-barème > barème > système global
    if (system == 'custom' && customNotes != null && customNotes.isNotEmpty) {
      if (storedValue == '( - - - )') return customNotes[0];
      if (storedValue == '( + - - )') {
        return customNotes.length > 1 ? customNotes[1] : customNotes[0];
      }
      if (storedValue == '( + + - )') {
        if (customNotes.length == 3) return customNotes[1];
        if (customNotes.length >= 3) return customNotes[2];
        return customNotes.isNotEmpty ? customNotes.last : '( + + - )';
      }
      if (storedValue == '( + + + )') return customNotes.last;
      return customNotes[0];
    }

    switch (system) {
      case 'character':
        return storedValue;

      case 'note_0_1_5':
        switch (storedValue) {
          case '( - - - )':
            return '0';
          case '( + - - )':
            return '0.5';
          case '( + + - )':
            return '1';
          case '( + + + )':
            return '1.5';
          default:
            return '0';
        }

      case 'note_0_3':
        switch (storedValue) {
          case '( - - - )':
            return '0';
          case '( + - - )':
            return '1';
          case '( + + - )':
            return '2';
          case '( + + + )':
            return '3';
          default:
            return '0';
        }

      case 'note_0_6':
        switch (storedValue) {
          case '( - - - )':
            return '0';
          case '( + - - )':
            return '2';
          case '( + + - )':
            return '4';
          case '( + + + )':
            return '6';
          default:
            return '0';
        }

      default:
        return storedValue;
    }
  }

  // Widget pour les sous-barèmes avec système personnalisé spécifique
  Widget _buildSousBaremeCard(
    Map<String, dynamic> sousBareme,
    Function setState,
    List<String> parentOptions, // Options du barème parent
    Map<String, Color> parentColors,
    String system, {
    required String classId,
    required String matiereId,
    required String baremeId,
  }) {
    // Déterminer les options d'affichage pour ce sous-barème spécifique
    final sousBaremeCustomNotes = sousBareme['customNotes'] as List<String>?;

    // Si le système est personnalisé et que ce sous-barème a ses propres notes
    bool hasSpecificNotes = system == 'custom' &&
        sousBaremeCustomNotes != null &&
        sousBaremeCustomNotes.isNotEmpty;

    final displayEvaluationOptions =
        hasSpecificNotes ? sousBaremeCustomNotes! : parentOptions;

    final evaluationColors = hasSpecificNotes
        ? _getEvaluationColors(system, customNotes: sousBaremeCustomNotes)
        : parentColors;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: Column(
        children: [
          ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(sousBareme['sousBaremeName'] ?? 'Sans nom'),
                ),
                if (system == 'custom')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasSpecificNotes)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, size: 10, color: Colors.purple),
                              SizedBox(width: 4),
                              Text(
                                'مخصص',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      IconButton(
                        icon: Icon(Icons.settings, size: 18),
                        onPressed: () async {
                          // Configurer les notes personnalisées pour ce sous-barème spécifique
                          final customNotes = await _showCustomNotesDialog(
                            context,
                            classId,
                            matiereId,
                          );

                          if (customNotes != null && customNotes.isNotEmpty) {
                            // Sauvegarder les notes pour ce sous-barème spécifique
                            await _saveSousBaremeCustomNotes(
                              classId,
                              matiereId,
                              baremeId,
                              sousBareme['id'],
                              customNotes,
                            );

                            // Mettre à jour l'état local
                            setState(() {
                              sousBareme['customNotes'] = customNotes;

                              // Mettre à jour la valeur d'affichage
                              sousBareme['displayEvaluation'] =
                                  _getDisplayEvaluation(
                                sousBareme['storedEvaluation'] ?? '( - - - )',
                                system,
                                customNotes: customNotes,
                              );
                            });
                          }
                        },
                        tooltip: 'تخصيص النظام لهذا المعيار الفرعي',
                        padding: EdgeInsets.all(4),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Afficher les notes personnalisées spécifiques à ce sous-barème
          // if (hasSpecificNotes)
          //   Container(
          //     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //     child: Wrap(
          //       spacing: 8,
          //       runSpacing: 4,
          //       alignment: WrapAlignment.center,
          //       children: sousBaremeCustomNotes!.map((note) {
          //         return Container(
          //           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //           decoration: BoxDecoration(
          //             color: Colors.purple.withOpacity(0.1),
          //             borderRadius: BorderRadius.circular(6),
          //             border: Border.all(
          //               color: Colors.purple,
          //               width: 1,
          //             ),
          //           ),
          //           child: Text(
          //             note,
          //             style: TextStyle(
          //               color: Colors.purple,
          //               fontSize: 12,
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //         );
          //       }).toList(),
          //     ),
          //   ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildEvaluationButtons(
              displayEvaluationOptions,
              evaluationColors,
              sousBareme['displayEvaluation'],
              system,
              (newDisplayValue) {
                // Convertir pour le stockage - UTILISER LES NOTES SPÉCIFIQUES SI DISPONIBLES
                String storedValue = _getMappedEvaluation(
                  newDisplayValue,
                  system,
                  customNotes: hasSpecificNotes ? sousBaremeCustomNotes : null,
                );

                setState(() {
                  sousBareme['displayEvaluation'] = newDisplayValue;
                  sousBareme['storedEvaluation'] = storedValue;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // Fonction de sauvegarde simplifiée
  Future<void> _saveEvaluationsSimple({
    required String classId,
    required String studentId,
    required List<Map<String, dynamic>> selections,
  }) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("Aucun utilisateur connecté");

      // Pour chaque sélection
      for (var selection in selections) {
        final String baremeId = selection['baremeId'];

        if ((selection['sousBaremes'] as List).isNotEmpty) {
          // Pour les barèmes avec sous-barèmes
          for (var sousBareme
              in selection['sousBaremes'] as List<Map<String, dynamic>>) {
            final String sousBaremeId = sousBareme['id'];
            final String? evaluationValue = sousBareme['storedEvaluation'];

            if (evaluationValue != null) {
              // Chemin pour le sous-barème direct
              final directDocRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('user_classes')
                  .doc(classId)
                  .collection('students')
                  .doc(studentId)
                  .collection('baremes')
                  .doc(sousBaremeId);

              // Chemin pour le sous-barème imbriqué
              final nestedDocRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('user_classes')
                  .doc(classId)
                  .collection('students')
                  .doc(studentId)
                  .collection('baremes')
                  .doc(baremeId)
                  .collection('sous_baremes')
                  .doc(sousBaremeId);

              // Préparer les données
              Map<String, dynamic> data = {
                'Marks': evaluationValue,
                'createdAt': FieldValue.serverTimestamp(),
              };

              // Ajouter le statut absent si nécessaire
              if (evaluationValue == 'غائب') {
                data['isAbsent'] = true;
                data['absenceDate'] = Timestamp.now();
              } else {
                data['isAbsent'] = false;
                data['absenceDate'] = null;
              }

              // Écrire dans les deux emplacements
              await Future.wait([
                directDocRef.set(data, SetOptions(merge: true)),
                nestedDocRef.set(data, SetOptions(merge: true)),
              ]);

              // Mettre à jour le barème principal pour indiquer qu'il a des sous-barèmes
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('user_classes')
                  .doc(classId)
                  .collection('students')
                  .doc(studentId)
                  .collection('baremes')
                  .doc(baremeId)
                  .set({
                'haveSoubarem': true,
                'createdAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            }
          }
        } else {
          // Pour les barèmes sans sous-barèmes
          final String? evaluationValue = selection['storedEvaluation'];

          if (evaluationValue != null) {
            Map<String, dynamic> data = {
              'Marks': evaluationValue,
              'createdAt': FieldValue.serverTimestamp(),
            };

            // Ajouter le statut absent si nécessaire
            if (evaluationValue == 'غائب') {
              data['isAbsent'] = true;
              data['absenceDate'] = Timestamp.now();
            } else {
              data['isAbsent'] = false;
              data['absenceDate'] = null;
            }

            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .collection('user_classes')
                .doc(classId)
                .collection('students')
                .doc(studentId)
                .collection('baremes')
                .doc(baremeId)
                .set(data, SetOptions(merge: true));
          }
        }
      }

      print('Sauvegarde réussie');
    } catch (e) {
      print('Erreur lors de la sauvegarde simplifiée: $e');
      rethrow;
    }
  }

  // Fonction pour charger les données de sélection
  Future<void> _loadSelectionsData(
    String classId,
    String matiereId,
    String studentId,
    String selectedSystem,
    Function(List<Map<String, dynamic>>) onDataLoaded,
  ) async {
    List<Map<String, dynamic>> selections = [];

    CollectionReference selectionsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('selections')
        .doc(classId)
        .collection(matiereId);

    var selectionsSnapshot = await selectionsRef.get();

    await Future.wait(selectionsSnapshot.docs.map((doc) async {
      // Charger les notes personnalisées pour ce barème
      List<String> baremeCustomNotes = [];
      if (selectedSystem == 'custom') {
        baremeCustomNotes =
            await _loadBaremeCustomNotes(classId, matiereId, doc.id);
      }

      var sousBaremesRef = doc.reference.collection('sousBaremes');
      var sousBaremesSnapshot = await sousBaremesRef.get();
      List<Map<String, dynamic>> sousBaremes = [];

      await Future.wait(sousBaremesSnapshot.docs.map((sousDoc) async {
        // CHARGER LES NOTES PERSONNALISÉES SPÉCIFIQUES AU SOUS-BARÈME
        List<String> sousBaremeCustomNotes = [];
        if (selectedSystem == 'custom') {
          sousBaremeCustomNotes = await _loadSousBaremeCustomNotes(
            classId,
            matiereId,
            doc.id,
            sousDoc.id,
          );
        }

        // Récupérer la valeur stockée (toujours en caractères)
        String? storedEvaluation = await _getEvaluation(
          classId: classId,
          studentId: studentId,
          baremeId: doc.id,
          sousBaremeId: sousDoc.id,
        );

        // Convertir pour l'affichage - UTILISER LES NOTES DU SOUS-BARÈME SI DISPONIBLES
        // Dans _loadSelectionsData, quand vous créez les sous-barèmes
        String displayValue = _getDisplayEvaluation(
          storedEvaluation ?? '( - - - )',
          selectedSystem,
          customNotes: sousBaremeCustomNotes.isNotEmpty
              ? sousBaremeCustomNotes // Notes spécifiques au sous-barème
              : baremeCustomNotes, // Sinon notes du barème parent
          baremeId: doc.id,
          sousBaremeId: sousDoc.id,
        );

        sousBaremes.add({
          'id': sousDoc.id,
          'sousBaremeName': sousDoc['sousBaremeName'],
          'displayEvaluation': displayValue,
          'storedEvaluation': storedEvaluation ?? '( - - - )',
          'customNotes':
              sousBaremeCustomNotes, // Notes spécifiques au sous-barème
          'parentBaremeId': doc.id, // ID du barème parent
        });
      }));

      // TRIER LES SOUS-BARÈMES
      sousBaremes.sort((a, b) =>
          (a['sousBaremeName'] ?? '').compareTo(b['sousBaremeName'] ?? ''));

      // Pour les barèmes principaux
      String? storedEvaluation = sousBaremes.isEmpty
          ? await _getEvaluation(
              classId: classId, studentId: studentId, baremeId: doc.id)
          : null;

      String displayValue = _getDisplayEvaluation(
        storedEvaluation ?? '( - - - )',
        selectedSystem,
        customNotes: baremeCustomNotes,
      );

      selections.add({
        'id': doc.id,
        'baremeId': doc['baremeId'],
        'baremeName': doc['baremeName'],
        'displayEvaluation': displayValue,
        'storedEvaluation': storedEvaluation ?? '( - - - )',
        'sousBaremes': sousBaremes,
        'customNotes':
            baremeCustomNotes, // Stocker les notes personnalisées pour ce barème
      });
    }));

    // TRIER LES BARÈMES
    selections.sort(
        (a, b) => (a['baremeName'] ?? '').compareTo(b['baremeName'] ?? ''));

    onDataLoaded(selections);
  }

  // Fonction pour charger les notes personnalisées d'un barème spécifique
  Future<List<String>> _loadBaremeCustomNotes(
    String classId,
    String matiereId,
    String baremeId,
  ) async {
    try {
      // D'abord essayer de charger les notes spécifiques au barème
      final baremeDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('bareme_custom_notes')
          .doc('$classId-$matiereId-$baremeId')
          .get();

      if (baremeDoc.exists && baremeDoc.data()?['notes'] != null) {
        return List<String>.from(baremeDoc.data()!['notes']);
      }

      // Si pas de notes spécifiques, charger les notes globales
      return await _loadCustomNotes(classId, matiereId);
    } catch (e) {
      print('Erreur lors du chargement des notes personnalisées du barème: $e');
      return [];
    }
  }

  // Fonction pour sauvegarder les notes personnalisées d'un barème spécifique
  Future<void> _saveBaremeCustomNotes(
    String classId,
    String matiereId,
    String baremeId,
    List<String> notes,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('bareme_custom_notes')
          .doc('$classId-$matiereId-$baremeId')
          .set({
        'notes': notes,
        'createdpppAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print(
          'Erreur lors de la sauvegarde des notes personnalisées du barème: $e');
      rethrow;
    }
  }

  // Fonction pour charger les notes personnalisées d'un sous-barème spécifique
  Future<List<String>> _loadSousBaremeCustomNotes(
    String classId,
    String matiereId,
    String baremeId,
    String sousBaremeId,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('sous_bareme_custom_notes')
          .doc('$classId-$matiereId-$baremeId-$sousBaremeId')
          .get();

      if (doc.exists && doc.data()?['notes'] != null) {
        return List<String>.from(doc.data()!['notes']);
      }

      // Si pas de notes spécifiques, essayer de charger les notes du barème parent
      return await _loadBaremeCustomNotes(classId, matiereId, baremeId);
    } catch (e) {
      print('Erreur lors du chargement des notes du sous-barème: $e');
      return [];
    }
  }

  // Fonction pour sauvegarder les notes personnalisées d'un sous-barème
  Future<void> _saveSousBaremeCustomNotes(
    String classId,
    String matiereId,
    String baremeId,
    String sousBaremeId,
    List<String> notes,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('sous_bareme_custom_notes')
          .doc('$classId-$matiereId-$baremeId-$sousBaremeId')
          .set({
        'notes': notes,
        'parentBaremeId': baremeId,
        'parentMatiereId': matiereId,
        'parentClassId': classId,
        'sousBaremeId': sousBaremeId, // Ajout du champ
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la sauvegarde des notes du sous-barème: $e');
      rethrow;
    }
  }

  Future<bool> _hasCustomNotes(
    String classId,
    String matiereId,
  ) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('custom_evaluation_systems')
          .doc('$classId-$matiereId')
          .get();

      return doc.exists && doc.data()?['notes'] != null;
    } catch (e) {
      print('Erreur lors de la vérification des notes personnalisées: $e');
      return false;
    }
  }

  Future<void> _deleteCustomNotes(
    String classId,
    String matiereId,
  ) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('bareme_custom_notes')
          .doc('$classId-$matiereId')
          .delete();

      print('Notes personnalisées supprimées avec succès');
    } catch (e) {
      print('Erreur lors de la suppression des notes personnalisées: $e');
      rethrow;
    }
  }

  Future<Color> _getStudentIndicatorColor(
      String classId, String studentId, String? subjectId) async {
    if (subjectId == null || subjectId.isEmpty) return Colors.red;

    try {
      // 1. Vérifier s'il y a des sélections pour cette matière
      final selectionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(classId)
          .collection(subjectId)
          .limit(1)
          .get();

      if (selectionsSnapshot.docs.isEmpty) {
        return Colors.red; // Pas encore programmé (aucun barème défini)
      }

      // 2. Récupérer toutes les sélections
      final allSelections = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(classId)
          .collection(subjectId)
          .get();

      int totalBaremes = 0;
      int evaluatedBaremes = 0;

      // 3. Parcourir toutes les sélections
      for (var selection in allSelections.docs) {
        final baremeId = selection.id;
        if (baremeId.isEmpty) continue;

        if (!selection.exists) continue;

        final data = selection.data();

        // Vérifier si ce bareme a des sous-baremes
        final hasSousBaremes =
            (data['sousBaremes'] as List<dynamic>?)?.isNotEmpty ?? false;

        if (hasSousBaremes) {
          try {
            // Compter les sous-baremes
            final sousBaremesSnapshot =
                await selection.reference.collection('sousBaremes').get();

            totalBaremes += sousBaremesSnapshot.docs.length;

            // Vérifier chaque sous-bareme
            for (var sousBareme in sousBaremesSnapshot.docs) {
              final sousBaremeId = sousBareme.id;
              if (sousBaremeId.isEmpty) continue;

              try {
                final evaluation = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .collection('user_classes')
                    .doc(classId)
                    .collection('students')
                    .doc(studentId)
                    .collection('baremes')
                    .doc(sousBaremeId)
                    .get();

                // MODIFICATION IMPORTANTE :
                // Une évaluation existe si le document existe (peu importe la valeur)
                if (evaluation.exists) {
                  evaluatedBaremes++;
                }
              } catch (e) {
                print(
                    'Erreur lors de la récupération de l\'évaluation pour sous-bareme $sousBaremeId: $e');
                continue;
              }
            }
          } catch (e) {
            print('Erreur lors de la récupération des sous-baremes: $e');
            continue;
          }
        } else {
          // Bareme principal sans sous-baremes
          totalBaremes++;

          try {
            final evaluation = await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser!.uid)
                .collection('user_classes')
                .doc(classId)
                .collection('students')
                .doc(studentId)
                .collection('baremes')
                .doc(baremeId)
                .get();

            // MODIFICATION IMPORTANTE :
            // Une évaluation existe si le document existe (peu importe la valeur)
            if (evaluation.exists) {
              evaluatedBaremes++;
            }
          } catch (e) {
            print(
                'Erreur lors de la récupération de l\'évaluation pour bareme $baremeId: $e');
            continue;
          }
        }
      }

      // Déterminer la couleur
      if (totalBaremes == 0) {
        return Colors.red; // Pas de baremes programmés
      } else if (evaluatedBaremes == 0) {
        return Colors.red; // Aucune évaluation (pas de documents)
      } else if (evaluatedBaremes == totalBaremes) {
        return Colors
            .green; // Toutes les évaluations faites (même si certaines sont 0/---)
      } else if (evaluatedBaremes > 0) {
        return Colors.orange; // Évaluations partielles
      } else {
        return Colors.red;
      }
    } catch (e) {
      print('Erreur dans _getStudentIndicatorColor: $e');
      return Colors.grey;
    }
  }

  Widget _buildClassList() {
    return _selectedClass == null
        ? _buildClassListView()
        : _buildClassDetailsView();
  }

  Widget _buildClassListView() {
    if (_isLoadingClasses) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "جاري تحميل الأقسام...",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshClasses,
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // En-tête des classes
          if (_classes.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Titre et compteur
                  Row(
                    children: [
                      Icon(Icons.class_, color: Theme.of(context).primaryColor),
                      SizedBox(width: 8),
                      Text(
                        "الأقسام الدراسية",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${_classes.length} قسم",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Boutons d'action
                  Row(
                    children: [
                      // Bouton Rafraîchir
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.blue[50],
                          border: Border.all(
                              color: const Color.fromARGB(255, 169, 230, 235)),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.refresh,
                                color: _isRefreshingClasses
                                    ? Colors.grey[400]
                                    : Colors.blue[700],
                                size: 22,
                              ),
                              onPressed:
                                  _isRefreshingClasses ? null : _refreshClasses,
                              tooltip: 'تحديث قائمة الأقسام',
                              padding: EdgeInsets.all(8),
                            ),
                            if (_isRefreshingClasses)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      SizedBox(width: 8),

                      // Bouton Ajouter une classe
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.green[50],
                          border: Border.all(
                              color: const Color.fromARGB(255, 188, 221, 189)),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.add,
                            color: Colors.green[700],
                            size: 22,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddClassPage(),
                              ),
                            ).then((_) {
                              // Rafraîchir après ajout
                              _refreshClasses();
                            });
                          },
                          tooltip: 'إضافة قسم جديد',
                          padding: EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Liste des classes
          Expanded(
            child: _classes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.class_,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          "لا توجد أقسام متاحة",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            "يجب عليك إضافة قسم من خلال زر 'إضافة قسم جديد'",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('إضافة قسم جديد'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddClassPage(),
                              ),
                            ).then((_) {
                              // Rafraîchir après ajout
                              _refreshClasses();
                            });
                          },
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    itemCount: _classes.length,
                    itemBuilder: (context, index) {
                      final classData = _classes[index];
                      return _buildClassListItem(classData);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassListItem(Map<String, dynamic> classData) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectClass(classData),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      classData['class_name'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteClass(classData['id']),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Nombre d'élèves
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.people, size: 12, color: Colors.blue),
                            SizedBox(width: 4),
                            Text(
                              "${classData['students'].length}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      // Nombre de matières
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.subject, size: 12, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              "${classData['subjects'].length}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nouveau bouton pour ajout multiple
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.post_add,
                            color: Colors.purple[700],
                            size: 20,
                          ),
                          onPressed: () =>
                              _addMultipleStudentsDialog(classData),
                          tooltip: 'إضافة قائمة تلاميذ',
                          padding: EdgeInsets.all(8),
                        ),
                      ),
                      // Bouton existant pour ajout individuel
                      TextButton.icon(
                        icon: Icon(Icons.person_add, size: 16),
                        label: Text('إضافة'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                        onPressed: () => _addStudent(classData),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectClass(Map<String, dynamic> classData,
      {bool autoLoadStudents = false}) {
    setState(() {
      _selectedClass = classData;
      selectedClassId = classData['class_id']?.toString();
      _showStudentsList = false;
      _students = [];
      _isLoadingStudents = false;
      _isLoadingSubjects = true; // Commencer le chargement des matières
    });

    // Charger les matières pour cette classe
    _loadSubjectsForClass(classData);

    if (autoLoadStudents) {
      _loadStudentsForClass();
    }
  }

  // Nouvelle méthode pour charger les matières
  Future<void> _loadSubjectsForClass(Map<String, dynamic> classData) async {
    try {
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classData['class_id'])
          .collection('matieres')
          .get();

      if (classDoc.docs.isNotEmpty) {
        List<Map<String, dynamic>> availableSubjects = [];

        for (var doc in classDoc.docs) {
          availableSubjects.add({
            'id': doc.id,
            'name': doc['name'] as String,
          });
        }

        // Trier par ordre alphabétique
        availableSubjects.sort((a, b) => a['name'].compareTo(b['name']));

        if (mounted) {
          setState(() {
            _subjects = availableSubjects;
            _isLoadingSubjects = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _subjects = [];
            _isLoadingSubjects = false;
          });
        }
      }
    } catch (e) {
      print("Erreur lors de la récupération des matières : $e");
      if (mounted) {
        setState(() {
          _subjects = [];
          _isLoadingSubjects = false;
        });
      }
    }
  }

  Widget _buildClassDetailsView() {
    return Column(
      children: [
        AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _selectedClass = null;
                _showStudentsList = false;
              });
            },
          ),
          title: Text(_selectedClass!['class_name']),
          // SUPPRIMER LE BOUTON "إضافة مادة" QUAND ON EST DANS LA LISTE DES ÉTUDIANTS
          actions: [
            if (!_showStudentsList) // <-- AJOUTER CETTE CONDITION
              TextButton.icon(
                icon: Icon(Icons.add, size: 20),
                label: Text('إضافة مادة'),
                style: TextButton.styleFrom(
                  foregroundColor: Color.fromARGB(255, 10, 101, 236),
                ),
                onPressed: () => _addSubjectDialog(_selectedClass!),
              ),
          ],
        ),
        Expanded(
          child:
              _showStudentsList ? _buildStudentsList() : _buildSubjectsGrid(),
        ),
      ],
    );
  }

  Widget _buildSubjectsGrid() {
    if (_isLoadingSubjects) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "جاري تحميل المواد...",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final subjects = _selectedClass!['subjects'];
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: _refreshSubjects,
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // En-tête des matières
          if (subjects.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Titre et compteur
                  Row(
                    children: [
                      Icon(Icons.subject,
                          color: Theme.of(context).primaryColor),
                      SizedBox(width: 8),
                      Text(
                        "المواد الدراسية",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${subjects.length} مادة",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Boutons d'action
                  Row(
                    children: [
                      // Bouton Rafraîchir
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.blue[50],
                          border: Border.all(
                              color: const Color.fromARGB(255, 60, 110, 150)),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.refresh,
                                color: _isRefreshingSubjects
                                    ? Colors.grey[400]
                                    : Colors.blue[700],
                                size: 22,
                              ),
                              onPressed: _isRefreshingSubjects
                                  ? null
                                  : _refreshSubjects,
                              tooltip: 'تحديث قائمة المواد',
                              padding: EdgeInsets.all(8),
                            ),
                            if (_isRefreshingSubjects)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      SizedBox(width: 8),

                      // Bouton Ajouter une matière
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.green[50],
                          border: Border.all(
                              color: const Color.fromARGB(255, 55, 156, 58)),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.add,
                            color: Colors.green[700],
                            size: 22,
                          ),
                          onPressed: () => _addSubjectDialog(_selectedClass!),
                          tooltip: 'إضافة مادة جديدة',
                          padding: EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Liste des matières
          Expanded(
            child: subjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.subject,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          "لا توجد مواد دراسية",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "انقر على زر 'إضافة مادة' لبدء إضافة المواد",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('إضافة مادة'),
                          onPressed: () => _addSubjectDialog(_selectedClass!),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isSmallScreen ? 2 : 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isSmallScreen ? 0.85 : 0.9,
                    ),
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      final subjectName = subject['name'];
                      return _buildSubjectGridItem(
                        subject,
                        subjectName,
                        SubjectHelper.getIconForSubject(subjectName),
                        SubjectHelper.getSubjectColor(subjectName),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectGridItem(
    Map<String, dynamic> subject,
    String subjectName,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          setState(() {
            selectedSubjectId = subject['id'];
            _showStudentsList = true;
          });
          await _loadStudentsForClass();
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 150, // Set a minimum height
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Important for GridView items
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 32,
                        color: color,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      subjectName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Spacer(),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () =>
                      _confirmDeleteSubject(_selectedClass!, subject['id']),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, size: 18),
                      SizedBox(width: 8),
                      Text('حذف'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadStudentsForClass() async {
    if (!mounted) return;

    setState(() {
      _isLoadingStudents = true;
      _students = [];
    });

    try {
      final students = _selectedClass!['students'];
      List<Map<String, dynamic>> studentsData = [];

      for (var studentId in students) {
        final studentDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('user_classes')
            .doc(_selectedClass!['id'])
            .collection('students')
            .doc(studentId)
            .get();

        if (studentDoc.exists) {
          studentsData.add(
              {'id': studentId, ...studentDoc.data() as Map<String, dynamic>});
        }
      }

      // Trier par ordre alphabétique
      studentsData.sort((a, b) {
        String nameA = (a['name'] ?? '').trim().toLowerCase();
        String nameB = (b['name'] ?? '').trim().toLowerCase();

        // Vérifier les noms vides
        if (nameA.isEmpty && nameB.isEmpty) return 0;
        if (nameA.isEmpty) return 1; // Les noms vides à la fin
        if (nameB.isEmpty) return -1; // Les noms vides à la fin

        return nameA.compareTo(nameB);
      });

      if (mounted) {
        setState(() {
          _students = studentsData;
          _isLoadingStudents = false;
        });
      }

      if (widget.showStudentsForMatiere == true) {
        await _addDefaultStudentsIfEmpty(_selectedClass!);
      }
    } catch (e) {
      print("Erreur lors du chargement des élèves : $e");
      if (mounted) {
        setState(() {
          _isLoadingStudents = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors du chargement des élèves')));
      }
    }
  }

  void _sortStudentsAlphabetically() {
    if (_students.isEmpty) return;

    setState(() {
      _students.sort((a, b) {
        String nameA = (a['name'] ?? '').trim().toLowerCase();
        String nameB = (b['name'] ?? '').trim().toLowerCase();

        if (nameA.isEmpty && nameB.isEmpty) return 0;
        if (nameA.isEmpty) return 1;
        if (nameB.isEmpty) return -1;

        return nameA.compareTo(nameB);
      });
    });
  }

  Future<void> _editStudentName(Map<String, dynamic> student) async {
    TextEditingController nameController =
        TextEditingController(text: student['name'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل اسم التلميذ', textDirection: TextDirection.rtl),
        content: TextField(
          controller: nameController,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            labelText: 'الاسم الجديد',
            hintText: 'أدخل الاسم الجديد',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', textDirection: TextDirection.rtl),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('الاسم لا يمكن أن يكون فارغاً')),
                );
                return;
              }

              final newName = nameController.text.trim();

              try {
                // Afficher un indicateur de chargement
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Mettre à jour dans Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .collection('user_classes')
                    .doc(_selectedClass!['id'])
                    .collection('students')
                    .doc(student['id'])
                    .update({
                  'name': newName,
                });

                // Fermer l'indicateur de chargement
                Navigator.pop(context);

                // Mettre à jour la liste locale
                setState(() {
                  int index =
                      _students.indexWhere((s) => s['id'] == student['id']);
                  if (index != -1) {
                    _students[index]['name'] = newName;
                  }
                });

                // Re-trier la liste
                _sortStudentsAlphabetically();

                Navigator.pop(context); // Fermer la boîte de dialogue

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم تحديث اسم التلميذ بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                // Fermer l'indicateur de chargement en cas d'erreur
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }

                print('خطأ في تحديث الاسم: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('حدث خطأ أثناء تحديث الاسم')),
                );
              }
            },
            child: Text('حفظ', textDirection: TextDirection.rtl),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshStudents() async {
    if (_selectedClass == null) return;

    setState(() {
      _isRefreshing = true;
    });

    await _loadStudentsForClass();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Widget _buildStudentsList() {
    if (_isLoadingStudents) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "جاري تحميل قائمة التلاميذ...",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final isVeryWide = constraints.maxWidth > 900;

        return RefreshIndicator(
          onRefresh: _refreshStudents,
          color: Theme.of(context).primaryColor,
          backgroundColor: Colors.white,
          child: _students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_alt_outlined,
                          size: 60, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        "لا يوجد تلاميذ",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_selectedClass != null)
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.person_add),
                            label: Text("إضافة تلاميذ"),
                            onPressed: () => _addStudent(_selectedClass!),
                          ),
                        ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.all(isWide ? 16 : 8),
                      sliver: SliverToBoxAdapter(
                        child: _buildStudentsHeader(isWide),
                      ),
                    ),
                    if (isVeryWide)
                      SliverPadding(
                        padding:
                            EdgeInsets.symmetric(horizontal: isWide ? 16 : 8),
                        sliver: _buildStudentsGrid(context, 3),
                      )
                    else if (isWide)
                      SliverPadding(
                        padding:
                            EdgeInsets.symmetric(horizontal: isWide ? 16 : 8),
                        sliver: _buildStudentsGrid(context, 2),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        sliver: _buildStudentsListView(),
                      ),
                    SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildStudentsHeader(bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200] ?? Colors.grey, width: 1),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people,
                    size: 16, color: Theme.of(context).primaryColor),
                SizedBox(width: 6),
                Text(
                  '${_students.length} تلميذ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              _buildActionButton(
                icon: Icons.post_add,
                color: Colors.purple,
                tooltip: 'إضافة قائمة تلاميذ',
                onPressed: () => _addMultipleStudentsDialog(_selectedClass!),
                isWide: isWide,
              ),
              _buildActionButton(
                icon: Icons.person_add_alt_1,
                color: Colors.green,
                tooltip: 'إضافة تلميذ جديد',
                onPressed: () => _addStudent(_selectedClass!),
                isWide: isWide,
              ),
              _buildActionButton(
                icon: Icons.refresh,
                color: Colors.blue,
                tooltip: 'تحديث القائمة',
                onPressed: _refreshStudents,
                isWide: isWide,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isWide,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: isWide ? 22 : 20),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.all(isWide ? 10 : 8),
        constraints: BoxConstraints(
          minWidth: isWide ? 44 : 36,
          minHeight: isWide ? 44 : 36,
        ),
      ),
    );
  }

  SliverGrid _buildStudentsGrid(BuildContext context, int crossAxisCount) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildStudentCard(_students[index], isGrid: true),
        childCount: _students.length,
      ),
    );
  }

  SliverList _buildStudentsListView() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: _buildStudentCard(_students[index], isGrid: false),
        ),
        childCount: _students.length,
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student,
      {bool isGrid = false}) {
    final photoBase64 = student['photoBase64'];
    final parentName = student['parentName'] ?? 'غير محدد';
    final birthDate = student['birthDate'];

    return FutureBuilder<Color>(
      future: _getStudentIndicatorColor(
          _selectedClass!['class_id'], student['id'], selectedSubjectId),
      builder: (context, snapshot) {
        final statusColor = snapshot.data ?? Colors.grey;
        bool isAbsent = student['isAbsent'] ?? false;

        if (isGrid) {
          return _buildStudentCardGrid(
              student, photoBase64, statusColor, isAbsent);
        }

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              if (selectedClassId != null && selectedSubjectId != null) {
                await _showSelectionsDialog(
                    selectedClassId!, selectedSubjectId!, student['id']);
              }
            },
            onLongPress: () {
              _showStudentContextMenu(student);
            },
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        child: photoBase64 != null && photoBase64.isNotEmpty
                            ? ClipOval(
                                child: Image.memory(
                                  base64Decode(photoBase64),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.person, size: 26),
                                ),
                              )
                            : Icon(Icons.person, size: 26),
                      ),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            if (isAbsent)
                              Container(
                                margin: EdgeInsets.only(left: 6),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'غائب',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                student['name'],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (parentName != 'غير محدد')
                          Text(
                            parentName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isAbsent ? Icons.person_off : Icons.person_outline,
                          color: isAbsent ? Colors.red : Colors.blue,
                          size: 20,
                        ),
                        onPressed: () => _toggleAbsentStatus(student),
                        tooltip: isAbsent ? 'إلغاء الغياب' : 'تسجيل غياب',
                        padding: EdgeInsets.all(6),
                        constraints:
                            BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      IconButton(
                        icon: Icon(Icons.info_outline,
                            color: Colors.blue, size: 20),
                        onPressed: () =>
                            _showStudentDetails(_selectedClass!, student['id']),
                        padding: EdgeInsets.all(6),
                        constraints:
                            BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: Colors.red[400], size: 20),
                        onPressed: () => _confirmDeleteStudent(
                            _selectedClass!, student['id']),
                        padding: EdgeInsets.all(6),
                        constraints:
                            BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentCardGrid(Map<String, dynamic> student,
      String? photoBase64, Color statusColor, bool isAbsent) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (selectedClassId != null && selectedSubjectId != null) {
            await _showSelectionsDialog(
                selectedClassId!, selectedSubjectId!, student['id']);
          }
        },
        onLongPress: () => _showStudentContextMenu(student),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: photoBase64 != null && photoBase64.isNotEmpty
                        ? ClipOval(
                            child: Image.memory(
                              base64Decode(photoBase64),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.person, size: 24),
                            ),
                          )
                        : Icon(Icons.person, size: 24),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (isAbsent)
                          Container(
                            margin: EdgeInsets.only(left: 4),
                            padding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text('غائب',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        Expanded(
                          child: Text(
                            student['name'],
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      student['parentName'] ?? 'غير محدد',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[600]),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'absent')
                    _toggleAbsentStatus(student);
                  else if (value == 'info')
                    _showStudentDetails(_selectedClass!, student['id']);
                  else if (value == 'delete')
                    _confirmDeleteStudent(_selectedClass!, student['id']);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'absent',
                    child: Row(
                      children: [
                        Icon(isAbsent ? Icons.person : Icons.person_off,
                            size: 18,
                            color: isAbsent ? Colors.red : Colors.blue),
                        SizedBox(width: 8),
                        Text(isAbsent ? 'إلغاء الغياب' : 'تسجيل غياب'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('معلومات'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('حذف', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleAbsentStatus(Map<String, dynamic> student) async {
    try {
      final isCurrentlyAbsent = student['isAbsent'] ?? false;
      final newAbsentStatus = !isCurrentlyAbsent;

      // Mettre à jour dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(_selectedClass!['id'])
          .collection('students')
          .doc(student['id'])
          .update({
        'isAbsent': newAbsentStatus,
        'absenceDate': newAbsentStatus ? Timestamp.now() : null,
      });

      // Mettre à jour localement
      setState(() {
        int index = _students.indexWhere((s) => s['id'] == student['id']);
        if (index != -1) {
          _students[index]['isAbsent'] = newAbsentStatus;
          if (newAbsentStatus) {
            _students[index]['absenceDate'] = Timestamp.now();
          } else {
            _students[index]['absenceDate'] = null;
          }
        }
      });

      // Gestion des évaluations selon le statut
      if (selectedClassId != null && selectedSubjectId != null) {
        if (newAbsentStatus) {
          // Marquer comme absent dans tous les barèmes
          await _markStudentAbsentInAllBaremes(
            selectedClassId!,
            selectedSubjectId!,
            student['id'],
          );
        } else {
          // IMPORTANT: Supprimer le statut absent de tous les barèmes
          await _removeAbsentStatusFromAllBaremes(
            selectedClassId!,
            selectedSubjectId!,
            student['id'],
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newAbsentStatus ? 'تم تسجيل التلميذ كغائب' : 'تم إلغاء حالة الغياب',
          ),
          backgroundColor: newAbsentStatus ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      print('Erreur lors du changement du statut d\'absence: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تغيير حالة الغياب'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// NOUVELLE MÉTHODE: Supprimer le statut absent de tous les barèmes
  Future<void> _removeAbsentStatusFromAllBaremes(
    String classId,
    String matiereId,
    String studentId,
  ) async {
    try {
      // Récupérer tous les barèmes et sous-barèmes
      final selectionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(classId)
          .collection(matiereId);

      final selectionsSnapshot = await selectionsRef.get();

      for (final baremeDoc in selectionsSnapshot.docs) {
        final baremeId = baremeDoc.id;
        final isBaremeSelected = baremeDoc['selected'] ?? false;

        // Supprimer le statut absent du barème principal
        if (isBaremeSelected) {
          await _removeAbsentFromBareme(
            classId: classId,
            studentId: studentId,
            baremeId: baremeId,
          );
        }

        // Supprimer le statut absent des sous-barèmes
        final sousBaremesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('selections')
            .doc(classId)
            .collection(matiereId)
            .doc(baremeId)
            .collection('sousBaremes')
            .get();

        for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
          final sousBaremeId = sousBaremeDoc.id;
          final isSousBaremeSelected = sousBaremeDoc['selected'] ?? false;

          if (isSousBaremeSelected) {
            await _removeAbsentFromSousBareme(
              classId: classId,
              studentId: studentId,
              baremeId: baremeId,
              sousBaremeId: sousBaremeId,
            );
          }
        }
      }

      print('✅ Statut absent supprimé de tous les barèmes');
    } catch (e) {
      print('❌ Erreur lors de la suppression du statut absent: $e');
    }
  }

// NOUVELLE MÉTHODE: Supprimer le statut absent d'un barème principal
  Future<void> _removeAbsentFromBareme({
    required String classId,
    required String studentId,
    required String baremeId,
  }) async {
    try {
      // Récupérer le document du barème
      final baremeRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .collection('baremes')
          .doc(baremeId);

      final baremeDoc = await baremeRef.get();

      if (baremeDoc.exists) {
        // Sauvegarder la note actuelle avant de la modifier
        final currentMarks = baremeDoc.data()?['Marks'] ?? '( - - - )';

        // Si la note actuelle est 'غائب', on veut la remettre à la valeur par défaut
        // Sinon, on garde la note actuelle
        final marksToKeep = currentMarks == 'غائب' ? '( - - - )' : currentMarks;

        await baremeRef.set({
          'Marks': marksToKeep,
          'isAbsent': false,
          'absenceDate': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Erreur suppression absent du barème $baremeId: $e');
    }
  }

// NOUVELLE MÉTHODE: Supprimer le statut absent d'un sous-barème
  Future<void> _removeAbsentFromSousBareme({
    required String classId,
    required String studentId,
    required String baremeId,
    required String sousBaremeId,
  }) async {
    try {
      // Pour les sous-barèmes, deux emplacements possibles
      final sousBaremeDirectRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .collection('baremes')
          .doc(sousBaremeId);

      final sousBaremeNestedRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .collection('baremes')
          .doc(baremeId)
          .collection('sous_baremes')
          .doc(sousBaremeId);

      // Mettre à jour dans les deux emplacements
      await Future.wait([
        sousBaremeDirectRef.set({
          'Marks': '( - - - )',
          'isAbsent': false,
          'absenceDate': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
        sousBaremeNestedRef.set({
          'Marks': '( - - - )',
          'isAbsent': false,
          'absenceDate': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      ]);
    } catch (e) {
      print('Erreur suppression absent du sous-barème $sousBaremeId: $e');
    }
  }

  Future<void> _markStudentAbsentInAllBaremes(
    String classId,
    String matiereId,
    String studentId,
  ) async {
    try {
      // Récupérer tous les barèmes et sous-barèmes
      final selectionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(classId)
          .collection(matiereId);

      final selectionsSnapshot = await selectionsRef.get();

      for (final baremeDoc in selectionsSnapshot.docs) {
        final baremeId = baremeDoc.id;
        final isBaremeSelected = baremeDoc['selected'] ?? false;

        // Marquer comme absent dans le barème principal
        if (isBaremeSelected) {
          await _saveAbsentEvaluation(
            classId: classId,
            studentId: studentId,
            baremeId: baremeId,
          );
        }

        // Marquer comme absent dans les sous-barèmes
        final sousBaremesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('selections')
            .doc(classId)
            .collection(matiereId)
            .doc(baremeId)
            .collection('sousBaremes')
            .get();

        for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
          final sousBaremeId = sousBaremeDoc.id;
          final isSousBaremeSelected = sousBaremeDoc['selected'] ?? false;

          if (isSousBaremeSelected) {
            await _saveAbsentEvaluation(
              classId: classId,
              studentId: studentId,
              baremeId: sousBaremeId,
              parentBaremeId: baremeId,
            );
          }
        }
      }

      print('✅ Élève marqué absent dans tous les barèmes');
    } catch (e) {
      print('❌ Erreur lors du marquage absent: $e');
    }
  }

  Future<void> _saveAbsentEvaluation({
    required String classId,
    required String studentId,
    required String baremeId,
    String? parentBaremeId,
  }) async {
    try {
      if (parentBaremeId != null) {
        // Pour les sous-barèmes
        final sousBaremeDirectRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('user_classes')
            .doc(classId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .doc(baremeId);

        final sousBaremeNestedRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('user_classes')
            .doc(classId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .doc(parentBaremeId)
            .collection('sous_baremes')
            .doc(baremeId);

        // Sauvegarder dans les deux emplacements
        await Future.wait([
          sousBaremeDirectRef.set({
            'Marks': 'غائب',
            'isAbsent': true,
            'absenceDate': Timestamp.now(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)),
          sousBaremeNestedRef.set({
            'Marks': 'غائب',
            'isAbsent': true,
            'absenceDate': Timestamp.now(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)),
        ]);
      } else {
        // Pour les barèmes principaux
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('user_classes')
            .doc(classId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .doc(baremeId)
            .set({
          'Marks': 'غائب',
          'isAbsent': true,
          'absenceDate': Timestamp.now(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde du statut absent: $e');
    }
  }

  // Méthode pour afficher le menu contextuel
  void _showStudentContextMenu(Map<String, dynamic> student) {
    final isAbsent = student['isAbsent'] ?? false;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(isAbsent ? Icons.person_add : Icons.person_off,
                    color: isAbsent ? Colors.green : Colors.orange),
                title: Text(isAbsent ? 'إلغاء الغياب' : 'تسجيل غياب'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleAbsentStatus(student);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('تعديل اسم التلميذ'),
                onTap: () {
                  Navigator.pop(context);
                  _editStudentName(student);
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: Colors.blue),
                title: Text('معلومات التلميذ'),
                onTap: () {
                  Navigator.pop(context);
                  _showStudentDetails(_selectedClass!, student['id']);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('حذف التلميذ'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteStudent(_selectedClass!, student['id']);
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إغلاق'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _navigateToDirectEvaluation(String studentId) async {
    if (selectedClassId == null || selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى اختيار قسم ومادة أولاً'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Vérifier d'abord si les sélections existent
      final selectionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(selectedClassId!)
          .collection(selectedSubjectId!);

      final selectionsSnapshot = await selectionsRef.get();

      if (selectionsSnapshot.docs.isEmpty) {
        // Si aucune sélection, d'abord aller à SelectionPage
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('عملية التقييم', textDirection: TextDirection.rtl),
            content: Text(
              'يجب عليك أولاً تحديد المعايير للتقييم قبل تقييم التلميذ.',
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء', textDirection: TextDirection.rtl),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectionPage(
                        preSelectedClassId: selectedClassId,
                        preSelectedMatiereId: selectedSubjectId,
                      ),
                    ),
                  ).then((_) {
                    // Après sélection, revenir et évaluer l'étudiant
                    if (mounted) {
                      _showSelectionsDialog(
                        selectedClassId!,
                        selectedSubjectId!,
                        studentId,
                      );
                    }
                  });
                },
                child: Text('تحديد المعايير', textDirection: TextDirection.rtl),
              ),
            ],
          ),
        );
      } else {
        // Si les sélections existent, évaluer directement
        await _showSelectionsDialog(
          selectedClassId!,
          selectedSubjectId!,
          studentId,
        );
      }
    } catch (e) {
      print('Erreur lors de la navigation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء التنقل: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _navigateToDynamicTable(String classId, String matiereId) async {
    try {
      // Utiliser les IDs déjà sélectionnés
      final currentClassId = selectedClassId ?? classId;
      final currentMatiereId = selectedSubjectId ?? matiereId;

      if (currentClassId == null || currentMatiereId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يرجى اختيار قسم ومادة أولاً'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Vérifier si l'utilisateur a déjà fait les sélections pour cette classe et matière
      final selectionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(currentClassId)
          .collection(currentMatiereId);

      final selectionsSnapshot = await selectionsRef.get();

      if (selectionsSnapshot.docs.isEmpty) {
        // Si aucune sélection n'existe, naviguer vers SelectionPage AVEC les IDs présélectionnés
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelectionPage(
              preSelectedClassId: currentClassId,
              preSelectedMatiereId: currentMatiereId,
            ),
          ),
        ).then((_) {
          // Après avoir fait les sélections, naviguer automatiquement vers la sélection des barèmes
          if (mounted) {
            _navigateDirectlyToBaremesSelection();
          }
        });
      } else {
        // Si les sélections existent déjà, naviguer directement vers DynamicTablePage
        _goToDynamicTablePage(currentClassId, currentMatiereId);
      }
    } catch (e) {
      print('Erreur lors de la navigation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء التنقل: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _goToDynamicTablePage(String classId, String matiereId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicTablePage(
          selectedClass: classId,
          selectedMatiere: matiereId,
        ),
      ),
    );
  }

  Future<void> _showStudentDetails(
      Map<String, dynamic> classData, String studentId) async {
    // AJOUTER UN CONTRÔLEUR POUR LE NOM
    TextEditingController nameController = TextEditingController();
    TextEditingController parentNameController = TextEditingController();
    TextEditingController parentPhoneController = TextEditingController();
    TextEditingController birthDateController = TextEditingController();
    TextEditingController remarksController = TextEditingController();

    final studentsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('user_classes')
        .doc(classData['id'])
        .collection('students');

    final studentDoc = await studentsCollection.doc(studentId).get();

    if (studentDoc.exists) {
      // CHARGER LE NOM DE L'ÉLÈVE
      nameController.text = studentDoc.get('name') ?? '';
      parentNameController.text = studentDoc.get('parentName') ?? '';
      parentPhoneController.text = studentDoc.get('parentPhone') ?? '';
      birthDateController.text = studentDoc.get('birthDate') ?? '';
      remarksController.text = studentDoc.get('remarks') ?? '';

      // Charger l'image Base64 si elle existe
      if (studentDoc.data()!.containsKey('photoBase64')) {
        final base64String = studentDoc.get('photoBase64');
        if (base64String != null && base64String.isNotEmpty) {
          _imageBytes = base64Decode(base64String);
        }
      } else {
        _imageBytes = null;
      }
    }

    // Fonction pour sélectionner la date
    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
      );
      if (picked != null) {
        birthDateController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل التلميذ', textDirection: TextDirection.rtl),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Afficher l'image depuis les bytes
              if (_imageBytes != null)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: MemoryImage(_imageBytes!),
                )
              else
                CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    child: Text('التقاط صورة'),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: Text('اختيار صورة'),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // AJOUTER LE CHAMP POUR MODIFIER LE NOM
              TextField(
                controller: nameController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'اسم التلميذ',
                  floatingLabelAlignment: FloatingLabelAlignment.start,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),

              TextField(
                controller: parentNameController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'اسم ولي الأمر',
                  floatingLabelAlignment: FloatingLabelAlignment.start,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),

              TextField(
                controller: parentPhoneController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'رقم هاتف ولي الأمر',
                  floatingLabelAlignment: FloatingLabelAlignment.start,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),

              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextField(
                    controller: birthDateController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'تاريخ الميلاد',
                      floatingLabelAlignment: FloatingLabelAlignment.start,
                      suffixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),

              TextField(
                controller: remarksController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'ملاحظات',
                  floatingLabelAlignment: FloatingLabelAlignment.start,
                  border: OutlineInputBorder(),
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
            onPressed: () async {
              try {
                // VALIDER LE NOM (ne doit pas être vide)
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('اسم التلميذ لا يمكن أن يكون فارغاً'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Convertir l'image en Base64
                String? base64Image;
                if (_imageBytes != null) {
                  base64Image = base64Encode(_imageBytes!);
                }

                // SAUVEGARDER TOUTES LES INFORMATIONS Y COMPRIS LE NOM
                await studentsCollection.doc(studentId).update({
                  'name': nameController.text.trim(), // AJOUT DU NOM
                  'parentName': parentNameController.text,
                  'parentPhone': parentPhoneController.text,
                  'birthDate': birthDateController.text,
                  'remarks': remarksController.text,
                  'photoBase64': base64Image ?? '',
                });

                Navigator.pop(context);

                // METTRE À JOUR LA LISTE LOCALE
                setState(() {
                  int index = _students.indexWhere((s) => s['id'] == studentId);
                  if (index != -1) {
                    _students[index]['name'] = nameController.text.trim();
                  }
                });

                // RE-TRIER LA LISTE
                _sortStudentsAlphabetically();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم تحديث المعلومات بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print("خطأ في تحديث المعلومات: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('حدث خطأ أثناء تحديث المعلومات'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // Méthode pour la navigation depuis l'AppBar
  void _navigateToDynamicTableFromAppBar() async {
    if (_selectedClass == null || selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى اختيار مادة أولاً'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Vérifier si l'utilisateur a déjà fait les sélections pour cette classe et matière
      final selectionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(_selectedClass!['class_id'])
          .collection(selectedSubjectId!);

      final selectionsSnapshot = await selectionsRef.get();

      if (selectionsSnapshot.docs.isEmpty) {
        // Si aucune sélection n'existe, naviguer d'abord vers SelectionPage
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('عملية التقييم', textDirection: TextDirection.rtl),
            content: Text(
              'يجب عليك أولاً تحديد المعايير للتقييم قبل الانتقال إلى الجدول.',
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء', textDirection: TextDirection.rtl),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectionPage(
                        preSelectedClassId: _selectedClass!['class_id'],
                        preSelectedMatiereId: selectedSubjectId!,
                      ),
                    ),
                  ).then((_) {
                    // Après avoir fait les sélections, naviguer vers DynamicTablePage
                    _goToDynamicTablePage(
                        _selectedClass!['class_id'], selectedSubjectId!);
                  });
                },
                child: Text('تحديد المعايير', textDirection: TextDirection.rtl),
              ),
            ],
          ),
        );
      } else {
        // Si les sélections existent déjà, naviguer directement vers DynamicTablePage
        _goToDynamicTablePage(_selectedClass!['class_id'], selectedSubjectId!);
      }
    } catch (e) {
      print('Erreur lors de la navigation depuis AppBar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء التنقل: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

// Méthode pour confirmer la réinitialisation de toutes les évaluations
  Future<void> _confirmResetAllEvaluations() async {
    if (selectedClassId == null || selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى اختيار مادة أولاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Compter d'abord le nombre d'élèves pour l'afficher dans la confirmation
    int studentCount = _students.length;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '⚠️ تأكيد العملية',
          style: TextStyle(fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من إعادة تعيين جميع تقييمات هذه المادة؟',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل العملية:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• القسم: ${_selectedClass!['class_name']}',
                    textDirection: TextDirection.rtl,
                  ),
                  Text(
                    '• المادة: ${_getSubjectName()}',
                    textDirection: TextDirection.rtl,
                  ),
                  Text(
                    '• عدد التلاميذ: $studentCount',
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'سيتم حذف جميع التقييمات لهذه المادة لجميع التلاميذ.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('نعم، إعادة التعيين'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _resetAllEvaluations();
    }
  }

// Méthode pour obtenir le nom de la matière
  String _getSubjectName() {
    if (selectedSubjectId == null) return 'غير معروفة';

    // Chercher dans les matières de la classe sélectionnée
    if (_selectedClass != null && _selectedClass!.containsKey('subjects')) {
      final subjects = _selectedClass!['subjects'] as List;
      for (var subject in subjects) {
        if (subject['id'] == selectedSubjectId) {
          return subject['name'];
        }
      }
    }

    return selectedSubjectId!;
  }

// Méthode principale pour réinitialiser toutes les évaluations
  Future<void> _resetAllEvaluations() async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Colors.red,
                strokeWidth: 4,
              ),
              SizedBox(height: 16),
              Text(
                'جاري إعادة تعيين التقييمات...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 8),
              Text(
                'قد تستغرق العملية بضع ثوان',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      int successCount = 0;
      int totalStudents = _students.length;

      // Récupérer tous les barèmes et sous-barèmes pour cette matière
      final selectionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(selectedClassId!)
          .collection(selectedSubjectId!);

      final selectionsSnapshot = await selectionsRef.get();

      // Collecter tous les IDs de barèmes et sous-barèmes
      List<String> allBaremeIds = [];
      Map<String, List<String>> sousBaremesMap = {};

      for (final baremeDoc in selectionsSnapshot.docs) {
        final baremeId = baremeDoc.id;

        // Ajouter le barème principal
        allBaremeIds.add(baremeId);

        // Récupérer les sous-barèmes
        final sousBaremesSnapshot =
            await baremeDoc.reference.collection('sousBaremes').get();

        if (sousBaremesSnapshot.docs.isNotEmpty) {
          List<String> sousBaremeIds = [];
          for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
            sousBaremeIds.add(sousBaremeDoc.id);
          }
          sousBaremesMap[baremeId] = sousBaremeIds;
        }
      }

      // Pour chaque élève, supprimer toutes les évaluations
      for (final student in _students) {
        final studentId = student['id'];

        // Supprimer les barèmes principaux
        for (final baremeId in allBaremeIds) {
          try {
            // Supprimer le barème principal
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser!.uid)
                .collection('user_classes')
                .doc(selectedClassId!)
                .collection('students')
                .doc(studentId)
                .collection('baremes')
                .doc(baremeId)
                .delete();

            // Supprimer les sous-barèmes directs
            if (sousBaremesMap.containsKey(baremeId)) {
              for (final sousBaremeId in sousBaremesMap[baremeId]!) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .collection('user_classes')
                    .doc(selectedClassId!)
                    .collection('students')
                    .doc(studentId)
                    .collection('baremes')
                    .doc(sousBaremeId)
                    .delete();
              }
            }
          } catch (e) {
            print('Erreur lors de la suppression du barème $baremeId: $e');
          }
        }

        successCount++;

        // Mettre à jour le statut de l'élève localement
        int index = _students.indexWhere((s) => s['id'] == studentId);
        if (index != -1) {
          _students[index]['isAbsent'] = false;
        }
      }

      // Fermer l'indicateur de chargement
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Afficher le résultat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ تم إعادة تعيين تقييمات $successCount تلميذ بنجاح',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Rafraîchir l'affichage
      setState(
          () {}); // Force le rebuild pour mettre à jour les couleurs des indicateurs
    } catch (e) {
      // Fermer l'indicateur de chargement en cas d'erreur
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Erreur lors de la réinitialisation des évaluations: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ حدث خطأ أثناء إعادة تعيين التقييمات',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen = constraints.maxWidth < 900;
        final showStudentsWithSubject = _selectedClass != null &&
            _showStudentsList &&
            selectedSubjectId != null;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: isSmallScreen ? 0 : 8,
            title: Row(
              children: [
                if (isSmallScreen)
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (_showStudentsList) {
                        setState(() {
                          _showStudentsList = false;
                          _students = [];
                        });
                      } else if (_selectedClass != null) {
                        setState(() {
                          _selectedClass = null;
                          _subjects = [];
                        });
                      }
                    },
                    tooltip: 'رجوع',
                    padding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                if (_isLoadingClasses ||
                    _isLoadingSubjects ||
                    _isLoadingStudents)
                  Padding(
                    padding: EdgeInsets.only(right: isSmallScreen ? 4 : 8),
                    child: SizedBox(
                      width: isSmallScreen ? 16 : 20,
                      height: isSmallScreen ? 16 : 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    _selectedClass == null
                        ? 'إدارة الاقسام'
                        : '${_selectedClass!['class_name']}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 15 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color.fromRGBO(7, 82, 96, 1),
            elevation: 2,
            actions: [
              if (!isSmallScreen && showStudentsWithSubject) ...[
                _buildAppBarButton(
                  icon: Icons.table_chart,
                  label: 'جدول النتائج',
                  color: Colors.green,
                  onPressed: _navigateToDynamicTableFromAppBar,
                  isSmall: isSmallScreen,
                ),
                _buildAppBarButton(
                  icon: Icons.delete_sweep,
                  label: 'إعادة تعيين',
                  color: Colors.red,
                  onPressed: _confirmResetAllEvaluations,
                  isSmall: isSmallScreen,
                ),
              ],
              if (isSmallScreen && showStudentsWithSubject)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    switch (value) {
                      case 'table':
                        _navigateToDynamicTableFromAppBar();
                        break;
                      case 'reset':
                        _confirmResetAllEvaluations();
                        break;
                      case 'bareme':
                        _navigateDirectlyToBaremesSelection();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'table',
                      child: Row(
                        children: [
                          Icon(Icons.table_chart,
                              color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('جدول النتائج'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'bareme',
                      child: Row(
                        children: [
                          Icon(Icons.settings,
                              color: Color(0xFFF89719), size: 20),
                          SizedBox(width: 8),
                          Text('المعايير'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reset',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('إعادة تعيين'),
                        ],
                      ),
                    ),
                  ],
                )
              else if (showStudentsWithSubject)
                _buildAppBarButton(
                  icon: Icons.settings,
                  label: 'المعايير',
                  color: Color(0xFFF89719),
                  onPressed: _navigateDirectlyToBaremesSelection,
                  isSmall: isSmallScreen,
                ),
              IconButton(
                icon: Icon(Icons.refresh,
                    color: Colors.white, size: isSmallScreen ? 22 : 24),
                onPressed: () {
                  if (_selectedClass == null) {
                    _refreshClasses();
                  } else if (_showStudentsList) {
                    _refreshStudents();
                  } else {
                    _refreshSubjects();
                  }
                },
                tooltip: 'تحديث البيانات',
              ),
              IconButton(
                icon: Icon(Icons.help_outline,
                    color: Colors.white, size: isSmallScreen ? 22 : 24),
                onPressed: () => _buildHelpSection(context),
                tooltip: 'مساعدة',
              ),
              SizedBox(width: isSmallScreen ? 4 : 8),
            ],
          ),
          body: SafeArea(
            child: _classes.isEmpty && !_isLoadingClasses
                ? Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.class_,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'لا توجد اقسام متاحة',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'يجب عليك إضافة قسم من خلال قسم "إضافة قسم جديد"',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  icon: Icon(Icons.add),
                                  label: Text('إضافة قسم جديد'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddClassPage(),
                                      ),
                                    ).then((_) {
                                      _refreshClasses();
                                    });
                                  },
                                ),
                                SizedBox(width: 16),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.refresh),
                                  label: Text('تحديث'),
                                  onPressed: _refreshClasses,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Directionality(
                    textDirection: TextDirection.rtl,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildClassList();
                      },
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildAppBarButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required bool isSmall,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: isSmall ? 16 : 18),
        label: Text(
          label,
          style: TextStyle(fontSize: isSmall ? 12 : 14),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 8 : 12,
            vertical: isSmall ? 6 : 8,
          ),
          textStyle: TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
