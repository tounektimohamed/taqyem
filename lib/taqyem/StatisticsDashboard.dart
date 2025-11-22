import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _classes = [];
  Map<String, dynamic>? _selectedClass;
  String? _selectedSubject;
  List<Map<String, dynamic>> _statisticsData = [];
  List<Map<String, dynamic>> _improvementAreas = [];
  bool _isLoading = false;

  // Couleurs personnalisées
  final Color _primaryColor = Color.fromRGBO(7, 82, 96, 1);
  final Color _secondaryColor = Color.fromRGBO(14, 164, 191, 1);
  final Color _accentColor = Color.fromRGBO(255, 193, 7, 1);
  final Color _warningColor = Color.fromRGBO(244, 67, 54, 1);
  final Color _backgroundColor = Color.fromRGBO(245, 248, 250, 1);

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    try {
      final classDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .get();

      setState(() {
        _classes = classDocs.docs.map((doc) {
          List<Map<String, String>> subjects = [];
          if (doc['subjects'] != null) {
            subjects = (doc['subjects'] as List).map((subject) {
              return {
                'id': subject['id'].toString(),
                'name': subject['name'].toString(),
              };
            }).toList();
          }

          return {
            'id': doc.id,
            'class_id': doc['class_id'].toString(),
            'class_name': doc['class_name'].toString(),
            'subjects': subjects,
          };
        }).toList();
      });
    } catch (e) {
      print("Erreur lors du chargement des classes : $e");
      _showErrorSnackBar('Erreur lors du chargement des classes');
    }
  }

  Future<void> _loadStatistics() async {
    if (_selectedClass == null || _selectedSubject == null) return;

    setState(() {
      _isLoading = true;
      _statisticsData.clear();
      _improvementAreas.clear();
    });

    try {
      final classId = _selectedClass!['id'];
      final classDocId = _selectedClass!['class_id'];
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .get();

      List<Map<String, dynamic>> stats = [];
      List<Map<String, dynamic>> improvementList = [];

      // Récupérer tous les baremeIds pour cette matière
      final baremeIds = await _getBaremeIds(classDocId, _selectedSubject!);
      final baremeDetails = await _getBaremeDetails(classDocId, _selectedSubject!);

      for (var studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;
        final studentName = studentDoc['name'];

        int totalEvaluations = 0;
        int excellentCount = 0;
        int goodCount = 0;
        int averageCount = 0;
        int poorCount = 0;
        List<Map<String, dynamic>> studentWeakAreas = [];

        // Parcourir tous les baremes pour cet étudiant
        for (var baremeId in baremeIds) {
          final baremeName = baremeDetails[baremeId]?['name'] ?? 'Compétence inconnue';
          
          final evaluation = await _getStudentEvaluation(
            classId: classId,
            studentId: studentId,
            baremeId: baremeId,
          );
          
          if (evaluation != null) {
            totalEvaluations++;
            _updateEvaluationCounts(evaluation, {
              'excellent': () => excellentCount++,
              'good': () => goodCount++,
              'average': () => averageCount++,
              'poor': () => poorCount++,
            });

            // Vérifier si c'est une compétence à améliorer
            if (evaluation == '( - - - )' || evaluation == '( + - - )') {
              studentWeakAreas.add({
                'baremeName': baremeName,
                'evaluation': evaluation,
                'priority': evaluation == '( - - - )' ? 'Élevée' : 'Moyenne',
              });
            }
          }

          // Vérifier les sous-barèmes
          final sousBaremesEvaluations = await _getSousBaremesEvaluations(
            classId: classId,
            studentId: studentId,
            baremeId: baremeId,
          );

          for (var sousEvaluation in sousBaremesEvaluations) {
            if (sousEvaluation != null) {
              totalEvaluations++;
              _updateEvaluationCounts(sousEvaluation, {
                'excellent': () => excellentCount++,
                'good': () => goodCount++,
                'average': () => averageCount++,
                'poor': () => poorCount++,
              });
            }
          }
        }

        // Ajouter les compétences à améliorer pour cet étudiant
        for (var weakArea in studentWeakAreas) {
          improvementList.add({
            'studentName': studentName,
            'baremeName': weakArea['baremeName'],
            'evaluation': weakArea['evaluation'],
            'priority': weakArea['priority'],
          });
        }

        double successRate = totalEvaluations > 0
            ? ((excellentCount + goodCount) / totalEvaluations) * 100
            : 0;

        stats.add({
          'studentName': studentName,
          'totalEvaluations': totalEvaluations,
          'excellentCount': excellentCount,
          'goodCount': goodCount,
          'averageCount': averageCount,
          'poorCount': poorCount,
          'successRate': successRate,
          'performanceLevel': _getPerformanceLevel(successRate),
        });
      }

      setState(() {
        _statisticsData = stats;
        _improvementAreas = improvementList;
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur lors du chargement des statistiques : $e");
      _showErrorSnackBar('Erreur lors du chargement des statistiques');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, Map<String, dynamic>>> _getBaremeDetails(String classDocId, String subjectId) async {
    final details = <String, Map<String, dynamic>>{};
    try {
      final selectionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(classDocId)
          .collection(subjectId)
          .get();

      for (var doc in selectionsSnapshot.docs) {
        final baremeId = doc['baremeId'] as String?;
        if (baremeId != null) {
          details[baremeId] = {
            'name': doc['baremeName'] ?? 'Compétence sans nom',
          };
        }
      }
    } catch (e) {
      print("Erreur récupération détails barèmes: $e");
    }
    return details;
  }

  Future<List<String>> _getBaremeIds(String classDocId, String subjectId) async {
    try {
      final selectionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('selections')
          .doc(classDocId)
          .collection(subjectId)
          .get();

      return selectionsSnapshot.docs
          .map((doc) => doc['baremeId'] as String?)
          .where((id) => id != null)
          .map((id) => id!)
          .toList();
    } catch (e) {
      print("Erreur lors de la récupération des barèmes: $e");
      return [];
    }
  }

  Future<String?> _getStudentEvaluation({
    required String classId,
    required String studentId,
    required String baremeId,
  }) async {
    try {
      final evalDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(classId)
          .collection('students')
          .doc(studentId)
          .collection('baremes')
          .doc(baremeId)
          .get();

      if (evalDoc.exists && evalDoc.data()?.containsKey('Marks') == true) {
        return evalDoc['Marks'] as String;
      }
      return null;
    } catch (e) {
      print('Erreur récupération évaluation bareme $baremeId: $e');
      return null;
    }
  }

  Future<List<String?>> _getSousBaremesEvaluations({
    required String classId,
    required String studentId,
    required String baremeId,
  }) async {
    try {
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

      return sousBaremesSnapshot.docs
          .map((doc) => doc.data().containsKey('Marks') ? doc['Marks'] as String : null)
          .toList();
    } catch (e) {
      print('Erreur récupération sous-barèmes pour bareme $baremeId: $e');
      return [];
    }
  }

  void _updateEvaluationCounts(
    String evaluation, 
    Map<String, Function> counters
  ) {
    switch (evaluation) {
      case '( + + + )':
        counters['excellent']!();
        break;
      case '( + + - )':
        counters['good']!();
        break;
      case '( + - - )':
        counters['average']!();
        break;
      case '( - - - )':
        counters['poor']!();
        break;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getPerformanceLevel(double successRate) {
    if (successRate >= 80) return 'ممتاز';
    if (successRate >= 60) return 'جيد جداً';
    if (successRate >= 40) return 'مقبول';
    return 'ضعيف';
  }

  Color _getPerformanceColor(String level) {
    switch (level) {
      case 'ممتاز':
        return Color.fromRGBO(76, 175, 80, 1);
      case 'جيد جداً':
        return Color.fromRGBO(139, 195, 74, 1);
      case 'مقبول':
        return Color.fromRGBO(255, 152, 0, 1);
      case 'ضعيف':
        return Color.fromRGBO(244, 67, 54, 1);
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Élevée':
        return _warningColor;
      case 'Moyenne':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // NOUVEAU : Sélecteurs compacts
  Widget _buildCompactSelectors() {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sélecteur de classe
          Row(
          children: [
            Icon(Icons.school_rounded, size: 20, color: _primaryColor),
            SizedBox(width: 8),
              Expanded(
                child: DropdownButton<Map<String, dynamic>>(
                  value: _selectedClass,
                  isExpanded: true,
                  underline: SizedBox(),
                  icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
                  hint: Text('اختر القسم', style: TextStyle(fontSize: 14)),
                  items: _classes.map((classData) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: classData,
                      child: Text(
                        classData['class_name'],
                        style: TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClass = value;
                      _selectedSubject = null;
                      _statisticsData.clear();
                      _improvementAreas.clear();
                    });
                  },
                ),
              ),
            ],
          ),
          
          if (_selectedClass != null) ...[
            Divider(height: 20, color: Colors.grey.shade300),
            // Sélecteur de matière
            Row(
              children: [
                Icon(Icons.subject_rounded, size: 20, color: _secondaryColor),
                SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedSubject,
                    isExpanded: true,
                    underline: SizedBox(),
                    icon: Icon(Icons.arrow_drop_down, color: _secondaryColor),
                    hint: Text('اختر المادة', style: TextStyle(fontSize: 14)),
                    items: (_selectedClass!['subjects'] as List<Map<String, String>>).map((subject) {
                      return DropdownMenuItem<String>(
                        value: subject['id'],
                        child: Text(
                          subject['name']!,
                          style: TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSubject = value;
                      });
                      _loadStatistics();
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsOverview() {
    if (_statisticsData.isEmpty || _isLoading) return SizedBox();

    final totalStudents = _statisticsData.length;
    final averageSuccessRate = _statisticsData
            .map((data) => data['successRate'] as double)
            .reduce((a, b) => a + b) /
        totalStudents;

    final totalEvaluations = _statisticsData
        .map((data) => data['totalEvaluations'] as int)
        .reduce((a, b) => a + b);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('نظرة عامة'),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildCompactStatCard('التلاميذ', totalStudents.toString(), Icons.people_alt_rounded, _primaryColor)),
              SizedBox(width: 8),
              Expanded(child: _buildCompactStatCard('التقييمات', totalEvaluations.toString(), Icons.assessment_rounded, _secondaryColor)),
              SizedBox(width: 8),
              Expanded(child: _buildCompactStatCard('النسبة', '${averageSuccessRate.toStringAsFixed(0)}%', Icons.trending_up_rounded, _accentColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // NOUVEAU : Indicateur des compétences à améliorer
  Widget _buildImprovementAreas() {
    if (_improvementAreas.isEmpty || _isLoading) return SizedBox();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(' التحسين'),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: _improvementAreas.take(5).map((area) {
                return ListTile(
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(area['priority']),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    area['studentName'],
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    area['baremeName'],
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(area['priority']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getPriorityColor(area['priority']).withOpacity(0.3)),
                    ),
                    child: Text(
                      area['priority'],
                      style: TextStyle(
                        fontSize: 10,
                        color: _getPriorityColor(area['priority']),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                );
              }).toList(),
            ),
          ),
          if (_improvementAreas.length > 5)
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'و ${_improvementAreas.length - 5} مهارات أخرى تحتاج تحسين',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    if (_statisticsData.isEmpty) return SizedBox();

    final performanceCounts = {
      'ممتاز': 0,
      'جيد جداً': 0,
      'مقبول': 0,
      'ضعيف': 0,
    };

    for (var data in _statisticsData) {
      performanceCounts[data['performanceLevel']] =
          performanceCounts[data['performanceLevel']]! + 1;
    }

    final chartData = performanceCounts.entries.map((entry) {
      return ChartData(entry.key, entry.value, _getPerformanceColor(entry.key));
    }).toList();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('توزيع المستويات'),
          SizedBox(height: 12),
          Container(
            height: 200,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: SfCircularChart(
              palette: [
                _getPerformanceColor('ممتاز'),
                _getPerformanceColor('جيد جداً'),
                _getPerformanceColor('مقبول'),
                _getPerformanceColor('ضعيف'),
              ],
              series: <CircularSeries>[
                DoughnutSeries<ChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (ChartData data, _) => data.x,
                  yValueMapper: (ChartData data, _) => data.y,
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                  radius: '70%',
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTable() {
    if (_statisticsData.isEmpty) return SizedBox();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('أداء التلاميذ'),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                horizontalMargin: 12,
                dataRowHeight: 40,
                headingRowHeight: 40,
                columns: [
                  _buildDataColumn('الاسم'),
                  _buildDataColumn('التقييمات'),
                  _buildDataColumn('ممتاز'),
                  _buildDataColumn('جيد'),
                  _buildDataColumn('مقبول'),
                  _buildDataColumn('ضعيف'),
                  _buildDataColumn('النسبة'),
                  _buildDataColumn('المستوى'),
                ],
                rows: _statisticsData.map((data) {
                  return DataRow(
                    cells: [
                      _buildDataCell(Text(
                        data['studentName'],
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      )),
                      _buildDataCell(Text(data['totalEvaluations'].toString())),
                      _buildDataCell(Text(
                        data['excellentCount'].toString(),
                        style: TextStyle(fontSize: 12, color: _getPerformanceColor('ممتاز')),
                      )),
                      _buildDataCell(Text(
                        data['goodCount'].toString(),
                        style: TextStyle(fontSize: 12, color: _getPerformanceColor('جيد جداً')),
                      )),
                      _buildDataCell(Text(
                        data['averageCount'].toString(),
                        style: TextStyle(fontSize: 12, color: _getPerformanceColor('مقبول')),
                      )),
                      _buildDataCell(Text(
                        data['poorCount'].toString(),
                        style: TextStyle(fontSize: 12, color: _getPerformanceColor('ضعيف')),
                      )),
                      _buildDataCell(Text(
                        '${data['successRate'].toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      )),
                      _buildDataCell(
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPerformanceColor(data['performanceLevel']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            data['performanceLevel'],
                            style: TextStyle(
                              fontSize: 10,
                              color: _getPerformanceColor(data['performanceLevel']),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataColumn _buildDataColumn(String label) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: _primaryColor,
          fontSize: 11,
        ),
      ),
    );
  }

  DataCell _buildDataCell(Widget child) {
    return DataCell(Container(child: child));
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: _primaryColor,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 60,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 12),
            Text(
              'لا توجد بيانات لعرضها',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 6),
            Text(
              _selectedSubject == null 
                ? 'اختر قسم ومادة لرؤية الإحصائيات'
                : 'لا توجد تقييمات لهذه المادة بعد',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              strokeWidth: 2,
            ),
            SizedBox(height: 12),
            Text(
              'جاري تحميل الإحصائيات...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'الإحصائيات',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              _buildCompactSelectors(), // Sélecteurs compacts
              if (_isLoading)
                _buildLoadingState()
              else if (_statisticsData.isEmpty)
                _buildEmptyState()
              else
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildStatisticsOverview(),
                        _buildImprovementAreas(), // Nouvelle section
                        _buildPerformanceChart(),
                        _buildStudentsTable(),
                        SizedBox(height: 16),
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
}

class ChartData {
  final String x;
  final int y;
  final Color color;

  ChartData(this.x, this.y, this.color);
}