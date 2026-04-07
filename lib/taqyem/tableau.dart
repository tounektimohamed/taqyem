import 'dart:async';
import 'dart:convert';
import 'dart:html' as html if (dart.library.html) 'dart:html';

import 'dart:math';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:Taqyem/taqyem/iphone.dart';
import 'package:Taqyem/taqyem/payment/PaymentPage.dart';
import 'package:Taqyem/taqyem/pdf_report_generator.dart';
import 'package:Taqyem/taqyem/tableau_pdf.dart';
import 'package:Taqyem/taqyem/word_report_generator.dart';
import 'package:Taqyem/taqyem/template_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:Taqyem/taqyem/da3m_tableau.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// Helper function for translating bareme names from JSON
// ============================================================
String getTranslatedBaremeNameFromJson(String baremeName, String className,
    String matiereName, Map<String, dynamic> jsonCriteriaData) {
  if (jsonCriteriaData.isEmpty || className.isEmpty || matiereName.isEmpty) {
    return baremeName;
  }

  try {
    String jsonClassName = className;

    if (jsonClassName.contains('أ') ||
        jsonClassName.contains('ب') ||
        jsonClassName.contains('ج') ||
        jsonClassName.contains('د')) {
      jsonClassName = jsonClassName.replaceAll(RegExp(r'[أ-د]$'), '').trim();
    }

    if (!jsonCriteriaData.containsKey(jsonClassName)) {
      return baremeName;
    }

    final classData = jsonCriteriaData[jsonClassName];
    if (classData is! Map<String, dynamic> ||
        !classData.containsKey('subjects')) {
      return baremeName;
    }

    final subjects = classData['subjects'] as Map<String, dynamic>;

    if (!subjects.containsKey(matiereName)) {
      return baremeName;
    }

    final subjectData = subjects[matiereName];
    if (subjectData is! Map<String, dynamic> ||
        !subjectData.containsKey('criteria')) {
      return baremeName;
    }

    final criteria = subjectData['criteria'] as List<dynamic>;
    final baremeCodeMatch = RegExp(r'مع\s*(\d+)').firstMatch(baremeName);
    if (baremeCodeMatch == null) {
      return baremeName;
    }

    final criterionIndex = int.tryParse(baremeCodeMatch.group(1)!) ?? -1;

    if (criterionIndex < 1 || criterionIndex > criteria.length) {
      return baremeName;
    }

    final criterion = criteria[criterionIndex - 1];
    if (criterion is! Map<String, dynamic>) {
      return baremeName;
    }

    String? criterionName = criterion['name'] as String?;
    return criterionName ?? baremeName;
  } catch (e) {
    return baremeName;
  }
}

// ============================================================
// Helper function for translating sous-bareme (indicator) names from JSON
// Pattern: "مع 1.أ" -> criterion 1, indicator "أ"
// ============================================================
String getTranslatedSousBaremeNameFromJson(
    String sousBaremeName,
    String className,
    String matiereName,
    Map<String, dynamic> jsonCriteriaData) {
  if (jsonCriteriaData.isEmpty || className.isEmpty || matiereName.isEmpty) {
    return sousBaremeName;
  }

  try {
    String jsonClassName = className;

    if (jsonClassName.contains('أ') ||
        jsonClassName.contains('ب') ||
        jsonClassName.contains('ج') ||
        jsonClassName.contains('د')) {
      jsonClassName = jsonClassName.replaceAll(RegExp(r'[أ-د]$'), '').trim();
    }

    if (!jsonCriteriaData.containsKey(jsonClassName)) {
      return sousBaremeName;
    }

    final classData = jsonCriteriaData[jsonClassName];
    if (classData is! Map<String, dynamic> ||
        !classData.containsKey('subjects')) {
      return sousBaremeName;
    }

    final subjects = classData['subjects'] as Map<String, dynamic>;

    if (!subjects.containsKey(matiereName)) {
      return sousBaremeName;
    }

    final subjectData = subjects[matiereName];
    if (subjectData is! Map<String, dynamic> ||
        !subjectData.containsKey('criteria')) {
      return sousBaremeName;
    }

    final criteria = subjectData['criteria'] as List<dynamic>;

    // Parse sous-bareme name: "مع 1.أ" -> criterion 1, indicator "أ"
    final sousBaremeMatch =
        RegExp(r'مع\s*(\d+)\s*[.:]\s*([أ-د])').firstMatch(sousBaremeName);
    if (sousBaremeMatch == null) {
      return sousBaremeName;
    }

    final criterionIndex = int.tryParse(sousBaremeMatch.group(1)!) ?? -1;
    final indicatorLetter = sousBaremeMatch.group(2) ?? '';

    if (criterionIndex < 1 || criterionIndex > criteria.length) {
      return sousBaremeName;
    }

    final criterion = criteria[criterionIndex - 1];
    if (criterion is! Map<String, dynamic>) {
      return sousBaremeName;
    }

    // Get indicators from criterion - indicators is a List<String> in JSON
    final indicators = criterion['indicators'];
    if (indicators is! List) {
      return sousBaremeName;
    }

    // Map indicator letter to index (أ=0, ب=1, ج=2, د=3)
    // Arabic Unicode: أ=1571, ب=1576, ج=1579, د=1583 - NOT contiguous!
    final Map<String, int> indicatorLetterMap = {
      'أ': 0,
      'ب': 1,
      'ج': 2,
      'د': 3
    };
    int indicatorIndex = indicatorLetterMap[indicatorLetter] ?? -1;

    if (indicatorIndex < 0 || indicatorIndex >= indicators.length) {
      return sousBaremeName;
    }

    final indicator = indicators[indicatorIndex];
    return indicator.toString();
  } catch (e) {
    return sousBaremeName;
  }
}

// ============================================================
// WeeklyWarningService - Gestion de l'affichage hebdomadaire</parameter>

// ============================================================
class WeeklyWarningService {
  static const String _warningKey = 'last_warning_shown';

  static Future<bool> shouldShowWarning() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getInt(_warningKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      const oneWeekInMs = 7 * 24 * 60 * 60 * 1000;
      return lastShown == 0 || (now - lastShown) > oneWeekInMs;
    } catch (e) {
      return true;
    }
  }

  static Future<void> markWarningShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_warningKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // print('Erreur sauvegarde avertissement: $e');
    }
  }
}

// ============================================================
// WeeklyWarningDialog - Dialog moderne et soigné
// ============================================================
class WeeklyWarningDialog extends StatefulWidget {
  final VoidCallback onClose;
  final bool isFrenchInterface;

  const WeeklyWarningDialog({
    Key? key,
    required this.onClose,
    required this.isFrenchInterface,
  }) : super(key: key);

  @override
  State<WeeklyWarningDialog> createState() => _WeeklyWarningDialogState();
}

class _WeeklyWarningDialogState extends State<WeeklyWarningDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _t(String ar, String fr) => widget.isFrenchInterface ? fr : ar;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header coloré ─────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1565C0),
                        const Color(0xFF42A5F5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Icône centrale
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.computer_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _t('نصيحة للاستخدام الأمثل', 'Conseil d\'utilisation'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // ── Corps ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    children: [
                      // Carte principale - PC recommandé
                      _InfoCard(
                        icon: Icons.desktop_windows_rounded,
                        iconColor: const Color(0xFF1565C0),
                        bgColor: const Color(0xFFE3F2FD),
                        title: _t(
                          'استخدام الكمبيوتر أفضل',
                          'PC recommandé pour l\'évaluation',
                        ),
                        subtitle: _t(
                          'للحصول على تجربة أفضل عند إدخال نتائج التلاميذ وإنشاء التقارير، يُنصح باستخدام الكمبيوتر.',
                          'Pour saisir les résultats des élèves et générer des rapports dans de meilleures conditions, utilisez de préférence un ordinateur.',
                        ),
                        isFrench: widget.isFrenchInterface,
                      ),

                      const SizedBox(height: 12),

                      // Carte secondaire - Mobile pour gestion rapide
                      _InfoCard(
                        icon: Icons.smartphone_rounded,
                        iconColor: const Color(0xFF2E7D32),
                        bgColor: const Color(0xFFE8F5E9),
                        title: _t(
                          'الهاتف للإدارة السريعة',
                          'Téléphone pour la gestion rapide',
                        ),
                        subtitle: _t(
                          'يمكنك استخدام هاتفك لإدارة الأقسام وتفعيل الحساب والاطلاع على النتائج.',
                          'Votre téléphone reste idéal pour gérer les classes, activer votre compte et consulter rapidement les résultats.',
                        ),
                        isFrench: widget.isFrenchInterface,
                      ),

                      const SizedBox(height: 16),

                      // Note "une fois par semaine"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _t(
                              'يظهر هذا التنبيه مرة واحدة كل أسبوع',
                              'Cet avis s\'affiche une fois par semaine',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Bouton ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onClose();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _t('فهمت، شكراً', 'Compris, merci !'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widget auxiliaire: carte d'info ───────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final bool isFrench;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.isFrench,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: iconColor.withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: isFrench ? TextDirection.ltr : TextDirection.rtl,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isFrench ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textDirection:
                      isFrench ? TextDirection.ltr : TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textDirection:
                      isFrench ? TextDirection.ltr : TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// N'oubliez pas d'ajouter l'import pour SharedPreferences
// Ajoutez en haut du fichier avec les autres imports:
// import 'package:shared_preferences/shared_preferences.dart';
// Classe utilitaire pour la traduction et la détection de langue
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

  // Ordre numérique des classes
  static int _getClassOrder(String className) {
    final Map<String, int> classOrder = {
      "السنة الأولى ابتدائي": 1,
      "السنة الأولى ابتدائي أ": 1,
      "السنة الأولى ابتدائي ب": 1,
      "السنة الأولى ابتدائي ج": 1,
      "السنة الأولى ابتدائي د": 1,
      "السنة الثانية ابتدائي": 2,
      "السنة الثانية ابتدائي أ": 2,
      "السنة الثانية ابتدائي ب": 2,
      "السنة الثانية ابتدائي ج": 2,
      "السنة الثانية ابتدائي د": 2,
      "السنة الثالثة ابتدائي": 3,
      "السنة الثالثة ابتدائي أ": 3,
      "السنة الثالثة ابتدائي ب": 3,
      "السنة الثالثة ابتدائي ج": 3,
      "السنة الثالثة ابتدائي د": 3,
      "السنة الرابعة ابتدائي": 4,
      "السنة الرابعة ابتدائي أ": 4,
      "السنة الرابعة ابتدائي ب": 4,
      "السنة الرابعة ابتدائي ج": 4,
      "السنة الرابعة ابتدائي د": 4,
      "السنة الخامسة ابتدائي": 5,
      "السنة الخامسة ابتدائي أ": 5,
      "السنة الخامسة ابتدائي ب": 5,
      "السنة الخامسة ابتدائي ج": 5,
      "السنة الخامسة ابتدائي د": 5,
      "السنة السادسة ابتدائي": 6,
      "السنة السادسة ابتدائي أ": 6,
      "السنة السادسة ابتدائي ب": 6,
      "السنة السادسة ابتدائي ج": 6,
      "السنة السادسة ابتدائي د": 6
    };

    return classOrder[className] ?? 999;
  }
// Méthode pour mapper les classes avec sections aux classes de base du JSON

  static List<String> sortClassesByNumericalOrder(List<String> classes) {
    return List<String>.from(classes)
      ..sort((a, b) {
        final orderA = _getClassOrder(a);
        final orderB = _getClassOrder(b);

        if (orderA != orderB) {
          return orderA.compareTo(orderB);
        }

        // Si même année, trier par section
        return _compareClassSections(a, b);
      });
  }

  static int _compareClassSections(String a, String b) {
    final sections = ['أ', 'ب', 'ج', 'د'];

    for (final section in sections) {
      if (a.contains(section) && !b.contains(section)) return -1;
      if (!a.contains(section) && b.contains(section)) return 1;
      if (a.contains(section) && b.contains(section)) {
        final indexA = sections.indexOf(section);
        final indexB = sections.indexOf(section);
        return indexA.compareTo(indexB);
      }
    }

    return a.compareTo(b);
  }

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
    // Main bareme (1 to 7)
    "مع 1": "C1",
    "مع 2": "C2",
    "مع 3": "C3",
    "مع 4": "C4",
    "مع 5": "C5",
    "مع 6": "C6",
    "مع 7": "C7",

    // Sub-bareme for each (1 to 7 with أ، ب، ج، د)
    // Bareme 1 sub-levels
    "مع 1.أ": "C1.A",
    "مع 1.ب": "C1.B",
    "مع 1.ج": "C1.C",
    "مع 1.د": "C1.D",

    // Bareme 2 sub-levels
    "مع 2.أ": "C2.A",
    "مع 2.ب": "C2.B",
    "مع 2.ج": "C2.C",
    "مع 2.د": "C2.D",

    // Bareme 3 sub-levels
    "مع 3.أ": "C3.A",
    "مع 3.ب": "C3.B",
    "مع 3.ج": "C3.C",
    "مع 3.د": "C3.D",

    // Bareme 4 sub-levels
    "مع 4.أ": "C4.A",
    "مع 4.ب": "C4.B",
    "مع 4.ج": "C4.C",
    "مع 4.د": "C4.D",

    // Bareme 5 sub-levels
    "مع 5.أ": "C5.A",
    "مع 5.ب": "C5.B",
    "مع 5.ج": "C5.C",
    "مع 5.د": "C5.D",

    // Bareme 6 sub-levels
    "مع 6.أ": "C6.A",
    "مع 6.ب": "C6.B",
    "مع 6.ج": "C6.C",
    "مع 6.د": "C6.D",

    // Bareme 7 sub-levels
    "مع 7.أ": "C7.A",
    "مع 7.ب": "C7.B",
    "مع 7.ج": "C7.C",
    "مع 7.د": "C7.D"
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

  // Traduire le nom d'une classe (uniquement pour l'affichage)
  static String translateClass(String arabicName) {
    return _classTranslations[arabicName] ?? arabicName;
  }

  // Traduire le nom d'une matière (uniquement pour l'affichage)
  static String translateMatiere(String arabicName) {
    return _matiereTranslations[arabicName] ?? arabicName;
  }

  // Traduire un critère/barème (uniquement pour l'affichage)
  static String translateBareme(String arabicName) {
    return _baremeTranslations[arabicName] ?? arabicName;
  }

  // Traduire un sous-critère (uniquement pour l'affichage)
  static String translateSousBareme(String arabicName) {
    return _baremeTranslations[arabicName] ?? arabicName;
  }

  // Obtenir le nom original arabe à partir de la traduction française (pour la recherche)
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
  static const String _IPHONE_ADVICE_KEY = 'iphone_advice_shown';
  String _selectedEvaluationDisplay = 'character'; // Par défaut: caractère
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
  bool _isFrenchInterface = false;
  bool _useJsonBaremeTranslation = false;
  Map<String, dynamic> _jsonCriteriaData = {};
  String _matiereName = '';
  String _classNameArabic = '';
  String _selectedTrimestre = 'الأول';
  String _selectedPeriode = '';
  String _selectedEvaluationType = 'تقييم';
  String _selectedTemplateId = 'classic';
  // دالة للكشف إذا كان الجهاز آيفون
  bool _isIPhone() {
    // في Flutter web، يمكننا الكشف عن نظام التشغيل
    if (kIsWeb) {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      // الكشف عن iPhone في متصفح الويب
      return userAgent.contains('iphone') ||
          userAgent.contains('ipad') ||
          (userAgent.contains('mac') &&
              userAgent.contains('safari') &&
              !userAgent.contains('android'));
    } else {
      // للتطبيقات المحمولة، يمكن استخدام Platform.isIOS
      // لكن هذا يتطلب إضافة import 'dart:io' show Platform;
      // return Platform.isIOS;
      return false; // مؤقتاً، يمكنك تعديله حسب الحاجة
    }
  }

  Future<bool> _shouldShowIPhoneAdvice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_IPHONE_ADVICE_KEY) ?? false);
    } catch (e) {
      return true;
    }
  }

  Future<void> _markIPhoneAdviceAsShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_IPHONE_ADVICE_KEY, true);
    } catch (e) {
      // print('Erreur sauvegarde conseil iPhone: $e');
    }
  }

  String _getDomaineForMatiere(String matiereName, bool isFrenchInterface) {
    // Définir les domaines en arabe
    final Map<String, String> domainesArabic = {
      'التواصل الشفوي': 'مجال اللغة العربية',
      'قراءة': 'مجال اللغة العربية',
      'قواعد لغة': 'مجال اللغة العربية',
      'انتاج كتابي': 'مجال اللغة العربية',
      'إنتاج كتابي': 'مجال اللغة العربية',
      'رياضيات': 'مجال العلوم والتكنولوجيا',
      'ايقاظ علمي': 'مجال العلوم والتكنولوجيا',
      'التربية التكنولوجية': 'مجال العلوم والتكنولوجيا',
      'تاريخ': 'مجال التنشئة',
      'التاريخ': 'مجال التنشئة',
      'الجغرافيا': 'مجال التنشئة',
      'التربية المدنية': 'مجال التنشئة',
      'التربية التشكيلية': 'مجال التنشئة',
      'التربية الموسيقية': 'مجال التنشئة',
      'تربية بدنية': 'مجال التنشئة',
      'تربية تشكيلية': 'مجال التنشئة',
      'تربية موسيقية': 'مجال التنشئة',
      'تربية تكنولوجية': 'مجال العلوم والتكنولوجيا',
      'تربية اسلامية': 'مجال التنشئة',
      'لغة فرنسية': 'مجال اللغة الفرنسية',
      'فرنسية': 'مجال اللغة الفرنسية',
      'لغة انقليزية': 'مجال اللغة الإنجليزية',
      'انجليزي': 'مجال اللغة الإنجليزية',
      'لغة إنجليزية': 'مجال اللغة الإنجليزية',
      'Expression orale et récitation': 'مجال اللغة العربية',
      'Lecture': 'مجال اللغة العربية',
      'Production écrite': 'مجال اللغة العربية',
      'écriture': 'مجال اللغة العربية',
      'dictée': 'مجال اللغة العربية',
      'langue': 'مجال اللغة العربية',
    };

    // Définir les domaines en français
    final Map<String, String> domainesFrench = {
      'Communication orale': 'Domaine Langue Arabe',
      'Lecture': 'Domaine Langue Arabe',
      'Grammaire': 'Domaine Langue Arabe',
      'Production écrite': 'Domaine Langue Arabe',
      'Écriture': 'Domaine Langue Arabe',
      'Dictée': 'Domaine Langue Arabe',
      'Mathématiques': 'Domaine Sciences et Technologie',
      'Éveil scientifique': 'Domaine Sciences et Technologie',
      'Éducation technologique': 'Domaine Sciences et Technologie',
      'Histoire': 'Domaine Socialisation',
      'Géographie': 'Domaine Socialisation',
      'Éducation civique': 'Domaine Socialisation',
      'Éducation artistique': 'Domaine Socialisation',
      'Éducation musicale': 'Domaine Socialisation',
      'Éducation physique': 'Domaine Socialisation',
      'Éducation islamique': 'Domaine Socialisation',
      'Français': 'Domaine Langue Française',
      'Langue française': 'Domaine Langue Française',
      'Anglais': 'Domaine Langue Anglaise',
      'Langue anglaise': 'Domaine Langue Anglaise',
      'Expression orale et récitation': 'Domaine Langue Arabe',
    };
    Map<String, Map<String, String>> _getEvaluationDisplayOptions() {
      return {
        'character': {
          'ar': 'حرفي',
          'fr': 'Caractère',
          'description_ar': '( - - - ), ( + - - ), ( + + - ), ( + + + )',
          'description_fr': '( - - - ), ( + - - ), ( + + - ), ( + + + )'
        },
        '1.3': {
          'ar': 'نظام 0-1.5',
          'fr': 'Système 0-1.5',
          'description_ar': '0, 0.5, 1, 1.5',
          'description_fr': '0, 0.5, 1, 1.5'
        },
        '0.6': {
          'ar': 'نظام 0-6',
          'fr': 'Système 0-6',
          'description_ar': '0, 2, 4, 6',
          'description_fr': '0, 2, 4, 6'
        },
        'costum': {
          'ar': 'مخصص',
          'fr': 'Personnalisé',
          'description_ar': 'تقييم مخصص',
          'description_fr': 'Évaluation personnalisée'
        },
        'ext': {
          'ar': 'مفصل',
          'fr': 'Détaillé',
          'description_ar': '( - - - ), ( + - - ), ( + + - ), ( + + + )',
          'description_fr': '( - - - ), ( + - - ), ( + + - ), ( + + + )'
        },
      };
    }

    // Sélectionner la map appropriée selon la langue
    final domaines = isFrenchInterface ? domainesFrench : domainesArabic;

    // Chercher le domaine correspondant
    for (var key in domaines.keys) {
      if (matiereName.contains(key) || key.contains(matiereName)) {
        return domaines[key]!;
      }
    }

    // Retourner un domaine par défaut
    return isFrenchInterface ? 'Domaine Général' : 'المجال العام';
  }

// Nouvelle méthode pour le rapport complet
// Dans la classe _DynamicTablePageState, ajoutez ces méthodes :

// Fonction pour convertir la valeur d'affichage en valeur stockée selon le système
// Dans la classe _DynamicTablePageState, ajoutez ces méthodes :

// Convertit la valeur affichée en valeur stockée
  String _getMappedEvaluation(String displayValue, String system,
      {List<String>? customNotes}) {
    // print(
    //     '🎯 _getMappedEvaluation - displayValue: "$displayValue", system: "$system", customNotes: $customNotes');

    // Si c'est "غائب"
    if (displayValue == 'غائب') {
      return 'غائب';
    }

    // SYSTÈME CUSTOM
    if (system == 'custom' && customNotes != null && customNotes.isNotEmpty) {
      // Normaliser les notes comme avant
      List<String> normalizedNotes = List.from(customNotes);
      while (normalizedNotes.length < 4) {
        if (normalizedNotes.length == 2) {
          normalizedNotes = [
            normalizedNotes[0],
            normalizedNotes[0],
            normalizedNotes[1],
            normalizedNotes[1],
          ];
        } else if (normalizedNotes.length == 3) {
          normalizedNotes = [
            normalizedNotes[0],
            normalizedNotes[1],
            normalizedNotes[1],
            normalizedNotes[2],
          ];
        } else {
          normalizedNotes = List.filled(4, normalizedNotes[0]);
        }
      }

      // Trouver l'index de la valeur affichée dans les notes normalisées
      final index = normalizedNotes.indexOf(displayValue);

      if (index != -1) {
        // Mapper l'index vers la valeur stockée
        if (index == 0) return '( - - - )';
        if (index == 1) return '( + - - )';
        if (index == 2) return '( + + - )';
        if (index == 3) return '( + + + )';
      }

      // Si la valeur n'est pas trouvée, essayer de la parser comme nombre
      final numValue = double.tryParse(displayValue);
      if (numValue != null) {
        // Pour les valeurs numériques, mapper proportionnellement
        final maxNote = double.tryParse(normalizedNotes.last) ?? 1.0;
        final ratio = numValue / maxNote;

        if (ratio < 0.25) return '( - - - )';
        if (ratio < 0.5) return '( + - - )';
        if (ratio < 0.75) return '( + + - )';
        return '( + + + )';
      }

      // Par défaut, retourner la plus basse
      return '( - - - )';
    }

    // SYSTÈME CHARACTER
    if (system == 'character') {
      return displayValue;
    }

    // SYSTÈMES NUMÉRIQUES STANDARDS
    switch (system) {
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

// Fonction pour charger TOUTES les notes personnalisées (globales + par barème)
  Future<Map<String, dynamic>> _loadAllCustomNotesForFlask(
      String classId, String matiereId) async {
    Map<String, dynamic> allCustomNotes = {
      'global': [],
      'baremes': {}, // Map<baremeId, List<String>>
      'sousBaremes': {}, // Map<sousBaremeId, List<String>>
    };

    try {
      // 1. Charger les notes globales
      final globalDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('bareme_custom_notes')
          .doc('$classId-$matiereId')
          .get();

      if (globalDoc.exists && globalDoc.data()?['notes'] != null) {
        allCustomNotes['global'] =
            List<String>.from(globalDoc.data()!['notes']);
        // print('🌍 Notes globales chargées: ${allCustomNotes['global']}');
      }

      // 2. Charger les notes des barèmes
      final selectionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(classId)
          .collection(matiereId)
          .get();

      for (final baremeDoc in selectionsSnapshot.docs) {
        final baremeId = baremeDoc.id;

        // Notes spécifiques au barème
        final baremeCustomDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('bareme_custom_notes')
            .doc('$classId-$matiereId-$baremeId')
            .get();

        if (baremeCustomDoc.exists &&
            baremeCustomDoc.data()?['notes'] != null) {
          allCustomNotes['baremes'][baremeId] =
              List<String>.from(baremeCustomDoc.data()!['notes']);
          // print(
          //     '📌 Notes barème $baremeId: ${allCustomNotes['baremes'][baremeId]}');
        }

        // Notes des sous-barèmes
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

          final sousCustomDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .collection('sous_bareme_custom_notes')
              .doc('$classId-$matiereId-$baremeId-$sousBaremeId')
              .get();

          if (sousCustomDoc.exists && sousCustomDoc.data()?['notes'] != null) {
            allCustomNotes['sousBaremes'][sousBaremeId] =
                List<String>.from(sousCustomDoc.data()!['notes']);
            // print(
            //     '🔹 Notes sous-barème $sousBaremeId: ${allCustomNotes['sousBaremes'][sousBaremeId]}');
          }
        }
      }
    } catch (e) {
      // print('❌ Erreur chargement notes custom: $e');
    }

    return allCustomNotes;
  }

// Ajouter cette méthode dans _DynamicTablePageState
  Future<void> _checkAndShowWeeklyWarning() async {
    if (!_isMounted) return;

    final shouldShow = await WeeklyWarningService.shouldShowWarning();

    if (shouldShow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isMounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WeeklyWarningDialog(
            isFrenchInterface: _isFrenchInterface,
            onClose: () async {
              await WeeklyWarningService.markWarningShown();
            },
          ),
        );
      });
    }
  }

