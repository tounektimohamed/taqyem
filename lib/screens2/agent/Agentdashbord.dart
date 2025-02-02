import 'package:Taqyem/screens2/admin/AccessLogsPage.dart';
import 'package:Taqyem/screens2/jeojson/formhtml.dart';
import 'package:Taqyem/screens2/users/ClaimsListPage.dart';
import 'package:Taqyem/screens2/jeojson/DrawShape2.dart';
import 'package:Taqyem/screens2/permis%20de%20bati/HousingApplicationListPage.dart';
import 'package:Taqyem/screens2/news/add_news_screen.dart';
import 'package:Taqyem/screens2/news/gerenews.dart';
import 'package:Taqyem/screens2/jeojson/sigweb.dart';
import 'package:Taqyem/screens2/jeojson/DrawShape.dart';
import 'package:Taqyem/screens2/users/User%20Management.dart';
import 'package:Taqyem/services2/AddClassPage.dart';
import 'package:Taqyem/taqyem/AddStudentPage.dart';
import 'package:Taqyem/taqyem/EditPage.dart';
import 'package:Taqyem/taqyem/StudentDetailsPage.dart';
import 'package:Taqyem/taqyem/ereur_solution.dart';
import 'package:Taqyem/taqyem/gistion.dart';
import 'package:Taqyem/taqyem/jadwelisnad.dart';
import 'package:Taqyem/taqyem/pdf/ManagePDFPage.dart';
import 'package:Taqyem/taqyem/selectionPage.dart';
import 'package:Taqyem/taqyem/listedeselection.dart';
import 'package:Taqyem/taqyem/touttableaux.dart';
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
                        'Gestion des utilisateurs',
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
                        'Ajouter une classe',
                        'lib/assets/icons/me/ajouter.gif',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddClassPage(), // Ajouter le paramètre de titre requis
                            ),
                          );
                        },
                      ),
                      buildDashboardItem(
                        context,
                        'Gestion des Classes ',
                        'lib/assets/icons/me/L7.gif',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ManageClassesPage(), // Ajouter le paramètre de titre requis
                            ),
                          );
                        },
                      ),

                      // buildDashboardItem(
                      //   context,
                      //   'إسناد اعداد',
                      //   'lib/assets/icons/me/note.gif',
                      //   () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) =>
                      //             ManageStudentGradesPage(), // de titre requis
                      //       ),
                      //     );
                      //   },
                      // ),

                      // buildDashboardItem(
                      //   context,
                      //   'AdminPage',
                      //   'lib/assets/icons/me/news1.gif',
                      //   () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => AdminPage(),
                      //       ),
                      //     );
                      //   },
                      // ),

                      // buildDashboardItem(
                      //   context,
                      //   'AdminPage-ادراج المعايير',
                      //   'lib/assets/icons/me/barm.gif',
                      //   () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => AdminCrudPage(),
                      //       ),
                      //     );
                      //   },
                      // ),
                      buildDashboardItem(
                        context,
                        'إعداد جدول جامع',
                        'lib/assets/icons/me/15-13-33-168_512.gif',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SelectionPage(),
                            ),
                          );
                        },
                      ),

                      buildDashboardItem(
                        context,
                        'قائمة الجداول الجامعة',
                        'lib/assets/icons/me/unnamed.gif',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClassListPage(),
                            ),
                          );
                        },
                      ),
                      buildDashboardItem(
                        context,
                        'Gestion des PDF (Ajouter et Supprimer)',
                        'lib/assets/icons/me/realisations-16918-removebg-preview.png',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UploadPDFPage(), // Ajouter le paramètre de titre requis
                            ),
                          );
                        },
                      ),
                      buildDashboardItem(
                        context,
                        'pdf partager',
                        'lib/assets/icons/me/ajout des images.png',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DisplayPDFsPage(), // Ajouter le paramètre de titre requis
                            ),
                          );
                        },
                      ),

                      
                      buildDashboardItem(
                        context,
                        'Voir les nouvelles',
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
                      //  buildDashboardItem(
                      //   context,
                      //   'Gestion des utilisateurs',
                      //   'lib/assets/icons/me/menagment.gif',
                      //   () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => const UserManagement(),
                      //       ),
                      //     );
                      //   },
                      // ),

                      // buildDashboardItem(
                      //   context,
                      //   'Ajouter une actualité',
                      //   'lib/assets/icons/me/news.gif',
                      //   () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => const AddNewsScreen(),
                      //       ),
                      //     );
                      //   },
                      // ),
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
