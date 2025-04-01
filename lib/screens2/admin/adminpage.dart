import 'dart:async';
import 'dart:math';

import 'package:Taqyem/landing/views/ManageCarouselItemsPage.dart';
import 'package:Taqyem/screens2/admin/AccessLogsPage.dart';
import 'package:Taqyem/screens2/news/add_news_screen.dart';
import 'package:Taqyem/screens2/news/gerenews.dart';
import 'package:Taqyem/screens2/users/User%20Management.dart';
import 'package:Taqyem/taqyem/AddClassPage.dart';
import 'package:Taqyem/taqyem/AddStudentPage.dart';
import 'package:Taqyem/taqyem/AdminProposalsPage.dart';
import 'package:Taqyem/taqyem/EditPage.dart';
import 'package:Taqyem/taqyem/feedback_management_page.dart';
import 'package:Taqyem/taqyem/feedback_system.dart';
import 'package:Taqyem/taqyem/payment/PaymentPage.dart';
import 'package:Taqyem/taqyem/payment/adminpyment.dart';
import 'package:Taqyem/taqyem/payment/demande.dart';
import 'package:Taqyem/taqyem/ereur_solution.dart';
import 'package:Taqyem/taqyem/listedeselection.dart';
import 'package:Taqyem/taqyem/pdf/ManagePDFPage.dart';
import 'package:Taqyem/taqyem/selectionPage.dart';
import 'package:Taqyem/taqyem/touttableaux.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_timeline_calendar/timeline/flutter_timeline_calendar.dart';
import '../login_signup/account_settings.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

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
  String userName = "Utilisateur";
  bool _isDrawerOpen = false;
  int _currentCarouselIndex = 0;
   Timer? _feedbackTimer; // Utilisez un Timer nullable
  bool _feedbackShown = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupRandomFeedback();
  }

@override
void dispose() {
  _feedbackTimer?.cancel(); // Utilisez l'opérateur ?. pour éviter les erreurs
  super.dispose();
}
void _setupRandomFeedback() {
  // Génère un délai aléatoire entre 2 et 8 heures (en millisecondes)
  final random = Random();
  final delayHours = 2 + random.nextInt(6); // Entre 2 et 7 heures
  final delayMillis = delayHours * 60 * 60 * 1000;

  _feedbackTimer = Timer(Duration(milliseconds: delayMillis), () {
    if (!_feedbackShown && mounted) {
      _showRandomFeedback();
      _feedbackShown = true;
    }
  });
}