// Fonction pour convertir la valeur stockée en valeur d'affichage selon le système
// VERSION CORRIGÉE - Gère tous les types de notes personnalisées
  String _getDisplayEvaluation(String storedValue, String system,
      {List<String>? customNotes, String? baremeId, String? sousBaremeId}) {
    // Debug pour voir ce qui se passe
    // print(
    //     '🎯 _getDisplayEvaluation - storedValue: "$storedValue", system: "$system", customNotes: $customNotes');

    // Si c'est "غائب"
    if (storedValue == 'غائب') {
      return 'غائب';
    }

    // SYSTÈME CUSTOM - Utiliser les notes personnalisées
    if (system == 'custom') {
      if (customNotes != null && customNotes.isNotEmpty) {
        // IMPORTANT: S'assurer d'avoir exactement 4 notes pour le mapping
        // Les notes personnalisées peuvent être n'importe quoi (textes ou nombres)
        List<String> normalizedNotes = List.from(customNotes);

        // Normaliser à 4 notes exactement
        if (normalizedNotes.length == 1) {
          // Une seule note : la répéter 4 fois
          normalizedNotes = List.filled(4, normalizedNotes[0]);
        } else if (normalizedNotes.length == 2) {
          // Deux notes : [bas, haut] -> [bas, bas, haut, haut]
          normalizedNotes = [
            normalizedNotes[0],
            normalizedNotes[0],
            normalizedNotes[1],
            normalizedNotes[1],
          ];
        } else if (normalizedNotes.length == 3) {
          // Trois notes : [bas, moyen, haut] -> [bas, moyen, moyen, haut]
          normalizedNotes = [
            normalizedNotes[0],
            normalizedNotes[1],
            normalizedNotes[1],
            normalizedNotes[2],
          ];
        } else if (normalizedNotes.length > 4) {
          // Plus de 4 notes : prendre les 4 premières
          normalizedNotes = normalizedNotes.sublist(0, 4);
        }
        // Si déjà 4 notes, on garde telles quelles

        // Maintenant on a toujours 4 notes pour le mapping
        final Map<String, String> mapping = {
          '( - - - )': normalizedNotes[0], // La plus basse
          '( + - - )': normalizedNotes[1], // Basse-moyenne
          '( + + - )': normalizedNotes[2], // Haute-moyenne
          '( + + + )': normalizedNotes[3], // La plus haute
        };

        final result = mapping[storedValue] ?? normalizedNotes[0];
        // print(
        //     '✅ Custom mapping: $storedValue -> $result (notes: $normalizedNotes)');
        return result;
      } else {
        // print(
        //     '⚠️ Système custom mais pas de notes personnalisées, fallback sur caractères');
        return storedValue;
      }
    }

    // SYSTÈME CHARACTER
    if (system == 'character' || system == 'ext') {
      return storedValue;
    }

    // SYSTÈMES NUMÉRIQUES STANDARDS
    switch (system) {
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
            return storedValue;
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
            return storedValue;
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
            return storedValue;
        }

      default:
        return storedValue;
    }
  }

// Fonction pour récupérer le système d'évaluation sélectionné
  Future<String> _getEvaluationSystem(String classId, String matiereId) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 'character';

      // Format: classId-matiereId
      final docId = '$classId-$matiereId';

      // print('🔍 Recherche système pour: $docId');

      final systemDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('evaluation_systems')
          .doc(docId)
          .get();

      if (systemDoc.exists) {
        final system = systemDoc.data()?['system'] ?? 'character';
        // print('✅ Système récupéré: $system');
        return system;
      }

      // Si pas trouvé avec l'ID composé, essayer de chercher dans tous les documents
      // print('⚠️ Document non trouvé avec ID: $docId');

      // Chercher tous les systèmes pour debug
      final allSystems = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('evaluation_systems')
          .get();

      // print('📋 Tous les systèmes disponibles:');
      // for (final doc in allSystems.docs) {
      //   print('   - ${doc.id}: ${doc.data()}');
      // }

      // print('ℹ️ Système par défaut: character');
      return 'character';
    } catch (e) {
      // print('❌ Erreur récupération système: $e');
      return 'character';
    }
  }

  Future<void> _debugAllEvaluationSystems() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // print('=== DÉBOGAGE SYSTÈMES D\'ÉVALUATION ===');

      final systemsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('evaluation_systems')
          .get();

      // print('📋 Systèmes trouvés: ${systemsSnapshot.docs.length}');
      // for (final doc in systemsSnapshot.docs) {
      //   print('   📄 ${doc.id} -> ${doc.data()}');
      // }

      // Vérifier spécifiquement pour la classe et matière actuelles
      final docId = '${widget.selectedClass}-${widget.selectedMatiere}';
      final specificDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('evaluation_systems')
          .doc(docId)
          .get();

      // if (specificDoc.exists) {
      //   print('✅ Système pour $docId: ${specificDoc.data()}');
      // } else {
      //   print('❌ Aucun système trouvé pour $docId');
      // }

      // print('=== FIN DÉBOGAGE ===');
    } catch (e) {
      // print('❌ Erreur débogage: $e');
    }
  }

// Fonction pour charger les notes personnalisées
  Future<List<String>> _loadCustomNotes(
      String classId, String matiereId) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('custom_notes')
          .doc('$classId-$matiereId')
          .get();

      if (doc.exists && doc.data()?['notes'] != null) {
        return List<String>.from(doc.data()!['notes']);
      }
      return [];
    } catch (e) {
      // print('Erreur lors du chargement des notes personnalisées: $e');
      return [];
    }
  }

  void _showTemplateSelectorThenReport() {
    showDialog(
      context: context,
      builder: (context) => TemplateSelectorDialog(
        isFrenchInterface: _isFrenchInterface,
        currentTemplateId: _selectedTemplateId,
        onSelected: (template) {
          setState(() => _selectedTemplateId = template.id);
          _showCompleteReportDialogWithTemplate(template.id);
        },
      ),
    );
  }

  void _showCompleteReportDialogWithTemplate(String templateId) {
    // Contrôleurs pour les champs
    TextEditingController periodeController =
        TextEditingController(text: _selectedPeriode);
    // NOUVEAU: Contrôleur pour la performance attendue
    TextEditingController performanceAttendueController =
        TextEditingController();

    // Options pour le trimestre
    final trimestreOptions = ['الأول', 'الثاني', 'الثالث'];
    final trimestreTranslations = {
      'الأول': 'Premier',
      'الثاني': 'Deuxième',
      'الثالث': 'Troisième'
    };

    // Options pour le type d'évaluation
    final evaluationOptions = ['تقييم', 'امتحان'];
    final evaluationTranslations = {'تقييم': 'Évaluation', 'امتحان': 'Examen'};

    // Variables pour stocker les noms de classe et matière
    String className = '';
    String matiereName = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Charger les noms de classe et matière
            Future<void> loadClassAndMatiereNames() async {
              try {
                // Récupérer le nom de la classe
                var classDoc = await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(widget.selectedClass)
                    .get();
                String arabicClassName = classDoc['name'] ?? 'غير معروف';
                className = _isFrenchInterface
                    ? DataTranslator.translateClass(arabicClassName)
                    : arabicClassName;

                // Récupérer le nom de la matière
                var matiereDoc = await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(widget.selectedClass)
                    .collection('matieres')
                    .doc(widget.selectedMatiere)
                    .get();
                String arabicMatiereName = matiereDoc['name'] ?? 'غير معروف';
                matiereName = _isFrenchInterface
                    ? DataTranslator.translateMatiere(arabicMatiereName)
                    : arabicMatiereName;

                if (mounted) {
                  setState(() {});
                }
              } catch (e) {
                // print('Erreur chargement noms: $e');
                className = _isFrenchInterface ? 'Inconnu' : 'غير معروف';
                matiereName = _isFrenchInterface ? 'Inconnu' : 'غير معروف';
                if (mounted) {
                  setState(() {});
                }
              }
            }

            // Charger les données au début
            WidgetsBinding.instance.addPostFrameCallback((_) {
              loadClassAndMatiereNames();
            });

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.book, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    _getTranslatedText('تقرير كامل', 'Rapport Complet'),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Section 1: Sélection du trimestre et période
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 20, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  _getTranslatedText('الفترة والتقييم',
                                      'Période et Évaluation'),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),

                            // الثلاثي
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getTranslatedText(
                                        'الثلاثي:', 'Trimestre:'),
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedTrimestre,
                                    items: trimestreOptions
                                        .map((t) => DropdownMenuItem(
                                              value: t,
                                              child: Text(
                                                _isFrenchInterface
                                                    ? trimestreTranslations[
                                                            t] ??
                                                        t
                                                    : t,
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _selectedTrimestre = v;
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                    ),
                                    isExpanded: true,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),

                            // الوحدة / الفترة
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getTranslatedText(
                                        'الوحدة / الفترة:', 'Unité / Période:'),
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(height: 8),
                                  TextField(
                                    controller: periodeController,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: _getTranslatedText(
                                          'مثال: الوحدة 1', 'Ex: Unité 1'),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),

                            // نوع التقييم
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getTranslatedText(
                                        'نوع التقييم:', 'Type d\'évaluation:'),
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedEvaluationType,
                                    items: evaluationOptions
                                        .map((t) => DropdownMenuItem(
                                              value: t,
                                              child: Text(
                                                _isFrenchInterface
                                                    ? evaluationTranslations[
                                                            t] ??
                                                        t
                                                    : t,
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _selectedEvaluationType = v;
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                    ),
                                    isExpanded: true,
                                  ),
                                ],
                              ),
                            ),

                            // NOUVEAU: Champ pour la performance attendue
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getTranslatedText('الأداء المنتظر',
                                        'Performance attendue:'),
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(height: 8),
                                  TextField(
                                    controller: performanceAttendueController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: _getTranslatedText(
                                          'أدخل الأداء المنتظر للتلاميذ...',
                                          'Entrez la performance attendue pour les élèves...'),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Section 2: Affichage de la classe (en lecture seule)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.school,
                                    size: 20, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  _getTranslatedText(
                                      'القسم المحدد', 'Classe sélectionnée'),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.class_, color: Colors.green),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: className.isEmpty
                                        ? Row(
                                            children: [
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                _getTranslatedText(
                                                    'جاري التحميل...',
                                                    'Chargement...'),
                                                style: TextStyle(
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            className,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.green[800],
                                            ),
                                          ),
                                  ),
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                _getTranslatedText(
                                    '(محدد تلقائياً من الصفحة الحالية)',
                                    '(Sélectionné automatiquement depuis la page actuelle)'),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green[600],
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Section 3: Affichage de la matière (en lecture seule)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.book,
                                    size: 20, color: Colors.orange),
                                SizedBox(width: 8),
                                Text(
                                  _getTranslatedText(
                                      'المادة المحددة', 'Matière sélectionnée'),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.menu_book, color: Colors.orange),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: matiereName.isEmpty
                                        ? Row(
                                            children: [
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                _getTranslatedText(
                                                    'جاري التحميل...',
                                                    'Chargement...'),
                                                style: TextStyle(
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            matiereName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.orange[800],
                                            ),
                                          ),
                                  ),
                                  Icon(Icons.check_circle,
                                      color: Colors.orange, size: 20),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                _getTranslatedText(
                                    '(محدد تلقائياً من الصفحة الحالية)',
                                    '(Sélectionné automatiquement depuis la page actuelle)'),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange[600],
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Résumé de la sélection
                      SizedBox(height: 16),
                      Container(
                        margin: EdgeInsets.only(top: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.summarize, color: Colors.purple),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getTranslatedText(
                                        'ملخص التقرير:', 'Résumé du Rapport:'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple[800],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${_getTranslatedText('الثلاثي', 'Trimestre')}: ${_isFrenchInterface ? trimestreTranslations[_selectedTrimestre] ?? _selectedTrimestre : _selectedTrimestre}',
                                    style: TextStyle(color: Colors.purple[800]),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${_getTranslatedText('الفترة', 'Période')}: ${periodeController.text.isNotEmpty ? periodeController.text : _getTranslatedText('غير محدد', 'Non spécifié')}',
                                    style: TextStyle(color: Colors.purple[800]),
                                  ),
                                  SizedBox(height: 2),
                                  if (performanceAttendueController
                                      .text.isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_getTranslatedText('الأداء المنتظر', 'Performance attendue')}:',
                                          style: TextStyle(
                                              color: Colors.purple[800],
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          performanceAttendueController.text,
                                          style: TextStyle(
                                              color: Colors.purple[800],
                                              fontSize: 12),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  SizedBox(height: 2),
                                  Text(
                                    '$className - $matiereName',
                                    style: TextStyle(
                                      color: Colors.purple[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Aperçu du contenu du rapport
                      if (className.isNotEmpty && matiereName.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(top: 16),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.teal),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.description, color: Colors.teal),
                                  SizedBox(width: 8),
                                  Text(
                                    _getTranslatedText('محتوى التقرير:',
                                        'Contenu du Rapport:'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal[800],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              _buildReportContentItem(
                                  '1. صفحة الغلاف', '1. Page de garde'),
                              _buildReportContentItem(
                                  '2. جدول المعايير والباريمات',
                                  '2. Tableau des critères et barèmes'),
                              _buildReportContentItem(
                                  '3. الجدول الكامل للنتائج',
                                  '3. Tableau complet des résultats'),
                              _buildReportContentItem('4. الإحصائيات والنسب',
                                  '4. Statistiques et pourcentages'),
                              // NOUVEAU: Ajout de la performance attendue dans l'aperçu
                              if (performanceAttendueController.text.isNotEmpty)
                                _buildReportContentItem('5. الأداء المنتظر',
                                    '5. Performance attendue'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_getTranslatedText('إلغاء', 'Annuler')),
                ),
                ElevatedButton(
                  onPressed: className.isNotEmpty && matiereName.isNotEmpty
                      ? () {
                          setState(() {
                            _selectedPeriode = periodeController.text.trim();
                          });
                          Navigator.pop(context);
                          _generateCompleteReport(
                            widget.selectedClass,
                            widget.selectedMatiere,
                            className,
                            matiereName,
                            performanceAttendue:
                                performanceAttendueController.text.trim(),
                            templateId: templateId,
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  child: Text(_getTranslatedText(
                      'إنشاء التقرير', 'Générer le Rapport')),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Méthode pour générer le rapport complet

// Méthode pour générer le rapport complet

  Future<void> _generateCompleteReport(
    String classId,
    String matiereId,
    String className,
    String matiereName, {
    String performanceAttendue = '',
    String templateId = 'classic',
  }) async {
    if (!await _checkAndUpdatePrintCredit()) {
      _showCreditErrorDialog();
      return;
    }

    setState(() {
      _isGeneratingReport = true;
    });

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => _buildLoadingDialog(isPDF: true),
      );

      // NOUVEAU: Envoyer uniquement les données essentielles à Flask
      final response = await _sendLightDataToFlaskForCompleteReport(
        classId: classId,
        matiereId: matiereId,
        className: className,
        matiereName: matiereName,
        performanceAttendue: performanceAttendue,
        templateId: templateId,
      );

      if (response['success']) {
        // Dédure le crédit
        await _deductPrintCredit();

        _showSuccessSnackbar(_getTranslatedText('تم إنشاء التقرير الكامل بنجاح',
            'Rapport complet généré avec succès'));
      } else {
        _showErrorSnackbar(response['message']);
      }
    } catch (e) {
      _showErrorSnackbar(_getTranslatedText('خطأ في إنشاء التقرير الكامل',
              'Erreur lors de la génération du rapport complet') +
          ': $e');
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });
      Navigator.of(context).pop();
    }
  }

// NOUVELLE MÉTHODE: Envoyer les données légères à Flask
//
// NOUVELLE MÉTHODE: Envoyer les données légères à Flask

// Dans votre fichier Flutter, modifiez la fonction principale:
  Future<List<Map<String, dynamic>>> _getStudentsForFlask(
      String classId, String matiereId, String evaluationSystem) async {
    List<Map<String, dynamic>> students = [];

    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .get();

      for (final studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;
        final studentName = studentDoc['name'] ?? 'تلميذ غير معروف';

        final Map<String, String> baremes = {};

        // Récupérer les barèmes
        final baremesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('user_classes')
            .doc(classId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .get();

        for (final baremeDoc in baremesSnapshot.docs) {
          final baremeId = baremeDoc.id;
          final storedValue = baremeDoc['Marks']?.toString() ?? '( - - - )';

          // Récupérer les notes personnalisées pour ce barème
          List<String> customNotes = [];
          if (evaluationSystem == 'custom') {
            customNotes =
                await _getCustomNotesForBareme(classId, matiereId, baremeId);
          }

          // Convertir la valeur selon le système
          final displayValue = _getDisplayEvaluation(
            storedValue,
            evaluationSystem,
            customNotes: customNotes,
          );

          baremes[baremeId] = displayValue;

          // Récupérer les sous-barèmes
          final sousBaremesSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .collection('user_classes')
              .doc(classId)
              .collection('students')
              .doc(studentId)
              .collection('baremes')
              .doc(baremeId)
              .collection('sous_baremes')
              .get();

          for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
            final sousBaremeId = sousBaremeDoc.id;
            final sousStoredValue =
                sousBaremeDoc['Marks']?.toString() ?? '( - - - )';

            // Récupérer les notes personnalisées pour ce sous-barème
            List<String> sousCustomNotes = [];
            if (evaluationSystem == 'custom') {
              sousCustomNotes = await _getSousBaremeCustomNotes(
                  classId, matiereId, baremeId, sousBaremeId);
            }

            // Convertir la valeur
            final sousDisplayValue = _getDisplayEvaluation(
              sousStoredValue,
              evaluationSystem,
              customNotes:
                  sousCustomNotes.isNotEmpty ? sousCustomNotes : customNotes,
            );

            baremes['$baremeId-$sousBaremeId'] = sousDisplayValue;
          }
        }

        students.add({
          'id': studentId,
          'name': studentName,
          'baremes': baremes,
        });
      }

      // Trier les étudiants
      students.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    } catch (e) {
      // print('❌ Erreur préparation étudiants: $e');
    }

    return students;
  }

  Future<Map<String, dynamic>> _sendLightDataToFlaskForCompleteReport({
    required String classId,
    required String matiereId,
    required String className,
    required String matiereName,
    required String performanceAttendue,
    String templateId = 'classic',
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'Utilisateur non connecté'};
      }

      // 🔥 Récupérer le système d'évaluation
      final String evaluationSystem =
          await _getEvaluationSystem(classId, matiereId);

      // 🔥 Récupérer TOUTES les notes personnalisées
      List<String> globalCustomNotes = [];
      Map<String, dynamic> baremeCustomNotes = {};
      Map<String, dynamic> sousBaremeCustomNotes = {};

      if (evaluationSystem == 'custom') {
        // Charger les notes globales
        globalCustomNotes = await _loadCustomNotes(classId, matiereId);

        // Charger les notes des barèmes
        final selectionsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('selections')
            .doc(classId)
            .collection(matiereId)
            .get();

        for (final baremeDoc in selectionsSnapshot.docs) {
          final baremeId = baremeDoc.id;

          // Notes spécifiques au barème
          final baremeCustomNotesDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('bareme_custom_notes')
              .doc('$classId-$matiereId-$baremeId')
              .get();

          if (baremeCustomNotesDoc.exists &&
              baremeCustomNotesDoc.data()?['notes'] != null) {
            baremeCustomNotes[baremeId] =
                List<String>.from(baremeCustomNotesDoc.data()!['notes']);
          }

          // Notes des sous-barèmes
          final sousBaremesSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('selections')
              .doc(classId)
              .collection(matiereId)
              .doc(baremeId)
              .collection('sousBaremes')
              .get();

          for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
            final sousBaremeId = sousBaremeDoc.id;

            final sousCustomNotesDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .collection('sous_bareme_custom_notes')
                .doc('$classId-$matiereId-$baremeId-$sousBaremeId')
                .get();

            if (sousCustomNotesDoc.exists &&
                sousCustomNotesDoc.data()?['notes'] != null) {
              sousBaremeCustomNotes[sousBaremeId] =
                  List<String>.from(sousCustomNotesDoc.data()!['notes']);
            }
          }
        }
      }

      // print('📤 SYSTÈME ENVOYÉ À FLASK: $evaluationSystem');
      // print('📤 NOTES GLOBALES: $globalCustomNotes');
      // print('📤 NOTES BARÈMES: $baremeCustomNotes');
      // print('📤 NOTES SOUS-BARÈMES: $sousBaremeCustomNotes');

      // Préparer les données des étudiants avec les notes converties
      final students =
          await _getStudentsForFlask(classId, matiereId, evaluationSystem);

      final Map<String, dynamic> completeData = {
        'userId': currentUser.uid,
        'user': {
          'profName': _profName,
          'schoolName': _schoolName,
        },
        'class': {
          'id': classId,
          'name': className,
        },
        'matiere': {
          'id': matiereId,
          'name': matiereName,
        },
        'performanceAttendue': performanceAttendue,
        'period': {
          'trimestre': _selectedTrimestre,
          'periode': _selectedPeriode,
          'evaluationType': _selectedEvaluationType,
        },
        'isFrenchInterface': _isFrenchInterface,
        'timestamp': DateTime.now().toIso8601String(),

        // ✅ ENVOYER LE SYSTÈME
        'evaluationSystem': evaluationSystem,

        // ✅ ENVOYER TOUTES LES NOTES PERSONNALISÉES
        'customNotes': {
          'global': globalCustomNotes,
          'baremes': baremeCustomNotes,
          'sousBaremes': sousBaremeCustomNotes,
        },

        // ✅ ENVOYER LES ÉTUDIANTS AVEC LEURS NOTES
        'students': students,

        // ✅ ENVOYER LE TEMPLATE ID
        'templateId': templateId,
      };

      // print('📤 Envoi des données à Flask...');

      final testUrl =
          Uri.parse('https://mohamedtsou-taqyem-imprission.hf.space/health');

      try {
        await http.get(testUrl).timeout(const Duration(seconds: 5));
        // print('✅ Serveur Flask accessible');
      } catch (e) {
        // print('❌ Serveur Flask inaccessible: $e');
        return {
          'success': false,
          'message': 'Serveur Flask non démarré sur HF Space'
        };
      }

      final url = Uri.parse(
          'https://mohamedtsou-taqyem-imprission.hf.space/generate-complete-report');

      // print('⏳ Génération du rapport...');
      // print(
      //     '📦 Taille des données: ~${json.encode(completeData).length} caractères');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: json.encode(completeData),
          )
          .timeout(const Duration(seconds: 120));

      // print('✅ Status HTTP: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          if (responseData.containsKey('downloadUrl')) {
            await _downloadReportFromUrl(
                responseData['downloadUrl'],
                responseData['filename'] ?? 'rapport.pdf',
                responseData['reportId']);

            await _saveReportMetadata(currentUser.uid, responseData['reportId'],
                responseData, className, matiereName);

            return {
              'success': true,
              'message': 'Rapport généré avec succès',
              'reportId': responseData['reportId']
            };
          } else if (responseData.containsKey('htmlContent')) {
            await _downloadHTMLContent(responseData['htmlContent']);
            return {'success': true, 'message': 'Rapport HTML généré'};
          } else {
            return {'success': false, 'message': 'Aucun contenu disponible'};
          }
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Erreur inconnue'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Erreur HTTP ${response.statusCode}'
        };
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Timeout serveur'};
    } catch (e) {
      // print('💥 Erreur inattendue: $e');
      return {'success': false, 'message': 'Erreur technique: $e'};
    }
  }

  Future<void> _downloadReportFromUrl(
      String downloadUrl, String filename, String reportId) async {
    try {
      // print('📥 Téléchargement depuis: $downloadUrl');

      if (kIsWeb) {
        // Version Web
        html.window.open(downloadUrl, '_blank');
        _showSuccessSnackbar(_getTranslatedText(
            'جاري تحميل التقرير...', 'Téléchargement du rapport...'));
      } else {
        // Version Mobile/Desktop
        final response = await http.get(Uri.parse(downloadUrl));

        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final directory = await getTemporaryDirectory();
          final filePath = '${directory.path}/$filename';

          // Utiliser XFile au lieu de File
          final xFile = XFile.fromData(
            bytes,
            name: filename,
            mimeType: 'application/pdf',
          );

          await xFile.saveTo(filePath);
          await OpenFile.open(filePath);

          _showSuccessSnackbar(
              _getTranslatedText('تم تحميل التقرير', 'Rapport téléchargé'));
        } else {
          throw Exception('Erreur de téléchargement: ${response.statusCode}');
        }
      }
    } catch (e) {
      // print('❌ Erreur téléchargement: $e');
      _showErrorSnackbar(
          _getTranslatedText('خطأ في التحميل', 'Erreur de téléchargement') +
              ': $e');
      rethrow;
    }
  }

  Future<void> _saveReportMetadata(
      String userId,
      String reportId,
      Map<String, dynamic> reportData,
      String className,
      String matiereName) async {
    try {
      await FirebaseFirestore.instance
          .collection('user_reports')
          .doc(userId)
          .collection('rapports')
          .doc(reportId)
          .set({
        'reportId': reportId,
        'className': className,
        'matiereName': matiereName,
        'downloadUrl': reportData['downloadUrl'],
        'generatedAt': DateTime.now().toIso8601String(),
        'profName': _profName,
        'schoolName': _schoolName,
        'trimestre': _selectedTrimestre,
        'periode': _selectedPeriode,
        'status': 'downloaded'
      });

      // print('✅ Métadonnées sauvegardées dans Firestore');
    } catch (e) {
      // print('⚠️ Erreur sauvegarde métadonnées: $e');
      // Ne pas bloquer l'utilisateur pour cette erreur
    }
  }

// NOUVELLE FONCTION: Récupérer l'historique des rapports
  Future<List<Map<String, dynamic>>> _getUserReportsHistory() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      final snapshot = await FirebaseFirestore.instance
          .collection('user_reports')
          .doc(currentUser.uid)
          .collection('rapports')
          .orderBy('generatedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'date': DateTime.parse(data['generatedAt']).toLocal()
        };
      }).toList();
    } catch (e) {
      // print('❌ Erreur récupération historique: $e');
      return [];
    }
  }

