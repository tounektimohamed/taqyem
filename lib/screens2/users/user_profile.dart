import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../components/text_field.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

enum Genders { male, female, other }

class _UserProfileState extends State<UserProfile> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool isLoading = false;
  bool isEditing = false;

  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _nicController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();

  Genders? _genderSelected;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.email)
          .get();

      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;

        setState(() {
          _nameController.text = userData['name'] ?? '';
          _dobController.text = userData['dob'] ?? '';
          _genderController.text = userData['gender'] ?? '';
          _nicController.text = userData['nic'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _mobileController.text = userData['mobile'] ?? '';
        });
      }
    } catch (e) {
      print('خطأ في جلب بيانات المستخدم: $e');
    }
  }

  Future<void> updateProfile() async {
    if (!_validateForm()) return;

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.email)
          .set({
        'name': _nameController.text,
        'dob': _dobController.text,
        'gender': _genderController.text,
        'nic': _nicController.text,
        'address': _addressController.text,
        'mobile': _mobileController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: Duration(seconds: 3),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تم تحديث بياناتك بنجاح',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Text('خطأ في تحديث البيانات: $e'),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  bool _validateForm() {
    if (_nameController.text.isEmpty) {
      _showError('الرجاء إدخال الاسم الكامل');
      return false;
    }
    if (_mobileController.text.isEmpty) {
      _showError('الرجاء إدخال رقم الهاتف');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الملف الشخصي',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDarkMode ? Colors.white : primaryColor,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.close_rounded : Icons.edit_rounded),
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
              });
            },
            tooltip: isEditing ? 'إلغاء التعديل' : 'تعديل',
          ),
        ],
      ),
      body: Container(
        color: isDarkMode ? Colors.grey[900] : Color(0xFFF8FAFD),
        child: Column(
          children: [
            // Header Section
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor.withOpacity(0.1),
                    primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryColor.withOpacity(0.2),
                        child: currentUser?.photoURL?.isEmpty ?? true
                            ? Icon(
                                Icons.person_rounded,
                                size: 60,
                                color: primaryColor,
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.network(
                                  currentUser!.photoURL!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      if (isEditing)
                        Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 5,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 20),
                            onPressed: () {
                              // Add camera/photo picker logic
                            },
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Text(
                    currentUser?.displayName ?? _nameController.text,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    currentUser?.email ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  if (!isEditing)
                    Container(
                      margin: EdgeInsets.only(top: 15),
                      padding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'معلومات للقراءة فقط',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Form Section
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information Section
                    _buildSectionTitle('المعلومات الأساسية'),
                    SizedBox(height: 15),

                    // Name Field
                    _buildEditableField(
                      label: 'الاسم الكامل',
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      isEditing: isEditing,
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: 15),

                    // Date of Birth Field
                    _buildDateField(),
                    SizedBox(height: 15),

                    // Gender Field
                    _buildGenderField(),
                    SizedBox(height: 15),

                    // NIC Field
                    _buildEditableField(
                      label: 'رقم البطاقة الوطنية',
                      controller: _nicController,
                      icon: Icons.credit_card_rounded,
                      isEditing: isEditing,
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: 25),

                    // Contact Information Section
                    _buildSectionTitle('معلومات الاتصال'),
                    SizedBox(height: 15),

                    // Address Field
                    _buildEditableField(
                      label: 'العنوان',
                      controller: _addressController,
                      icon: Icons.location_on_rounded,
                      isEditing: isEditing,
                      keyboardType: TextInputType.streetAddress,
                      maxLines: 2,
                    ),
                    SizedBox(height: 15),

                    // Mobile Number Field
                    _buildEditableField(
                      label: 'رقم الهاتف',
                      controller: _mobileController,
                      icon: Icons.phone_rounded,
                      isEditing: isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 30),

                    // Save Button (only shown when editing)
                    if (isEditing) _buildSaveButton(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditing,
    required TextInputType keyboardType,
    int maxLines = 1,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: isEditing
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        enabled: isEditing,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.cairo(
          fontSize: 15,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(
            color: isEditing
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[600],
          ),
          prefixIcon: Icon(
            icon,
            color: isEditing
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[600],
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: false,
          suffixIcon: !isEditing
              ? null
              : controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, size: 20),
                      onPressed: () => controller.clear(),
                    )
                  : null,
        ),
      ),
    );
  }

  Widget _buildDateField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: isEditing
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _dobController,
        readOnly: true,
        enabled: isEditing,
        onTap: isEditing
            ? () async {
                var datePicked = await DatePicker.showSimpleDatePicker(
                  context,
                  titleText: 'اختر تاريخ الميلاد',
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2099),
                  dateFormat: "dd-MMMM-yyyy",
                  locale: DateTimePickerLocale.ar,
                  looping: true,
                );
                if (datePicked != null) {
                  String date =
                      '${datePicked.day}-${datePicked.month}-${datePicked.year}';
                  setState(() {
                    _dobController.text = date;
                  });
                }
              }
            : null,
        style: GoogleFonts.cairo(
          fontSize: 15,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: 'تاريخ الميلاد',
          labelStyle: GoogleFonts.cairo(
            color: isEditing
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.calendar_today_rounded,
            color: isEditing
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[600],
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixText: isEditing ? 'انقر للاختيار' : null,
          suffixStyle: GoogleFonts.cairo(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: isEditing
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _genderController,
        readOnly: true,
        enabled: isEditing,
        onTap: isEditing
            ? () => showDialog(
                  context: context,
                  builder: (context) => Directionality(
                    textDirection: TextDirection.rtl,
                    child: AlertDialog(
                      title: Text(
                        'اختر الجنس',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      content: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              RadioListTile(
                                value: Genders.male,
                                title: Text('ذكر'),
                                groupValue: _genderSelected,
                                onChanged: (value) {
                                  setState(() {
                                    _genderSelected = value as Genders;
                                    _genderController.text = 'ذكر';
                                    Navigator.of(context).pop();
                                  });
                                },
                                activeColor: Theme.of(context).colorScheme.primary,
                              ),
                              RadioListTile(
                                value: Genders.female,
                                title: Text('أنثى'),
                                groupValue: _genderSelected,
                                onChanged: (value) {
                                  setState(() {
                                    _genderSelected = value as Genders;
                                    _genderController.text = 'أنثى';
                                    Navigator.of(context).pop();
                                  });
                                },
                                activeColor: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                )
            : null,
        style: GoogleFonts.cairo(
          fontSize: 15,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: 'الجنس',
          labelStyle: GoogleFonts.cairo(
            color: isEditing
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.person_outline_rounded,
            color: isEditing
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[600],
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixText: isEditing ? 'انقر للاختيار' : null,
          suffixStyle: GoogleFonts.cairo(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isLoading ? null : updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.symmetric(vertical: 15),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'حفظ التغييرات',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _nicController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    super.dispose();
  }
}