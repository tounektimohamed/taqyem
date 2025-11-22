import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendanceSystemPage extends StatefulWidget {
  const AttendanceSystemPage({Key? key}) : super(key: key);

  @override
  _AttendanceSystemPageState createState() => _AttendanceSystemPageState();
}

class _AttendanceSystemPageState extends State<AttendanceSystemPage> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _classes = [];
  Map<String, dynamic>? _selectedClass;
  List<Map<String, dynamic>> _students = [];
  Map<String, String> _attendanceStatus = {};
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showClassSelection = true;

  // Statuts de présence
  final Map<String, String> _statusOptions = {
    'present': 'حاضر',
    'absent': 'غائب',
    'late': 'متأخر',
    'excused': 'معذور',
  };

  final Map<String, Color> _statusColors = {
    'present': Colors.green,
    'absent': Colors.red,
    'late': Colors.orange,
    'excused': Colors.blue,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClasses();
    });
  }

  Future<void> _loadClasses() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final classDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .get();

      if (classDocs.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _showClassSelection = true;
        });
        return;
      }

      setState(() {
        _classes = classDocs.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data()
          };
        }).toList();
        _isLoading = false;
      });

      if (_classes.length == 1) {
        _selectClass(_classes.first);
      }
    } catch (e) {
      print("Erreur lors du chargement des classes : $e");
      setState(() {
        _isLoading = false;
      });
      _showError('Erreur lors du chargement des classes');
    }
  }

  Future<void> _selectClass(Map<String, dynamic> classData) async {
    setState(() {
      _selectedClass = classData;
      _showClassSelection = false;
      _isLoading = true;
    });

    await _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      if (_selectedClass == null) return;

      final students = _selectedClass!['students'] ?? [];
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
          studentsData.add({
            'id': studentId,
            ...studentDoc.data() as Map<String, dynamic>
          });
        }
      }

      studentsData.sort((a, b) => a['name'].compareTo(b['name']));
      await _loadExistingAttendance();

      setState(() {
        _students = studentsData;
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur lors du chargement des élèves : $e");
      setState(() {
        _isLoading = false;
      });
      _showError('Erreur lors du chargement des élèves');
    }
  }

  Future<void> _loadExistingAttendance() async {
    try {
      if (_selectedClass == null) return;

      final attendanceDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(_selectedClass!['id'])
          .collection('attendance')
          .doc(_getDateKey(_selectedDate))
          .get();

      if (attendanceDoc.exists) {
        final attendanceData = attendanceDoc.data() as Map<String, dynamic>;
        setState(() {
          _attendanceStatus = Map<String, String>.from(attendanceData['attendance'] ?? {});
        });
      } else {
        setState(() {
          _attendanceStatus = {};
        });
      }
    } catch (e) {
      print("Erreur lors du chargement de la présence : $e");
    }
  }

  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadExistingAttendance();
    }
  }

  void _updateAttendance(String studentId, String status) {
    setState(() {
      _attendanceStatus[studentId] = status;
    });
  }

  Future<void> _saveAttendance() async {
    if (_isSaving || _selectedClass == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final dateKey = _getDateKey(_selectedDate);
      final attendanceRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('user_classes')
          .doc(_selectedClass!['id'])
          .collection('attendance')
          .doc(dateKey);

      await attendanceRef.set({
        'date': _selectedDate,
        'class_id': _selectedClass!['id'],
        'class_name': _selectedClass!['class_name'],
        'subject_id': null,
        'attendance': _attendanceStatus,
        'created_at': FieldValue.serverTimestamp(),
        'total_students': _students.length,
        'present_count': _attendanceStatus.values.where((status) => status == 'present').length,
        'absent_count': _attendanceStatus.values.where((status) => status == 'absent').length,
      }, SetOptions(merge: true));

      _showSuccess('تم حفظ سجل الحضور بنجاح');
    } catch (e) {
      print("Erreur lors de la sauvegarde : $e");
      _showError('حدث خطأ أثناء حفظ الحضور');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _applyToAll(String status) {
    setState(() {
      for (var student in _students) {
        _attendanceStatus[student['id']] = status;
      }
    });
  }

  void _goBackToClassSelection() {
    setState(() {
      _selectedClass = null;
      _showClassSelection = true;
      _students = [];
      _attendanceStatus = {};
    });
  }

  void _showSuccess(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _showError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  // Écran de sélection de classe
  Widget _buildClassSelection() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_classes.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.class_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                "لا توجد أقسام متاحة",
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                "يجب عليك إضافة قسم أولاً لاستخدام نظام الحضور",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header fixe
        Container(
          padding: EdgeInsets.all(16),
          color: Color.fromRGBO(241, 250, 251, 1),
          child: Column(
            children: [
             
              Text(
                'اختر القسم الذي ترغب في تسجيل الحضور له',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color.fromARGB(179, 248, 102, 4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Liste scrollable
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _classes.length,
            itemBuilder: (context, index) {
              final classData = _classes[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(Icons.class_, color: Colors.blue),
                  title: Text(
                    classData['class_name'] ?? 'بدون اسم',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${classData['students']?.length ?? 0} تلميذ',
                    textAlign: TextAlign.right,
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _selectClass(classData),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Écran principal de présence - CORRIGÉ POUR ÉVITER LE DÉBORDEMENT
  Widget _buildAttendanceScreen() {
    return Column(
      children: [
        // Header fixe
        _buildHeader(),
        // Contenu scrollable
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                _buildDateSelector(),
                _buildQuickActions(),
                _buildSummary(),
                _buildStudentList(),
                if (!_isLoading && _students.isNotEmpty) _buildSaveButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      color: Color.fromRGBO(7, 82, 96, 1),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _goBackToClassSelection,
              ),
              Expanded(
                child: Text(
                  'نظام الحضور',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _selectedClass?['class_name'] ?? 'القسم',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'اختر التاريخ:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(_selectedDate),
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.calendar_today),
                    label: Text('تغيير التاريخ'),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'إجراءات سريعة:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statusOptions.entries.map((entry) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _statusColors[entry.key]?.withOpacity(0.1),
                      foregroundColor: _statusColors[entry.key],
                    ),
                    onPressed: () => _applyToAll(entry.key),
                    child: Text('${entry.value} للجميع'),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_students.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "لا يوجد تلاميذ في هذا القسم",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'قائمة التلاميذ:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
          SizedBox(height: 12),
          ..._students.map((student) {
            final currentStatus = _attendanceStatus[student['id']] ?? 'present';
            return _buildStudentAttendanceCard(student, currentStatus);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStudentAttendanceCard(Map<String, dynamic> student, String currentStatus) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            // Photo de l'étudiant
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
              child: student['photoUrl'] != null && student['photoUrl'].isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        student['photoUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.person, size: 20);
                        },
                      ),
                    )
                  : Icon(Icons.person, size: 20),
            ),
            
            SizedBox(width: 12),
            
            // Informations de l'étudiant
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    student['name'],
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (student['parentName'] != null && student['parentName'].isNotEmpty)
                    Text(
                      student['parentName'],
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            
            SizedBox(width: 12),
            
            // Statut de présence
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: currentStatus,
                underline: SizedBox(),
                icon: Icon(Icons.arrow_drop_down, size: 16),
                isDense: true,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _updateAttendance(student['id'], newValue);
                  }
                },
                items: _statusOptions.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _statusColors[entry.key],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          entry.value,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final presentCount = _attendanceStatus.values.where((status) => status == 'present').length;
    final absentCount = _attendanceStatus.values.where((status) => status == 'absent').length;
    final lateCount = _attendanceStatus.values.where((status) => status == 'late').length;
    final excusedCount = _attendanceStatus.values.where((status) => status == 'excused').length;
    final totalCount = _students.length;

    return Container(
      padding: EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'ملخص الحضور:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: 12),
              // Grille responsive pour les statistiques
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 400;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: isSmall ? 2 : 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: isSmall ? 1.2 : 0.8,
                    children: [
                      _buildSummaryItem('المجموع', totalCount, Colors.blue),
                      _buildSummaryItem('الحاضرون', presentCount, Colors.green),
                      _buildSummaryItem('الغائبون', absentCount, Colors.red),
                      _buildSummaryItem('آخرون', lateCount + excusedCount, Colors.orange),
                    ],
                  );
                },
              ),
              SizedBox(height: 12),
              LinearProgressIndicator(
                value: totalCount == 0 ? 0 : presentCount / totalCount,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 8),
              Text(
                'نسبة الحضور: ${totalCount == 0 ? 0 : ((presentCount / totalCount) * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, int count, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: EdgeInsets.all(16),
      child: ElevatedButton.icon(
        icon: _isSaving 
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(Icons.save, size: 20),
        label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ الحضور'),
        onPressed: _isSaving ? null : _saveAttendance,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _showClassSelection 
          ? AppBar(
              title: Text('نظام الحضور'),
              backgroundColor: Color.fromRGBO(255, 255, 255, 1),
              elevation: 4,
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: _showClassSelection ? _buildClassSelection() : _buildAttendanceScreen(),
    );
  }
}