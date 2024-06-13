import 'package:flutter/material.dart';
import 'package:flutter_timeline_calendar/timeline/flutter_timeline_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:DREHATT_app/screens2/User%20Management.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  ValueNotifier<CalendarDateTime> _selectedDate = ValueNotifier<CalendarDateTime>(
    CalendarDateTime(year: DateTime.now().year, month: DateTime.now().month, day: DateTime.now().day),
  );

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Supprimer la flèche de retour
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'lib/assets/icons/me/logo.png',
                height: 50,
              ),
              CircleAvatar(
                backgroundImage: AssetImage('lib/assets/icons/me/admin2.gif'),
              ),
            ],
          ),
          backgroundColor: Color.fromARGB(255, 123, 176, 189),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Text "My Dashboard" under AppBar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  'My Dashboard',
                  style: GoogleFonts.roboto(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Calendar and reminder section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: TimelineCalendar(
                  calendarType: CalendarType.GREGORIAN,
                  calendarOptions: CalendarOptions(
                    viewType: ViewType.DAILY,
                    toggleViewType: true,
                    headerMonthElevation: 0,
                    headerMonthBackColor: const Color.fromARGB(255, 241, 250, 251),
                  ),
                  dayOptions: DayOptions(
                    compactMode: true,
                    dayFontSize: 15,
                    weekDaySelectedColor: Theme.of(context).colorScheme.primary,
                    selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                    disableDaysBeforeNow: false,
                    unselectedBackgroundColor: Colors.white,
                  ),
                  headerOptions: HeaderOptions(
                    weekDayStringType: WeekDayStringTypes.SHORT,
                    monthStringType: MonthStringTypes.FULL,
                    backgroundColor: const Color.fromARGB(255, 241, 250, 251),
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
                          day: DateTime.now().day);
                    });
                  },
                  dateTime: _selectedDate.value,
                ),
              ),
              
              // Date text and reminder
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _selectedDate.value.toString().substring(0, 10),
                      style: GoogleFonts.roboto(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                  ],
                ),
              ),
              
              // Dashboard items
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
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
                      'View Reports',
                      'lib/assets/icons/me/admin3.gif',
                      () {
                        // Ajouter l'action pour visualiser les rapports
                      },
                    ),
                    buildDashboardItem(
                      context,
                      'System Settings',
                      'lib/assets/icons/me/admin3.gif',
                      () {
                        // Ajouter l'action pour les paramètres du système
                      },
                    ),
                    buildDashboardItem(
                      context,
                      'Logout',
                      'lib/assets/icons/me/logout.gif',
                      () {
                        Navigator.pop(context);
                      },
                    ),
                    // Ajoutez d'autres éléments ici si nécessaire
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDashboardItem(BuildContext context, String title, String iconPath, VoidCallback onPressed) {
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
              offset: Offset(0, 3),
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
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