// NOUVELLE FONCTION: Afficher l'historique des rapports
// NOUVELLE FONCTION: Afficher l'historique des rapports avec suppression
  void _showReportsHistory() {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getUserReportsHistory(),
          builder: (context, snapshot) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.history, color: Colors.blue),
                  SizedBox(width: 10),
                  Text(_getTranslatedText(
                      'التقارير السابقة', 'Historique des rapports')),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: snapshot.connectionState == ConnectionState.waiting
                    ? Center(child: CircularProgressIndicator())
                    : snapshot.hasData && snapshot.data!.isNotEmpty
                        ? ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final report = snapshot.data![index];
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: Icon(Icons.picture_as_pdf,
                                      color: Colors.red),
                                  title: Text(
                                    '${report['className']} - ${report['matiereName']}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm')
                                            .format(report['date']),
                                      ),
                                      if (report['downloadUrl'] != null)
                                        Text(
                                          _getTranslatedText('حجم الملف',
                                                  'Taille fichier') +
                                              ': ${_formatFileSize(report['fileSize'] ?? 0)}',
                                          style: TextStyle(
                                              fontSize: 10, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.download),
                                        tooltip: _getTranslatedText(
                                            'تحميل', 'Télécharger'),
                                        onPressed: () {
                                          if (report['downloadUrl'] != null) {
                                            _downloadReportFromUrl(
                                                report['downloadUrl'],
                                                '${report['className']}_${report['matiereName']}_${DateFormat('yyyyMMdd_HHmm').format(report['date'])}.pdf',
                                                report['reportId']);
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        tooltip: _getTranslatedText(
                                            'حذف', 'Supprimer'),
                                        onPressed: () {
                                          _showDeleteReportDialog(report);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              _getTranslatedText('لا توجد تقارير سابقة',
                                  'Aucun rapport précédent'),
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_getTranslatedText('إغلاق', 'Fermer')),
                ),
              ],
            );
          },
        );
      },
    );
  }

// NOUVELLE FONCTION: Afficher le dialogue de confirmation de suppression
  void _showDeleteReportDialog(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 10),
            Text(_getTranslatedText('تأكيد الحذف', 'Confirmation suppression')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTranslatedText('هل أنت متأكد من حذف هذا التقرير؟',
                  'Êtes-vous sûr de vouloir supprimer ce rapport ?'),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${report['className']} - ${report['matiereName']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(report['date']),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text(
              _getTranslatedText('سيتم حذف التقرير نهائياً ولا يمكن استرجاعه.',
                  'Le rapport sera définitivement supprimé et ne pourra pas être récupéré.'),
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getTranslatedText('إلغاء', 'Annuler')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialogue de confirmation
              _deleteReport(report['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(_getTranslatedText('حذف', 'Supprimer')),
          ),
        ],
      ),
    );
  }

// NOUVELLE FONCTION: Supprimer un rapport
  Future<void> _deleteReport(String reportId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackbar(
            _getTranslatedText('يجب تسجيل الدخول', 'Connectez-vous d\'abord'));
        return;
      }

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text(_getTranslatedText(
                  'جاري الحذف...', 'Suppression en cours...')),
            ],
          ),
        ),
      );

      // Appeler l'API Flask pour supprimer le rapport
      final response = await http.delete(
        Uri.parse(
            'https://mohamedtsou-taqyem-imprission.hf.space/delete-report/$reportId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      // Fermer le dialogue de chargement
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        if (result['success'] == true) {
          _showSuccessSnackbar(_getTranslatedText(
              'تم حذف التقرير', 'Rapport supprimé avec succès'));

          // Rafraîchir la liste des rapports
          if (Navigator.of(context).canPop()) {
            Navigator.pop(context); // Fermer le dialogue d'historique
          }

          // Réafficher l'historique mis à jour
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showReportsHistory();
          });
        } else {
          _showErrorSnackbar(result['message'] ??
              _getTranslatedText('فشل الحذف', 'Échec de la suppression'));
        }
      } else {
        _showErrorSnackbar(
            _getTranslatedText('خطأ في الاتصال', 'Erreur de connexion'));
      }
    } on TimeoutException {
      Navigator.pop(context);
      _showErrorSnackbar(_getTranslatedText('انتهت المهلة', 'Timeout'));
    } catch (e) {
      if (Navigator.of(context).canPop()) Navigator.pop(context);
      _showErrorSnackbar(
          _getTranslatedText('خطأ تقني', 'Erreur technique') + ': $e');
    }
  }

// NOUVELLE FONCTION: Formater la taille du fichier
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

// MODIFIEZ votre menu d'impression pour ajouter l'historique
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
              if (value == 'complete_report') {
                _showCompleteReportDialogWithTemplate(_selectedTemplateId);
              } else if (value == 'choose_template') {
                _showTemplateSelectorThenReport();
              } else if (value == 'baremes_table') {
                _showClassAndMatiereSelectionDialog();
              } else if (value == 'history') {
                _showReportsHistory();
              } else {
                _showEvaluationInfoDialog(() {
                  if (value == 'html') {
                    _generateHTMLReport(downloadAsPDF: false);
                  } else if (value == 'pdf') {
                    _generateHTMLReport(downloadAsPDF: true);
                  }
                });
              }
            },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        // PopupMenuItem<String>(
        //   value: 'html',
        //   child: Row(
        //     children: [
        //       Icon(Icons.description, color: Colors.blue),
        //       SizedBox(width: 8),
        //       Text(_getTranslatedText('طباعة الجدول (HTML)', 'Imprimer le tableau (HTML)')),
        //     ],
        //   ),
        // ),
        // PopupMenuItem<String>(
        //   value: 'pdf',
        //   child: Row(
        //     children: [
        //       Icon(Icons.picture_as_pdf, color: Colors.red),
        //       SizedBox(width: 8),
        //       Text(_getTranslatedText('طباعة الجدول (PDF)', 'Imprimer le tableau (PDF)')),
        //     ],
        //   ),
        // ),
        // PopupMenuDivider(),
        // PopupMenuItem<String>(
        //   value: 'baremes_table',
        //   child: Row(
        //     children: [
        //       Icon(Icons.table_chart, color: Colors.green),
        //       SizedBox(width: 8),
        //       Text(_getTranslatedText('طباعة جدول المعايير', 'Imprimer tableau des critères')),
        //     ],
        //   ),
        // ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'complete_report',
          child: Row(
            children: [
              Icon(Icons.book, color: Colors.purple),
              SizedBox(width: 8),
              Text(_getTranslatedText('تقرير كامل', 'Rapport Complet')),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'choose_template',
          child: Row(
            children: [
              Icon(Icons.palette, color: Colors.teal),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getTranslatedText('اختر التصميم ثم اطبع',
                      'Choisir le design puis imprimer')),
                  Text(
                    _getTranslatedText(
                      'الحالي: ${ReportTemplates.getById(_selectedTemplateId).nameAr}',
                      'Actuel: ${ReportTemplates.getById(_selectedTemplateId).nameFr}',
                    ),
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'history',
          child: Row(
            children: [
              Icon(Icons.history, color: Colors.orange),
              SizedBox(width: 8),
              Text(_getTranslatedText('التقارير السابقة', 'Historique')),
            ],
          ),
        ),
      ],
    );
  }

//
// //
//

  Future<void> _downloadPdfFromBase64(String pdfBase64) async {
    try {
      final bytes = base64Decode(pdfBase64);

      if (kIsWeb) {
        // Version Web
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..setAttribute(
            'download',
            'rapport_${DateTime.now().millisecondsSinceEpoch}.pdf',
          )
          ..click();

        Future.delayed(const Duration(seconds: 2), () {
          html.Url.revokeObjectUrl(url);
        });

        // print('✅ PDF téléchargé sur le web');
      } else {
        // Version Mobile/Desktop
        final directory = await getTemporaryDirectory();
        final filePath =
            '${directory.path}/rapport_${DateTime.now().millisecondsSinceEpoch}.pdf';

        final xFile = XFile.fromData(
          bytes,
          name: 'rapport_${DateTime.now().millisecondsSinceEpoch}.pdf',
          mimeType: 'application/pdf',
        );

        await xFile.saveTo(filePath);
        await OpenFile.open(filePath);

        // print('✅ PDF sauvegardé: $filePath');
      }
    } catch (e) {
      // print('❌ Erreur téléchargement PDF base64: $e');
      rethrow;
    }
  }

  Future<void> _downloadGeneratedReport(String pdfUrl) async {
    try {
      if (kIsWeb) {
        html.window.open(pdfUrl, '_blank');
      } else {
        final response = await http.get(Uri.parse(pdfUrl));
        final bytes = response.bodyBytes;

        final directory = await getTemporaryDirectory();
        final filePath =
            '${directory.path}/rapport_complet_${DateTime.now().millisecondsSinceEpoch}.pdf';

        // Utiliser XFile au lieu de File
        final xFile = XFile.fromData(
          bytes,
          name: 'rapport_complet_${DateTime.now().millisecondsSinceEpoch}.pdf',
          mimeType: 'application/pdf',
        );

        await xFile.saveTo(filePath);
        await OpenFile.open(filePath);
      }
    } catch (e) {
      // print('Erreur téléchargement rapport: $e');
      rethrow;
    }
  }

  Future<void> _downloadHTMLContent(String htmlContent) async {
    try {
      if (kIsWeb) {
        // Version Web
        final blob = html.Blob([htmlContent], 'text/html; charset=utf-8');
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..setAttribute(
            'download',
            'rapport_${DateTime.now().millisecondsSinceEpoch}.html',
          )
          ..click();

        Future.delayed(const Duration(seconds: 2), () {
          html.Url.revokeObjectUrl(url);
        });

        // print('✅ Fichier HTML téléchargé sur le web');
      } else {
        // Version Mobile/Desktop
        final directory = await getTemporaryDirectory();
        final filePath =
            '${directory.path}/rapport_${DateTime.now().millisecondsSinceEpoch}.html';

        final xFile = XFile.fromData(
          Uint8List.fromList(utf8.encode(htmlContent)),
          name: 'rapport_${DateTime.now().millisecondsSinceEpoch}.html',
          mimeType: 'text/html',
        );

        await xFile.saveTo(filePath);
        await OpenFile.open(filePath);

        // print('✅ Fichier HTML sauvegardé: $filePath');
      }
    } catch (e) {
      // print('❌ Erreur téléchargement HTML: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> _getStudentsForCompleteReport(
      String classId, String matiereId) async {
    try {
      // Récupérer le système d'évaluation
      final String evaluationSystem =
          await _getEvaluationSystem(classId, matiereId);

      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .get();

      final List<dynamic> students = [];
      for (final studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;
        final studentName = _getFieldSafe(studentDoc, 'name',
            _isFrenchInterface ? 'Élève inconnu' : 'تلميذ غير معروف');

        final baremesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('user_classes')
            .doc(classId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .get();

        final Map<String, String> baremes = {};
        for (final baremeDoc in baremesSnapshot.docs) {
          final baremeId = baremeDoc.id;
          final storedValue = _getFieldSafe(baremeDoc, 'Marks', '( - - - )');

          // IMPORTANT: Charger les notes personnalisées du barème
          final customNotes =
              await _getCustomNotesForBareme(classId, matiereId, baremeId);

          // Convertir selon le système avec les notes personnalisées
          final displayValue = _getDisplayEvaluation(
            storedValue,
            evaluationSystem,
            customNotes: customNotes,
          );

          baremes[baremeId] = displayValue;

          // Gérer les sous-barèmes
          final sousBaremesSnapshot =
              await baremeDoc.reference.collection('sous_baremes').get();

          for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
            final sousBaremeId = sousBaremeDoc.id;
            final sousStoredValue =
                _getFieldSafe(sousBaremeDoc, 'Marks', '( - - - )');

            // IMPORTANT: Charger les notes personnalisées du sous-barème
            final sousCustomNotes = await _getSousBaremeCustomNotes(
              classId,
              matiereId,
              baremeId,
              sousBaremeId,
            );

            // Convertir selon le système avec les notes personnalisées
            final sousDisplayValue = _getDisplayEvaluation(
              sousStoredValue,
              evaluationSystem,
              customNotes: sousCustomNotes,
            );

            baremes['$baremeId-$sousBaremeId'] = sousDisplayValue;
          }
        }

        students.add({
          'id': studentId,
          'name': studentName,
          'baremes': baremes,
        });
      }

      // Trier les étudiants par ordre alphabétique
      students.sort((a, b) {
        String nameA = a['name'] ?? '';
        String nameB = b['name'] ?? '';

        if (!_isFrenchInterface && nameA.contains(RegExp(r'[\u0600-\u06FF]'))) {
          return _arabicStringComparator(nameA, nameB);
        }

        return nameA.compareTo(nameB);
      });

      return students;
    } catch (e) {
      // print('Erreur récupération étudiants rapport complet: $e');
      return [];
    }
  }

// Méthodes auxiliaires pour récupérer les données
  Future<List<dynamic>> _getStudentsForReport(
      String classId, String matiereId) async {
    try {
      // Récupérer le système d'évaluation
      final String evaluationSystem =
          await _getEvaluationSystem(classId, matiereId);
      final List<String> customNotes =
          await _loadCustomNotes(classId, matiereId);

      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .get();

      final List<dynamic> students = [];
      for (final studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;
        final studentName = _getFieldSafe(studentDoc, 'name',
            _isFrenchInterface ? 'Élève inconnu' : 'تلميذ غير معروف');

        final baremesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('user_classes')
            .doc(classId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .get();

        final Map<String, String> baremes = {};
        for (final baremeDoc in baremesSnapshot.docs) {
          final baremeId = baremeDoc.id;
          final storedValue = _getFieldSafe(baremeDoc, 'Marks', '( - - - )');

          // Convertir selon le système
          final displayValue = _getDisplayEvaluation(
            storedValue,
            evaluationSystem,
            customNotes: customNotes,
          );

          baremes[baremeId] = displayValue;

          final sousBaremesSnapshot =
              await baremeDoc.reference.collection('sous_baremes').get();

          for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
            final sousBaremeId = sousBaremeDoc.id;
            final sousStoredValue =
                _getFieldSafe(sousBaremeDoc, 'Marks', '( - - - )');

            final sousDisplayValue = _getDisplayEvaluation(
              sousStoredValue,
              evaluationSystem,
              customNotes: customNotes,
            );

            baremes['$baremeId-$sousBaremeId'] = sousDisplayValue;
          }
        }

        students.add({
          'id': studentId,
          'name': studentName,
          'baremes': baremes,
        });
      }

      // Trier les étudiants par ordre alphabétique
      students.sort((a, b) {
        String nameA = a['name'] ?? '';
        String nameB = b['name'] ?? '';

        if (!_isFrenchInterface && nameA.contains(RegExp(r'[\u0600-\u06FF]'))) {
          return _arabicStringComparator(nameA, nameB);
        }

        return nameA.compareTo(nameB);
      });

      return students;
    } catch (e) {
      // print('Erreur récupération étudiants: $e');
      return [];
    }
  }

  Future<List<dynamic>> _getBaremesForReport(
      String classId, String matiereId) async {
    try {
      final String evaluationSystem =
          await _getEvaluationSystem(classId, matiereId);
      final List<String> customNotes =
          await _loadCustomNotes(classId, matiereId);

      final baremesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(classId)
          .collection(matiereId)
          .get();

      final List<dynamic> baremes = [];
      for (final baremeDoc in baremesSnapshot.docs) {
        final baremeId = _getFieldSafe(baremeDoc, 'baremeId', '');
        final baremeName = _getFieldSafe(baremeDoc, 'baremeName', 'غير معروف');
        final isBaremeSelected = _getFieldSafe(baremeDoc, 'selected', false);

        String displayedBaremeName = _isFrenchInterface
            ? DataTranslator.translateBareme(baremeName)
            : baremeName;

        if (_useJsonBaremeTranslation &&
            _classNameArabic.isNotEmpty &&
            _matiereName.isNotEmpty) {
          displayedBaremeName = _getTranslatedBaremeName(
              baremeName, _classNameArabic, _matiereName);
        }

        if (isBaremeSelected) {
          // Récupérer les sous-barèmes
          final sousBaremesSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .collection('selections')
              .doc(classId)
              .collection(matiereId)
              .doc(baremeId)
              .collection('sousBaremes')
              .get();

          final List<Map<String, dynamic>> sousBaremesList = [];

          for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
            final sousBaremeId = sousBaremeDoc.id;
            final sousBaremeName =
                _getFieldSafe(sousBaremeDoc, 'sousBaremeName', 'غير معروف');
            final isSousBaremeSelected =
                _getFieldSafe(sousBaremeDoc, 'selected', false);

            final displayedSousBaremeName = _isFrenchInterface
                ? DataTranslator.translateSousBareme(sousBaremeName)
                : sousBaremeName;

            if (isSousBaremeSelected) {
              sousBaremesList.add({
                'id': sousBaremeId,
                'value': displayedSousBaremeName,
                'originalValue': sousBaremeName,
                'type': 'sousBareme',
                'parentBaremeId': baremeId,
                'evaluationSystem': evaluationSystem,
                'customNotes': customNotes,
              });
            }
          }

          // ✅ TRIER les sous-barèmes par ordre alphabétique
          sousBaremesList.sort((a, b) {
            String nameA = a['value'] ?? '';
            String nameB = b['value'] ?? '';

            if (!_isFrenchInterface &&
                nameA.contains(RegExp(r'[\u0600-\u06FF]'))) {
              return _arabicStringComparator(nameA, nameB);
            }
            return nameA.compareTo(nameB);
          });

          baremes.add({
            'id': baremeId,
            'value': displayedBaremeName,
            'originalValue': baremeName,
            'type': 'bareme',
            'sousBaremes': sousBaremesList,
            'evaluationSystem': evaluationSystem,
            'customNotes': customNotes,
          });
        }
      }

      // ✅ TRIER les barèmes principaux par ordre alphabétique
      baremes.sort((a, b) {
        String nameA = a['value'] ?? '';
        String nameB = b['value'] ?? '';

        if (!_isFrenchInterface && nameA.contains(RegExp(r'[\u0600-\u06FF]'))) {
          return _arabicStringComparator(nameA, nameB);
        }
        return nameA.compareTo(nameB);
      });

      return baremes;
    } catch (e) {
      // print('Erreur récupération barèmes: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _getSummaryForReport(
      String classId, String matiereId) async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .get();

      final totalStudents = studentsSnapshot.docs.length;
      final Map<String, int> sumCriteriaMaxPerBareme = {};

      // Logique pour calculer les statistiques (similaire à fetchMarks)
      // ... (vous pouvez adapter la logique de fetchMarks ici)

      return {
        'totalStudents': totalStudents,
        'sumCriteriaMaxPerBareme': sumCriteriaMaxPerBareme,
      };
    } catch (e) {
      // print('Erreur récupération résumé: $e');
      return {
        'totalStudents': 0,
        'sumCriteriaMaxPerBareme': {},
      };
    }
  }

