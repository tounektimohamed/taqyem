import 'package:Taqyem/screens2/login_signup/AboutApp.dart';
import 'package:Taqyem/screens2/login_signup/rating_page.dart';
import 'package:Taqyem/screens2/login_signup/sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Taqyem/components/language.dart';
import 'package:Taqyem/components/language_constants.dart';
import 'package:Taqyem/screens2/app%20option%20setting/help_center.dart';
import 'package:Taqyem/screens2/app%20option%20setting/termsNconditions.dart';
import 'package:Taqyem/screens2/users/user_profile.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPageUI extends StatefulWidget {
  const SettingsPageUI({super.key});

  @override
  _SettingPageUIState createState() => _SettingPageUIState();
}

class _SettingPageUIState extends State<SettingsPageUI> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  User? currentUser = FirebaseAuth.instance.currentUser;

  // متغيرات لتخزين بيانات المستخدم
  String? userName;
  String? userEmail;
  String? userDisplayName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (currentUser != null) {
      try {
        // جلب بيانات المستخدم من Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser!
                .email) // أو currentUser!.uid حسب كيفية تخزينك للبيانات
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          setState(() {
            userName =
                userData['name'] ?? currentUser!.displayName ?? 'المستخدم';
            userEmail = currentUser!.email ?? 'بريد إلكتروني';
            userDisplayName = userData['name'] ??
                currentUser!.displayName ??
                currentUser!.email?.split('@').first ??
                'المستخدم';
            _isLoading = false;
          });
        } else {
          // إذا لم توجد بيانات في Firestore، استخدم بيانات Firebase Auth
          setState(() {
            userName = currentUser!.displayName ?? 'المستخدم';
            userEmail = currentUser!.email ?? 'بريد إلكتروني';
            userDisplayName = currentUser!.displayName ??
                currentUser!.email?.split('@').first ??
                'المستخدم';
            _isLoading = false;
          });
        }
      } catch (e) {
        print('خطأ في جلب بيانات المستخدم: $e');
        // في حالة الخطأ، استخدم بيانات Firebase Auth فقط
        setState(() {
          userName = currentUser!.displayName ?? 'المستخدم';
          userEmail = currentUser!.email ?? 'بريد إلكتروني';
          userDisplayName = currentUser!.displayName ??
              currentUser!.email?.split('@').first ??
              'المستخدم';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: isDarkMode ? Colors.white : primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                // User Profile Card
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor.withOpacity(0.9),
                            secondaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: currentUser?.photoURL != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(35),
                                      child: Image.network(
                                        currentUser!.photoURL!,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userDisplayName!,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    userEmail!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 5),
                                  if (userName != null &&
                                      userName != userDisplayName)
                                    Text(
                                      'اسم المستخدم: $userName',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.white),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const UserProfile(),
                                  ),
                                ).then((_) {
                                  // إعادة تحميل البيانات بعد العودة من تعديل الملف الشخصي
                                  _fetchUserData();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 10),

                // Settings List
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: isDarkMode
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 20,
                                offset: Offset(0, -5),
                              ),
                            ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: SettingsList(
                        lightTheme: SettingsThemeData(
                          settingsListBackground: Colors.transparent,
                          leadingIconsColor: primaryColor,
                          tileHighlightColor: primaryColor.withOpacity(0.1),
                        ),
                        darkTheme: SettingsThemeData(
                          settingsListBackground: Colors.transparent,
                          leadingIconsColor: Colors.white,
                          tileHighlightColor: Colors.white.withOpacity(0.1),
                        ),
                        shrinkWrap: true,
                        sections: [
                          // Account Settings Section
                          SettingsSection(
                            title: Transform.translate(
                              offset: Offset(20, 0),
                              child: Text(
                                'إعدادات الحساب',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            tiles: [
                              SettingsTile.navigation(
                                leading: Icon(
                                  Icons.person_outline_rounded,
                                  color: primaryColor,
                                ),
                                title: Text(
                                  'الملف الشخصي',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                description: Text(
                                  'تعديل معلومات حسابك الشخصية',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 18,
                                  color: Colors.grey[500],
                                ),
                                onPressed: (context) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const UserProfile(),
                                    ),
                                  ).then((_) {
                                    // إعادة تحميل البيانات بعد العودة
                                    _fetchUserData();
                                  });
                                },
                              ),
                            ],
                          ),

                          // Support Section
                          SettingsSection(
                            title: Transform.translate(
                              offset: Offset(20, 0),
                              child: Text(
                                'الدعم والمساعدة',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            tiles: [
                              SettingsTile.navigation(
                                leading: Icon(
                                  Icons.help_outline_rounded,
                                  color: primaryColor,
                                ),
                                title: Text(
                                  'مركز المساعدة',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 18,
                                  color: Colors.grey[500],
                                ),
                                onPressed: (context) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HelpCenter(),
                                    ),
                                  );
                                },
                              ),
                              SettingsTile.navigation(
                                leading: Icon(
                                  Icons.description_rounded,
                                  color: primaryColor,
                                ),
                                title: Text(
                                  'الشروط والأحكام',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 18,
                                  color: Colors.grey[500],
                                ),
                                onPressed: (context) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TermsAndConditions(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          // About Section
                          SettingsSection(
                            title: Transform.translate(
                              offset: Offset(20, 0),
                              child: Text(
                                'حول التطبيق',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            tiles: [
                              SettingsTile.navigation(
                                leading: Icon(
                                  Icons.info_rounded,
                                  color: primaryColor,
                                ),
                                title: Text(
                                  'عن التطبيق',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 18,
                                  color: Colors.grey[500],
                                ),
                                onPressed: (context) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AboutApp(),
                                    ),
                                  );
                                },
                              ),
                              SettingsTile.navigation(
                                leading: Icon(
                                  Icons.star_rounded,
                                  color: primaryColor,
                                ),
                                title: Text(
                                  'قيم التطبيق',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 18,
                                  color: Colors.grey[500],
                                ),
                                onPressed: (context) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RatingPage(),
                                    ),
                                  );
                                },
                                
                              ),
                              SettingsTile(
                                leading: Icon(
                                  Icons.verified_rounded,
                                  color: primaryColor,
                                ),
                                title: Text(
                                  'الإصدار',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                trailing: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '1.0.0',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Dangerous Actions Section
                          SettingsSection(
                            title: Transform.translate(
                              offset: Offset(20, 0),
                              
                            ),
                            tiles: [
                              SettingsTile(
                                leading: Icon(
                                  Icons.logout_rounded,
                                  color: Colors.red,
                                ),
                                title: Text(
                                  'تسجيل الخروج',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.red,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 18,
                                  color: Colors.red.withOpacity(0.7),
                                ),
                                onPressed: (context) {
                                  _showLogoutConfirmation(context);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
              SizedBox(height: 10),
              Text(
                'ستحتاج لإدخال بيانات الدخول مرة أخرى للوصول إلى حسابك.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SignIn()),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ في تسجيل الخروج: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text(
                'حذف الحساب',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('هل أنت متأكد من حذف حسابك بشكل دائم؟'),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'هذا الإجراء لا يمكن التراجع عنه. سيتم حذف جميع بياناتك بشكل نهائي.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Implement account deletion logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم إرسال طلب حذف الحساب'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('حذف الحساب'),
            ),
          ],
        ),
      ),
    );
  }
}
