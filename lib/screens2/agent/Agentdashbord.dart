import 'package:DREHATT_app/screens2/jeojson/formhtml.dart';
import 'package:DREHATT_app/screens2/users/ClaimsListPage.dart';
import 'package:DREHATT_app/screens2/jeojson/DrawShape2.dart';
import 'package:DREHATT_app/screens2/permis%20de%20bati/HousingApplicationListPage.dart';
import 'package:DREHATT_app/screens2/news/add_news_screen.dart';
import 'package:DREHATT_app/screens2/news/gerenews.dart';
import 'package:DREHATT_app/screens2/jeojson/sigweb.dart';
import 'package:DREHATT_app/screens2/jeojson/DrawShape.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_timeline_calendar/timeline/flutter_timeline_calendar.dart';
import '../login_signup/account_settings.dart';

class AgentDashboard extends StatefulWidget {
  const AgentDashboard({Key? key}) : super(key: key);

  @override
  _AgentDashboardState createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
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
          bool isDesktop =
              constraints.maxWidth > 600; // Définir un seuil pour le bureau

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec logo et icône utilisateur
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
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: currentUser?.photoURL == null
                              ? const Icon(Icons.person_outlined)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),

                // Calendrier et date sélectionnée
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
                      weekDaySelectedColor:
                          Theme.of(context).colorScheme.primary,
                      selectedBackgroundColor:
                          Theme.of(context).colorScheme.primary,
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
                          day: DateTime.now().day,
                        );
                      });
                    },
                    dateTime: _selectedDate.value,
                  ),
                ),

                // Texte de la date sélectionnée
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

                // Éléments du tableau de bord
                Padding(
                  padding: EdgeInsets.all(isDesktop ? 32 : 16),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isDesktop
                        ? 4
                        : 2, // Ajuster les colonnes en fonction de la taille de l'écran
                    crossAxisSpacing: isDesktop ? 24 : 16,
                    mainAxisSpacing: isDesktop ? 24 : 16,
                    children: [
                      buildDashboardItem(
                        context,
                        'Voir les actualités',
                        'lib/assets/icons/me/news1.gif',
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
                        'Page des réclamations',
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
                        'Liste des demandes de permis de construire',
                        'lib/assets/icons/me/maps.gif',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  HousingApplicationListPage(),
                            ),
                          );
                        },
                      ),
                      buildDashboardItem(
                        context,
                        'Ajouter une actualité',
                        'lib/assets/icons/me/news.gif',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddNewsScreen(),
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
                                  title:
                                      'Sig web'), // Ajouter le paramètre de titre requis
                            ),
                          );
                        },
                      ),
                      buildDashboardItem(
                        context,
                        'Permis de construire',
                        'lib/assets/icons/me/plan.png',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MapDrawingPage(), // Ajouter le paramètre de titre requis
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
                              builder: (context) => CombinedMapPage(),
                            ),
                          );
                        },
                      ),
                       buildDashboardItem(
                        context,
                        'Ajouter tiff ',
                        'lib/assets/icons/me/plan.png',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddHtmlFormPage(), // Ajouter le paramètre de titre requis
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
                fontSize: MediaQuery.of(context).size.width > 600
                    ? 18
                    : 16, // Ajuster la taille de la police pour la réactivité
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
