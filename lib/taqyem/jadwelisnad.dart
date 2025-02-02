// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class ClassPage extends StatefulWidget {
//   final String currentUserUid;

//   const ClassPage({required this.currentUserUid, Key? key}) : super(key: key);

//   @override
//   _ClassPageState createState() => _ClassPageState();
// }

// class _ClassPageState extends State<ClassPage> {
//   List<Map<String, dynamic>> _classes = [];
//   List<Map<String, dynamic>> _subjects = [];
//   List<Map<String, dynamic>> _students = [];
//   String? _selectedClassId;
//   String? _selectedSubjectId;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.currentUserUid.isNotEmpty) {
//       _fetchClasses();
//     } else {
//       print("Erreur : currentUserUid est vide.");
//     }
//   }

//   Future<void> _fetchClasses() async {
//     try {
//       final classDocs = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.currentUserUid)
//           .collection('user_classes')
//           .get();

//       if (mounted) {
//         setState(() {
//           _classes = classDocs.docs.map((doc) {
//             return {
//               'id': doc.id,
//               'class_id': doc.data()['class_id'] ?? '',
//               'class_name': doc.data()['class_name'] ?? 'Sans nom',
//             };
//           }).toList();
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print("Erreur lors du chargement des classes : $e");
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _fetchSubjects(String classId) async {
//     if (classId.isEmpty) return;
//     try {
//       final subjectDocs = await FirebaseFirestore.instance
//           .collection('classes')
//           .doc(classId)
//           .collection('matieres')
//           .get();

//       if (mounted) {
//         setState(() {
//           _subjects = subjectDocs.docs.map((doc) {
//             return {
//               'id': doc.id,
//               'name': doc.data()['name'] ?? 'Sans nom',
//             };
//           }).toList();
//         });
//       }
//     } catch (e) {
//       print("Erreur lors du chargement des matières : $e");
//     }
//   }

//   Future<void> _fetchStudents(String classId) async {
//     if (classId.isEmpty) return;
//     try {
//       final studentDocs = await FirebaseFirestore.instance
//           .collection('classes')
//           .doc(classId)
//           .collection('students')
//           .get();

//       if (mounted) {
//         setState(() {
//           _students = studentDocs.docs.map((doc) {
//             return {
//               'id': doc.id,
//               'name': doc.data()['name'] ?? 'Sans nom',
//             };
//           }).toList();
//         });
//       }
//     } catch (e) {
//       print("Erreur lors du chargement des étudiants : $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Classes')),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: _classes.length,
//                     itemBuilder: (context, index) {
//                       final classe = _classes[index];
//                       return ListTile(
//                         title: Text(classe['class_name']),
//                         onTap: () {
//                           setState(() {
//                             _selectedClassId = classe['class_id'];
//                             _subjects.clear();
//                             _students.clear();
//                           });
//                           _fetchSubjects(classe['class_id']);
//                         },
//                       );
//                     },
//                   ),
//                 ),
//                 if (_selectedClassId != null && _subjects.isNotEmpty)
//                   Expanded(
//                     child: ListView.builder(
//                       itemCount: _subjects.length,
//                       itemBuilder: (context, index) {
//                         final subject = _subjects[index];
//                         return ListTile(
//                           title: Text(subject['name']),
//                           onTap: () {
//                             setState(() {
//                               _selectedSubjectId = subject['id'];
//                               _students.clear();
//                             });
//                             _fetchStudents(_selectedClassId!);
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                 if (_selectedSubjectId != null && _students.isNotEmpty)
//                   Expanded(
//                     child: ListView.builder(
//                       itemCount: _students.length,
//                       itemBuilder: (context, index) {
//                         final student = _students[index];
//                         return ListTile(
//                           title: Text(student['name']),
//                         );
//                       },
//                     ),
//                   ),
//               ],
//             ),
//     );
//   }
// }