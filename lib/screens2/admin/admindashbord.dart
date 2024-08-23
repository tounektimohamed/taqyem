import 'package:DREHATT_app/landing/views/ManageCarouselItemsPage.dart';
import 'package:DREHATT_app/screens2/jeojson/DrawShape.dart';
import 'package:DREHATT_app/screens2/jeojson/DrawShape2.dart';
import 'package:DREHATT_app/screens2/jeojson/sigweb.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_timeline_calendar/timeline/flutter_timeline_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';

// Import other necessary files
import 'package:DREHATT_app/screens2/admin/AccessLogsPage.dart';
import 'package:DREHATT_app/screens2/users/ClaimsListPage.dart';
import 'package:DREHATT_app/screens2/permis%20de%20bati/HousingApplicationForm.dart';
import 'package:DREHATT_app/screens2/permis%20de%20bati/HousingApplicationListPage.dart';
import 'package:DREHATT_app/screens2/jeojson/SubscribersPage.dart';
import 'package:DREHATT_app/screens2/news/gerenews.dart';
import 'package:DREHATT_app/screens2/users/User%20Management.dart';
import '../login_signup/account_settings.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ValueNotifier<CalendarDateTime> _selectedDate =
      ValueNotifier<CalendarDateTime>(
    CalendarDateTime(
      year: DateTime.now().year,
      month: DateTime.now().month,
      day: DateTime.now().day,
    ),
  );

  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 600; // Define a breakpoint for desktop

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with logo and user icon
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 20,
                    vertical: isDesktop ? 20 : 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'lib/assets/icons/me/logo.png',
                        height: isDesktop ? 80 : 50,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPageUI(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: isDesktop ? 30 : 20,
                          backgroundImage: currentUser?.photoURL != null
                              ? NetworkImage(currentUser!.photoURL!)
                              : null,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: currentUser?.photoURL == null
                              ? const Icon(Icons.person_outlined)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),

                // Calendar and selected date
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 20,
                    vertical: isDesktop ? 30 : 20,
                  ),
                  child: TimelineCalendar(
                    calendarType: CalendarType.GREGORIAN,
                    calendarOptions: CalendarOptions(
                      viewType: ViewType.DAILY,
                      toggleViewType: true,
                      headerMonthElevation: 0,
                      headerMonthBackColor:
                          const Color.fromARGB(255, 241, 250, 251),
                    ),
                    dayOptions: DayOptions(
                      compactMode: true,
                      dayFontSize: isDesktop ? 18 : 15,
                      weekDaySelectedColor: Theme.of(context).colorScheme.primary,
                      selectedBackgroundColor:
                          Theme.of(context).colorScheme.primary,
                      disableDaysBeforeNow: false,
                      unselectedBackgroundColor: Colors.white,
                    ),
                    headerOptions: HeaderOptions(
                      weekDayStringType: WeekDayStringTypes.SHORT,
                      monthStringType: MonthStringTypes.FULL,
                      backgroundColor:
                          const Color.fromARGB(255, 241, 250, 251),
                      headerTextColor: Colors.black,
                    ),
                    onChangeDateTime: (date) {
                      setState(() {
                        _selectedDate.value = date;
                      });
                    },
                    onDateTimeReset: (p0) {
                      setState(() {
                        _selectedDate.value = CalendarDateTime(
                          year: DateTime.now().year,
                          month: DateTime.now().month,
                          day: DateTime.now().day,
                        );
                      });
                    },
                    dateTime: _selectedDate.value,
                  ),
                ),

                // Selected date text
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 20,
                    vertical: isDesktop ? 20 : 10,
                  ),
                  child: Text(
                    _selectedDate.value.toString().substring(0, 10),
                    style: GoogleFonts.roboto(
                      fontSize: isDesktop ? 30 : 25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Dashboard items
                Padding(
                  padding: EdgeInsets.all(isDesktop ? 32 : 16),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isDesktop ? 4 : 2, // Adjust columns based on screen size
                    crossAxisSpacing: isDesktop ? 24 : 16,
                    mainAxisSpacing: isDesktop ? 24 : 16,
                    children: [
                      buildDashboardItem(
                        context,
                        'User Management',
                        'lib/assets/icons/me/menagment.gif',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserManagement(),
                            ),
                          );
                        },
                      ),
                      buildDashboardItem(
                        context,
                        'View News',
                        'lib/assets/icons/me/admin1.gif',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GereListPage(),
                            ),
                          );
                        },
                      ),
                      buildDashboardItem(
                        context,
                        'View Access Logs',
                        'lib/assets/icons/me/admin1.gif',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AccessLogsPage(),
                            ),
                          );
                        },
                      ),
                      buildDashboardItem(
                        context,
                        'View Subscribers',
                        'lib/assets/icons/me/subscribers.gif',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SubscribersPage(),
                            ),
                          );
                        },
                      ),
                      buildDashboardItem(
                        context,
                        'Claims List Page',
                        'lib/assets/icons/me/subscribers.gif',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClaimsListPage(),
                            ),
                          );
                        },
                      ),
                      buildDashboardItem(
                        context,
                        'Housing Applications',
                        'lib/assets/icons/me/maps.gif',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HousingApplicationListPage(),
                            ),
                          );
                        },
                      ),
                      buildDashboardItem(
                        context,
                        'Manage Carousel',
                        'lib/assets/icons/me/caroussel.png',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageCarouselItemsPage(),
                            ),
                          );
                        },
                      ),
                      buildDashboardItem(
                        context,
                        'Zone d’affichage des couches',
                        'lib/assets/icons/me/caroussel.png',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SigWeb(
                                  title: 'Sig web'),
                            ),
                          );
                        },
                      ),
                      buildDashboardItem(
                        context,
                        'Suivi des PAUS',
                        'lib/assets/icons/me/caroussel.png',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SigWeb(
                                  title: 'Sig web'), // Add the required title parameter
                            ),
                          );
                        },
                      ),
                      buildDashboardItem(
                        context,
                        'Permis de batis',
                        'lib/assets/icons/me/plan.png',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MapDrawingPage(), // Add the required title parameter
                            ),
                          );
                        },
                      ),
                      buildDashboardItem(
                        context,
                        'Suivi des plans de lotissement',
                        'lib/assets/icons/me/plan.png',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CombinedMapPage(), // Add the required title parameter
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildDashboardItem(BuildContext context, String title, String iconPath,
      VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: 70,
              height: 70,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16, // Adjust font size for responsiveness
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