// Widget pour afficher un élément du contenu du rapport
  Widget _buildReportContentItem(String arabicText, String frenchText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.teal),
          SizedBox(width: 8),
          Text(
            _isFrenchInterface ? frenchText : arabicText,
            style: TextStyle(color: Colors.teal[800]),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _loadUserData();
    fetchMarks();
    _startTimer();
    _setupUserListener();
    _detectLanguage();
    _checkAndShowWeeklyWarning();
    _loadEvaluationSystem();
    _loadJsonData();
    _loadUserPreferences();
    _loadClassNameFromFirebase();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugAllEvaluationSystems(); // Pour debug
    });
  }

  Future<void> _loadJsonData() async {
    try {
      String jsonString =
          await rootBundle.loadString('assets/evaluation_excel.json');
      final jsonDataTmp = jsonDecode(jsonString);
      setState(() {
        _jsonCriteriaData = jsonDataTmp['classes'] as Map<String, dynamic>;
      });
      // print('JSON data loaded: ${_jsonCriteriaData.keys.toList()}');
    } catch (e) {
      // print("Erreur lors du chargement du fichier JSON: $e");
    }
  }

  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _useJsonBaremeTranslation =
            prefs.getBool('useJsonBaremeTranslation') ?? false;
      });
      // print('User preferences loaded: _useJsonBaremeTranslation=$_useJsonBaremeTranslation');
    } catch (e) {
      // print("Erreur lors du chargement des préférences: $e");
    }
  }

  Future<void> _loadClassNameFromFirebase() async {
    try {
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .get();
      if (classDoc.exists) {
        setState(() {
          _classNameArabic = classDoc.get('name') ?? '';
        });
        // print('Loaded class name from Firebase: $_classNameArabic');
      }
    } catch (e) {
      // print('Error loading class name: $e');
    }
  }

  String _getTranslatedBaremeName(
      String baremeName, String className, String matiereName) {
    print(
        'TRANSLATION DEBUG: _useJsonBaremeTranslation=$_useJsonBaremeTranslation, className=$className, matiereName=$matiereName, baremeName=$baremeName');

    if (!_useJsonBaremeTranslation ||
        _jsonCriteriaData.isEmpty ||
        className.isEmpty ||
        matiereName.isEmpty) {
      print(
          'TRANSLATION: returning original - settings disabled or empty data');
      return baremeName;
    }

    try {
      String jsonClassName = className;
      print('TRANSLATION: jsonClassName = $jsonClassName');

      if (jsonClassName.contains('أ') ||
          jsonClassName.contains('ب') ||
          jsonClassName.contains('ج') ||
          jsonClassName.contains('د')) {
        jsonClassName = jsonClassName.replaceAll(RegExp(r'[أ-د]$'), '').trim();
      }
      // print('DEBUG mapped className: $jsonClassName');

      if (!_jsonCriteriaData.containsKey(jsonClassName)) {
        // print('DEBUG: class $jsonClassName not found in JSON');
        return baremeName;
      }

      final classData = _jsonCriteriaData[jsonClassName];
      if (classData is! Map<String, dynamic> ||
          !classData.containsKey('subjects')) {
        return baremeName;
      }

      final subjects = classData['subjects'] as Map<String, dynamic>;

      if (!subjects.containsKey(matiereName)) {
        return baremeName;
      }

      final subjectData = subjects[matiereName];
      if (subjectData is! Map<String, dynamic> ||
          !subjectData.containsKey('criteria')) {
        // print('DEBUG: no criteria for matiere $matiereName');
        return baremeName;
      }

      final criteria = subjectData['criteria'] as List<dynamic>;
      // print('DEBUG criteria count: ${criteria.length}');

      final baremeCodeMatch = RegExp(r'مع\s*(\d+)').firstMatch(baremeName);
      if (baremeCodeMatch == null) {
        // print('DEBUG: no regex match for $baremeName');
        return baremeName;
      }

      final criterionIndex = int.tryParse(baremeCodeMatch.group(1)!) ?? -1;
      // print('DEBUG: index=$criterionIndex');

      if (criterionIndex < 1 || criterionIndex > criteria.length) {
        // print('DEBUG: index out of range');
        return baremeName;
      }

      final criterion = criteria[criterionIndex - 1];
      if (criterion is! Map<String, dynamic>) {
        // print('DEBUG: criterion not a map');
        return baremeName;
      }

      String? criterionName = criterion['name'] as String?;
      // print('DEBUG criterion name: $criterionName');

      return criterionName ?? baremeName;
    } catch (e) {
      // print('Error getting translated bareme name: $e');
      return baremeName;
    }
  }

  Future<void> _loadEvaluationSystem() async {
    try {
      final system = await _getEvaluationSystem(
          widget.selectedClass, widget.selectedMatiere);
      if (_isMounted) {
        setState(() {
          _selectedEvaluationDisplay = system;
        });
        // print('✅ Système d\'évaluation chargé: $system');
      }
    } catch (e) {
      // print('❌ Erreur chargement système: $e');
    }
  }

  void _showClassAndMatiereSelectionDialog() {
    // Contrôleurs pour les champs de recherche
    TextEditingController classSearchController = TextEditingController();
    TextEditingController matiereSearchController = TextEditingController();

    // États pour les listes filtrées
    List<Map<String, dynamic>> filteredClasses = [];
    List<Map<String, dynamic>> filteredMatieres = [];

    // États pour les sélections
    Map<String, dynamic>? selectedClass;
    Map<String, dynamic>? selectedMatiere;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Charger les classes depuis Firestore
            Future<void> loadClasses() async {
              try {
                final classesSnapshot = await FirebaseFirestore.instance
                    .collection('classes')
                    .get();

                List<Map<String, dynamic>> classes = [];
                for (var classDoc in classesSnapshot.docs) {
                  classes.add({
                    'id': classDoc.id,
                    'name': classDoc['name'] ?? 'غير معروف',
                    'frenchName': DataTranslator.translateClass(
                        classDoc['name'] ?? 'غير معروف'),
                    'order': _getClassOrder(classDoc['name'] ?? 'غير معروف'),
                  });
                }

                // Trier par ordre numérique
                classes.sort((a, b) {
                  final orderA = a['order'] as int;
                  final orderB = b['order'] as int;
                  return orderA.compareTo(orderB);
                });

                setState(() {
                  filteredClasses = classes;
                });
              } catch (e) {
                // print('Erreur chargement classes: $e');
              }
            }

            // Charger les matières pour une classe
            Future<void> loadMatieres(String classId) async {
              try {
                final matieresSnapshot = await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .collection('matieres')
                    .get();

                List<Map<String, dynamic>> matieres = [];
                for (var matiereDoc in matieresSnapshot.docs) {
                  matieres.add({
                    'id': matiereDoc.id,
                    'name': matiereDoc['name'] ?? 'غير معروف',
                    'frenchName': DataTranslator.translateMatiere(
                        matiereDoc['name'] ?? 'غير معروف'),
                  });
                }

                setState(() {
                  filteredMatieres = matieres;
                });
              } catch (e) {
                // print('Erreur chargement matières: $e');
              }
            }

            // Initialisation
            if (filteredClasses.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                loadClasses();
              });
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.table_chart, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    _getTranslatedText(
                        'طباعة جدول المعايير', 'Imprimer tableau des critères'),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    // Recherche de classe
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTranslatedText(
                                'اختر القسم:', 'Sélectionnez la classe:'),
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: classSearchController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: _getTranslatedText(
                                  'بحث عن قسم...', 'Rechercher une classe...'),
                              prefixIcon: Icon(Icons.search),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            onChanged: (value) {
                              setState(() {
                                // Filtrer les classes selon la recherche
                                // Cette fonctionnalité nécessiterait une liste complète des classes
                              });
                            },
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: filteredClasses.isEmpty
                                ? Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ListView.builder(
                                    itemCount: filteredClasses.length,
                                    itemBuilder: (context, index) {
                                      final classe = filteredClasses[index];
                                      return ListTile(
                                        leading: Icon(Icons.class_,
                                            color: selectedClass?['id'] ==
                                                    classe['id']
                                                ? Colors.blue
                                                : Colors.grey),
                                        title: Text(
                                          _isFrenchInterface
                                              ? classe['frenchName']
                                              : classe['name'],
                                        ),
                                        trailing:
                                            selectedClass?['id'] == classe['id']
                                                ? Icon(Icons.check,
                                                    color: Colors.green)
                                                : null,
                                        onTap: () {
                                          setState(() {
                                            selectedClass = classe;
                                            selectedMatiere = null;
                                            filteredMatieres.clear();
                                            loadMatieres(classe['id']);
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Recherche de matière
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTranslatedText(
                                'اختر المادة:', 'Sélectionnez la matière:'),
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: matiereSearchController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: _getTranslatedText('بحث عن مادة...',
                                  'Rechercher une matière...'),
                              prefixIcon: Icon(Icons.search),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              enabled: selectedClass != null,
                            ),
                            enabled: selectedClass != null,
                            onChanged: (value) {
                              setState(() {
                                // Filtrer les matières selon la recherche
                              });
                            },
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: selectedClass == null
                                ? Center(
                                    child: Text(
                                      _getTranslatedText('اختر قسمًا أولاً',
                                          'Sélectionnez d\'abord une classe'),
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : filteredMatieres.isEmpty
                                    ? Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : ListView.builder(
                                        itemCount: filteredMatieres.length,
                                        itemBuilder: (context, index) {
                                          final matiere =
                                              filteredMatieres[index];
                                          return ListTile(
                                            leading: Icon(Icons.book,
                                                color: selectedMatiere?['id'] ==
                                                        matiere['id']
                                                    ? Colors.blue
                                                    : Colors.grey),
                                            title: Text(
                                              _isFrenchInterface
                                                  ? matiere['frenchName']
                                                  : matiere['name'],
                                            ),
                                            trailing: selectedMatiere?['id'] ==
                                                    matiere['id']
                                                ? Icon(Icons.check,
                                                    color: Colors.green)
                                                : null,
                                            onTap: () {
                                              setState(() {
                                                selectedMatiere = matiere;
                                              });
                                            },
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),

                    // Résumé de la sélection
                    if (selectedClass != null && selectedMatiere != null)
                      Container(
                        margin: EdgeInsets.only(top: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getTranslatedText(
                                        'تم الاختيار:', 'Sélection:'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                  Text(
                                    '${_isFrenchInterface ? selectedClass!['frenchName'] : selectedClass!['name']} - '
                                    '${_isFrenchInterface ? selectedMatiere!['frenchName'] : selectedMatiere!['name']}',
                                    style: TextStyle(color: Colors.green[800]),
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_getTranslatedText('إلغاء', 'Annuler')),
                ),
                ElevatedButton(
                  onPressed: selectedClass != null && selectedMatiere != null
                      ? () {
                          Navigator.pop(context);
                          _generateBaremesTableReport(
                            selectedClass!['id'],
                            selectedMatiere!['id'],
                            selectedClass!['name'],
                            selectedMatiere!['name'],
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: Text(_getTranslatedText(
                      'طباعة الجدول', 'Imprimer le tableau')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  int _getClassOrder(String className) {
    if (className.contains('الأولى')) return 1;
    if (className.contains('الثانية')) return 2;
    if (className.contains('الثالثة')) return 3;
    if (className.contains('الرابعة')) return 4;
    if (className.contains('الخامسة')) return 5;
    if (className.contains('السادسة')) return 6;
    return 999;
  }

// Nouvelle méthode pour générer le rapport de barèmes
  Future<void> _generateBaremesTableReport(
    String classId,
    String matiereId,
    String className,
    String matiereName,
  ) async {
    // Normaliser le nom de la classe
    final normalizedClassName = _mapClassToJsonBase(className);

    // Récupérer les critères depuis le JSON avec la classe normalisée
    final criteria = await _getCriteriaFromJson(
        classId, matiereId, normalizedClassName, matiereName);

    if (!await _checkAndUpdatePrintCredit()) {
      _showCreditErrorDialog();
      return;
    }

    setState(() {
      _isGeneratingReport = true;
    });

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => _buildLoadingDialog(isPDF: true),
      );

      // Récupérer les critères depuis le code 3
      final criteria = await _getCriteriaFromJson(
          classId, matiereId, className, matiereName);

      // Générer le rapport HTML
      await HTMLReportGenerator.generateAndDownloadReport(
        profName: _profName,
        matiereName: matiereName,
        className: className,
        schoolName: _schoolName,
        baremes: [], // Vide car on affiche seulement les critères
        students: [], // Vide
        sumCriteriaMaxPerBareme: {},
        totalStudents: 0,
        isFrenchInterface: _isFrenchInterface,
        downloadAsPDF: true,
        trimestre: _selectedTrimestre,
        periode: _selectedPeriode,
        evaluationType: _selectedEvaluationType,
        selectedClass: classId,
        criteria: criteria, // Nouveau paramètre pour les critères
      );

      // Dédure le crédit
      await _deductPrintCredit();

      _showSuccessSnackbar(_getTranslatedText('تم إنشاء جدول المعايير بنجاح',
          'Tableau des critères généré avec succès'));
    } catch (e) {
      _showErrorSnackbar(_getTranslatedText('خطأ في إنشاء جدول المعايير',
              'Erreur lors de la génération du tableau des critères') +
          ': $e');
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });
      Navigator.of(context).pop();
    }
  }

// Méthode pour récupérer les critères depuis le JSON
// Méthode pour normaliser le nom de classe

// Méthode pour mapper les classes avec sections aux classes de base du JSON
  String _mapClassToJsonBase(String classNameWithSection) {
    // Dictionnaire de mapping complet
    final Map<String, String> classMapping = {
      // Première année
      'السنة الأولى ابتدائي': 'السنة الأولى ابتدائي',
      'السنة الأولى ابتدائي أ': 'السنة الأولى ابتدائي',
      'السنة الأولى ابتدائي ب': 'السنة الأولى ابتدائي',
      'السنة الأولى ابتدائي ج': 'السنة الأولى ابتدائي',
      'السنة الأولى ابتدائي د': 'السنة الأولى ابتدائي',

      // Deuxième année
      'السنة الثانية ابتدائي': 'السنة الثانية ابتدائي',
      'السنة الثانية ابتدائي أ': 'السنة الثانية ابتدائي',
      'السنة الثانية ابتدائي ب': 'السنة الثانية ابتدائي',
      'السنة الثانية ابتدائي ج': 'السنة الثانية ابتدائي',
      'السنة الثانية ابتدائي د': 'السنة الثانية ابتدائي',

      // Troisième année
      'السنة الثالثة ابتدائي': 'السنة الثالثة ابتدائي',
      'السنة الثالثة ابتدائي أ': 'السنة الثالثة ابتدائي',
      'السنة الثالثة ابتدائي ب': 'السنة الثالثة ابتدائي',
      'السنة الثالثة ابتدائي ج': 'السنة الثالثة ابتدائي',
      'السنة الثالثة ابتدائي د': 'السنة الثالثة ابتدائي',

      // Quatrième année
      'السنة الرابعة ابتدائي': 'السنة الرابعة ابتدائي',
      'السنة الرابعة ابتدائي أ': 'السنة الرابعة ابتدائي',
      'السنة الرابعة ابتدائي ب': 'السنة الرابعة ابتدائي',
      'السنة الرابعة ابتدائي ج': 'السنة الرابعة ابتدائي',
      'السنة الرابعة ابتدائي د': 'السنة الرابعة ابتدائي',

      // Cinquième année
      'السنة الخامسة ابتدائي': 'السنة الخامسة ابتدائي',
      'السنة الخامسة ابتدائي أ': 'السنة الخامسة ابتدائي',
      'السنة الخامسة ابتدائي ب': 'السنة الخامسة ابتدائي',
      'السنة الخامسة ابتدائي ج': 'السنة الخامسة ابتدائي',
      'السنة الخامسة ابتدائي د': 'السنة الخامسة ابتدائي',

      // Sixième année
      'السنة السادسة ابتدائي': 'السنة السادسة ابتدائي',
      'السنة السادسة ابتدائي أ': 'السنة السادسة ابتدائي',
      'السنة السادسة ابتدائي ب': 'السنة السادسة ابتدائي',
      'السنة السادسة ابتدائي ج': 'السنة السادسة ابتدائي',
      'السنة السادسة ابتدائي د': 'السنة السادسة ابتدائي',
    };

    // Retourner la classe de base ou la classe originale si non trouvée
    return classMapping[classNameWithSection] ?? classNameWithSection;
  }

// Utilisez cette méthode dans _getCriteriaFromJson

  Future<List<Map<String, dynamic>>> _getCriteriaFromJson(
    String classId,
    String matiereId,
    String className,
    String matiereName,
  ) async {
    try {
      // print('🎯 ===== DEBUT RECHERCHE CRITERES JSON =====');
      // print('📌 Paramètres d\'entrée:');
      // print('   • Classe originale: "$className"');
      // print('   • Matière: "$matiereName"');

      // 1. Mapper la classe avec section vers la classe de base du JSON
      final String jsonClassName = _mapClassToJsonBase(className);
      // print('🔄 Classe mappée pour JSON: "$jsonClassName"');

      // 2. Charger le JSON
      final jsonString =
          await rootBundle.loadString('assets/evaluation_excel.json');
      final jsonData = json.decode(jsonString);

      // 3. Vérifier la structure
      if (!jsonData.containsKey('classes')) {
        // print('❌ ERREUR: Clé "classes" non trouvée dans JSON');
        return [];
      }

      final classes = jsonData['classes'] as Map<String, dynamic>;
      // print('📚 Classes disponibles dans JSON: ${classes.keys.length}');

      // Afficher toutes les classes disponibles pour le débogage
      // print('   Liste des classes JSON:');
      classes.keys.toList().sort();
      // for (final key in classes.keys) {
      //   print('   • $key');
      // }

      // 4. Chercher la classe dans le JSON
      if (!classes.containsKey(jsonClassName)) {
        // print('❌ ERREUR: Classe "$jsonClassName" non trouvée dans JSON');

        // Chercher des correspondances partielles
        for (final key in classes.keys) {
          if (key.contains(jsonClassName) || jsonClassName.contains(key)) {
            // print('   🔍 Correspondance trouvée: "$key"');
            return _extractCriteriaForClass(classes[key], matiereName);
          }
        }

        // print('   ❌ Aucune correspondance trouvée');
        return [];
      }

      // print('✅ SUCCES: Classe "$jsonClassName" trouvée dans JSON');

      // 5. Extraire les critères
      final classData = classes[jsonClassName];
      return _extractCriteriaForClass(classData, matiereName);
    } catch (e) {
      // print('💥 ERREUR FATALE dans _getCriteriaFromJson: $e');
      return [];
    } finally {
      // print('===== FIN RECHERCHE CRITERES JSON =====\n');
    }
  }

  List<Map<String, dynamic>> _extractCriteriaForClass(
      dynamic classData, String matiereName) {
    try {
      // print('🔍 Extraction critères pour matière: "$matiereName"');

      if (classData is! Map<String, dynamic>) {
        // print('❌ Données de classe invalides');
        return [];
      }

      // Vérifier la structure subjects
      if (!classData.containsKey('subjects') ||
          classData['subjects'] is! Map<String, dynamic>) {
        // print('❌ Clé "subjects" non trouvée ou invalide');
        return [];
      }

      final subjects = classData['subjects'] as Map<String, dynamic>;
      // print('📖 Matières disponibles dans la classe: ${subjects.keys.length}');

      // Afficher toutes les matières pour le débogage
      // print('   Liste des matières:');
      // for (final key in subjects.keys) {
      //   print('   • $key');
      // }

      // Chercher la matière exacte
      if (!subjects.containsKey(matiereName)) {
        // print('❌ Matière "$matiereName" non trouvée');
        // print('   Chercher des correspondances...');

        // Chercher par nom partiel
        for (final key in subjects.keys) {
          if (key.contains(matiereName) || matiereName.contains(key)) {
            // print('   ✅ Matière trouvée par correspondance: "$key"');
            return _processSubjectData(subjects[key], key);
          }
        }

        // Chercher par traduction
        if (_isFrenchInterface) {
          final arabicMatiereName =
              DataTranslator.getArabicMatiereFromFrench(matiereName);
          // print('   🔍 Chercher version arabe: "$arabicMatiereName"');

          if (subjects.containsKey(arabicMatiereName)) {
            // print('   ✅ Matière trouvée par traduction: "$arabicMatiereName"');
            return _processSubjectData(
                subjects[arabicMatiereName], arabicMatiereName);
          }
        }

        // print('❌ Matière non trouvée après toutes les recherches');
        return [];
      }

      // print('✅ Matière trouvée: "$matiereName"');
      return _processSubjectData(subjects[matiereName], matiereName);
    } catch (e) {
      // print('❌ Erreur extraction critères: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _processSubjectData(
      dynamic subjectData, String originalMatiereName) {
    try {
      if (subjectData is! Map<String, dynamic>) {
        // print('❌ Données matière invalides');
        return [];
      }

      // print('📊 Vérification données matière:');
      // print('   • has_criteria: ${subjectData['has_criteria']}');
      // print('   • criteria_count: ${subjectData['criteria_count']}');

      if (subjectData['has_criteria'] != true) {
        // print('⚠️ Matière sans critères (has_criteria = false)');
        return [];
      }

      final criteriaList = subjectData['criteria'] as List<dynamic>?;
      if (criteriaList == null || criteriaList.isEmpty) {
        // print('⚠️ Liste de critères vide ou null');
        return [];
      }

      // print('✅ ${criteriaList.length} critères trouvés');

      // Afficher les noms des critères pour le débogage
      // for (int i = 0; i < criteriaList.length; i++) {
      //   final criterion = criteriaList[i] as Map<String, dynamic>;
      //   print(
      //       '   ${i + 1}. ${criterion['name']} (${criterion['indicators_count'] ?? 0} indicateurs)');
      // }

      // Traiter et trier les critères
      return _createCriteriaList(criteriaList, originalMatiereName);
    } catch (e) {
      // print('❌ Erreur traitement données matière: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _createCriteriaList(
      List<dynamic> criteriaList, String matiereName) {
    final List<Map<String, dynamic>> criteria = [];

    for (int i = 0; i < criteriaList.length; i++) {
      final criterion = criteriaList[i] as Map<String, dynamic>;
      final criteriaName = criterion['name']?.toString() ?? 'معيار ${i + 1}';

      // Récupérer les indicateurs
      final indicators = criterion['indicators'] as List<dynamic>? ?? [];

      // Garder les indicateurs DANS L'ORDRE DU JSON
      final List<String> indicatorStrings = indicators
          .map((indicator) => indicator.toString())
          .where((indicator) => indicator.trim().isNotEmpty)
          .toList();

      // NE PAS TRIER les indicateurs
      // indicatorStrings.sort(_arabicStringComparator); // À SUPPRIMER

      // Créer l'entrée du critère
      criteria.add({
        'id': i + 1,
        'name': _isFrenchInterface
            ? DataTranslator.translateMatiere(criteriaName)
            : criteriaName,
        'originalName': criteriaName,
        'frenchName': DataTranslator.translateMatiere(criteriaName),
        'arabicName': criteriaName,
        'domaine': _getDomaineForMatiere(matiereName, _isFrenchInterface),
        'indicators': indicatorStrings, // Garder l'ordre original
        'indicators_count': indicatorStrings.length,
        'displayNumber': i + 1, // Garder l'ordre du JSON
        'sortKey': i + 1, // Utiliser l'index comme clé de tri
        'jsonOrder': i, // Ajouter l'ordre original du JSON
      });
    }

    // NE PAS TRIER LES CRITÈRES
    // Supprimer tout le code de tri ici
    // if (_isFrenchInterface) { ... }
    // else { ... }

    // Garder l'ordre du JSON tel quel
    // Les critères sont déjà dans l'ordre d'itération du JSON

// print('✅ ${criteria.length} critères chargés dans l\'ordre du JSON');
    return criteria;
  }

// Méthode auxiliaire pour extraire les critères d'une classe
  List<Map<String, dynamic>> _extractCriteriaFromClassData(
      dynamic classData, String matiereName) {
    if (classData is Map<String, dynamic> &&
        classData.containsKey('subjects') &&
        classData['subjects'] is Map<String, dynamic>) {
      final subjects = classData['subjects'] as Map<String, dynamic>;

      if (subjects.containsKey(matiereName)) {
        final subjectData = subjects[matiereName];
        final bool hasCriteria = subjectData['has_criteria'] ?? false;

        if (hasCriteria && subjectData['criteria'] != null) {
          final criteriaList = subjectData['criteria'] as List<dynamic>;
// print('✅ Critères trouvés pour $matiereName: ${criteriaList.length}');

          return _processCriteriaList(criteriaList, matiereName);
        } else {
// print('⚠️ Pas de critères pour $matiereName ou has_criteria=false');
        }
      } else {
// print('❌ Matière non trouvée dans la classe: $matiereName');
// print('Matières disponibles: ${subjects.keys.join(', ')}');
      }
    }

    return [];
  }

//
  List<Map<String, dynamic>> _processCriteriaList(
      List<dynamic> criteriaList, String matiereName) {
    List<Map<String, dynamic>> criteria = [];

    for (int i = 0; i < criteriaList.length; i++) {
      final criteriaData = criteriaList[i] as Map<String, dynamic>;
      final criteriaName = criteriaData['name']?.toString() ?? 'معيار ${i + 1}';
      final indicators = criteriaData['indicators'] as List<dynamic>? ?? [];

      // Garder l'ordre original du JSON
      final List<String> indicatorStrings = indicators
          .map((indicator) => indicator.toString())
          .where((indicator) => indicator.isNotEmpty)
          .toList();

      // NE PAS TRIER
      // indicatorStrings.sort(_arabicStringComparator); // À SUPPRIMER

      criteria.add({
        'name': _isFrenchInterface
            ? DataTranslator.translateMatiere(criteriaName)
            : criteriaName,
        'originalName': criteriaName,
        'domaine': _getDomaineForMatiere(matiereName, _isFrenchInterface),
        'indicators': indicatorStrings.map((indicator) {
          return _isFrenchInterface
              ? DataTranslator.translateMatiere(indicator)
              : indicator;
        }).toList(), // Garder l'ordre original
        'sortKey':
            (i + 1).toString().padLeft(3, '0'), // Garder l'ordre numérique
        'jsonIndex': i, // Index original du JSON
      });
    }

    // NE PAS TRIER
    // Supprimer tout le code de tri
    // criteria.sort((a, b) { ... });

    return criteria;
  }

// Méthode pour extraire l'année arabe d'un nom de classe
  String _extractArabicYear(String className) {
    // Extrait "الأولى", "الثانية", etc.
    final patterns = [
      'الأولى',
      'الثانية',
      'الثالثة',
      'الرابعة',
      'الخامسة',
      'السادسة'
    ];

    for (final pattern in patterns) {
      if (className.contains(pattern)) {
        return pattern;
      }
    }

    return className;
  }

// Comparateur pour tri alphabétique arabe
  int _arabicStringComparator(String a, String b) {
    // Normaliser les chaînes
    final normalizedA = _normalizeArabicForSort(a);
    final normalizedB = _normalizeArabicForSort(b);

    // Ordre des lettres arabes
    const arabicAlphabet = 'اأإآبتثجحخدذرزسشصضطظعغفقكلمنهويىةؤئء';

    for (int i = 0; i < math.min(normalizedA.length, normalizedB.length); i++) {
      final charA = normalizedA[i];
      final charB = normalizedB[i];

      final indexA = arabicAlphabet.indexOf(charA);
      final indexB = arabicAlphabet.indexOf(charB);

      if (indexA != -1 && indexB != -1 && indexA != indexB) {
        return indexA - indexB;
      }

      // Comparaison Unicode comme fallback
      if (charA != charB) {
        return charA.codeUnitAt(0) - charB.codeUnitAt(0);
      }
    }

    return normalizedA.length - normalizedB.length;
  }

// Normalisation du texte arabe pour le tri
  String _normalizeArabicForSort(String text) {
    // Supprimer les diacritiques
    String normalized = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

    // Normaliser les formes de lettres
    final Map<String, String> normalizationMap = {
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ؤ': 'و',
      'ئ': 'ي',
      'ة': 'ه',
      'ى': 'ي',
      'ٱ': 'ا',
      'ٳ': 'ا',
      'ٲ': 'ا',
    };

    normalizationMap.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    return normalized.trim();
  }

// Générer une clé de tri pour l'arabe
  String _generateArabicSortKey(String text) {
    final normalized = _normalizeArabicForSort(text);
    final withoutSpaces = normalized.replaceAll(' ', '');
    return withoutSpaces.toLowerCase();
  }

  void _detectLanguage() async {
    try {
      var matiereDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .get();

      String matiereName = matiereDoc['name'] ?? '';

      // Vérifier si c'est une matière en français
      bool isFrenchInterface;

      if (DataTranslator.isForeignMatiere(matiereName)) {
        isFrenchInterface = true;
      } else {
        // Vérifier le contenu de la matière
        final containsFrench =
            matiereName.contains(RegExp(r'[a-zA-Zéèêëàâäôöûüç]'));
        final containsArabic = matiereName.contains(RegExp(r'[\u0600-\u06FF]'));

        // Si contient du français mais pas d'arabe
        isFrenchInterface = containsFrench && !containsArabic;
      }

      setState(() {
        _matiereName = matiereName;
        _isFrenchInterface = isFrenchInterface;
        // print('Détection langue - Matière: "$matiereName", '
        //     'Interface française: $isFrenchInterface');
      });
    } catch (e) {
      // print('Erreur détection langue: $e');
      setState(() {
        _isFrenchInterface = false;
      });
    }
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
      // print('Erreur lecture champ $field: $e');
      return defaultValue;
    }
  }

  void _setupUserListener() {
    if (currentUser == null) return;

    _userSubscription = FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser!.uid)
        .snapshots()
        .listen((snapshot) {
      if (_isMounted && snapshot.exists) {
        setState(() {
          _remainingPrints = _getFieldSafe(snapshot, 'remainingPrints', 5);
          _isAccountActive = _getFieldSafe(snapshot, 'isActive', false);
          _profName = _getFieldSafe(snapshot, 'profName', '');
          _schoolName = _getFieldSafe(snapshot, 'schoolName', '');

          final expirationDate =
              _getFieldSafe(snapshot, 'accountExpiration', null);
          if (expirationDate != null && expirationDate is Timestamp) {
            _remainingTime = expirationDate.toDate().difference(DateTime.now());
          }
        });
      }
    });
  }

// Modifiez la méthode _showEvaluationInfoDialog
  void _showEvaluationInfoDialog(VoidCallback onConfirm) {
    TextEditingController periodeController =
        TextEditingController(text: _selectedPeriode);

    // Options pour le trimestre
    final trimestreOptions = ['الأول', 'الثاني', 'الثالث'];
    final trimestreTranslations = {
      'الأول': 'Premier',
      'الثاني': 'Deuxième',
      'الثالث': 'Troisième'
    };

    // Options pour le type d'évaluation
    final evaluationOptions = ['تقييم', 'امتحان'];
    final evaluationTranslations = {'تقييم': 'Évaluation', 'امتحان': 'Examen'};

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              _getTranslatedText(
                  'معلومات التقييم', 'Informations d\'évaluation'),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الثلاثي
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTranslatedText('الثلاثي:', 'Trimestre:'),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedTrimestre,
                      items: trimestreOptions
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  _isFrenchInterface
                                      ? trimestreTranslations[t] ?? t
                                      : t,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _selectedTrimestre = v;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // الوحدة / الفترة
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTranslatedText(
                          'الوحدة / الفترة:', 'Unité / Période:'),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: periodeController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText:
                            _getTranslatedText('مثال: الوحدة 1', 'Ex: Unité 1'),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // نوع التقييم
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTranslatedText('نوع التقييم:', 'Type d\'évaluation:'),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedEvaluationType,
                      items: evaluationOptions
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  _isFrenchInterface
                                      ? evaluationTranslations[t] ?? t
                                      : t,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _selectedEvaluationType = v;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getTranslatedText('إلغاء', 'Annuler')),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _selectedPeriode = periodeController.text.trim();
              });
              Navigator.pop(context);

              // ✅ التحقق مما إذا كان يجب عرض النصيحة
              final shouldShow = await _shouldShowIPhoneAdvice();

              if (shouldShow) {
                showDialog(
                  context: context,
                  builder: (context) => IPhoneAdviceDialog(
                    isFrenchInterface: _isFrenchInterface,
                    onContinue: () async {
                      await _markIPhoneAdviceAsShown();
                      onConfirm();
                    },
                  ),
                );
              } else {
                // تم عرض النصيحة من قبل، متابعة عادية
                onConfirm();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: Text(_getTranslatedText('متابعة', 'Continuer')),
          ),
        ],
      ),
    );
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
      // print('Erreur lors de la vérification du crédit: $e');
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
      // print('Erreur lors de la vérification du statut du compte: $e');
    }
  }

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

      // print('Statut compte - Actif: $isActive, Credits: $remainingPrints');

      if (isActive) {
        // print('Compte actif - Pas de déduction de crédit');
        return true;
      }

      if (remainingPrints > 0) {
        // print('Crédits suffisants - Restant: $remainingPrints');
        return true;
      }

      // print('Plus de crédits disponibles');
      return false;
    } catch (e) {
      // print('Erreur lors de la vérification du crédit: $e');
      return false;
    }
  }

  // MODIFICATION : Traduction des textes selon la langue
  String _getTranslatedText(String arabicText, String frenchText) {
    return _isFrenchInterface ? frenchText : arabicText;
  }

  Future<void> _saveAndOpenPDF(Uint8List pdfBytes) async {
    try {
      if (kIsWeb) {
        // Pour le web
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'tableau_resultats.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Pour mobile/desktop
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/tableau_resultats.pdf';

        // Utiliser XFile au lieu de File
        final xFile = XFile.fromData(
          pdfBytes,
          name: 'tableau_resultats.pdf',
          mimeType: 'application/pdf',
        );

        await xFile.saveTo(filePath);
        await OpenFile.open(filePath);
      }
    } catch (e) {
      // print('Erreur sauvegarde PDF: $e');
      throw e;
    }
  }

  Future<void> _generateHTMLReport({bool downloadAsPDF = false}) async {
    if (!await _checkAndUpdatePrintCredit()) {
      _showCreditErrorDialog();
      return;
    }

    setState(() {
      _isGeneratingReport = true;
    });

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            _buildLoadingDialog(isPDF: downloadAsPDF),
      );

      // Récupérer les données CORRECTEMENT
      final matiereName = await _getMatiereName();
      final className = await _getClassName();

      // DEBUG: Afficher les données avant envoi
      // print('=== DONNÉES POUR RAPPORT HTML ===');
      // print('Total étudiants: $totalStudents');
      // print('Statistiques sumCriteriaMaxPerBareme:');
      // sumCriteriaMaxPerBareme.forEach((key, value) {
      //   print('  $key: $value');
      // });

      var data = {
        'profName': _profName,
        'matiereName': matiereName,
        'className': className,
        'schoolName': _schoolName,
        'baremes': await _getBaremes(),
        'students': await _getStudents(),
        'sumCriteriaMaxPerBareme': sumCriteriaMaxPerBareme,
        'totalStudents': totalStudents,
        'selectedClass': widget.selectedClass,
        'isFrenchInterface': _isFrenchInterface,
        'trimestre': _selectedTrimestre,
        'periode': _selectedPeriode,
        'evaluationType': _selectedEvaluationType,
      };

      // Générer le rapport (HTML ou PDF)
      await HTMLReportGenerator.generateAndDownloadReport(
        profName: _profName,
        matiereName: matiereName,
        className: className,
        schoolName: _schoolName,
        baremes: data['baremes'] as List<dynamic>,
        students: data['students'] as List<dynamic>,
        sumCriteriaMaxPerBareme:
            sumCriteriaMaxPerBareme, // IMPORTANT: envoyer les bonnes données
        totalStudents: totalStudents,
        isFrenchInterface: _isFrenchInterface,
        downloadAsPDF: downloadAsPDF,
        trimestre: _selectedTrimestre,
        periode: _selectedPeriode,
        evaluationType: _selectedEvaluationType,
      );

      // Dédure le crédit
      await _deductPrintCredit();

      _showSuccessSnackbar(downloadAsPDF
          ? _getTranslatedText('تم إنشاء PDF بنجاح', 'PDF généré avec succès')
          : _getTranslatedText(
              'تم إنشاء التقرير بنجاح', 'Rapport généré avec succès'));
    } catch (e) {
      _showErrorSnackbar(_getTranslatedText('خطأ في إنشاء التقرير',
              'Erreur lors de la génération du rapport') +
          ': $e');
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });
      Navigator.of(context).pop();
    }
  }

  Widget _buildLoadingDialog({bool isPDF = false}) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    isPDF ? Colors.red : Colors.blue),
                strokeWidth: 3,
              ),
              Icon(
                isPDF ? Icons.picture_as_pdf : Icons.description,
                color: isPDF ? Colors.red : Colors.blue,
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            isPDF
                ? _getTranslatedText(
                    "جاري إنشاء PDF...", "Génération du PDF en cours...")
                : _getTranslatedText("جاري إنشاء التقرير...",
                    "Génération du rapport en cours..."),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 10),
          Text(
            _getTranslatedText("يرجى الانتظار...", "Veuillez patienter..."),
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
                    _getTranslatedText(
                        'الرصيد المستخدم: ${_remainingPrints - 1}/5',
                        'Crédit utilisé: ${_remainingPrints - 1}/5'),
                    style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showCreditErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.credit_card_off, color: Colors.orange),
            SizedBox(width: 10),
            Text(_getTranslatedText('انتهت الرصيد', 'Crédit Épuisé')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTranslatedText('لم يعد لديك رصيد طباعة متاح.',
                  'Vous n\'avez plus de crédits d\'impression disponibles.'),
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              _getTranslatedText('يرجى تفعيل حسابك للمواصلة في إنشاء التقارير.',
                  'Veuillez activer votre compte pour continuer à générer des rapports.'),
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
                      _getTranslatedText('الرصيد المتبقي: $_remainingPrints/5',
                          'Crédits restants: $_remainingPrints/5'),
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
            child: Text(_getTranslatedText('لاحقاً', 'Plus tard')),
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
            child:
                Text(_getTranslatedText('تفعيل الحساب', 'Activer le compte')),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport(String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackbar(_getTranslatedText(
          'المستخدم غير مسجل الدخول.', 'Utilisateur non connecté.'));
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
        // Ajouter les informations du dialogue
        'trimestre': _selectedTrimestre,
        'periode': _selectedPeriode,
        'evaluationType': _selectedEvaluationType,
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
      _showErrorSnackbar(_getTranslatedText('خطأ في إنشاء التقرير:',
              'Erreur lors de la génération du rapport:') +
          ' $e');
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });
      Navigator.of(context).pop();
    }
  }

  Widget _buildLoadingDialogForReport() {
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
            _getTranslatedText(
                "جاري إنشاء التقرير...", "Génération du rapport en cours..."),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 10),
          Text(
            _getTranslatedText("يرجى الانتظار...", "Veuillez patienter..."),
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
                    _getTranslatedText(
                        'الرصيد المستخدم: ${_remainingPrints - 1}/5',
                        'Crédit utilisé: ${_remainingPrints - 1}/5'),
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
      // Récupérer le système d'évaluation
      final String evaluationSystem = await _getEvaluationSystem(
          widget.selectedClass, widget.selectedMatiere);

      // Récupérer les notes personnalisées
      List<String> customNotes = [];
      if (evaluationSystem == 'custom') {
        customNotes = await _loadCustomNotes(
            widget.selectedClass, widget.selectedMatiere);
        // print('📝 Notes custom chargées: $customNotes');
      }

      // print('📤 ENVOI À FLASK - SYSTÈME: $evaluationSystem');

      Map<String, dynamic> finalData = {
        "userId": data['userId'],
        "user": {
          "profName": data['profName'],
          "schoolName": data['schoolName'],
        },
        "class": {
          "name": data['className'],
        },
        "matiere": {
          "name": data['matiereName'],
        },
        "period": {
          "trimestre": _selectedTrimestre,
          "periode": _selectedPeriode,
          "evaluationType": _selectedEvaluationType,
        },
        "performanceAttendue": data['performanceAttendue'] ?? '',
        "isFrenchInterface": _isFrenchInterface,
        "evaluationSystem": evaluationSystem,
        "customNotes": customNotes,
      };

      final url = Uri.parse(
          'https://mohamedtsou-taqyem-imprission.hf.space/generate_pdf');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(finalData),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        if (kIsWeb) {
          // Version Web
          final blob = html.Blob([bytes], 'application/pdf');
          final url = html.Url.createObjectUrlFromBlob(blob);

          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download',
                'tableau_resultats_${DateTime.now().millisecondsSinceEpoch}.pdf')
            ..click();

          html.Url.revokeObjectUrl(url);
        } else {
          // Version Mobile/Desktop
          final directory = await getTemporaryDirectory();
          final filePath =
              '${directory.path}/tableau_resultats_${DateTime.now().millisecondsSinceEpoch}.pdf';

          final xFile = XFile.fromData(
            bytes,
            name:
                'tableau_resultats_${DateTime.now().millisecondsSinceEpoch}.pdf',
            mimeType: 'application/pdf',
          );

          await xFile.saveTo(filePath);
          await OpenFile.open(filePath);
        }

        _showSuccessSnackbar(
            _getTranslatedText('تم إنشاء PDF بنجاح', 'PDF généré avec succès'));
        return true;
      } else {
        _showErrorSnackbar(_getTranslatedText(
            'خطأ في إنشاء PDF', 'Erreur lors de la génération du PDF'));
        return false;
      }
    } on TimeoutException {
      _showErrorSnackbar(_getTranslatedText('انتهت المهلة', 'Timeout'));
      return false;
    } catch (e) {
      _showErrorSnackbar(_getTranslatedText('خطأ تقني:', 'Erreur technique:') +
          ' ${e.toString()}');
      return false;
    }
  }

  String _getDisplayEvaluationForExport(String storedValue, String system,
      {List<String>? customNotes}) {
    // Vérifier si c'est "غائب"
    if (storedValue == 'غائب') {
      return 'غائب';
    }

    // Si c'est déjà un nombre, le retourner tel quel
    if (double.tryParse(storedValue) != null) {
      return storedValue;
    }

    if (system == 'custom' && customNotes != null && customNotes.isNotEmpty) {
      final Map<String, String> mapping = {
        '( - - - )': customNotes[0],
        '( + - - )': customNotes.length > 1 ? customNotes[1] : customNotes[0],
        '( + + - )': customNotes.length > 2 ? customNotes[2] : customNotes.last,
        '( + + + )': customNotes.last,
      };
      return mapping[storedValue] ?? customNotes[0];
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
            return storedValue;
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
            return storedValue;
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
            return storedValue;
        }

      default:
        return storedValue;
    }
  }

  Future<bool> _sendHTMLDataToFlask(Map<String, dynamic> data) async {
    try {
      final String evaluationSystem = await _getEvaluationSystem(
          widget.selectedClass, widget.selectedMatiere);

      List<String> customNotes = [];
      if (evaluationSystem == 'custom') {
        customNotes = await _loadCustomNotes(
            widget.selectedClass, widget.selectedMatiere);
      }

      // Préparer les données des étudiants avec conversion
      List<Map<String, dynamic>> processedStudents = [];

      for (var student in data['students']) {
        Map<String, dynamic> processedStudent = {
          'id': student['id'],
          'name': student['name'],
          'baremes': {},
        };

        student['baremes'].forEach((key, value) {
          String convertedValue = _getDisplayEvaluationForExport(
            value.toString(),
            evaluationSystem,
            customNotes: customNotes,
          );
          processedStudent['baremes'][key] = convertedValue;
        });

        processedStudents.add(processedStudent);
      }

      Map<String, dynamic> finalData = {
        'profName': data['profName'],
        'matiereName': data['matiereName'],
        'className': data['className'],
        'schoolName': data['schoolName'],
        'baremes': data['baremes'],
        'students': processedStudents,
        'sumCriteriaMaxPerBareme': data['sumCriteriaMaxPerBareme'],
        'totalStudents': data['totalStudents'],
        'selectedClass': data['selectedClass'],
        'isFrenchInterface': _isFrenchInterface,
        'trimestre': _selectedTrimestre,
        'periode': _selectedPeriode,
        'evaluationType': _selectedEvaluationType,
        'evaluationSystem': evaluationSystem,
        'customNotes': customNotes,
      };

      final url =
          Uri.parse('https://imprission.onrender.com/generate-html-report');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(finalData),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final htmlContent = utf8.decode(response.bodyBytes);

        if (kIsWeb) {
          // Version Web
          final blob = html.Blob([htmlContent], 'text/html; charset=utf-8');
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.window.open(url, '_blank');
          html.Url.revokeObjectUrl(url);
        } else {
          // Version Mobile/Desktop
          final directory = await getTemporaryDirectory();
          final filePath =
              '${directory.path}/rapport_${DateTime.now().millisecondsSinceEpoch}.html';

          final xFile = XFile.fromData(
            Uint8List.fromList(utf8.encode(htmlContent)),
            name: 'rapport_${DateTime.now().millisecondsSinceEpoch}.html',
            mimeType: 'text/html',
          );

          await xFile.saveTo(filePath);
          await OpenFile.open(filePath);
        }

        _showSuccessSnackbar(_getTranslatedText(
            'تم إنشاء التقرير بنجاح', 'Rapport généré avec succès'));
        return true;
      } else {
        _showErrorSnackbar(_getTranslatedText('خطأ في إنشاء التقرير HTML:',
                'Erreur lors de la génération du rapport HTML:') +
            ' ${response.statusCode}');
        return false;
      }
    } on TimeoutException {
      _showErrorSnackbar(_getTranslatedText('انتهت المهلة', 'Timeout'));
      return false;
    } catch (e) {
      _showErrorSnackbar(_getTranslatedText('خطأ تقني:', 'Erreur technique:') +
          ' ${e.toString()}');
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

        // print('✅ Crédit déduit - Nouveau solde: ${remainingPrints - 1}');
      }
    } catch (e) {
      // print('Erreur lors de la déduction du crédit: $e');
    }
  }

  // MODIFICATION : Traduction des noms pour l'interface
  // MODIFICATION : Garder les noms arabes dans la BD, traduire uniquement pour l'affichage
  Future<String> _getMatiereName() async {
    try {
      var matiereDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .collection('matieres')
          .doc(widget.selectedMatiere)
          .get();

      String arabicName = _getFieldSafe(matiereDoc, 'name', 'غير معروف');
      // L'enregistrement en BD reste en arabe, on traduit uniquement pour l'affichage
      return _isFrenchInterface
          ? DataTranslator.translateMatiere(arabicName)
          : arabicName;
    } catch (e) {
      return _isFrenchInterface ? 'Inconnu' : 'غير معروف';
    }
  }

  Future<String> _getClassName() async {
    try {
      var classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.selectedClass)
          .get();

      String arabicName = _getFieldSafe(classDoc, 'name', 'غير معروف');
      // L'enregistrement en BD reste en arabe, on traduit uniquement pour l'affichage
      return _isFrenchInterface
          ? DataTranslator.translateClass(arabicName)
          : arabicName;
    } catch (e) {
      return _isFrenchInterface ? 'Inconnu' : 'غير معروف';
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

        // Traduire si nécessaire
        String displayedBaremeName = _isFrenchInterface
            ? DataTranslator.translateBareme(baremeName)
            : baremeName;

        if (_useJsonBaremeTranslation &&
            _classNameArabic.isNotEmpty &&
            _matiereName.isNotEmpty) {
          displayedBaremeName = _getTranslatedBaremeName(
              baremeName, _classNameArabic, _matiereName);
        }

        if (isBaremeSelected) {
          // Récupérer les sous-barèmes
          final sousBaremesSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .collection('selections')
              .doc(widget.selectedClass)
              .collection(widget.selectedMatiere)
              .doc(baremeId)
              .collection('sousBaremes')
              .get();

          final List<Map<String, dynamic>> sousBaremesList = [];

          for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
            final sousBaremeId = sousBaremeDoc.id;
            final sousBaremeName =
                _getFieldSafe(sousBaremeDoc, 'sousBaremeName', 'غير معروف');
            final isSousBaremeSelected =
                _getFieldSafe(sousBaremeDoc, 'selected', false);

            if (isSousBaremeSelected) {
              final displayedSousBaremeName = _isFrenchInterface
                  ? DataTranslator.translateSousBareme(sousBaremeName)
                  : sousBaremeName;

              sousBaremesList.add({
                'id': sousBaremeId,
                'value': displayedSousBaremeName,
                'originalValue': sousBaremeName,
                'type': 'sousBareme',
              });
            }
          }

          // ✅ TRIER les sous-barèmes par ordre alphabétique
          sousBaremesList.sort((a, b) {
            String nameA = a['value'] ?? '';
            String nameB = b['value'] ?? '';

            if (!_isFrenchInterface &&
                nameA.contains(RegExp(r'[\u0600-\u06FF]'))) {
              return _arabicStringComparator(nameA, nameB);
            }
            return nameA.compareTo(nameB);
          });

          baremes.add({
            'id': baremeId,
            'value': displayedBaremeName,
            'originalValue': baremeName,
            'type': 'bareme',
            'sousBaremes': sousBaremesList,
          });
        }
      }

      // ✅ TRIER les barèmes principaux par ordre alphabétique
      baremes.sort((a, b) {
        String nameA = a['value'] ?? '';
        String nameB = b['value'] ?? '';

        if (!_isFrenchInterface && nameA.contains(RegExp(r'[\u0600-\u06FF]'))) {
          return _arabicStringComparator(nameA, nameB);
        }
        return nameA.compareTo(nameB);
      });

      return baremes;
    } catch (e) {
      // print('Erreur récupération barèmes: $e');
      return [];
    }
  }

  Future<List<dynamic>> _getStudents() async {
    try {
      // Récupérer le système d'évaluation
      final String evaluationSystem = await _getEvaluationSystem(
          widget.selectedClass, widget.selectedMatiere);

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
        final studentName = _getFieldSafe(studentDoc, 'name',
            _isFrenchInterface ? 'Élève inconnu' : 'تلميذ غير معروف');

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
          final storedValue = _getFieldSafe(baremeDoc, 'Marks', '( - - - )');

          // Charger les notes personnalisées du barème
          final customNotes = await _getCustomNotesForBareme(
              widget.selectedClass, widget.selectedMatiere, baremeId);

          // ✅ Convertir selon le système POUR L'AFFICHAGE DANS L'APP
          final displayValue = _getDisplayEvaluation(
            storedValue,
            evaluationSystem,
            customNotes: customNotes,
          );

          baremes[baremeId] = displayValue;

          // Gérer les sous-barèmes
          final sousBaremesSnapshot =
              await baremeDoc.reference.collection('sous_baremes').get();

          for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
            final sousBaremeId = sousBaremeDoc.id;
            final sousStoredValue =
                _getFieldSafe(sousBaremeDoc, 'Marks', '( - - - )');

            final sousCustomNotes = await _getSousBaremeCustomNotes(
              widget.selectedClass,
              widget.selectedMatiere,
              baremeId,
              sousBaremeId,
            );

            final sousDisplayValue = _getDisplayEvaluation(
              sousStoredValue,
              evaluationSystem,
              customNotes: sousCustomNotes,
            );

            baremes['$baremeId-$sousBaremeId'] = sousDisplayValue;
          }
        }

        students.add({
          'id': studentId,
          'name': studentName,
          'baremes': baremes, // ✅ Notes déjà converties pour l'affichage
        });
      }

      // Trier les étudiants
      students.sort((a, b) {
        String nameA = a['name'] ?? '';
        String nameB = b['name'] ?? '';

        if (!_isFrenchInterface && nameA.contains(RegExp(r'[\u0600-\u06FF]'))) {
          return _arabicStringComparator(nameA, nameB);
        }

        return nameA.compareTo(nameB);
      });

      return students;
    } catch (e) {
      // print('❌ Erreur récupération étudiants: $e');
      return [];
    }
  }

  Future<List<String>> _getCustomNotesForBareme(
      String classId, String matiereId, String baremeId) async {
    try {
      // 1. Chercher les notes spécifiques au barème
      final specificDocId = '$classId-$matiereId-$baremeId';

      final specificDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('bareme_custom_notes')
          .doc(specificDocId)
          .get();

      if (specificDoc.exists) {
        final notes = specificDoc.data()?['notes'];
        if (notes != null && notes is List && notes.isNotEmpty) {
          return List<String>.from(notes);
        }
      }

      // 2. Chercher les notes globales (sans baremeId)
      final globalDocId = '$classId-$matiereId';

      final globalDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('bareme_custom_notes')
          .doc(globalDocId)
          .get();

      if (globalDoc.exists) {
        final notes = globalDoc.data()?['notes'];
        if (notes != null && notes is List && notes.isNotEmpty) {
          return List<String>.from(notes);
        }
      }

      return [];
    } catch (e) {
      // print('Erreur chargement notes: $e');
      return [];
    }
  }

  Future<List<String>> _getSousBaremeCustomNotes(
    String classId,
    String matiereId,
    String baremeId,
    String sousBaremeId,
  ) async {
    try {
      // Chercher avec sousBaremeId
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('sous_bareme_custom_notes')
          .where('sousBaremeId', isEqualTo: sousBaremeId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final notes = doc.data()['notes'];

        if (notes != null && notes is List && notes.isNotEmpty) {
          return List<String>.from(notes);
        }
      }

      return [];
    } catch (e) {
      // print('Erreur chargement notes sous-barème: $e');
      return [];
    }
  }

  void _loadUserData() async {
    if (currentUser != null && _isMounted) {
      try {
        var userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser!.uid)
            .get();

        if (_isMounted && userDoc.exists) {
          setState(() {
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
// print('Erreur lors du chargement des données utilisateur: $e');
      }
    }
  }

  // MODIFICATION : Dialogues traduits
  void _showEditDialog() {
    TextEditingController profController =
        TextEditingController(text: _profName);
    TextEditingController schoolController =
        TextEditingController(text: _schoolName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(_getTranslatedText('الإعدادات', 'Paramètres'),
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: profController,
                      decoration: InputDecoration(
                        labelText: _getTranslatedText(
                            'اسم الأستاذ', 'Nom du professeur'),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: schoolController,
                      decoration: InputDecoration(
                        labelText: _getTranslatedText(
                            'اسم المدرسة', 'Nom de l\'école'),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school),
                      ),
                    ),
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 8),
                    SwitchListTile(
                      title: Text(_getTranslatedText('ترجمة أسماء المعايير',
                          'Traduire les noms des critères')),
                      subtitle: Text(_getTranslatedText(
                          'يعرض أسماء المعايير حسب ملف evaluation_excel.json',
                          'Affiche les noms des critères selon le fichier JSON')),
                      value: _useJsonBaremeTranslation,
                      onChanged: (value) async {
                        if (!context.mounted) return;
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('useJsonBaremeTranslation', value);
                        setDialogState(() {
                          _useJsonBaremeTranslation = value;
                        });
                        if (mounted) {
                          setState(() {
                            _useJsonBaremeTranslation = value;
                          });
                        }
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(_getTranslatedText('إلغاء', 'Annuler')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (currentUser != null) {
                      await FirebaseFirestore.instance
                          .collection('Users')
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

                      _showSuccessSnackbar(_getTranslatedText(
                          'تم تحديث المعلومات', 'Informations mises à jour'));
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(_getTranslatedText('حفظ', 'Enregistrer')),
                ),
              ],
            );
          },
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
              Text(
                  _getTranslatedText('معلومات جديدة', 'Nouvelles informations'),
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  _getTranslatedText('يرجى إكمال معلوماتك للمتابعة',
                      'Veuillez compléter vos informations pour continuer'),
                  style: TextStyle(color: Colors.grey[600])),
              SizedBox(height: 16),
              TextField(
                controller: profController,
                decoration: InputDecoration(
                  labelText:
                      _getTranslatedText('اسم الأستاذ', 'Nom du professeur'),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: schoolController,
                decoration: InputDecoration(
                  labelText:
                      _getTranslatedText('اسم المدرسة', 'Nom de l\'école'),
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
                  _showErrorSnackbar(_getTranslatedText('يرجى ملء جميع الحقول',
                      'Veuillez remplir tous les champs'));
                  return;
                }

                if (currentUser != null) {
                  await FirebaseFirestore.instance
                      .collection('Users')
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

                  _showSuccessSnackbar(_getTranslatedText(
                      'تم حفظ المعلومات', 'Informations enregistrées'));
                }
                Navigator.of(context).pop();
              },
              child: Text(_getTranslatedText('حفظ', 'Enregistrer')),
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

      // Récupérer les étudiants
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

      // Récupérer les barèmes sélectionnés
      var selectedBaremes = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .get();

      // Réinitialiser les compteurs
      sumCriteriaMaxPerBareme.clear();

      // Initialiser les compteurs pour tous les barèmes sélectionnés
      for (var baremeDoc in selectedBaremes.docs) {
        var baremeId = _getFieldSafe(baremeDoc, 'baremeId', '');
        var isBaremeSelected = _getFieldSafe(baremeDoc, 'selected', false);

        if (isBaremeSelected) {
          sumCriteriaMaxPerBareme[baremeId] = 0;
        }

        // Vérifier les sous-barèmes
        var sousBaremesSnapshot =
            await baremeDoc.reference.collection('sousBaremes').get();
        for (var sousBaremeDoc in sousBaremesSnapshot.docs) {
          var isSousBaremeSelected =
              _getFieldSafe(sousBaremeDoc, 'selected', false);
          if (isSousBaremeSelected) {
            var sousBaremeId = sousBaremeDoc.id;
            sumCriteriaMaxPerBareme[sousBaremeId] = 0;
          }
        }
      }

      // Compter les élèves qui ont atteint chaque critère
      for (var studentDoc in studentsSnapshot.docs) {
        var studentId = studentDoc.id;

        for (var baremeDoc in selectedBaremes.docs) {
          var baremeId = _getFieldSafe(baremeDoc, 'baremeId', '');
          var isBaremeSelected = _getFieldSafe(baremeDoc, 'selected', false);

          if (isBaremeSelected) {
            // Vérifier le barème principal
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
              var value = _getFieldSafe(baremeSnapshot, 'Marks', '( - - - )');
              // Compter si la note est positive
              if (value == '( + + + )' || value == '( + + - )') {
                sumCriteriaMaxPerBareme[baremeId] =
                    (sumCriteriaMaxPerBareme[baremeId] ?? 0) + 1;
              }
            }
          }

          // Vérifier les sous-barèmes
          var sousBaremesSnapshot =
              await baremeDoc.reference.collection('sousBaremes').get();
          for (var sousBaremeDoc in sousBaremesSnapshot.docs) {
            var isSousBaremeSelected =
                _getFieldSafe(sousBaremeDoc, 'selected', false);
            if (isSousBaremeSelected) {
              var sousBaremeId = sousBaremeDoc.id;

              // Vérifier la valeur du sous-barème
              var sousBaremeSnapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('user_classes')
                  .doc(widget.selectedClass)
                  .collection('students')
                  .doc(studentId)
                  .collection('baremes')
                  .doc(baremeId)
                  .collection('sous_baremes')
                  .doc(sousBaremeId)
                  .get();

              if (sousBaremeSnapshot.exists) {
                var value =
                    _getFieldSafe(sousBaremeSnapshot, 'Marks', '( - - - )');
                if (value == '( + + + )' || value == '( + + - )') {
                  sumCriteriaMaxPerBareme[sousBaremeId] =
                      (sumCriteriaMaxPerBareme[sousBaremeId] ?? 0) + 1;
                }
              }
            }
          }
        }
      }

      if (_isMounted) {
        setState(() {});
      }
    } catch (e) {
      // print('Erreur lors de la récupération des marques : $e');
    }
  }

  // MODIFICATION : Widgets avec textes traduits
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
      message: _getTranslatedText(
          'الرصيد المتبقي للطباعة', 'Crédit d\'impression restant'),
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
      message: _getTranslatedText(
          'الوقت المتبقي قبل الانتهاء', 'Temps restant avant expiration'),
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
      message: _isAccountActive
          ? _getTranslatedText('حساب نشط', 'Compte actif')
          : _getTranslatedText('حساب غير نشط', 'Compte inactif'),
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
              _isAccountActive
                  ? _getTranslatedText('نشط', 'Actif')
                  : _getTranslatedText('غير نشط', 'Inactif'),
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

  Widget _buildUpgradeButton() {
    if (_isAccountActive) return SizedBox();

    return Tooltip(
      message: _getTranslatedText('تفعيل حسابك', 'Activer votre compte'),
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
              Text(
                  _getTranslatedText(
                      'المستخدم غير مسجل الدخول.', 'Utilisateur non connecté.'),
                  style: TextStyle(fontSize: 18)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_getTranslatedText('العودة', 'Retour')),
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
              Text(
                  _getTranslatedText('جاري تحميل معلوماتك...',
                      'Chargement de vos informations...'),
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
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: _getTranslatedText('رجوع', 'Retour'),
          ),
          title: Text(
              _getTranslatedText(
                  'الجدول الجامع للنتائج', 'Tableau Global des Résultats'),
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
          textDirection:
              _isFrenchInterface ? TextDirection.ltr : TextDirection.rtl,
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
                      _getTranslatedText(
                          'تاريخ الإصدار: ${DateTime.now().toString().substring(0, 10)}',
                          'Date d\'émission: ${DateTime.now().toString().substring(0, 10)}'),
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
                              _getTranslatedText(
                                  'حساب محدود - $_remainingPrints/5 طباعة',
                                  'Compte limité - $_remainingPrints/5 impressions'),
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
        String className = _isFrenchInterface ? 'Inconnu' : 'غير معروف';
        String matiereName = _isFrenchInterface ? 'Inconnu' : 'غير معروف';

        if (snapshot.connectionState == ConnectionState.waiting) {
          className = _isFrenchInterface ? 'Chargement...' : 'جاري التحميل...';
          matiereName =
              _isFrenchInterface ? 'Chargement...' : 'جاري التحميل...';
        } else if (snapshot.hasData) {
          className = snapshot.data!['className'] ??
              (_isFrenchInterface ? 'Inconnu' : 'غير معروف');
          matiereName = snapshot.data!['matiereName'] ??
              (_isFrenchInterface ? 'Inconnu' : 'غير معروف');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
                _getTranslatedText('الأستاذ:', 'Professeur:'),
                _profName.isEmpty
                    ? (_isFrenchInterface ? 'Non renseigné' : 'غير محدد')
                    : _profName),
            SizedBox(height: 4),
            _buildInfoRow(
                _getTranslatedText('المادة:', 'Matière:'), matiereName),
            SizedBox(height: 4),
            _buildInfoRow(_getTranslatedText('القسم:', 'Classe:'), className),
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
// print("Erreur chargement image: $error");
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
          _getTranslatedText('مدرسة:', 'École:') + ' $_schoolName',
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

      // Traduire si l'interface est en français
      if (_isFrenchInterface) {
        className = DataTranslator.translateClass(className);
        matiereName = DataTranslator.translateMatiere(matiereName);
      }

      return {
        'className': className,
        'matiereName': matiereName,
      };
    } catch (e) {
      return {
        'className': _isFrenchInterface ? 'Inconnu' : 'غير معروف',
        'matiereName': _isFrenchInterface ? 'Inconnu' : 'غير معروف',
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
                Text(_getTranslatedText(
                    'جاري تحميل الأقسام...', 'Chargement des classes...')),
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
                Text(
                    _getTranslatedText(
                        'خطأ في التحميل', 'Erreur de chargement'),
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
                Text(
                    _getTranslatedText(
                        'لم يتم العثور على أي قسم.', 'Aucune classe trouvée.'),
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text(
                    _getTranslatedText('يرجى إضافة أقسام أولاً.',
                        'Veuillez ajouter des classes d\'abord.'),
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
              isFrenchInterface: _isFrenchInterface,
              useJsonBaremeTranslation: _useJsonBaremeTranslation,
              classNameArabic: _classNameArabic,
              matiereName: _matiereName,
              jsonCriteriaData: _jsonCriteriaData,
              profName: _profName,
              schoolName: _schoolName,
            );
          }
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                  _getTranslatedText('لم يتم العثور على أي قسم مطابق.',
                      'Aucune classe correspondante trouvée.'),
                  style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text(
                  _getTranslatedText('القسم المحدد غير موجود.',
                      'La classe sélectionnée n\'existe pas.'),
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  // MODIFICATION : Navigation avec détection de langue
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
        orElse: () => {
          'id': baremeId,
          'value': _isFrenchInterface ? 'Inconnu' : 'غير معروف'
        },
      );

      String baremeName = selectedBareme['value'] ??
          (_isFrenchInterface ? 'Inconnu' : 'غير معروف');

      String? sousBaremeName;
      if (sousBaremeId != null) {
        var selectedSousBareme = baremesValues.firstWhere(
          (bareme) =>
              bareme['id'] == sousBaremeId &&
              bareme['parentBaremeId'] == baremeId,
          orElse: () => {
            'id': sousBaremeId,
            'value': _isFrenchInterface ? 'Inconnu' : 'غير معروف'
          },
        );

        sousBaremeName = selectedSousBareme['value'] ??
            (_isFrenchInterface ? 'Inconnu' : 'غير معروف');
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
            className: classAndMatiereNames['className'] ??
                (_isFrenchInterface ? 'Inconnu' : 'غير معروف'),
            matiereName: classAndMatiereNames['matiereName'] ??
                (_isFrenchInterface ? 'Inconnu' : 'غير معروف'),
            baremeName: baremeName,
            sousBaremeName: sousBaremeName,
          ),
        ),
      );
    } catch (e) {
      // print('Erreur lors de la navigation vers la page de classification : $e');
      _showErrorSnackbar(
          _getTranslatedText('خطأ في التنقل', 'Erreur lors de la navigation'));
    }
  }

  Future<List<Map<String, dynamic>>> _getBaremesValues(
      List<QueryDocumentSnapshot> selectedBaremes) async {
    final List<Map<String, dynamic>> result = [];
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    for (final baremeDoc in selectedBaremes) {
      final baremeId = baremeDoc.id;
      final baremeData = baremeDoc.data() as Map<String, dynamic>;

      // CORRECTION : Récupérer correctement le nom du barème
      final baremeName =
          baremeData['baremeName'] ?? baremeData['value'] ?? 'غير معروف';
      final isBaremeSelected = baremeData['selected'] ?? false;

      // CORRECTION : Récupérer les sous-barèmes
      final sousBaremesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .doc(baremeId)
          .collection('sousBaremes')
          .get();

      if (isBaremeSelected) {
        result.add({
          'id': baremeId,
          'value': _isFrenchInterface
              ? DataTranslator.translateBareme(baremeName)
              : baremeName,
          'originalValue': baremeName,
          'sousBaremes': [],
        });
      }

      // CORRECTION : Traiter les sous-barèmes
      for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
        final sousBaremeData = sousBaremeDoc.data() as Map<String, dynamic>;
        final isSousBaremeSelected = sousBaremeData['selected'] ?? false;
        final sousBaremeName = sousBaremeData['sousBaremeName'] ?? 'غير معروف';

        if (isSousBaremeSelected) {
          result.add({
            'id': sousBaremeDoc.id,
            'value': _isFrenchInterface
                ? DataTranslator.translateSousBareme(sousBaremeName)
                : sousBaremeName,
            'originalValue': sousBaremeName,
            'parentBaremeId': baremeId,
          });
        }
      }
    }

    return result;
  }
}

