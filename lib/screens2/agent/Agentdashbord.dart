import 'package:Taqyem/landing/views/ManageCarouselItemsPage.dart';
import 'package:Taqyem/screens2/admin/AccessLogsPage.dart';
import 'package:Taqyem/screens2/news/add_news_screen.dart';
import 'package:Taqyem/screens2/news/gerenews.dart';
import 'package:Taqyem/screens2/users/User%20Management.dart';
import 'package:Taqyem/taqyem/AddClassPage.dart';
import 'package:Taqyem/taqyem/AddStudentPage.dart';
import 'package:Taqyem/taqyem/EditPage.dart';
import 'package:Taqyem/taqyem/ereur_solution.dart';
import 'package:Taqyem/taqyem/pdf/ManagePDFPage.dart';
import 'package:Taqyem/taqyem/selectionPage.dart';
import 'package:Taqyem/taqyem/touttableaux.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_timeline_calendar/timeline/flutter_timeline_calendar.dart';
import '../login_signup/account_settings.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
  bool _isDrawerOpen = false;

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(
        'Tableau de bord',
        style: GoogleFonts.roboto(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
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
            radius: 20,
            backgroundImage: currentUser?.photoURL != null
                ? NetworkImage(currentUser!.photoURL!)
                : null,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: currentUser?.photoURL == null
                ? const Icon(Icons.person_outlined, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 16),
      ],
    ),
    drawer: _buildModernDrawer(context),
    body: LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 600;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              // Sections supplémentaires
              CarouselSection(),
              NewsSection(),
            ],
          ),
        );
      },
    ),
  );
}


  Widget _buildModernDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 5,
              offset: Offset(3, 0),
            ),
          ],
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: currentUser?.photoURL != null
                        ? NetworkImage(currentUser!.photoURL!)
                        : null,
                    backgroundColor: Colors.white,
                    child: currentUser?.photoURL == null
                        ? const Icon(Icons.person_outlined, color: Colors.black)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentUser?.displayName ?? 'Utilisateur',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    currentUser?.email ?? '',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              Icons.people,
              'إدارة المستخدمين',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserManagement(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context,
              Icons.people,
              'إدارة الحلول ',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ErrorOrigin(),
                  ),
                );
              },
            ),
            // _buildDrawerItem(
            //   context,
            //   Icons.add,
            //   'Ajouter une classe',
            //   () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => AddClassPage(),
            //       ),
            //     );
            //   },
            // ),
            // _buildDrawerItem(
            //   context,
            //   Icons.class_,
            //   'Gestion des Classes',
            //   () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => ManageClassesPage(),
            //       ),
            //     );
            //   },
            // ),
            _buildDrawerItem(
              context,
              Icons.admin_panel_settings,
              'AdminPage-ادراج المعايير',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminCrudPage(),
                  ),
                );
              },
            ),
            // _buildDrawerItem(
            //   context,
            //   Icons.table_chart,
            //   'إعداد جدول جامع',
            //   () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => SelectionPage(),
            //       ),
            //     );
            //   },
            // ),
            // _buildDrawerItem(
            //   context,
            //   Icons.list,
            //   'قائمة الجداول الجامعة',
            //   () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => ClassListPage(),
            //       ),
            //     );
            //   },
            // ),
            _buildDrawerItem(
              context,
              Icons.picture_as_pdf,
              'مشاركة وثائق تعلمية',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UploadPDFPage(),
                  ),
                );
              },
            ),
            // _buildDrawerItem(
            //   context,
            //   Icons.share,
            //   'PDF partager',
            //   () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => UploadPDFPage(),
            //       ),
            //     );
            //   },
            // ),
            _buildDrawerItem(
              context,
              Icons.article,
              'رؤية الأخبار',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GereListPage(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context,
              Icons.settings,
              'Paramètres',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPageUI(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context,
              Icons.settings,
              'إضافة خبر ',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddNewsScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context,
              Icons.settings,
              'رؤية سجلات الوصول',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccessLogsPage(),
                  ),
                );
              },
            ),
             _buildDrawerItem(
              context,
              Icons.settings,
              'Manage Carousel',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageCarouselItemsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Fermer le drawer
        Future.delayed(Duration(milliseconds: 300), onTap); // Délai pour l'animation
      },
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        hoverColor: Colors.white.withOpacity(0.1),
        tileColor: Colors.transparent,
      ),
    );
  }
}




class CarouselSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('carouselItems').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erreur de chargement",
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Aucun élément disponible",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }

          var carouselItems = snapshot.data!.docs;

          return Column(
            children: [
              CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  autoPlay: true,
                  autoPlayInterval: Duration(seconds: 3),
                  enlargeCenterPage: true,
                  aspectRatio: 16 / 9,
                  viewportFraction: 0.8,
                ),
                items: carouselItems.map((item) {
                  var data = item.data() as Map<String, dynamic>;
                  var url = data['url'] ?? '';

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: url.isNotEmpty
                          ? Image.network(
                              url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                );
                              },
                            )
                          : Center(
                              child: Icon(Icons.image, size: 50, color: Colors.grey),
                            ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              AnimatedSmoothIndicator(
                activeIndex: 0, // Remplacez par un state pour un vrai suivi
                count: carouselItems.length,
                effect: WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: Colors.blue,
                  dotColor: Colors.grey,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


class NewsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            height: 10,
          ),
          // Titre pour la section des nouvelles
          Text(
            'Actualités',
            selectionColor: Colors.yellow,
            style: GoogleFonts.roboto(
              fontSize: 25,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          // StreamBuilder pour récupérer les dernières nouvelles
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('news')
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var newsDocs = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: newsDocs.length,
                itemBuilder: (context, index) {
                  var news = newsDocs[index].data() as Map<String, dynamic>;
                  var title = news['title'] ?? 'Pas de Titre';
                  var content = news['content'] ?? 'Pas de Contenu';
                  var timestamp = news['timestamp'] as Timestamp;
                  var date = timestamp.toDate();

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        title,
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Publié le ${date.day}/${date.month}/${date.year}',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