void _showRandomFeedback() {
  // Vérifie l'heure actuelle (entre 9h et 20h)
  final now = DateTime.now();
  if (now.hour >= 9 && now.hour <= 7) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('شاركنا رأيك'),
          content: const Text('كيف تجد تجربتك مع التطبيق حتى الآن؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                FeedbackSystem.showFeedbackDialog(context);
              },
              child: const Text('إعطاء رأي'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _setupRandomFeedback(); // Reprogramme pour plus tard
                _feedbackShown = false;
              },
              child: const Text('لاحقاً'),
            ),
          ],
        ),
      );
    });
  } else {
    // Si c'est en dehors des heures normales, reprogramme pour le lendemain
    _setupRandomFeedback();
  }
}

  Future<void> _loadUserData() async {
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userName =
              userDoc['name'] ?? currentUser?.displayName ?? "Utilisateur";
        });
      }
    }
  }

  Stream<DocumentSnapshot> _getAccountStatusStream() {
    if (currentUser == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser!.uid)
        .snapshots();
  }

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
          StreamBuilder<DocumentSnapshot>(
            stream: _getAccountStatusStream(),
            builder: (context, snapshot) {
              bool isActive = false;
              Duration? remainingTime;

              if (snapshot.hasData && snapshot.data!.exists) {
                isActive = snapshot.data!['isActive'] ?? false;
                var expiration = snapshot.data!['accountExpiration']?.toDate();
                if (expiration != null) {
                  remainingTime = expiration.difference(DateTime.now());
                }
              }

              return Tooltip(
                message: isActive
                    ? 'Compte Premium${remainingTime != null ? '\nExpire dans ${remainingTime.inDays} jours' : ''}'
                    : 'Compte Standard - Mettez à niveau pour débloquer toutes les fonctionnalités',
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[800] : Colors.grey[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: isActive ? Colors.green[200] : Colors.red[200],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isActive ? 'PREMIUM' : 'STANDARD',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPageUI(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: currentUser?.photoURL != null
                    ? NetworkImage(currentUser!.photoURL!)
                    : null,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: currentUser?.photoURL == null
                    ? const Icon(Icons.person_outlined, color: Colors.white)
                    : null,
              ),
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
                // Carousel Section with improved UI
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('carouselItems')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return CircularProgressIndicator();

                    final items = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {
                        'imageUrl': data['url'] ?? '',
                        'title': data['title'] ?? '',
                        'subtitle': data['subtitle'] ?? '',
                        'description': data['description'] ?? '',
                      };
                    }).toList();

                    return Column(
                      children: [
                        const SizedBox(height: 20),
                        SimpleCarousel(items: items),
                        const SizedBox(height: 30),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),
                _buildQuickAccessSection(context),
                const SizedBox(height: 30),
                const SizedBox(height: 30),

                // Calendar Section with improved visual distinction
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TimelineCalendar(
                        calendarType: CalendarType.GREGORIAN,
                        calendarOptions: CalendarOptions(
                          viewType: ViewType.DAILY,
                          toggleViewType: true,
                          headerMonthElevation: 0,
                          headerMonthBackColor: Colors.grey[50],
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
                          selectedTextColor: Colors.white,
                        ),
                        headerOptions: HeaderOptions(
                          weekDayStringType: WeekDayStringTypes.SHORT,
                          monthStringType: MonthStringTypes.FULL,
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
                      const SizedBox(height: 16),
                      // Quick navigation buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDateNavButton(context, 'Aujourd\'hui', () {
                            setState(() {
                              _selectedDate.value = CalendarDateTime(
                                year: DateTime.now().year,
                                month: DateTime.now().month,
                                day: DateTime.now().day,
                              );
                            });
                          }),
                          _buildDateNavButton(context, 'Demain', () {
                            final tomorrow =
                                DateTime.now().add(const Duration(days: 1));
                            setState(() {
                              _selectedDate.value = CalendarDateTime(
                                year: tomorrow.year,
                                month: tomorrow.month,
                                day: tomorrow.day,
                              );
                            });
                          }),
                          _buildDateNavButton(context, 'Semaine prochaine', () {
                            final nextWeek =
                                DateTime.now().add(const Duration(days: 7));
                            setState(() {
                              _selectedDate.value = CalendarDateTime(
                                year: nextWeek.year,
                                month: nextWeek.month,
                                day: nextWeek.day,
                              );
                            });
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Selected Date Section with improved prominence
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEEE, d MMMM y', 'fr_FR').format(
                          DateTime(
                            _selectedDate.value.year,
                            _selectedDate.value.month,
                            _selectedDate.value.day,
                          ),
                        ),
                        style: GoogleFonts.roboto(
                          fontSize: isDesktop ? 22 : 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // News Section with all improvements
                NewsSection(),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateNavButton(
      BuildContext context, String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
        ),
      ), // <== Ici, il manquait une virgule
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
        ),
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
              offset: const Offset(3, 0),
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
                    userName, // Utilisation du nom de l'utilisateur
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // Text(
                  //   currentUser?.email ?? '',
                  //   style: GoogleFonts.roboto(
                  //     fontSize: 14,
                  //     color: Colors.white70,
                  //   ),
                  // ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: _getAccountStatusStream(),
                    builder: (context, snapshot) {
                      bool isActive = false;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        isActive = snapshot.data!['isActive'] ?? false;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: Colors.green[300]
                                      ?.withOpacity(isActive ? 1 : 0) ??
                                  Colors.red[300],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isActive ? 'Compte Premium' : 'Compte Standard',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: isActive
                                    ? Colors.green[200]
                                    : Colors.red[200],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Class Management Section
            _buildDrawerSectionHeader('Gestion des Classes'),
            _buildDrawerItem(
              context,
              Icons.school,
              'إضافة قسم جديد',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddClassPage(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context,
              Icons.class_,
              'إدارة الأقسام',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageClassesPage(),
                  ),
                );
              },
            ),

            // Tables Section
            _buildDrawerSectionHeader('Gestion des Tableaux'),
            _buildDrawerItem(
              context,
              Icons.table_chart,
              'إعداد جدول جامع',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectionPage(),
                  ),
                );
              },
            ),
            // _buildDrawerItem(
            //   context,
            //   Icons.list_alt,
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

            // Documents Section
            _buildDrawerSectionHeader('Documents'),
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
            
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
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
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 300), onTap);
      },
      onHover: (isHovering) {},
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

class SimpleCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const SimpleCarousel({Key? key, required this.items}) : super(key: key);

  @override
  _SimpleCarouselState createState() => _SimpleCarouselState();
}

