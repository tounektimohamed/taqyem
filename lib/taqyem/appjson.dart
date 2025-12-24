// // main.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'dart:convert';

// class appmed extends StatefulWidget {
//   @override
//   _appmedState createState() => _appmedState();
// }

// class _appmedState extends State<appmed> {
//   Map<String, dynamic> jsonData = {};
//   List<String> classes = [];
//   List<String> subjects = [];
//   List<BaremeItem> baremeItems = [];
//   String? selectedClass;
//   String? selectedSubject;
//   bool isLoading = true;
//   String? errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     loadJsonData();
//   }
// // Dans _appmedState (code 1), ajoutez cette méthode
// Map<String, dynamic> getClassData(String className) {
//   if (jsonData.containsKey('classes') && 
//       jsonData['classes'].containsKey(className)) {
//     return jsonData['classes'][className];
//   }
//   return {};
// }

// Map<String, dynamic> getSubjectData(String className, String subjectName) {
//   if (jsonData.containsKey('classes') && 
//       jsonData['classes'].containsKey(className)) {
//     final classData = jsonData['classes'][className];
//     if (classData.containsKey('subjects') && 
//         classData['subjects'].containsKey(subjectName)) {
//       return classData['subjects'][subjectName];
//     }
//   }
//   return {};
// }

// List<Map<String, dynamic>> getCriteriaForSubject(String className, String subjectName) {
//   final subjectData = getSubjectData(className, subjectName);
//   if (subjectData.containsKey('criteria') && 
//       subjectData['has_criteria'] == true) {
//     return List<Map<String, dynamic>>.from(subjectData['criteria']);
//   }
//   return [];
// }
//   Future<void> loadJsonData() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });

//     try {
//       // تحميل ملف JSON
//       final jsonString = await rootBundle.loadString('assets/evaluation_excel.json');
      
//       if (jsonString.trim().isEmpty) {
//         throw Exception('ملف JSON فارغ');
//       }
      
//       jsonData = json.decode(jsonString);
      
//       print('تم تحميل بيانات JSON بنجاح');
//       print('المفاتيح الرئيسية: ${jsonData.keys.toList()}');
      
//       // استخراج قوائم الصفوف من البيانات
//       classes = [];
//       if (jsonData.containsKey('classes')) {
//         final classesMap = jsonData['classes'] as Map<String, dynamic>;
//         classes = classesMap.keys.toList();
//         print('الصفوف المتاحة: $classes');
//         print('عدد الصفوف: ${classes.length}');
//       } else {
//         print('لم يتم العثور على مفتاح "classes" في JSON');
//       }
      
//       // استخراج قائمة المواد الفريدة
//       subjects = [];
//       final subjectNames = <String>{};
      
//       if (jsonData.containsKey('classes')) {
//         final classesMap = jsonData['classes'] as Map<String, dynamic>;
        
//         classesMap.forEach((className, classData) {
//           print('جاري معالجة الصف: $className');
//           if (classData is Map<String, dynamic> && classData.containsKey('subjects')) {
//             final subjectsMap = classData['subjects'] as Map<String, dynamic>;
//             print('المواد في $className: ${subjectsMap.keys.toList()}');
//             subjectNames.addAll(subjectsMap.keys);
//           }
//         });
//       }
      
//       subjects = subjectNames.toList()..sort();
//       print('المواد المتاحة: $subjects');
//       print('عدد المواد: ${subjects.length}');
      
//       // إضافة طباعة لفحص بعض المواد
//       if (subjects.isNotEmpty) {
//         print('عينة من المواد: ${subjects.take(5).toList()}');
//       }
      
//       setState(() {
//         isLoading = false;
//       });
      
//     } catch (e) {
//       print('خطأ في تحميل JSON: $e');
//       print('Stack trace: ${e.toString()}');
//       setState(() {
//         errorMessage = 'خطأ في تحميل البيانات: ${e.toString()}';
//         isLoading = false;
//         jsonData = {};
//         classes = [];
//         subjects = [];
//       });
//     }
//   }

//   void filterData() {
//     if (selectedClass == null || selectedSubject == null) {
//       setState(() {
//         baremeItems = [];
//       });
//       return;
//     }
    
