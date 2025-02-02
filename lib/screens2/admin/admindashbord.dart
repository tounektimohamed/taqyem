import 'package:Taqyem/landing/views/ManageCarouselItemsPage.dart';
import 'package:Taqyem/screens2/jeojson/DrawShape.dart';
import 'package:Taqyem/screens2/jeojson/DrawShape2.dart';
import 'package:Taqyem/screens2/jeojson/formhtml.dart';
import 'package:Taqyem/screens2/jeojson/sigweb.dart';
import 'package:Taqyem/screens2/news/add_news_screen.dart';
import 'package:Taqyem/services2/AddClassPage.dart';
import 'package:Taqyem/taqyem/AddStudentPage.dart';
import 'package:Taqyem/taqyem/EditPage.dart';
import 'package:Taqyem/taqyem/selectionPage.dart';
import 'package:Taqyem/taqyem/touttableaux.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_timeline_calendar/timeline/flutter_timeline_calendar.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

// Importer d'autres fichiers nécessaires
import 'package:Taqyem/screens2/admin/AccessLogsPage.dart';
import 'package:Taqyem/screens2/users/ClaimsListPage.dart';
import 'package:Taqyem/screens2/permis%20de%20bati/HousingApplicationForm.dart';
import 'package:Taqyem/screens2/permis%20de%20bati/HousingApplicationListPage.dart';
import 'package:Taqyem/screens2/jeojson/SubscribersPage.dart';
import 'package:Taqyem/screens2/news/gerenews.dart';
import 'package:Taqyem/screens2/users/User%20Management.dart';
import '../../taqyem/pdf/ManagePDFPage.dart';
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
          bool isDesktop = constraints.maxWidth > 600; // Définir un seuil pour le mode bureau

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
                          backgroundColor: Theme.of(context).colorScheme.primary,
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
                    crossAxisCount: isDesktop ? 4 : 2, // Ajuster les colonnes selon la taille de l'écran
                    crossAxisSpacing: isDesktop ? 24 : 16,
                    mainAxisSpacing: isDesktop ? 24 : 16,
                    children: [

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

                      

                      buildDashboardItem(
                        context,
                        'AdminPage-ادراج المعايير',
                        'lib/assets/icons/me/barm.gif',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminCrudPage(),
                            ),
                          );
                        },
                      ),
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
                        'Voir les journaux d\'accès',
                        'lib/assets/icons/me/assessment.gif',
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
                      //  buildDashboardItem(
                      //   context,
                      //   'Suivi des PAUS',
                      //   'lib/assets/icons/me/isens_thumb-removebg-preview.png',
                      //   () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => const SigWeb(
                      //             title:
                      //                 'Sig web'), // Ajouter le paramètre de titre requis
                      //       ),
                      //     );
                      //   },
                      // ),
                      // buildDashboardItem(
                      //   context,
                      //   'Permis de construire',
                      //   'lib/assets/icons/me/permis_debati-removebg-preview.png',
                      //   () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) =>
                      //             MapDrawingPage(), // Ajouter le paramètre de titre requis
                      //       ),
                      //     );
                      //   },
                      // ),
                      //  buildDashboardItem(
                      //   context,
                      //   'Suivi des plans de lotissement',
                      //   'lib/assets/icons/me/realisations-16918-removebg-preview.png',
                      //   () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) =>
                      //             CombinedMapPage(), // Ajouter le paramètre de titre requis
                      //       ),
                      //     );
                      //   },
                      // ),
                      //   buildDashboardItem(
                      //   context,
                      //   'Ajouter tiff ',
                      //   'lib/assets/icons/me/ajout des images.png',
                      //   () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) =>
                      //             AddHtmlFormPage(), // Ajouter le paramètre de titre requis
                      //       ),
                      //     );
                      //   },
                      // ),
                    
                     
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
                      buildDashboardItem(
                        context,
                        'Voir les abonnés',
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
                      // buildDashboardItem(
                      //   context,
                      //   'Liste des réclamations',
                      //   'lib/assets/icons/me/admin4.gif',
                      //   () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => ClaimsListPage(),
                      //       ),
                      //     );
                      //   },
                      // ),
                      // buildDashboardItem(
                      //   context,
                      //   'Demandes de logement',
                      //   'lib/assets/icons/me/maps.gif',
                      //   () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => HousingApplicationListPage(),
                      //       ),
                      //     );
                      //   },
                      // ),
                      // buildDashboardItem(
                      //   context,
                      //   'Gérer le carrousel',
                      //   'lib/assets/icons/me/G-carrousel.png',
                      //   () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => ManageCarouselItemsPage(),
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

  Widget buildDashboardItem(
    BuildContext context,
    String title,
    String imagePath,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.grey,
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 80,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