// MODIFICATION : Ajouter le paramètre isFrenchInterface à StudentsTable

// MODIFICATION : Ajouter le paramètre isFrenchInterface à StudentsTable
class StudentsTable extends StatefulWidget {
  final String classDocId;
  final String selectedClass;
  final String selectedMatiere;
  final User currentUser;
  final Map<String, int> sumCriteriaMaxPerBareme;
  final int totalStudents;
  final Function(String, {String? sousBaremeId}) navigateToClassificationPage;
  final bool isFrenchInterface;
  final bool useJsonBaremeTranslation;
  final String classNameArabic;
  final String matiereName;
  final Map<String, dynamic> jsonCriteriaData;
  final String profName;
  final String schoolName;

  const StudentsTable({
    Key? key,
    required this.classDocId,
    required this.selectedClass,
    required this.selectedMatiere,
    required this.currentUser,
    required this.sumCriteriaMaxPerBareme,
    required this.totalStudents,
    required this.navigateToClassificationPage,
    required this.isFrenchInterface,
    required this.useJsonBaremeTranslation,
    required this.classNameArabic,
    required this.matiereName,
    required this.jsonCriteriaData,
    required this.profName,
    required this.schoolName,
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
  String? _currentEvaluationSystem;
  bool _isLoadingSystem = true;
  // États pour gérer le loading des boutons
  final Map<String, bool> _classificationLoadingStates = {};
  final Map<String, bool> _treatmentPlanLoadingStates = {};

  // Variables pour le cache des données
  List<QueryDocumentSnapshot>? _cachedStudents;
  List<QueryDocumentSnapshot>? _cachedSelections;
  bool _isMounted = false;

  // NOUVEAU: Variable pour stocker le système d'évaluation

  // Couleurs modernes pour l'UI
  final Color _primaryColor = const Color(0xFF2E7D32);
  final Color _secondaryColor = const Color(0xFF4CAF50);
  final Color _accentColor = const Color(0xFF8BC34A);
  final Color _backgroundColor = const Color(0xFFF5F5F5);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF333333);
  final Color _borderColor = const Color(0xFFE0E0E0);

  // MODIFICATION : Méthode de traduction
  String _getTranslatedText(String arabicText, String frenchText) {
    return widget.isFrenchInterface ? frenchText : arabicText;
  }

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

// Normalisation du texte arabe pour le tri
  String _normalizeArabicForSort(String text) {
    // Supprimer les diacritiques
    String normalized = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

    // Normaliser les formes de lettres
    final Map<String, String> normalizationMap = {
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ؤ': 'و',
      'ئ': 'ي',
      'ة': 'ه',
      'ى': 'ي',
      'ٱ': 'ا',
      'ٳ': 'ا',
      'ٲ': 'ا',
    };

    normalizationMap.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    return normalized.trim();
  }

// Comparateur pour tri alphabétique arabe
  int _arabicStringComparator(String a, String b) {
    // Normaliser les chaînes
    final normalizedA = _normalizeArabicForSort(a);
    final normalizedB = _normalizeArabicForSort(b);

    // Ordre des lettres arabes
    const arabicAlphabet = 'اأإآبتثجحخدذرزسشصضطظعغفقكلمنهويىةؤئء';

    for (int i = 0; i < math.min(normalizedA.length, normalizedB.length); i++) {
      final charA = normalizedA[i];
      final charB = normalizedB[i];

      final indexA = arabicAlphabet.indexOf(charA);
      final indexB = arabicAlphabet.indexOf(charB);

      if (indexA != -1 && indexB != -1 && indexA != indexB) {
        return indexA - indexB;
      }

      // Comparaison Unicode comme fallback
      if (charA != charB) {
        return charA.codeUnitAt(0) - charB.codeUnitAt(0);
      }
    }

    return normalizedA.length - normalizedB.length;
  }

//   // Fonction pour trier les barèmes par ordre alphabétique
// List<Map<String, dynamic>> _sortBaremesAlphabetically(List<Map<String, dynamic>> baremes) {
//   // Créer une copie de la liste pour ne pas modifier l'originale
//   List<Map<String, dynamic>> sortedBaremes = List.from(baremes);

//   sortedBaremes.sort((a, b) {
//     // Récupérer les noms à comparer
//     String nameA = a['value']?.toString() ?? '';
//     String nameB = b['value']?.toString() ?? '';

//     // Si l'interface est en arabe, utiliser le comparateur arabe
//     if (!_isFrenchInterface && nameA.contains(RegExp(r'[\u0600-\u06FF]'))) {
//       return _arabicStringComparator(nameA, nameB);
//     }

//     // Sinon, tri alphabétique standard
//     return nameA.compareTo(nameB);
//   });

//   return sortedBaremes;
// }
// Méthode pour trier les étudiants par ordre alphabétique
  List<QueryDocumentSnapshot> _sortStudentsAlphabetically(
      List<QueryDocumentSnapshot> students) {
    List<QueryDocumentSnapshot> sortedStudents = List.from(students);

    sortedStudents.sort((a, b) {
      String nameA = a['name'] ?? '';
      String nameB = b['name'] ?? '';

      // Pour le tri en arabe
      if (!widget.isFrenchInterface &&
          nameA.contains(RegExp(r'[\u0600-\u06FF]'))) {
        return _arabicStringComparator(nameA, nameB);
      }

      // Pour le tri en français
      return nameA.compareTo(nameB);
    });

    return sortedStudents;
  }

  // Fonction modifiée pour grouper les barèmes triés
  // CORRECTION : Méthode groupBaremes sécurisée
  Map<String, List<Map<String, dynamic>>> groupBaremes(
      List<Map<String, dynamic>> baremesValues) {
    // print('🔍 Début groupBaremes - ${baremesValues.length} éléments');

    // Grouper par barème principal (regrouper sous-barèmes avec leur parent)
    Map<String, List<Map<String, dynamic>>> groupedBaremes = {};

    // D'abord, trouver tous les barèmes principaux
    final mainBaremes =
        baremesValues.where((b) => b['type'] == 'bareme').toList();

    for (final bareme in mainBaremes) {
      final baremeId = bareme['id'];
      final baremeValue = bareme['value'] ?? '';

      // Créer une entrée pour ce barème principal
      if (!groupedBaremes.containsKey(baremeId)) {
        groupedBaremes[baremeId] = [];
      }

      // Ajouter le barème principal
      groupedBaremes[baremeId]!.add(bareme);

      // Ajouter ses sous-barèmes
      final sousBaremes = bareme['sousBaremes'] as List<dynamic>? ?? [];
      for (final sousBareme in sousBaremes) {
        groupedBaremes[baremeId]!.add({
          'id': sousBareme['id'],
          'value': sousBareme['value'],
          'originalValue': sousBareme['originalValue'],
          'type': 'sousBareme',
          'parentBaremeId': baremeId,
        });
      }
    }

    // Maintenant, traiter les sous-barèmes qui n'ont pas de parent dans la liste
    final orphanSousBaremes = baremesValues
        .where((b) =>
            b['type'] == 'sousBareme' &&
            !groupedBaremes.containsKey(b['parentBaremeId']))
        .toList();

    if (orphanSousBaremes.isNotEmpty) {
      groupedBaremes['orphans'] = orphanSousBaremes;
    }

    // print('📊 Groupes créés: ${groupedBaremes.length}');
    // for (var entry in groupedBaremes.entries) {
    //   print('   Groupe ${entry.key}: ${entry.value.length} éléments');
    // }

    return groupedBaremes;
  }

  // Fonction pour déterminer si c'est un barème principal ou sous-barème
  String _getBaremeDisplayName(
      Map<String, dynamic> bareme, Map<String, dynamic> subEntry) {
    String type = subEntry['type'] ?? 'bareme';

    if (type == 'sousBareme') {
      // Pour les sous-barèmes, afficher seulement le nom du sous-barème
      return subEntry['value'];
    } else {
      // Pour les barèmes principaux
      return bareme['value'];
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

  // NOUVELLE MÉTHODE: Charger le système d'évaluation

  // NOUVELLE MÉTHODE: Déterminer si on doit afficher la colonne de somme
  Future<bool> _shouldDisplaySumColumn() async {
    // Attendre que le système soit chargé
    if (_currentEvaluationSystem == null) {
      await _loadEvaluationSystem();
      if (_currentEvaluationSystem == null) {
        return false;
      }
    }

// print('🔍 Vérification affichage colonne somme pour système: $_currentEvaluationSystem');

    // Systèmes qui utilisent des notes numériques
    final numericSystems = ['note_0_1_5', 'note_0_3', 'note_0_6', 'custom'];

    // Vérifier si c'est un système numérique
    if (numericSystems.contains(_currentEvaluationSystem)) {
      // Pour le système custom, vérifier si les notes sont numériques
      if (_currentEvaluationSystem == 'custom') {
        final hasNumericNotes = await _isCustomSystemWithNumericNotes();
        // print('📊 Système custom - Notes numériques: $hasNumericNotes');
        return hasNumericNotes;
      }
      // Pour les autres systèmes numériques, toujours afficher
      // print('✅ Système numérique - Afficher colonne somme');
      return true;
    }

    // Systèmes basés sur des caractères (pas de colonne somme)
    final characterSystems = ['character', 'ext'];
    if (characterSystems.contains(_currentEvaluationSystem)) {
      // print('❌ Système basé sur caractères - Cacher colonne somme');
      return false;
    }

    // Par défaut, ne pas afficher
// print('⚠️ Système non reconnu - Cacher colonne somme par défaut');
    return false;
  }

  // NOUVELLE MÉTHODE: Méthode corrigée pour déterminer si c'est un système character

  bool _isCharacterSystem() {
    // Systèmes qui utilisent des caractères plutôt que des notes
    final characterSystems = ['character', 'ext'];

    // Si le système est null, essayer de le charger
    if (_currentEvaluationSystem == null) {
      return true; // Par défaut, traiter comme character
    }

    return characterSystems.contains(_currentEvaluationSystem);
  }

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _loadStudentsOnce();
    _loadSelectionsOnce();
    _loadEvaluationSystem().then((_) {
      // Rafraîchir après avoir chargé le système
      if (_isMounted) {
        setState(() {
          _isLoadingSystem = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _loadEvaluationSystem() async {
    try {
      final system = await _getEvaluationSystem(
          widget.selectedClass, widget.selectedMatiere);
      if (_isMounted) {
        setState(() {
          _currentEvaluationSystem = system;
        });
        // print('✅ _StudentsTableState - Système chargé: $system');
      }
    } catch (e) {
      // print('❌ Erreur chargement système dans _StudentsTableState: $e');
      if (_isMounted) {
        setState(() {
          _currentEvaluationSystem = 'character';
        });
      }
    }
  }

  Future<void> _checkCustomNotesType() async {
    try {
      if (_currentEvaluationSystem == 'custom') {
        final hasNumericNotes = await _isCustomSystemWithNumericNotes();
// print('🔍 Type de notes custom: ${hasNumericNotes ? 'Numériques' : 'Textuelles'}');

        // Log toutes les notes custom pour debug
        final customNotes = await _loadCustomNotes(
            widget.selectedClass, widget.selectedMatiere);
// print('📝 Notes custom disponibles: $customNotes');

        // Vérifier chaque note
        for (final note in customNotes) {
          final numValue = double.tryParse(note.trim());
          // print('   - "$note" -> numérique: ${numValue != null}');
        }
      }
    } catch (e) {
      // print('❌ Erreur vérification type notes: $e');
    }
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
        // Trier les étudiants par ordre alphabétique
        List<QueryDocumentSnapshot> sortedDocs = snapshot.docs.toList();
        sortedDocs.sort((a, b) {
          String nameA = a['name'] ?? '';
          String nameB = b['name'] ?? '';

          if (!widget.isFrenchInterface &&
              nameA.contains(RegExp(r'[\u0600-\u06FF]'))) {
            return _arabicStringComparator(nameA, nameB);
          }

          return nameA.compareTo(nameB);
        });

        setState(() {
          _cachedStudents = sortedDocs;
        });
      }
    } catch (e) {
      // print('Erreur chargement étudiants: $e');
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
      // print('Erreur chargement sélections: $e');
    }
  }

  // Méthode pour rafraîchir les données manuellement
  Future<void> _refreshData() async {
    await _loadStudentsOnce();
    await _loadSelectionsOnce();
    await _loadEvaluationSystem(); // Recharger aussi le système d'évaluation
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
          SizedBox(height: 8),
          _buildTopActionButtons(),
          SizedBox(height: 8),
          Expanded(
            child: _buildContentWithCachedData(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopActionButtons() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getTranslatedText('دليل الأزرار:', 'Legend:'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem(
                Colors.green,
                _getTranslatedText('تصنيف', 'Classification'),
                _getTranslatedText('تصنيف التلاميذ حسب المستوى',
                    'Classer les élèves par niveau'),
              ),
              SizedBox(width: 24),
              _buildLegendItem(
                Colors.blue,
                _getTranslatedText('تشخيص', 'Traitement'),
                _getTranslatedText('خطة علاجية للتلاميذ',
                    'Plan de traitement pour les élèves'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String title, String description) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
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

  Widget _buildHeader() {
    return FutureBuilder<Map<String, String>>(
      future: _getClassAndMatiereNames(),
      builder: (context, snapshot) {
        String className = widget.isFrenchInterface ? 'Inconnu' : 'غير معروف';
        String matiereName = widget.isFrenchInterface ? 'Inconnu' : 'غير معروف';

        if (snapshot.connectionState == ConnectionState.waiting) {
          className =
              widget.isFrenchInterface ? 'Chargement...' : 'جاري التحميل...';
          matiereName =
              widget.isFrenchInterface ? 'Chargement...' : 'جاري التحميل...';
        } else if (snapshot.hasData) {
          className = snapshot.data!['className'] ??
              (widget.isFrenchInterface ? 'Inconnu' : 'غير معروف');
          matiereName = snapshot.data!['matiereName'] ??
              (widget.isFrenchInterface ? 'Inconnu' : 'غير معروف');
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
                  tooltip: _getTranslatedText(
                      'تحديث البيانات', 'Rafraîchir les données'),
                ),
                SizedBox(width: 12),
                Icon(Icons.school, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTranslatedText(
                            'جدول التقييم', 'Tableau d\'évaluation'),
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
                    '${widget.totalStudents} ' +
                        _getTranslatedText('تلميذ', 'élèves'),
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

      // Traduire si l'interface est en français
      if (widget.isFrenchInterface) {
        className = DataTranslator.translateClass(className);
        matiereName = DataTranslator.translateMatiere(matiereName);
      }

      return {
        'className': className,
        'matiereName': matiereName,
      };
    } catch (e) {
      return {
        'className': widget.isFrenchInterface ? 'Inconnu' : 'غير معروف',
        'matiereName': widget.isFrenchInterface ? 'Inconnu' : 'غير معروف',
      };
    }
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
            _getTranslatedText(
                'جاري تحميل البيانات...', 'Chargement des données...'),
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
            textDirection: widget.isFrenchInterface
                ? TextDirection.ltr
                : TextDirection.rtl,
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
            _getTranslatedText(
                'لم يتم العثور على أي تلميذ.', 'Aucun élève trouvé.'),
            textDirection: widget.isFrenchInterface
                ? TextDirection.ltr
                : TextDirection.rtl,
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

    // Trier les étudiants par ordre alphabétique
    List<QueryDocumentSnapshot> sortedStudents =
        _sortStudentsAlphabetically(studentsDocs);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getBaremesValues(_cachedSelections!),
      builder: (context, baremesValuesSnapshot) {
        if (baremesValuesSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }
        if (baremesValuesSnapshot.hasError) {
          return _buildErrorWidget(
              '${_getTranslatedText('خطأ:', 'Erreur:')} ${baremesValuesSnapshot.error}');
        }
        if (!baremesValuesSnapshot.hasData ||
            baremesValuesSnapshot.data!.isEmpty) {
          return _buildEmptyStateForCriteria();
        }
        //   _debugBaremesStructure(baremesValuesSnapshot.data!);

        return _buildDataTable(sortedStudents, baremesValuesSnapshot.data!);
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
            _getTranslatedText(
                'لم يتم العثور على أي معيار.', 'Aucun critère trouvé.'),
            textDirection: widget.isFrenchInterface
                ? TextDirection.ltr
                : TextDirection.rtl,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

// MÉTHODE CORRIGÉE: Mettre à jour le build pour utiliser FutureBuilder

  Widget _buildDataTable(List<QueryDocumentSnapshot> studentsDocs,
      List<Map<String, dynamic>> baremesValues) {
    if (_isLoadingSystem) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(_getTranslatedText('جاري تحميل نظام التقييم...',
                'Chargement du système d\'évaluation...')),
          ],
        ),
      );
    }

    //  _debugBaremesStructure(baremesValues);

    final Map<String, List<Map<String, dynamic>>> groupedBaremes = {};

    final mainBaremes =
        baremesValues.where((b) => b['type'] == 'bareme').toList();
    final sousBaremes =
        baremesValues.where((b) => b['type'] == 'sousBareme').toList();

    for (final bareme in mainBaremes) {
      final baremeId = bareme['id'];
      groupedBaremes[baremeId] = [bareme];

      final sousBaremesOfThisBareme =
          sousBaremes.where((s) => s['parentBaremeId'] == baremeId).toList();

      for (final sousBareme in sousBaremesOfThisBareme) {
        groupedBaremes[baremeId]!.add(sousBareme);
      }
    }

    final orphanSousBaremes = sousBaremes
        .where((s) => !groupedBaremes.containsKey(s['parentBaremeId']))
        .toList();

    if (orphanSousBaremes.isNotEmpty) {
      groupedBaremes['orphans'] = orphanSousBaremes;
    }

    return FutureBuilder<bool>(
      future: _shouldDisplaySumColumn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final bool shouldDisplaySumColumn = snapshot.data ?? false;

        return Card(
          elevation: 4,
          margin: EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  columns: _buildTableColumns(
                      groupedBaremes, shouldDisplaySumColumn),
                  rows: _buildTableRows(
                      studentsDocs, groupedBaremes, shouldDisplaySumColumn),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<DataColumn> _buildTableColumns(
      Map<String, List<Map<String, dynamic>>> groupedBaremes,
      bool shouldDisplaySumColumn) {
    List<DataColumn> columns = [];

    // Colonne Nom
    columns.add(DataColumn(
      label: Container(
        width: 160,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            _getTranslatedText('الاسم واللقب', 'Nom et prénom'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _primaryColor,
              fontSize: 14,
            ),
          ),
        ),
      ),
    ));

    // Colonne Somme (conditionnelle)
    if (shouldDisplaySumColumn) {
      columns.add(DataColumn(
        label: Container(
          width: 100,
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              _getTranslatedText('المجموع', 'Total'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ));
    }

    // Colonnes Barèmes
    for (var entry in groupedBaremes.entries) {
      for (final bareme in entry.value) {
        columns.add(DataColumn(
          label: _buildColumnHeader(
            bareme['value'],
            entry.key,
            originalValue: bareme['originalValue'],
          ),
        ));
      }
    }

    return columns;
  }

// Mettre à jour la méthode pour construire les lignes avec shouldDisplaySumColumn
  List<DataRow> _buildTableRows(
      List<QueryDocumentSnapshot> studentsDocs,
      Map<String, List<Map<String, dynamic>>> groupedBaremes,
      bool shouldDisplaySumColumn) {
    List<DataRow> rows = [];

    // Lignes étudiants
    rows.addAll(_buildStudentRows(
        studentsDocs, groupedBaremes, shouldDisplaySumColumn));

    // Lignes statistiques
    rows.add(_buildStatsRow(
        _getTranslatedText(
            'عدد التلاميذ المحققين', 'Nombre d\'élèves ayant atteint'),
        groupedBaremes,
        shouldDisplaySumColumn,
        isPercentage: false));

    rows.add(_buildStatsRow(_getTranslatedText('النسبة المئوية', 'Pourcentage'),
        groupedBaremes, shouldDisplaySumColumn,
        isPercentage: true));

    // Lignes boutons
    rows.addAll(_buildButtonRows(groupedBaremes, shouldDisplaySumColumn));

    return rows;
  }

// NOUVELLE MÉTHODE: Construction de l'en-tête de colonne
  Widget _buildColumnHeader(String title, String groupKey,
      {String? originalValue}) {
    return Container(
      width: 110,
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _headerColors.putIfAbsent(groupKey, () => _getRandomColor()),
            _headerColors[groupKey]!.withOpacity(0.8),
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
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (originalValue != null) ...[
            SizedBox(height: 2),
            Text(
              originalValue,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.white70,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

// Mettre à jour _buildStudentRows pour inclure shouldDisplaySumColumn

  List<DataRow> _buildStudentRows(
      List<QueryDocumentSnapshot> studentsDocs,
      Map<String, List<Map<String, dynamic>>> groupedBaremes,
      bool shouldDisplaySumColumn) {
    return studentsDocs.asMap().entries.map((entry) {
      final index = entry.key;
      final studentDoc = entry.value;
      final studentId = studentDoc.id;
      final studentName =
          studentDoc['name'] ?? _getTranslatedText('غير معروف', 'Inconnu');

      List<DataCell> cells = [];

      // Cellule Nom
      cells.add(DataCell(_buildStudentNameCell(studentName)));

      // Cellule Somme (conditionnelle)
      if (shouldDisplaySumColumn) {
        cells.add(DataCell(
          FutureBuilder<double>(
            future: _calculateStudentTotal(studentId, groupedBaremes),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildSumCellLoading();
              }

              if (snapshot.hasError) {
// print('❌ Erreur calcul somme pour $studentId: ${snapshot.error}');
                return _buildSumCellError();
              }

              final total = snapshot.data ?? 0.0;

              // Vérifier si le système est custom avec des notes non numériques
              if (_currentEvaluationSystem == 'custom') {
                return FutureBuilder<bool>(
                  future: _isCustomSystemWithNumericNotes(),
                  builder: (context, numericSnapshot) {
                    if (numericSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return _buildSumCellLoading();
                    }

                    if (numericSnapshot.hasError ||
                        !(numericSnapshot.data ?? false)) {
                      // Système custom sans notes numériques
                      return _buildSumCellNotAvailable();
                    }

                    // Système custom avec notes numériques
                    return _buildSumCellValue(total);
                  },
                );
              }

              // Pour les autres systèmes numériques
              return _buildSumCellValue(total);
            },
          ),
        ));
      }

      // Cellules Barèmes
      cells.addAll(_buildStudentCells(studentId, groupedBaremes));

      return DataRow(
        color: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            return index.isEven
                ? _backgroundColor.withOpacity(0.3)
                : Colors.transparent;
          },
        ),
        cells: cells,
      );
    }).toList();
  }

  Widget _buildSumCellLoading() {
    return Container(
      width: 100,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
        ),
      ),
    );
  }

// MÉTHODE AUXILIAIRE: Cellule d'erreur de la somme
  Widget _buildSumCellError() {
    return Container(
      width: 100,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Icon(
            Icons.error_outline,
            size: 14,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

// MÉTHODE AUXILIAIRE: Cellule somme non disponible (pour custom textuel)
  Widget _buildSumCellNotAvailable() {
    return Container(
      width: 100,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            _getTranslatedText('N/A', 'N/A'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

// MÉTHODE AUXILIAIRE: Cellule avec valeur de la somme
  Widget _buildSumCellValue(double total) {
    // Formater le total selon le système
    String formattedTotal;
    if (_currentEvaluationSystem == 'custom') {
      // Pour custom, afficher tel quel
      formattedTotal = total.toStringAsFixed(2);
    } else if (_currentEvaluationSystem == 'note_0_1_5') {
      // Format pour 0-1.5
      formattedTotal = total.toStringAsFixed(2);
    } else if (_currentEvaluationSystem == 'note_0_3') {
      // Format pour 0-3
      formattedTotal = total.toStringAsFixed(1);
    } else if (_currentEvaluationSystem == 'note_0_6') {
      // Format pour 0-6
      formattedTotal = total.toStringAsFixed(1);
    } else {
      // Format par défaut
      formattedTotal = total.toStringAsFixed(1);
    }

    // Déterminer la couleur selon la valeur
    Color textColor;
    Color backgroundColor;

    // Adapter les seuils selon le système
    if (total == 0) {
      textColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.1);
    } else if (_currentEvaluationSystem == 'note_0_1_5' && total < 0.75) {
      textColor = Colors.orange;
      backgroundColor = Colors.orange.withOpacity(0.1);
    } else if (_currentEvaluationSystem == 'note_0_3' && total < 1.5) {
      textColor = Colors.orange;
      backgroundColor = Colors.orange.withOpacity(0.1);
    } else if (_currentEvaluationSystem == 'note_0_6' && total < 3) {
      textColor = Colors.orange;
      backgroundColor = Colors.orange.withOpacity(0.1);
    } else {
      textColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
    }

    return Container(
      width: 100,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: textColor.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            formattedTotal,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

// MÉTHODE AUXILIAIRE: Construction des cellules de barèmes pour un étudiant
  List<DataCell> _buildStudentCells(String studentId,
      Map<String, List<Map<String, dynamic>>> groupedBaremes) {
    List<DataCell> cells = [];

    for (var entry in groupedBaremes.entries) {
      for (final bareme in entry.value) {
        if (bareme['type'] == 'bareme') {
          // Barème principal
          cells.add(DataCell(_buildMarkCell(studentId, bareme['id'])));

          // Sous-barèmes
          for (final sousBareme
              in (bareme['sousBaremes'] as List<dynamic>? ?? [])) {
            cells.add(DataCell(_buildMarkCell(studentId, sousBareme['id'])));
          }
        } else {
          // Sous-barème seul
          cells.add(DataCell(_buildMarkCell(studentId, bareme['id'])));
        }
      }
    }

    return cells;
  }

// MÉTHODE AUXILIAIRE: Cellule de note individuelle
  Widget _buildMarkCell(String studentId, String baremeKey) {
    return Container(
      width: 110,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: FutureBuilder<String>(
        future: _getSelectedValue(studentId, baremeKey),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            );
          }

          if (snapshot.hasError) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Center(
                child: Icon(
                  Icons.error_outline,
                  size: 12,
                  color: Colors.red,
                ),
              ),
            );
          }

          final value = snapshot.data ?? _dropdownValues[0];

          // Vérifier si c'est "غائب"
          final isAbsent = value == 'غائب';

          return FutureBuilder<List<String>>(
            future: _getDropdownValuesForBareme(baremeKey),
            builder: (context, dropdownSnapshot) {
              if (dropdownSnapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAbsent
                        ? Colors.grey.withOpacity(0.2)
                        : _getValueColor(value).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isAbsent
                          ? Colors.grey
                          : _getValueColor(value).withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: isAbsent ? Colors.grey : _getValueColor(value),
                        fontWeight: FontWeight.bold,
                        fontSize: isAbsent ? 10 : 12,
                      ),
                    ),
                  ),
                );
              }

              final dropdownValues = dropdownSnapshot.data ?? _dropdownValues;

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isAbsent
                      ? Colors.grey.withOpacity(0.2)
                      : _getValueColor(value).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isAbsent
                        ? Colors.grey
                        : _getValueColor(value).withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isAbsent ? Colors.grey : _getValueColor(value),
                      fontWeight: FontWeight.bold,
                      fontSize: isAbsent ? 10 : 12,
                      fontStyle: isAbsent ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

// MÉTHODE AUXILIAIRE: Déterminer la couleur selon la valeur
  Color _getValueColor(String value) {
    // Si c'est "غائب"
    if (value == 'غائب') {
      return Colors.grey;
    }

    // Pour les systèmes standard
    switch (value) {
      case '( + + + )':
      case '1.5': // note_0_1_5 max
      case '3': // note_0_3 max
      case '6': // note_0_6 max
        return Colors.green;

      case '( + + - )':
      case '1': // note_0_1_5
      case '2': // note_0_3
      case '4': // note_0_6
        return Colors.orange;

      case '( + - - )':
      case '0.5': // note_0_1_5
      case '1': // note_0_3
      case '2': // note_0_6
        return Colors.orangeAccent;

      case '( - - - )':
      case '0': // toutes les notes min
        return Colors.red;

      default:
        // Pour les notes personnalisées, essayer de déterminer si c'est numérique
        final numValue = double.tryParse(value);
        if (numValue != null) {
          // Note numérique dans custom
          if (numValue >= 3) return Colors.green;
          if (numValue >= 2) return Colors.orange;
          if (numValue >= 1) return Colors.orangeAccent;
          return Colors.red;
        }

        // Note textuelle dans custom - utiliser une couleur neutre
        return Colors.blue;
    }
  }

// MÉTHODE AUXILIAIRE: Cellule nom étudiant
  Widget _buildStudentNameCell(String studentName) {
    return Container(
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
              textDirection: widget.isFrenchInterface
                  ? TextDirection.ltr
                  : TextDirection.rtl,
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
// NOUVELLE MÉTHODE: Cellule nom étudiant

  bool _isCharacterBasedSystem() {
    if (_currentEvaluationSystem == null) return true;

    final characterBasedSystems = [
      'character',
      'ext',
    ];

    // Le système custom est basé sur caractères s'il n'a pas de notes numériques
    if (_currentEvaluationSystem == 'custom') {
      return true; // Par défaut, considérer comme basé sur caractères
    }

    return characterBasedSystems.contains(_currentEvaluationSystem);
  }

// NOUVELLE MÉTHODE: Cellules des barèmes pour un étudiant

// NOUVELLE MÉTHODE: Lignes de boutons
  List<DataRow> _buildButtonRows(
      Map<String, List<Map<String, dynamic>>> groupedBaremes,
      bool shouldDisplaySumColumn) {
    return [
      _buildButtonRow(
        _getTranslatedText('تصنيف', 'Classer'),
        Colors.green,
        Colors.yellow,
        groupedBaremes,
        shouldDisplaySumColumn,
        isClassification: true,
      ),
      _buildButtonRow(
        _getTranslatedText('تشخيص ', 'Plan de traitement'),
        Colors.blue,
        Colors.white,
        groupedBaremes,
        shouldDisplaySumColumn,
        isClassification: false,
      ),
    ];
  }

  DataRow _buildStatsRow(
      String title,
      Map<String, List<Map<String, dynamic>>> groupedBaremes,
      bool shouldDisplaySumColumn,
      {required bool isPercentage}) {
    List<DataCell> cells = [];

    // Cellule titre
    cells.add(DataCell(
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
    ));

    // Cellule vide pour la colonne de somme si elle existe
    if (shouldDisplaySumColumn) {
      cells.add(DataCell(Container(width: 100)));
    }

    // Cellules statistiques
    cells.addAll(_buildStatCells(groupedBaremes, isPercentage));

    return DataRow(
      color: MaterialStateProperty.all(_primaryColor.withOpacity(0.05)),
      cells: cells,
    );
  }

  DataRow _buildButtonRow(
      String buttonText,
      Color backgroundColor,
      Color textColor,
      Map<String, List<Map<String, dynamic>>> groupedBaremes,
      bool shouldDisplaySumColumn,
      {required bool isClassification}) {
    List<DataCell> cells = [];

    // Première cellule vide
    cells.add(DataCell(Container()));

    // Cellule vide pour la colonne de somme si elle existe
    if (shouldDisplaySumColumn) {
      cells.add(DataCell(Container(width: 100)));
    }

    // Cellules boutons
    cells.addAll(_buildButtonCells(
        buttonText, backgroundColor, textColor, groupedBaremes,
        isClassification: isClassification));

    return DataRow(
      cells: cells,
    );
  }

  List<DataCell> _buildStatCells(
      Map<String, List<Map<String, dynamic>>> groupedBaremes,
      bool isPercentage) {
    List<DataCell> cells = [];

    for (var entry in groupedBaremes.entries) {
      for (final bareme in entry.value) {
        if (bareme['type'] == 'bareme') {
          // Barème principal avec ses sous-barèmes
          for (final subEntry in [
            {'id': bareme['id'], 'type': 'bareme'},
            ...(bareme['sousBaremes'] as List<dynamic>? ?? [])
          ]) {
            cells.add(DataCell(
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
                    child: _buildStatValue(subEntry['id'], isPercentage),
                  ),
                ),
              ),
            ));
          }
        } else {
          // Sous-barème seul
          cells.add(DataCell(
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
                  child: _buildStatValue(bareme['id'], isPercentage),
                ),
              ),
            ),
          ));
        }
      }
    }

    return cells;
  }

  List<DataCell> _buildButtonCells(String buttonText, Color backgroundColor,
      Color textColor, Map<String, List<Map<String, dynamic>>> groupedBaremes,
      {required bool isClassification}) {
    List<DataCell> cells = [];

    for (var entry in groupedBaremes.entries) {
      for (final bareme in entry.value) {
        for (final subEntry in [
          {'id': bareme['id'], 'type': 'bareme', 'name': bareme['value']},
          ...(bareme['sousBaremes'] as List<dynamic>? ?? []).map(
              (s) => {'id': s['id'], 'type': 'sousBareme', 'name': s['value']})
        ]) {
          cells.add(DataCell(
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
          ));
        }
      }
    }

    return cells;
  }

  Future<bool> _isCustomSystemWithNumericNotes() async {
    if (_currentEvaluationSystem != 'custom') return false;

    try {
      // 1. Vérifier les notes globales
      final globalCustomNotes =
          await _loadCustomNotes(widget.selectedClass, widget.selectedMatiere);

      if (globalCustomNotes.isNotEmpty) {
        return _areNotesNumeric(globalCustomNotes);
      }

      // 2. Vérifier les notes des barèmes
      final baremesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .get();

      for (final baremeDoc in baremesSnapshot.docs) {
        final baremeId = baremeDoc['baremeId'] ?? baremeDoc.id;
        final customNotes = await _getCustomNotesForBareme(
            widget.selectedClass, widget.selectedMatiere, baremeId);

        if (customNotes.isNotEmpty) {
          return _areNotesNumeric(customNotes);
        }
      }

      // 3. Vérifier les notes des sous-barèmes
      for (final baremeDoc in baremesSnapshot.docs) {
        final baremeId = baremeDoc['baremeId'] ?? baremeDoc.id;
        final sousBaremesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUser.uid)
            .collection('selections')
            .doc(widget.selectedClass)
            .collection(widget.selectedMatiere)
            .doc(baremeId)
            .collection('sousBaremes')
            .get();

        for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
          final sousBaremeId = sousBaremeDoc.id;
          final customNotes = await _getSousBaremeCustomNotes(
            widget.selectedClass,
            widget.selectedMatiere,
            baremeId,
            sousBaremeId,
          );

          if (customNotes.isNotEmpty) {
            return _areNotesNumeric(customNotes);
          }
        }
      }

      return false;
    } catch (e) {
// print('❌ Erreur vérification notes custom: $e');
      return false;
    }
  }

  bool _areNotesNumeric(List<String> notes) {
    for (final note in notes) {
      final trimmedNote = note.trim();
      final numValue = double.tryParse(trimmedNote);
      if (numValue == null) {
// print('⚠️ Note non numérique trouvée: "$trimmedNote"');
        return false;
      }
    }
// print('✅ Toutes les notes sont numériques');
    return true;
  }

// NOUVELLE MÉTHODE: Vérifier les notes personnalisées par barème/sous-barème
  Future<bool> _hasNumericCustomNotesForBareme(String baremeKey) async {
    if (_currentEvaluationSystem != 'custom') return false;

    try {
      List<String> customNotes = [];

      if (await _isSousBareme(baremeKey)) {
        // Sous-barème
        final parentInfo = await _getParentBaremeInfo(baremeKey);
        final baremeId = parentInfo['parentBaremeId']!;
        final sousBaremeId = baremeKey;

        customNotes = await _getSousBaremeCustomNotes(
          widget.selectedClass,
          widget.selectedMatiere,
          baremeId,
          sousBaremeId,
        );
      } else {
        // Barème principal
        customNotes = await _getCustomNotesForBareme(
          widget.selectedClass,
          widget.selectedMatiere,
          baremeKey,
        );
      }

      // Si pas de notes personnalisées spécifiques, utiliser les notes globales
      if (customNotes.isEmpty) {
        customNotes = await _loadCustomNotes(
            widget.selectedClass, widget.selectedMatiere);
      }

      // Vérifier si toutes les notes sont numériques
      if (customNotes.isEmpty) return false;

      for (final note in customNotes) {
        final trimmedNote = note.trim();
        final numValue = double.tryParse(trimmedNote);
        if (numValue == null) {
// print('⚠️ Note non numérique pour barème $baremeKey: "$trimmedNote"');
          return false;
        }
      }

      return true;
    } catch (e) {
// print('❌ Erreur vérification notes numériques barème: $e');
      return false;
    }
  }

// CORRECTION : Méthode améliorée pour afficher les statistiques
  Widget _buildStatValue(String baremeKey, bool isPercentage) {
    // DEBUG: Afficher la clé recherchée
    // print('🔍 Recherche statistique pour: $baremeKey');

    // Rechercher la valeur dans sumCriteriaMaxPerBareme
    int? count = widget.sumCriteriaMaxPerBareme[baremeKey];

    // Si non trouvé, essayer de chercher avec différentes variations de la clé
    if (count == null) {
      // Essayer de trouver la clé dans les statistiques disponibles
      for (var key in widget.sumCriteriaMaxPerBareme.keys) {
        if (key.contains(baremeKey) || baremeKey.contains(key)) {
          count = widget.sumCriteriaMaxPerBareme[key];
// print('🔄 Clé trouvée avec variation: $key -> $count');
          break;
        }
      }
    }

    // Si toujours null, utiliser 0
    count ??= 0;

// print('📊 Statistique finale - Clé: $baremeKey, Valeur: $count, Pourcentage: $isPercentage');

    if (isPercentage) {
      if (widget.totalStudents == 0) {
        return Text(
          _getTranslatedText('لا توجد درجات', 'Pas de notes'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _secondaryColor,
            fontSize: 12,
          ),
        );
      } else {
        final percentage = (count / widget.totalStudents * 100);
        return Text(
          '${percentage.toStringAsFixed(2)}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _secondaryColor,
            fontSize: 12,
          ),
        );
      }
    } else {
      return Text(
        count.toString(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _accentColor,
          fontSize: 12,
        ),
      );
    }
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
// print('Erreur: $e');
                if (_isMounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${_getTranslatedText('حدث خطأ:', 'Erreur:')} $e'),
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

    // print('🔍 Début _getBaremesValues - ${selectedBaremes.length} barèmes');

    for (final baremeDoc in selectedBaremes) {
      final baremeId = baremeDoc['baremeId'] ?? baremeDoc.id;
      final baremeName = baremeDoc['baremeName'] ?? 'غير معروف';
      final isBaremeSelected = baremeDoc['selected'] ?? false;

      String displayedBaremeName = baremeName;
      String? originalBaremeValue;
      print(
          'TABLEAU BAREme: useJsonTranslation=${widget.useJsonBaremeTranslation}, baremeName="$baremeName"');
      if (widget.useJsonBaremeTranslation &&
          widget.classNameArabic.isNotEmpty &&
          widget.matiereName.isNotEmpty) {
        final translated = getTranslatedBaremeNameFromJson(
            baremeName,
            widget.classNameArabic,
            widget.matiereName,
            widget.jsonCriteriaData);
        if (translated != baremeName) {
          displayedBaremeName = translated;
          originalBaremeValue = baremeName;
        }
      } else if (widget.isFrenchInterface) {
        final translated = DataTranslator.translateBareme(baremeName);
        if (translated != baremeName) {
          displayedBaremeName = translated;
          originalBaremeValue = baremeName;
        }
      }

      // Récupérer les sous-barèmes
      final sousBaremesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .doc(baremeId)
          .collection('sousBaremes')
          .get();

      final List<Map<String, dynamic>> sousBaremesList = [];

      for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
        final isSousBaremeSelected = sousBaremeDoc['selected'] ?? false;
        final sousBaremeName = sousBaremeDoc['sousBaremeName'] ?? 'غير معروف';

        if (isSousBaremeSelected) {
          String displayedSousBaremeName = sousBaremeName;
          bool wasTranslated = false;
          if (widget.useJsonBaremeTranslation &&
              widget.classNameArabic.isNotEmpty &&
              widget.matiereName.isNotEmpty) {
            final translated = getTranslatedSousBaremeNameFromJson(
                sousBaremeName,
                widget.classNameArabic,
                widget.matiereName,
                widget.jsonCriteriaData);
            if (translated != sousBaremeName) {
              displayedSousBaremeName = translated;
              wasTranslated = true;
            }
          } else if (widget.isFrenchInterface) {
            final translated =
                DataTranslator.translateSousBareme(sousBaremeName);
            if (translated != sousBaremeName) {
              displayedSousBaremeName = translated;
              wasTranslated = true;
            }
          }

          sousBaremesList.add({
            'id': sousBaremeDoc.id,
            'value': displayedSousBaremeName,
            'originalValue': wasTranslated ? sousBaremeName : null,
            'type': 'sousBareme',
          });
        }
      }

      // ✅ TRIER les sous-barèmes par ordre alphabétique
      sousBaremesList.sort((a, b) {
        String nameA = a['value'] ?? '';
        String nameB = b['value'] ?? '';

        if (!widget.isFrenchInterface &&
            nameA.contains(RegExp(r'[\u0600-\u06FF]'))) {
          return _arabicStringComparator(nameA, nameB);
        }
        return nameA.compareTo(nameB);
      });

      if (isBaremeSelected) {
        result.add({
          'id': baremeId,
          'value': displayedBaremeName,
          'originalValue': originalBaremeValue,
          'type': 'bareme',
          'sousBaremes': sousBaremesList,
        });
      } else if (sousBaremesList.isNotEmpty) {
        for (final sousBareme in sousBaremesList) {
          result.add({
            'id': sousBareme['id'],
            'value': sousBareme['value'],
            'type': 'sousBareme',
            'parentBaremeId': baremeId,
          });
        }
      }
    }

    // ✅ TRIER les barèmes principaux par ordre alphabétique
    result.sort((a, b) {
      if (a['type'] != b['type']) {
        if (a['type'] == 'bareme') return -1;
        if (b['type'] == 'bareme') return 1;
      }

      String nameA = a['value'] ?? '';
      String nameB = b['value'] ?? '';

      if (!widget.isFrenchInterface &&
          nameA.contains(RegExp(r'[\u0600-\u06FF]'))) {
        return _arabicStringComparator(nameA, nameB);
      }
      return nameA.compareTo(nameB);
    });

    return result;
  }

  Future<String> _getSelectedValue(String studentId, String baremeKey) async {
    try {
      // S'assurer que le système est chargé
      if (_currentEvaluationSystem == null) {
        await _loadEvaluationSystem();
      }

      final String evaluationSystem = _currentEvaluationSystem ?? 'character';
      String storedValue = _dropdownValues[0];
      List<String> customNotes = [];

      final isSousBareme = await _isSousBareme(baremeKey);

      if (isSousBareme) {
        // print('🔍 SOUS-BARÈME détecté: $baremeKey');

        final parentInfo = await _getParentBaremeInfo(baremeKey);
        final baremeId = parentInfo['parentBaremeId'];
        final sousBaremeId = baremeKey;

        var sousBaremeDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUser.uid)
            .collection('user_classes')
            .doc(widget.classDocId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .doc(baremeId)
            .collection('sous_baremes')
            .doc(sousBaremeId)
            .get();

        if (sousBaremeDoc.exists) {
          if (sousBaremeDoc.data()?['isAbsent'] == true) {
            return 'غائب';
          }
          storedValue =
              sousBaremeDoc.data()?['Marks']?.toString() ?? '( - - - )';

          customNotes = await _getSousBaremeCustomNotes(
            widget.selectedClass,
            widget.selectedMatiere,
            baremeId!,
            sousBaremeId,
          );
        }
      } else {
        // print('🔍 BARÈME PRINCIPAL détecté: $baremeKey');

        var baremeDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUser.uid)
            .collection('user_classes')
            .doc(widget.classDocId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .doc(baremeKey)
            .get();

        if (baremeDoc.exists) {
          if (baremeDoc.data()?['isAbsent'] == true) {
            return 'غائب';
          }
          storedValue = baremeDoc.data()?['Marks']?.toString() ?? '( - - - )';

          customNotes = await _getCustomNotesForBareme(
              widget.selectedClass, widget.selectedMatiere, baremeKey);
        }
      }

// print('🎯 Conversion: $storedValue -> système: $evaluationSystem, notes: $customNotes');

      final result = _getDisplayEvaluation(
        storedValue,
        evaluationSystem,
        customNotes: customNotes,
      );

      // print('✅ Résultat: $result');
      return result;
    } catch (e) {
      // print('❌ Erreur récupération valeur pour $baremeKey: $e');
      return _dropdownValues[0];
    }
  }

// VERSION CORRIGÉE - Gère tous types de notes personnalisées
  String _getDisplayEvaluation(String storedValue, String system,
      {List<String>? customNotes, String? baremeId, String? sousBaremeId}) {
    // Debug pour voir ce qui se passe
    // print(
    //     '🎯 _getDisplayEvaluation - storedValue: "$storedValue", system: "$system", customNotes: $customNotes');

    // Si c'est "غائب"
    if (storedValue == 'غائب') {
      return 'غائب';
    }

    // SYSTÈME CUSTOM - Utiliser les notes personnalisées
    if (system == 'custom') {
      if (customNotes != null && customNotes.isNotEmpty) {
        // IMPORTANT: S'assurer d'avoir au moins 4 notes
        // Si on a moins de 4 notes, on les répète intelligemment
        List<String> normalizedNotes = List.from(customNotes);

        // Normaliser à 4 notes si nécessaire
        while (normalizedNotes.length < 4) {
          if (normalizedNotes.length == 2) {
            // Pour 2 notes: [bas, haut] -> [bas, bas, haut, haut]
            normalizedNotes = [
              normalizedNotes[0],
              normalizedNotes[0],
              normalizedNotes[1],
              normalizedNotes[1],
            ];
          } else if (normalizedNotes.length == 3) {
            // Pour 3 notes: [bas, moyen, haut] -> [bas, moyen, moyen, haut]
            normalizedNotes = [
              normalizedNotes[0],
              normalizedNotes[1],
              normalizedNotes[1],
              normalizedNotes[2],
            ];
          } else {
            // Si une seule note, la répéter 4 fois
            normalizedNotes = List.filled(4, normalizedNotes[0]);
          }
        }

        // Maintenant on a toujours 4 notes pour le mapping
        final Map<String, String> mapping = {
          '( - - - )': normalizedNotes[0], // La plus basse
          '( + - - )': normalizedNotes[1], // Basse-moyenne
          '( + + - )': normalizedNotes[2], // Haute-moyenne
          '( + + + )': normalizedNotes[3], // La plus haute
        };

        final result = mapping[storedValue] ?? normalizedNotes[0];
        // print(
        //     '✅ Custom mapping: $storedValue -> $result (notes: $normalizedNotes)');
        return result;
      } else {
        // print(
        //     '⚠️ Système custom mais pas de notes personnalisées, fallback sur caractères');
        return storedValue;
      }
    }

    // SYSTÈME CHARACTER
    if (system == 'character') {
      return storedValue;
    }

    // SYSTÈMES NUMÉRIQUES STANDARDS
    switch (system) {
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

  Future<bool> _isSousBareme(String baremeKey) async {
    try {
      // Vérifier si c'est un sous-barème en cherchant dans la collection sous_bareme_custom_notes
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('sous_bareme_custom_notes')
          .where('sousBaremeId', isEqualTo: baremeKey)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
// print('✅ $baremeKey est un sous-barème');
        return true;
      }

      // Vérifier aussi dans les sélections
      final selectionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .get();

      for (final baremeDoc in selectionsSnapshot.docs) {
        final baremeId = baremeDoc['baremeId'];
        final sousBaremesSnapshot =
            await baremeDoc.reference.collection('sousBaremes').get();

        for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
          if (sousBaremeDoc.id == baremeKey) {
// print('✅ $baremeKey est un sous-barème de $baremeId');
            return true;
          }
        }
      }

// print('❌ $baremeKey n\'est pas un sous-barème');
      return false;
    } catch (e) {
// print('❌ Erreur vérification sous-barème: $e');
      return false;
    }
  }

  Future<Map<String, String>> _getParentBaremeInfo(String sousBaremeId) async {
    try {
      // Chercher dans sous_bareme_custom_notes
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('sous_bareme_custom_notes')
          .where('sousBaremeId', isEqualTo: sousBaremeId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        return {
          'parentBaremeId': data['parentBaremeId'] ?? '',
          'parentClassId': data['parentClassId'] ?? widget.selectedClass,
          'parentMatiereId': data['parentMatiereId'] ?? widget.selectedMatiere,
        };
      }

      // Chercher dans les sélections
      final selectionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('selections')
          .doc(widget.selectedClass)
          .collection(widget.selectedMatiere)
          .get();

      for (final baremeDoc in selectionsSnapshot.docs) {
        final baremeId = baremeDoc['baremeId'];
        final sousBaremesSnapshot =
            await baremeDoc.reference.collection('sousBaremes').get();

        for (final sousBaremeDoc in sousBaremesSnapshot.docs) {
          if (sousBaremeDoc.id == sousBaremeId) {
            return {
              'parentBaremeId': baremeId,
              'parentClassId': widget.selectedClass,
              'parentMatiereId': widget.selectedMatiere,
            };
          }
        }
      }

      return {
        'parentBaremeId': '',
        'parentClassId': widget.selectedClass,
        'parentMatiereId': widget.selectedMatiere,
      };
    } catch (e) {
// print('❌ Erreur récupération parent bareme: $e');
      return {
        'parentBaremeId': '',
        'parentClassId': widget.selectedClass,
        'parentMatiereId': widget.selectedMatiere,
      };
    }
  }

  Future<List<String>> _getCustomNotesForBareme(
      String classId, String matiereId, String baremeId) async {
    try {
// print('🔍 CHERCHE NOTES pour barème: $baremeId');

      // D'abord vérifier si c'est un sous-barème
      final isSousBareme = await _isSousBareme(baremeId);

      if (isSousBareme) {
// print('⚠️ $baremeId est un sous-barème, utiliser _getSousBaremeCustomNotes');
        final parentInfo = await _getParentBaremeInfo(baremeId);
        final parentBaremeId = parentInfo['parentBaremeId'] ?? '';

        return await _getSousBaremeCustomNotes(
          classId,
          matiereId,
          parentBaremeId,
          baremeId,
        );
      }

      // C'est un barème principal - continuer avec la logique normale
// print('📌 C\'est un barème principal');

      // 1. Chercher d'abord les notes GLOBALES (sans baremeId)
      final globalDocId = '$classId-$matiereId';
// print('   📍 Chercher notes globales: $globalDocId');

      final globalDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('bareme_custom_notes')
          .doc(globalDocId)
          .get();

      if (globalDoc.exists) {
        final notes = globalDoc.data()?['notes'];
        if (notes != null && notes is List && notes.isNotEmpty) {
          final result = List<String>.from(notes);
// print('✅ Notes globales trouvées: $result');
          return result;
        }
      }

      // 2. Chercher les notes spécifiques au barème
      final specificDocId = '$classId-$matiereId-$baremeId';
// print('   📍 Chercher notes spécifiques: $specificDocId');

      final specificDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('bareme_custom_notes')
          .doc(specificDocId)
          .get();

      if (specificDoc.exists) {
        final notes = specificDoc.data()?['notes'];
        if (notes != null && notes is List && notes.isNotEmpty) {
          final result = List<String>.from(notes);
// print('✅ Notes spécifiques trouvées: $result');
          return result;
        }
      }

      // 3. Voir TOUS les documents pour debug
// print('🔍 Voir tous les documents bareme_custom_notes...');
      final allDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('bareme_custom_notes')
          .get();

// print('📋 Total documents: ${allDocs.docs.length}');
      for (final doc in allDocs.docs) {
// print('   📄 ${doc.id}');
        final data = doc.data();
        if (data['notes'] != null) {
// print('     📝 Notes: ${data['notes']}');
        }
      }

// print('⚠️ Aucune note personnalisée trouvée');
      return [];
    } catch (e) {
// print('❌ Erreur chargement notes: $e');
      return [];
    }
  }

  Future<bool> _sousBaremeHasCustomNotes(
    String classId,
    String matiereId,
    String baremeId,
    String sousBaremeId,
  ) async {
    try {
      // Chercher dans sous_bareme_custom_notes
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('sous_bareme_custom_notes')
          .where('sousBaremeId', isEqualTo: sousBaremeId)
          .where('parentBaremeId', isEqualTo: baremeId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final notes = doc.data()['notes'];
        return notes != null && notes is List && notes.isNotEmpty;
      }

      // Chercher dans bareme_custom_notes avec l'ID complet
      final fullId = '$classId-$matiereId-$baremeId-$sousBaremeId';
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('bareme_custom_notes')
          .doc(fullId)
          .get();

      if (doc.exists) {
        final notes = doc.data()?['notes'];
        return notes != null && notes is List && notes.isNotEmpty;
      }

      return false;
    } catch (e) {
// print('Erreur vérification notes sous-barème: $e');
      return false;
    }
  }

  Future<List<String>> _getSousBaremeCustomNotes(
    String classId,
    String matiereId,
    String baremeId,
    String sousBaremeId,
  ) async {
    try {
// print('🔍 SOUS-BARÈME: Recherche notes pour sousBaremeId: $sousBaremeId');
// print('   parentBaremeId: $baremeId');
// print('   classId: $classId');
// print('   matiereId: $matiereId');

      // ESSAI 1: Chercher avec la structure complète (la plus spécifique)
      final fullId = '$classId-$matiereId-$baremeId-$sousBaremeId';
// print('   📍 Chercher avec ID complet: $fullId');

      final fullDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('bareme_custom_notes')
          .doc(fullId)
          .get();

      if (fullDoc.exists) {
        final notes = fullDoc.data()?['notes'];
        if (notes != null && notes is List && notes.isNotEmpty) {
          final result = List<String>.from(notes);
// print('✅ Notes trouvées avec ID complet: $result');
          return result;
        }
      }

      // ESSAI 2: Chercher dans sous_bareme_custom_notes avec tous les filtres
      final querySnapshot1 = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('sous_bareme_custom_notes')
          .where('sousBaremeId', isEqualTo: sousBaremeId)
          .where('parentBaremeId', isEqualTo: baremeId)
          .where('parentClassId', isEqualTo: classId)
          .where('parentMatiereId', isEqualTo: matiereId)
          .limit(1)
          .get();

      if (querySnapshot1.docs.isNotEmpty) {
        final doc = querySnapshot1.docs.first;
        final notes = doc.data()['notes'];

        if (notes != null && notes is List && notes.isNotEmpty) {
          final result = List<String>.from(notes);
// print('✅ Notes trouvées avec tous les filtres: $result');
          return result;
        }
      }

      // ESSAI 3: Chercher seulement avec sousBaremeId et parentBaremeId (plus large)
      final querySnapshot2 = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('sous_bareme_custom_notes')
          .where('sousBaremeId', isEqualTo: sousBaremeId)
          .where('parentBaremeId', isEqualTo: baremeId)
          .limit(1)
          .get();

      if (querySnapshot2.docs.isNotEmpty) {
        final doc = querySnapshot2.docs.first;
        final notes = doc.data()['notes'];

        if (notes != null && notes is List && notes.isNotEmpty) {
          final result = List<String>.from(notes);
// print('✅ Notes trouvées avec sousBaremeId et parentBaremeId: $result');
          return result;
        }
      }

      // ESSAI 4: Chercher seulement avec sousBaremeId (le plus large)
      final querySnapshot3 = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('sous_bareme_custom_notes')
          .where('sousBaremeId', isEqualTo: sousBaremeId)
          .limit(1)
          .get();

      if (querySnapshot3.docs.isNotEmpty) {
        final doc = querySnapshot3.docs.first;
        final notes = doc.data()['notes'];

        if (notes != null && notes is List && notes.isNotEmpty) {
          final result = List<String>.from(notes);
// print('✅ Notes trouvées avec seulement sousBaremeId: $result');
          return result;
        }
      }

      // ESSAI 5: Vérifier si les notes sont dans bareme_custom_notes avec sousBaremeId seul
      final sousBaremeDocId = '$classId-$matiereId-$sousBaremeId';
      final sousBaremeDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('bareme_custom_notes')
          .doc(sousBaremeDocId)
          .get();

      if (sousBaremeDoc.exists) {
        final notes = sousBaremeDoc.data()?['notes'];
        if (notes != null && notes is List && notes.isNotEmpty) {
          final result = List<String>.from(notes);
// print('✅ Notes trouvées dans bareme_custom_notes: $result');
          return result;
        }
      }

      // ESSAI 6: Chercher toutes les notes disponibles pour debug
// print('⚠️ Aucune note personnalisée trouvée - Affichage tous les documents:');

      final allDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('sous_bareme_custom_notes')
          .get();

// print('📋 Total documents dans sous_bareme_custom_notes: ${allDocs.docs.length}');
      for (final doc in allDocs.docs) {
        final data = doc.data();
// print('   📄 ${doc.id}');
// print('     sousBaremeId: ${data['sousBaremeId']}');
// print('     parentBaremeId: ${data['parentBaremeId']}');
// print('     parentClassId: ${data['parentClassId']}');
// print('     parentMatiereId: ${data['parentMatiereId']}');
// print('     Notes: ${data['notes'] ?? []}');
      }

      // ESSAI 7: Utiliser les notes du barème parent
// print('↪️ Utilisation des notes du barème parent: $baremeId');
      final parentNotes = await _getCustomNotesForBareme(
        classId,
        matiereId,
        baremeId,
      );

      if (parentNotes.isNotEmpty) {
// print('✅ Notes du parent utilisées: $parentNotes');
        return parentNotes;
      }

      // ESSAI 8: Utiliser les notes globales
      final globalNotes = await _loadCustomNotes(classId, matiereId);
      if (globalNotes.isNotEmpty) {
// print('✅ Notes globales utilisées: $globalNotes');
        return globalNotes;
      }

// print('⚠️ Aucune note personnalisée trouvée pour sous-barème $sousBaremeId');
      return [];
    } catch (e) {
// print('❌ Erreur chargement notes sous-barème: $e');
      return [];
    }
  }

  Future<String> _getEvaluationSystem(String classId, String matiereId) async {
    try {
      // Même format que dans _DynamicTablePageState
      final docId = '$classId-$matiereId';

// print('🔍 _StudentsTableState - Recherche système pour: $docId');

      final systemDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('evaluation_systems')
          .doc(docId)
          .get();

      if (systemDoc.exists) {
        final system = systemDoc.data()?['system'] ?? 'character';
// print('✅ _StudentsTableState - Système trouvé: $system');
        return system;
      }

// print('⚠️ _StudentsTableState - Système par défaut: character');
      return 'character';
    } catch (e) {
// print('❌ _StudentsTableState - Erreur récupération système: $e');
      return 'character';
    }
  }

  Future<List<String>> _loadCustomNotes(
      String classId, String matiereId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('bareme_custom_notes')
          .where(FieldPath.documentId,
              isGreaterThanOrEqualTo: '$classId-$matiereId-')
          .where(FieldPath.documentId, isLessThan: '$classId-$matiereId-\uf8ff')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        if (data['notes'] != null) {
// print("🔥 CUSTOM NOTES LOADED: ${data['notes']}");
          return List<String>.from(data['notes']);
        }
      }

// print("⚠️ NO MATCHING CUSTOM NOTES");
      return [];
    } catch (e) {
// print('Erreur lors du chargement des notes personnalisées: $e');
      return [];
    }
  }

  Future<List<String>> _getDropdownValuesForBareme(String baremeKey) async {
    try {
      List<String> customNotes = [];

      if (baremeKey.contains('-')) {
        // C'EST UN SOUS-BARÈME
        var parts = baremeKey.split('-');
        var baremeId = parts[0];
        var sousBaremeId = parts[1];

// print('🔍 Sous-barème détecté dans getDropdownValues: $sousBaremeId');

        // Récupérer le système pour le sous-barème
        final evaluationSystem = await _getEvaluationSystemForSousBareme(
          widget.selectedClass,
          widget.selectedMatiere,
          baremeId,
          sousBaremeId,
        );

// print('📊 Système pour sous-barème $sousBaremeId: $evaluationSystem');

        if (evaluationSystem == 'custom') {
          // Charger les notes personnalisées du sous-barème
          customNotes = await _getSousBaremeCustomNotes(
            widget.selectedClass,
            widget.selectedMatiere,
            baremeId,
            sousBaremeId,
          );

// print('📝 Notes custom sous-barème: ${customNotes.length} notes');
        }

        return _getDropdownValues(evaluationSystem, customNotes);
      } else {
        // BARÈME PRINCIPAL
        final String evaluationSystem = await _getEvaluationSystem(
            widget.selectedClass, widget.selectedMatiere);

// print('📊 Système pour barème $baremeKey: $evaluationSystem');

        if (evaluationSystem == 'custom') {
          customNotes = await _getCustomNotesForBareme(
              widget.selectedClass, widget.selectedMatiere, baremeKey);

// print('📝 Notes custom barème: ${customNotes.length} notes');
        }

        return _getDropdownValues(evaluationSystem, customNotes);
      }
    } catch (e) {
// print('❌ Erreur getDropdownValuesForBareme: $e');
      return ['( - - - )', '( + - - )', '( + + - )', '( + + + )'];
    }
  }

  Future<String> _getEvaluationSystemForSousBareme(String classId,
      String matiereId, String baremeId, String sousBaremeId) async {
    try {
      // D'abord vérifier si le sous-barème a son propre système
      final sousBaremeSystemDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('evaluation_systems')
          .doc('$classId-$matiereId-$baremeId-$sousBaremeId')
          .get();

      if (sousBaremeSystemDoc.exists) {
        final system = sousBaremeSystemDoc['system'] ?? 'character';
// print('✅ Système trouvé pour sous-barème $sousBaremeId: $system');
        return system;
      }

      // Sinon, utiliser le système du barème parent
      final parentSystem = await _getEvaluationSystem(classId, matiereId);
// print('↪️ Utilisation système parent: $parentSystem');
      return parentSystem;
    } catch (e) {
// print('❌ Erreur récupération système sous-barème: $e');
      return 'character';
    }
  }

// Modifier l'existant
  List<String> _getDropdownValues(
      String evaluationSystem, List<String> customNotes) {
    switch (evaluationSystem) {
      case 'character':
        return ['( - - - )', '( + - - )', '( + + - )', '( + + + )'];

      case 'note_0_1_5':
        return ['0', '0.5', '1', '1.5'];

      case 'note_0_3':
        return ['0', '1', '2', '3'];

      case 'note_0_6':
        return ['0', '2', '4', '6'];

      case 'custom':
        return customNotes.isNotEmpty
            ? customNotes
            : ['( - - - )', '( + - - )', '( + + - )', '( + + + )'];

      default:
        return ['( - - - )', '( + - - )', '( + + - )', '( + + + )'];
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
        _getTranslatedText('مجموعة العلاج', 'Groupe de traitement'): [],
        _getTranslatedText('مجموعة الدعم', 'Groupe de soutien'): [],
        _getTranslatedText('مجموعة التميز', 'Groupe d\'excellence'): [],
      };

      for (var studentDoc in studentsSnapshot.docs) {
        var studentId = studentDoc.id;
        var studentName = studentDoc['name'] ??
            _getTranslatedText('اسم غير معروف', 'Nom inconnu');

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
            studentGroups[_getTranslatedText(
                    'مجموعة التميز', 'Groupe d\'excellence')]!
                .add(studentName);
          } else if (value == '( + + - )') {
            studentGroups[
                    _getTranslatedText('مجموعة الدعم', 'Groupe de soutien')]!
                .add(studentName);
          } else if (value == '( + - - )' || value == '( - - - )') {
            studentGroups[_getTranslatedText(
                    'مجموعة العلاج', 'Groupe de traitement')]!
                .add(studentName);
          }
        }
      }

      if (_isMounted) {
        _showClassificationDialog(studentGroups);
      }
    } catch (e) {
// print('Erreur lors de la classification des élèves: $e');
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
                        _getTranslatedText(
                            'تصنيف التلاميذ', 'Classification des élèves'),
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
                          ...[
                            _getTranslatedText(
                                'مجموعة التميز', 'Groupe d\'excellence'),
                            _getTranslatedText(
                                'مجموعة الدعم', 'Groupe de soutien'),
                            _getTranslatedText(
                                'مجموعة العلاج', 'Groupe de traitement')
                          ].map((groupName) {
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
                          _getTranslatedText('إغلاق', 'Fermer'),
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

    if (groupName.contains(_getTranslatedText('التميز', 'excellence')) ||
        groupName.contains('excellence')) {
      cardColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green;
    } else if (groupName.contains(_getTranslatedText('الدعم', 'soutien')) ||
        groupName.contains('soutien')) {
      cardColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange;
    } else {
      cardColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
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

  // Méthode pour calculer la somme des notes d'un élève

  Future<double> _calculateStudentTotal(String studentId,
      Map<String, List<Map<String, dynamic>>> groupedBaremes) async {
    double total = 0.0;

    try {
      // Récupérer le système d'évaluation
      final String evaluationSystem = await _getEvaluationSystem(
          widget.selectedClass, widget.selectedMatiere);

// print('🔍 CALCUL SOMME pour étudiant $studentId');
// print('📊 Groupes disponibles: ${groupedBaremes.length}');

      // Parcourir tous les groupes
      for (var entry in groupedBaremes.entries) {
        final groupKey = entry.key;
        final baremesInGroup = entry.value;

// print('  Groupe: $groupKey, ${baremesInGroup.length} éléments');

        for (final bareme in baremesInGroup) {
          final baremeType = bareme['type'] ?? 'bareme';
          final baremeId = bareme['id'];

          // Ne pas calculer les barèmes principaux qui ont des sous-barèmes
          // (on calcule seulement les sous-barèmes et les barèmes sans sous-barèmes)
          if (baremeType == 'bareme') {
            final sousBaremes = bareme['sousBaremes'] as List<dynamic>? ?? [];
            if (sousBaremes.isNotEmpty) {
              // Ce barème a des sous-barèmes - calculer les sous-barèmes
              for (final sousBareme in sousBaremes) {
                final sousBaremeId = sousBareme['id'];
                final value = await _getNumericValueForBareme(
                    studentId, sousBaremeId, evaluationSystem);
// print('    - SOUS-BARÈME: $sousBaremeId -> $value');
                if (value > 0) {
                  total += value;
// print('      ✅ Ajouté à la somme: $value (Total: $total)');
                }
              }
              continue; // Passer au prochain élément
            }
          }

          // Pour les barèmes sans sous-barèmes et les sous-barèmes seuls
          if (baremeId != null && baremeId.isNotEmpty) {
            final value = await _getNumericValueForBareme(
                studentId, baremeId, evaluationSystem);
// print('    - ${baremeType == 'bareme' ? 'BARÈME' : 'SOUS-BARÈME'}: $baremeId -> $value');
            if (value > 0) {
              total += value;
// print('      ✅ Ajouté à la somme: $value (Total: $total)');
            }
          }
        }
      }

// print('✅ SOMME TOTALE pour $studentId: $total');
    } catch (e) {
// print('❌ Erreur calcul total pour $studentId: $e');
// print('Stack trace: ${e.toString()}');
    }

    return total;
  }

// MÉTHODE CORRIGÉE: Conversion avec vérification des notes numériques

  Future<double> _getNumericValueForBareme(
      String studentId, String baremeKey, String evaluationSystem) async {
    try {
      // Récupérer la valeur stockée
      final storedValue = await _getStoredValue(studentId, baremeKey);

      // Vérifier si c'est "غائب" (absent)
      if (storedValue == 'غائب') {
        return 0.0;
      }

      // Charger les notes personnalisées si nécessaire
      List<String> customNotes = [];
      if (evaluationSystem == 'custom') {
        if (baremeKey.contains('-')) {
          // Sous-barème
          var parts = baremeKey.split('-');
          if (parts.length >= 2) {
            var baremeId = parts[0];
            var sousBaremeId = parts[1];
            customNotes = await _getSousBaremeCustomNotes(
              widget.selectedClass,
              widget.selectedMatiere,
              baremeId,
              sousBaremeId,
            );
          }
        } else {
          // Barème principal
          customNotes = await _getCustomNotesForBareme(
            widget.selectedClass,
            widget.selectedMatiere,
            baremeKey,
          );
        }
      }

      // Convertir selon le système
      final displayValue = _getDisplayEvaluation(
        storedValue,
        evaluationSystem,
        customNotes: customNotes,
      );

      // Convertir en nombre
      return _convertToNumber(displayValue, evaluationSystem, customNotes);
    } catch (e) {
// print('Erreur conversion numérique pour $baremeKey: $e');
      return 0.0;
    }
  }

// Méthode pour récupérer la valeur stockée (sans conversion)
  Future<String> _getStoredValue(String studentId, String baremeKey) async {
    try {
      final isSousBareme = await _isSousBareme(baremeKey);

      if (isSousBareme) {
        final parentInfo = await _getParentBaremeInfo(baremeKey);
        final baremeId = parentInfo['parentBaremeId'];
        final sousBaremeId = baremeKey;

        var sousBaremeDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUser.uid)
            .collection('user_classes')
            .doc(widget.classDocId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .doc(baremeId)
            .collection('sous_baremes')
            .doc(sousBaremeId)
            .get();

        return sousBaremeDoc.data()?['Marks']?.toString() ?? '( - - - )';
      } else {
        var baremeDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUser.uid)
            .collection('user_classes')
            .doc(widget.classDocId)
            .collection('students')
            .doc(studentId)
            .collection('baremes')
            .doc(baremeKey)
            .get();

        return baremeDoc.data()?['Marks']?.toString() ?? '( - - - )';
      }
    } catch (e) {
      return '( - - - )';
    }
  }

  double _convertToNumber(
      String displayValue, String system, List<String> customNotes) {
    // Si c'est "غائب" ou vide
    if (displayValue == 'غائب' || displayValue.isEmpty) {
      return 0.0;
    }

    // Pour le système custom
    if (system == 'custom') {
      // Si pas de notes personnalisées, traiter comme character system
      if (customNotes.isEmpty) {
// print('⚠️ Pas de notes custom, fallback sur character system');
        switch (displayValue) {
          case '( - - - )':
            return 0.0;
          case '( + - - )':
            return 0.5;
          case '( + + - )':
            return 1.0;
          case '( + + + )':
            return 1.5;
          default:
            return 0.0;
        }
      }

      // Essayer de convertir directement en nombre
      final numValue = double.tryParse(displayValue);
      if (numValue != null) {
        return numValue;
      }

      // Si non numérique, essayer de trouver l'index dans customNotes
      final index = customNotes.indexOf(displayValue);
      if (index != -1) {
        // Convertir l'index en valeur numérique proportionnelle
        // Exemple: si 4 notes [0, 0.25, 0.5, 0.75], l'index 0 = 0, index 3 = 0.75
        if (index == 0) return 0.0;
        if (index == customNotes.length - 1) {
          // Dernière note (max)
          final maxValue =
              double.tryParse(customNotes.last) ?? customNotes.length - 1.0;
          return maxValue;
        }
        return index.toDouble();
      }

      return 0.0;
    }

    // Pour les autres systèmes (character)
    if (system == 'character') {
      switch (displayValue) {
        case '( - - - )':
          return 0.0;
        case '( + - - )':
          return 0.5;
        case '( + + - )':
          return 1.0;
        case '( + + + )':
          return 1.5;
        default:
          return 0.0;
      }
    }

    // Pour les systèmes numériques
    final numValue = double.tryParse(displayValue);
    return numValue ?? 0.0;
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
                child: Text(value),
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

// Widget d'alerte pour tous les utilisateurs avec texte spécifique iPhone
class IPhoneAdviceDialog extends StatelessWidget {
  final bool isFrenchInterface;
  final VoidCallback onContinue;

  const IPhoneAdviceDialog({
    Key? key,
    required this.isFrenchInterface,
    required this.onContinue,
  }) : super(key: key);

  String _t(String ar, String fr) => isFrenchInterface ? fr : ar;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_iphone,
              color: Colors.orange,
              size: 28,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _t('تنبيه لمستخدمي آيفون', 'Alerte pour utilisateurs iPhone'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Message principal
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 40,
                  ),
                  SizedBox(height: 12),
                  Text(
                    _t(
                      'مشاكل معروفة على أجهزة آيفون',
                      'Problèmes connus sur iPhone',
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    _t(
                      'قد تواجه بعض المشاكل في عرض وتحميل التقارير على أجهزة آيفون '
                          'بسبب قيود نظام iOS.',
                      'Vous pourriez rencontrer des problèmes d\'affichage et de téléchargement '
                          'des rapports sur iPhone en raison des restrictions du système iOS.',
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Solution recommandée
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.computer, color: Colors.blue, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _t(
                        'للحصول على أفضل تجربة، ننصح باستخدام جهاز كمبيوتر',
                        'Pour une meilleure expérience, nous recommandons d\'utiliser un ordinateur',
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Note "une seule fois"
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
                SizedBox(width: 6),
                Text(
                  _t(
                    'هذه الرسالة تظهر مرة واحدة فقط',
                    'Ce message s\'affiche une seule fois',
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            _t('إلغاء', 'Annuler'),
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onContinue();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            _t('متابعة على أي حال', 'Continuer quand même'),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