//     setState(() {
//       baremeItems = [];
//     });
    
//     try {
//       // الحصول على بيانات المادة المحددة للصف المحدد
//       if (jsonData.containsKey('classes') && 
//           jsonData['classes'].containsKey(selectedClass)) {
        
//         final classData = jsonData['classes'][selectedClass] as Map<String, dynamic>;
        
//         if (classData.containsKey('subjects') && 
//             (classData['subjects'] as Map<String, dynamic>).containsKey(selectedSubject)) {
          
//           final subjectsMap = classData['subjects'] as Map<String, dynamic>;
//           final subjectData = subjectsMap[selectedSubject] as Map<String, dynamic>;
          
//           final bool hasCriteria = subjectData['has_criteria'] ?? false;
          
//           if (!hasCriteria || subjectData['criteria'] == null) {
//             print('لا توجد معايير لهذه المادة');
//             return;
//           }
          
//           final criteriaList = subjectData['criteria'] as List<dynamic>;
//           print('عدد المعايير: ${criteriaList.length}');
          
//           List<BaremeItem> items = [];
          
//           // معالجة كل معيار
//           for (int i = 0; i < criteriaList.length; i++) {
//             final criteria = criteriaList[i] as Map<String, dynamic>;
//             final criteriaName = criteria['name']?.toString() ?? 'معيار ${i + 1}';
//             final criteriaNumber = 'مع ${i + 1}';
            
//             // إضافة عنوان المعيار
//             items.add(BaremeItem(
//               isHeader: true,
//               bareme: criteriaNumber,
//               baremeKey: criteriaName,
//             ));
            
//             // معالجة المؤشرات داخل المعيار
//             final indicators = criteria['indicators'] as List<dynamic>?;
//             if (indicators != null && indicators.isNotEmpty) {
//               for (int j = 0; j < indicators.length; j++) {
//                 final indicatorText = indicators[j]?.toString() ?? '';
//                 if (indicatorText.isNotEmpty) {
//                   items.add(BaremeItem(
//                     isHeader: false,
//                     bareme: criteriaNumber,
//                     sousBareme: '${i + 1}.${j + 1}',
//                     critere: criteriaName,
//                     indicateur: indicatorText,
//                     className: selectedClass,
//                     subjectName: selectedSubject,
//                     index: j + 1,
//                   ));
//                 }
//               }
//             }
//           }
          
//           setState(() {
//             baremeItems = items;
//           });
          
//           print('تم تحميل ${baremeItems.length} عنصر (${baremeItems.where((item) => item.isHeader).length} معيار)');
//         } else {
//           print('لا توجد بيانات للمادة $selectedSubject في الصف $selectedClass');
//         }
//       } else {
//         print('لا توجد بيانات للصف $selectedClass');
//       }
//     } catch (e) {
//       print('خطأ في معالجة البيانات: $e');
//       print('Stack trace: ${e.toString()}');
//       setState(() {
//         baremeItems = [];
//       });
//     }
//   }

//   void onClassChanged(String? value) {
//     setState(() {
//       selectedClass = value;
//       selectedSubject = null; // إعادة تعيين المادة عند تغيير الصف
//       baremeItems = [];
//     });
//   }