class _SimpleCarouselState extends State<SimpleCarousel> {
  int _currentIndex = 0;
  final CarouselController _controller = CarouselController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Carousel Principal
        CarouselSlider.builder(
          itemCount: widget.items.length,
          carouselController: _controller,
          options: CarouselOptions(
            height: 200,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.85,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final item = widget.items[index];
            return _buildCarouselItem(item);
          },
        ),
        SizedBox(height: 12),
        // Indicateurs
        AnimatedSmoothIndicator(
          activeIndex: _currentIndex,
          count: widget.items.length,
          effect: WormEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showDetail(context, item);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Image.network(
                item['imageUrl'],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  return progress == null
                      ? child
                      : Center(child: CircularProgressIndicator());
                },
              ),
              // Overlay de texte
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? '',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item['subtitle'] != null)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          item['subtitle']!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Image
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    item['imageUrl'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              // Content
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] ?? '',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 8),
                        Text(
                          item['description'] ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class NewsSection extends StatefulWidget {
  @override
  _NewsSectionState createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String userId;
  Set<String> seenNews = {};

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      _loadSeenNews();
    }
  }

  Future<void> _loadSeenNews() async {
    var seenNewsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('seen_news')
        .get();

    setState(() {
      seenNews = seenNewsSnapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  Future<void> _markAsSeen(String newsId) async {
    setState(() {
      seenNews.add(newsId);
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('seen_news')
        .doc(newsId)
        .set({'seen': true});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Actualités',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all news page
                },
                child: Text(
                  'Voir tout',
                  style: GoogleFonts.roboto(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('news')
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _buildNewsSkeleton();
              }

              var newsDocs = snapshot.data!.docs;

              if (newsDocs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Aucune actualité disponible',
                      style: GoogleFonts.roboto(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: newsDocs.length,
                itemBuilder: (context, index) {
                  var newsDoc = newsDocs[index];
                  var news = newsDoc.data() as Map<String, dynamic>;
                  var newsId = newsDoc.id;
                  var title = news['title'] ?? 'Pas de Titre';
                  var content = news['content'] ?? 'Pas de Contenu';
                  var category = news['category'] ?? 'Général';
                  var timestamp = news['timestamp'] as Timestamp;
                  var date = timestamp.toDate();
                  bool isNew = !seenNews.contains(newsId);

                  return GestureDetector(
                    onTap: () {
                      _markAsSeen(newsId);
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: isNew
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 4,
                            ),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: GoogleFonts.roboto(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (isNew)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Nouveau',
                                        style: GoogleFonts.roboto(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (category.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    category,
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeago.format(date, locale: 'fr'),
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      ),
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

  Widget _buildNewsSkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 20,
                color: Colors.grey[200],
              ),
              const SizedBox(height: 8),
              Container(
                width: 100,
                height: 16,
                color: Colors.grey[200],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 16,
                color: Colors.grey[200],
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                height: 16,
                color: Colors.grey[200],
              ),
              const SizedBox(height: 12),
              Container(
                width: 120,
                height: 14,
                color: Colors.grey[200],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildQuickAccessSection(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accès Rapide',
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // Adaptation dynamique du nombre de colonnes
            final crossAxisCount = constraints.maxWidth > 400 ? 4 : 2;
            final childAspectRatio = constraints.maxWidth > 600 ? 1.0 : 0.9;
            final isLargeScreen = constraints.maxWidth > 600;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
              padding: EdgeInsets.zero,
              children: [
                _buildResponsiveQuickAccessCard(
                  context,
                  Icons.add,
                  'إضافة قسم',
                  Colors.blue[700]!,
                  isLargeScreen,
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AddClassPage())),
                ),
                _buildResponsiveQuickAccessCard(
                  context,
                  Icons.manage_accounts,
                  'إدارة الأقسام',
                  Colors.green[700]!,
                  isLargeScreen,
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ManageClassesPage())),
                ),
                _buildResponsiveQuickAccessCard(
                  context,
                  Icons.table_chart,
                  'إعداد جدول جامع',
                  Colors.orange[700]!,
                  isLargeScreen,
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SelectionPage())),
                ),
                _buildResponsiveQuickAccessCard(
                  context,
                  Icons.payment,
                  'تفعيل الحساب',
                  Colors.purple[700]!,
                  isLargeScreen,
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => PaymentPage())),
                  showBadge: true,
                ),
                
              ],
            );
          },
        ),
      ],
    ),
  );
}

Widget _buildResponsiveQuickAccessCard(
  BuildContext context,
  IconData icon,
  String title,
  Color color,
  bool isLargeScreen,
  VoidCallback onTap, {
  bool showBadge = false,
}) {
  return Card(
    elevation: isLargeScreen ? 3 : 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(isLargeScreen ? 16 : 12),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(isLargeScreen ? 16 : 12),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minHeight: isLargeScreen ? 140 : 120, // Hauteur minimale ajustée
        ),
        padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize:
              MainAxisSize.min, // Important pour éviter le débordement
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: isLargeScreen ? 36 : 30,
                    color: color,
                  ),
                ),
                if (showBadge)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8), // Espacement réduit
            Flexible(
              // Utilisation de Flexible pour le texte
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: isLargeScreen ? 16 : 13, // Taille de police réduite
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