//   void onSubjectChanged(String? value) {
//     setState(() {
//       selectedSubject = value;
//     });
//     filterData();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('نظام تقييم المعايير البيداغوجية'),
//         centerTitle: true,
//         backgroundColor: Colors.blue[700],
//       ),
//       body: isLoading
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 16),
//                   Text(
//                     'جاري تحميل البيانات...',
//                     style: TextStyle(fontSize: 16, color: Colors.blue),
//                   ),
//                 ],
//               ),
//             )
//           : errorMessage != null
//               ? Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.error_outline, size: 64, color: Colors.red),
//                       SizedBox(height: 16),
//                       Text(
//                         'حدث خطأ في تحميل البيانات',
//                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                       ),
//                       SizedBox(height: 8),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 32),
//                         child: Text(
//                           errorMessage!,
//                           textAlign: TextAlign.center,
//                           style: TextStyle(color: Colors.grey),
//                         ),
//                       ),
//                       SizedBox(height: 16),
//                       ElevatedButton.icon(
//                         onPressed: loadJsonData,
//                         icon: Icon(Icons.refresh),
//                         label: Text('إعادة المحاولة'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue,
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               : Column(
//                   children: [
//                     // منطقة اختيار الصف والمادة
//                     Container(
//                       padding: EdgeInsets.all(16),
//                       color: Colors.blue[50],
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: DropdownButtonFormField<String>(
//                               value: selectedClass,
//                               decoration: InputDecoration(
//                                 labelText: 'اختر الصف',
//                                 border: OutlineInputBorder(),
//                                 filled: true,
//                                 fillColor: Colors.white,
//                               ),
//                               items: [
//                                 DropdownMenuItem<String>(
//                                   value: null,
//                                   child: Text('اختر الصف', style: TextStyle(color: Colors.grey)),
//                                 ),
//                                 ...classes.map<DropdownMenuItem<String>>((value) {
//                                   return DropdownMenuItem<String>(
//                                     value: value,
//                                     child: Text(value),
//                                   );
//                                 }).toList(),
//                               ],
//                               onChanged: onClassChanged,
//                             ),
//                           ),
//                           SizedBox(width: 16),
//                           Expanded(
//                             child: DropdownButtonFormField<String>(
//                               value: selectedSubject,
//                               decoration: InputDecoration(
//                                 labelText: 'اختر المادة',
//                                 border: OutlineInputBorder(),
//                                 filled: true,
//                                 fillColor: Colors.white,
//                               ),
//                               items: [
//                                 DropdownMenuItem<String>(
//                                   value: null,
//                                   child: Text('اختر المادة', style: TextStyle(color: Colors.grey)),
//                                 ),
//                                 ...subjects.map<DropdownMenuItem<String>>((value) {
//                                   return DropdownMenuItem<String>(
//                                     value: value,
//                                     child: Text(value),
//                                   );
//                                 }).toList(),
//                               ],
//                               onChanged: onSubjectChanged,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
                    
//                     // عرض الإحصائيات
//                     if (selectedClass != null && selectedSubject != null)
//                       Container(
//                         padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                         color: Colors.green[50],
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Row(
//                               children: [
//                                 Icon(Icons.school, size: 16, color: Colors.green[800]),
//                                 SizedBox(width: 4),
//                                 Text(
//                                   'الصف: $selectedClass',
//                                   style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800]),
//                                 ),
//                               ],
//                             ),
//                             Row(
//                               children: [
//                                 Icon(Icons.book, size: 16, color: Colors.green[800]),
//                                 SizedBox(width: 4),
//                                 Text(
//                                   'المادة: $selectedSubject',
//                                   style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800]),
//                                 ),
//                               ],
//                             ),
//                             Row(
//                               children: [
//                                 Icon(Icons.list_alt, size: 16, color: Colors.green[800]),
//                                 SizedBox(width: 4),
//                                 Text(
//                                   'عدد المعايير: ${baremeItems.where((item) => item.isHeader).length}',
//                                   style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800]),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
                    
//                     // رسالة إذا لم يتم تحديد اختيار
//                     if (selectedClass == null || selectedSubject == null)
//                       Expanded(
//                         child: Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.filter_list, size: 80, color: Colors.blue),
//                               SizedBox(height: 20),
//                               Text(
//                                 'اختر الصف والمادة لعرض المعايير',
//                                 style: TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.bold),
//                               ),
//                               SizedBox(height: 10),
//                               Text(
//                                 '${classes.length} صف متاح | ${subjects.length} مادة متاحة',
//                                 style: TextStyle(fontSize: 14, color: Colors.grey),
//                               ),
//                               SizedBox(height: 20),
//                               Wrap(
//                                 spacing: 8,
//                                 runSpacing: 8,
//                                 children: [
//                                   Chip(
//                                     label: Text('${classes.length} صف'),
//                                     backgroundColor: Colors.blue[100],
//                                   ),
//                                   Chip(
//                                     label: Text('${subjects.length} مادة'),
//                                     backgroundColor: Colors.green[100],
//                                   ),
//                                 ],
//                               ),
//                               SizedBox(height: 20),
//                               if (subjects.isNotEmpty)
//                                 Container(
//                                   padding: EdgeInsets.all(16),
//                                   margin: EdgeInsets.symmetric(horizontal: 20),
//                                   decoration: BoxDecoration(
//                                     color: Colors.grey[100],
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         'بعض المواد المتاحة:',
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.blue,
//                                         ),
//                                       ),
//                                       SizedBox(height: 8),
//                                       Wrap(
//                                         spacing: 8,
//                                         runSpacing: 8,
//                                         children: subjects.take(10).map((subject) {
//                                           return Chip(
//                                             label: Text(subject),
//                                             backgroundColor: Colors.blue[50],
//                                           );
//                                         }).toList(),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                             ],
//                           ),
//                         ),
//                       )
//                     else if (baremeItems.isEmpty)
//                       Expanded(
//                         child: Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.search_off, size: 80, color: Colors.orange),
//                               SizedBox(height: 20),
//                               Text(
//                                 'لا توجد معايير للصف والمادة المختارين',
//                                 style: TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold),
//                               ),
//                               SizedBox(height: 10),
//                               Text(
//                                 'يرجى اختيار صف ومادة آخرين',
//                                 style: TextStyle(fontSize: 14, color: Colors.grey),
//                               ),
//                               SizedBox(height: 20),
//                               ElevatedButton(
//                                 onPressed: () {
//                                   setState(() {
//                                     selectedClass = null;
//                                     selectedSubject = null;
//                                   });
//                                 },
//                                 child: Text('تغيير الاختيار'),
//                               ),
//                             ],
//                           ),
//                         ),
//                       )
//                     else
//                       Expanded(
//                         child: ListView.builder(
//                           itemCount: baremeItems.length,
//                           itemBuilder: (context, index) {
//                             final item = baremeItems[index];
                            
//                             if (item.isHeader) {
//                               return Container(
//                                 padding: EdgeInsets.all(16),
//                                 margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     colors: [Colors.blue[700]!, Colors.blue[800]!],
//                                     begin: Alignment.topLeft,
//                                     end: Alignment.bottomRight,
//                                   ),
//                                   borderRadius: BorderRadius.circular(10),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.blue.withOpacity(0.3),
//                                       blurRadius: 5,
//                                       offset: Offset(0, 3),
//                                     ),
//                                   ],
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     Container(
//                                       width: 40,
//                                       height: 40,
//                                       decoration: BoxDecoration(
//                                         color: Colors.white,
//                                         shape: BoxShape.circle,
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color: Colors.black.withOpacity(0.1),
//                                             blurRadius: 3,
//                                             offset: Offset(0, 2),
//                                           ),
//                                         ],
//                                       ),
//                                       child: Center(
//                                         child: Text(
//                                           item.bareme.replaceAll('مع ', ''),
//                                           style: TextStyle(
//                                             color: Colors.blue[700],
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     SizedBox(width: 16),
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             item.baremeKey,
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontSize: 18,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                           SizedBox(height: 4),
//                                           Text(
//                                             'يشمل ${baremeItems.where((i) => !i.isHeader && i.bareme == item.bareme).length} مؤشر فرعي',
//                                             style: TextStyle(
//                                               color: Colors.white.withOpacity(0.9),
//                                               fontSize: 12,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                     Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
//                                   ],
//                                 ),
//                               );
//                             } else {
//                               return Card(
//                                 margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
//                                 elevation: 2,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                   side: BorderSide(color: Colors.grey[200]!, width: 1),
//                                 ),
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(16),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           Container(
//                                             width: 50,
//                                             height: 50,
//                                             decoration: BoxDecoration(
//                                               color: Colors.blue[50],
//                                               borderRadius: BorderRadius.circular(25),
//                                               border: Border.all(color: Colors.blue, width: 2),
//                                             ),
//                                             child: Center(
//                                               child: Text(
//                                                 item.sousBareme,
//                                                 style: TextStyle(
//                                                   color: Colors.blue[700],
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 16,
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                           SizedBox(width: 16),
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment: CrossAxisAlignment.start,
//                                               children: [
//                                                 Container(
//                                                   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                                                   decoration: BoxDecoration(
//                                                     color: Colors.green[50],
//                                                     borderRadius: BorderRadius.circular(6),
//                                                     border: Border.all(color: Colors.green),
//                                                   ),
//                                                   child: Row(
//                                                     mainAxisSize: MainAxisSize.min,
//                                                     children: [
//                                                       Icon(Icons.category, size: 14, color: Colors.green[800]),
//                                                       SizedBox(width: 6),
//                                                       Flexible(
//                                                         child: Text(
//                                                           item.critere,
//                                                           style: TextStyle(
//                                                             fontSize: 13,
//                                                             color: Colors.green[800],
//                                                             fontWeight: FontWeight.bold,
//                                                           ),
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ),
//                                                 SizedBox(height: 12),
//                                                 Text(
//                                                   item.indicateur,
//                                                   style: TextStyle(
//                                                     fontSize: 15,
//                                                     height: 1.5,
//                                                     color: Colors.grey[800],
//                                                   ),
//                                                 ),
//                                                 SizedBox(height: 12),
//                                                 Divider(height: 1, color: Colors.grey[200]),
//                                                 SizedBox(height: 8),
//                                                 Row(
//                                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                                   children: [
//                                                     Row(
//                                                       children: [
//                                                         Icon(Icons.format_list_numbered, size: 14, color: Colors.grey),
//                                                         SizedBox(width: 4),
//                                                         Text(
//                                                           'المؤشر ${item.index}',
//                                                           style: TextStyle(
//                                                             fontSize: 12,
//                                                             color: Colors.grey[600],
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     Row(
//                                                       children: [
//                                                         Icon(Icons.check_circle_outline, size: 14, color: Colors.grey),
//                                                         SizedBox(width: 4),
//                                                         Text(
//                                                           'معيار ${item.bareme}',
//                                                           style: TextStyle(
//                                                             fontSize: 12,
//                                                             color: Colors.grey[600],
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             }
//                           },
//                         ),
//                       ),
//                   ],
//                 ),
//       floatingActionButton: selectedClass != null && selectedSubject != null
//           ? FloatingActionButton.extended(
//               onPressed: () {
//                 showDialog(
//                   context: context,
//                   builder: (context) => AlertDialog(
//                     title: Row(
//                       children: [
//                         Icon(Icons.more_vert, color: Colors.blue),
//                         SizedBox(width: 8),
//                         Text('خيارات إضافية'),
//                       ],
//                     ),
//                     content: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         ListTile(
//                           leading: Icon(Icons.print, color: Colors.blue),
//                           title: Text('طباعة الجدول'),
//                           onTap: () {
//                             Navigator.pop(context);
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text('جارٍ إعداد الطباعة...'),
//                                 backgroundColor: Colors.blue,
//                               ),
//                             );
//                           },
//                         ),
//                         Divider(),
//                         ListTile(
//                           leading: Icon(Icons.save_alt, color: Colors.green),
//                           title: Text('حفظ كملف Excel'),
//                           onTap: () {
//                             Navigator.pop(context);
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text('جارٍ إعداد ملف Excel...'),
//                                 backgroundColor: Colors.green,
//                               ),
//                             );
//                           },
//                         ),
//                         Divider(),
//                         ListTile(
//                           leading: Icon(Icons.share, color: Colors.orange),
//                           title: Text('مشاركة النتائج'),
//                           onTap: () {
//                             Navigator.pop(context);
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text('جارٍ إعداد المشاركة...'),
//                                 backgroundColor: Colors.orange,
//                               ),
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                     actions: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: Text('إلغاء'),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//               icon: Icon(Icons.more_horiz),
//               label: Text('خيارات'),
//               backgroundColor: Colors.blue,
//             )
//           : null,
//     );
//   }
// }

// class BaremeItem {
//   final bool isHeader;
//   final String bareme;
//   final String baremeKey;
//   final String sousBareme;
//   final String critere;
//   final String indicateur;
//   final String? className;
//   final String? subjectName;
//   final int? index;

//   BaremeItem({
//     required this.isHeader,
//     required this.bareme,
//     this.baremeKey = '',
//     this.sousBareme = '',
//     this.critere = '',
//     this.indicateur = '',
//     this.className,
//     this.subjectName,
//     this.index,
//   });
// }