import 'dart:async';
import 'dart:math';
import 'package:Taqyem/taqyem/AddClassPage.dart';
import 'package:Taqyem/taqyem/AddStudentPage.dart';
import 'package:Taqyem/taqyem/StatisticsDashboard.dart';
import 'package:Taqyem/taqyem/appjson.dart';
import 'package:Taqyem/taqyem/chat/chat_system.dart';
import 'package:Taqyem/taqyem/data/addprobsolu.dart';
import 'package:Taqyem/taqyem/data/app_wrapper.dart';
import 'package:Taqyem/taqyem/data/firebase_data-service.dart';
import 'package:Taqyem/taqyem/data/import_json_screen.dart';
import 'package:Taqyem/taqyem/data/provider_wrapper.dart';
import 'package:Taqyem/taqyem/feedback_system.dart';
import 'package:Taqyem/taqyem/guide_admin_page.dart';
import 'package:Taqyem/taqyem/da3m_help_admin_page.dart';
import 'package:Taqyem/taqyem/payment/PaymentPage.dart';
import 'package:Taqyem/taqyem/pdf/ManagePDFPage.dart';
import 'package:Taqyem/taqyem/presence.dart';
import 'package:Taqyem/taqyem/selectionPage.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_timeline_calendar/timeline/flutter_timeline_calendar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../login_signup/account_settings.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:Taqyem/components/interactive_guide.dart';

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
  String? _conversationId;
  int _unreadCount = 0;
  User? currentUser = FirebaseAuth.instance.currentUser;
  String userName = "Utilisateur";
  bool _isDrawerOpen = false;
  int _currentCarouselIndex = 0;
  Timer? _feedbackTimer;
  bool _feedbackShown = false;
  bool _showOnboarding = false;

  final List<String> _allowedUserIds = [
    'fhilpGu5Eddhl46rZbsLoldiXnb2',
    'dxjCTRGQU5MYqEbDEnzQ9ZYkUCA3'
  ];

  // Vérifie si l'utilisateur courant peut voir l'option
  bool _canShowAddProbItem() {
    if (currentUser == null) return false;
    // Retourne TRUE si l'utilisateur est dans la liste des autorisés
    return _allowedUserIds.contains(currentUser!.uid);
  }

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    if (currentUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.uid)
          .get();

      final hasSeen = doc.data()?['hasSeenOnboarding'] ?? false;

      if (!hasSeen && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showOnboardingGuide();
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showOnboardingGuide();
        });
      }
    }
  }

  void _showOnboardingGuide() {
    if (currentUser != null && mounted) {
      InteractiveGuide.startGuide(context);
    }
  }

  void _showGuideFromDrawer() {
    if (currentUser != null && mounted) {
      InteractiveGuide.startGuide(context);
    }
  }

  String _extractUserId(String input) {
    // Règles d'extraction
    final regex = RegExp(r'(?:/Users/)?([^/]+)$');
    final match = regex.firstMatch(input);

    if (match != null && match.groupCount >= 1) {
      return match.group(1) ?? input;
    }

    return input;
  }

  Future<void> _openChat() async {
    if (currentUser == null) return;

    try {
      // Nettoyer l'ID utilisateur
      final cleanUserId = _cleanUserId(currentUser!.uid);

      // Créer ou récupérer la conversation
      final conversationId =
          await ChatSystem.getOrCreateConversation(cleanUserId);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              conversationId: conversationId,
              userId: cleanUserId,
              userName: userName,
            ),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de l\'ouverture du chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture du chat'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _cleanUserId(String userId) {
    print('🧹 Nettoyage de l\'ID: $userId');

    // Règles de nettoyage
    final cleaned = userId
        .replaceAll('/Users/', '')
        .replaceAll('users/', '')
        .replaceAll('/users/', '')
        .trim();

    print('🧹 ID nettoyé: $cleaned');
    return cleaned;
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _setupRandomFeedback() {
    final random = Random();
    final delayHours = 2 + random.nextInt(6);
    final delayMillis = delayHours * 60 * 60 * 1000;

    _feedbackTimer = Timer(Duration(milliseconds: delayMillis), () {
      if (!_feedbackShown && mounted) {
        _showRandomFeedback();
        _feedbackShown = true;
      }
    });
  }

  void _showRandomFeedback() {
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
                  _setupRandomFeedback();
                  _feedbackShown = false;
                },
                child: const Text('لاحقاً'),
              ),
            ],
          ),
        );
      });
    } else {
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
          'لوحة التحكم',
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
          Tooltip(
            message: 'دليل البدء',
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.help_outline, color: Colors.white, size: 22),
              ),
              onPressed: () async {
                if (currentUser != null) {
                  await OnboardingHelper.resetOnboarding(currentUser!.uid);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      InteractiveGuide.startGuide(context);
                    }
                  });
                }
              },
            ),
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
      body: Stack(
        children: [
          // Contenu principal
          LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 600;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('carouselItems')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const CircularProgressIndicator();

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
                              _buildDateNavButton(context, 'Semaine prochaine',
                                  () {
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
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
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
                    NewsSection(),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),

          // Bouton de chat flottant
          if (currentUser != null)
            Positioned(
              bottom: 20,
              right: 20,
              child: StreamBuilder<int>(
                stream: ChatSystem.getUnreadCountStream(
                    _cleanUserId(currentUser!.uid)),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return ChatFloatingButton(
                    onPressed: _openChat,
                    unreadCount: unreadCount,
                  );
                },
              ),
            ),
        ],
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
      ),
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
                    userName,
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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

            // Afficher l'option addprobsolu seulement si l'utilisateur n'est pas exclu
            // Afficher addprobsolu seulement si l'utilisateur N'EST PAS exclu
            if (_canShowAddProbItem())
              _buildDrawerItem(
                context,
                Icons.class_,
                'addprobsolu',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddProbProviderWrapper(),
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

// Les autres classes restent inchangées (SimpleCarousel, NewsSection, etc.)
// ... (gardez tout le reste du code tel quel à partir d'ici)
class SimpleCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final double? height;
  final bool autoPlay;
  final Duration? autoPlayInterval;
  final Function(Map<String, dynamic>)? onItemTap;
  final bool showIndicators;

  const SimpleCarousel({
    Key? key,
    required this.items,
    this.height = 200,
    this.autoPlay = true,
    this.autoPlayInterval,
    this.onItemTap,
    this.showIndicators = true,
  }) : super(key: key);

  @override
  _SimpleCarouselState createState() => _SimpleCarouselState();
}

class _SimpleCarouselState extends State<SimpleCarousel> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Carousel Principal
        CarouselSlider.builder(
          itemCount: widget.items.length,
          carouselController: _carouselController,
          options: CarouselOptions(
            height: widget.height,
            autoPlay: widget.autoPlay,
            autoPlayInterval:
                widget.autoPlayInterval ?? const Duration(seconds: 3),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            enlargeCenterPage: true,
            viewportFraction: 0.85,
            enableInfiniteScroll: widget.items.length > 1,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final item = widget.items[index];
            return _buildCarouselItem(item, index);
          },
        ),

        // Indicateurs
        if (widget.showIndicators && widget.items.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildIndicators(),
          ),
      ],
    );
  }

  Widget _buildCarouselItem(Map<String, dynamic> item, int index) {
    final imageUrl = item['imageUrl']?.toString() ?? '';
    final title = item['title']?.toString() ?? '';
    final subtitle = item['subtitle']?.toString();

    return GestureDetector(
      onTap: () => _handleItemTap(item),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image de fond
              _buildImage(imageUrl),

              // Overlay de gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),

              // Contenu textuel
              if (title.isNotEmpty || subtitle != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 4,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (subtitle != null && subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

              // Badge de numéro (optionnel)
              if (widget.items.length > 1)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}/${widget.items.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 50,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 50, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  "Image non disponible",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bouton précédent
        if (widget.items.length > 1)
          IconButton(
            onPressed: _currentIndex > 0
                ? () {
                    _carouselController.previousPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: _currentIndex > 0
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade300,
            ),
            iconSize: 20,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(),
          ),

        // Indicateurs
        AnimatedSmoothIndicator(
          activeIndex: _currentIndex,
          count: widget.items.length,
          effect: ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: Theme.of(context).primaryColor,
            dotColor: Colors.grey.shade300,
            spacing: 6,
            expansionFactor: 3,
          ),
        ),

        // Bouton suivant
        if (widget.items.length > 1)
          IconButton(
            onPressed: _currentIndex < widget.items.length - 1
                ? () {
                    _carouselController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              color: _currentIndex < widget.items.length - 1
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade300,
            ),
            iconSize: 20,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_search, size: 50, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              "Aucun élément à afficher",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleItemTap(Map<String, dynamic> item) {
    HapticFeedback.lightImpact();

    if (widget.onItemTap != null) {
      widget.onItemTap!(item);
    } else {
      _showDetailSheet(item);
    }
  }

  void _showDetailSheet(Map<String, dynamic> item) {
    final imageUrl = item['imageUrl']?.toString() ?? '';
    final title = item['title']?.toString() ?? '';
    final description = item['description']?.toString() ?? '';
    final subtitle = item['subtitle']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Image
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 250,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 250,
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 60,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Contenu
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre
                          if (title.isNotEmpty)
                            Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),

                          // Sous-titre
                          if (subtitle != null && subtitle.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                subtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.7),
                                    ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Description
                          if (description.isNotEmpty)
                            Text(
                              description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),

                          // Espace pour le padding bottom
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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

  Future<void> _launchUrl(String url) async {
    try {
      // Ajouter https:// si nécessaire
      String validUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        validUrl = 'https://$url';
      }

      final Uri uri = Uri.parse(validUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible d\'ouvrir le lien: $url'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de l\'ouverture du lien: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture du lien'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
                'الأخبار',
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
                  'عرض الكل',
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
                  var link = news['link']; // Récupérer le lien
                  var hasLink = news['hasLink'] ?? false;
                  var category = news['category'] ?? 'Général';
                  var timestamp = news['timestamp'] as Timestamp;
                  var date = timestamp.toDate();
                  bool isNew = !seenNews.contains(newsId);

                  return GestureDetector(
                    onTap: () {
                      _markAsSeen(newsId);
                      // Si l'actualité a un lien, l'ouvrir
                      if (hasLink && link != null && link.isNotEmpty) {
                        _launchUrl(link);
                      }
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
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // En-tête avec titre et badge Nouveau
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

                              // Catégorie
                              if (category.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  margin: const EdgeInsets.only(bottom: 8),
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

                              // Contenu
                              Text(
                                content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Lien (si présent)
                              if (hasLink && link != null && link.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.link,
                                        size: 16,
                                        color: Colors.blue[700],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          link,
                                          style: GoogleFonts.roboto(
                                            fontSize: 12,
                                            color: Colors.blue[700],
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.open_in_new,
                                        size: 14,
                                        color: Colors.blue[700],
                                      ),
                                    ],
                                  ),
                                ),

                              // Pied de page avec date
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'اختصارات سريعة',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Indicateur de nombre d'éléments pour grand écran
              if (MediaQuery.of(context).size.width > 600)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '6 raccourcis',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;

            // Déterminer le nombre de colonnes basé sur la largeur
            int crossAxisCount;
            double childAspectRatio;
            double horizontalSpacing;

            if (screenWidth > 1200) {
              // Très grand écran (PC)
              crossAxisCount = 6;
              childAspectRatio = 1.1;
              horizontalSpacing = 20;
            } else if (screenWidth > 900) {
              // Grand écran
              crossAxisCount = 5;
              childAspectRatio = 1.0;
              horizontalSpacing = 16;
            } else if (screenWidth > 600) {
              // Tablette
              crossAxisCount = 4;
              childAspectRatio = 0.95;
              horizontalSpacing = 14;
            } else {
              // Téléphone
              crossAxisCount = 2;
              childAspectRatio = 0.9;
              horizontalSpacing = 12;
            }

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: horizontalSpacing,
              mainAxisSpacing: horizontalSpacing,
              childAspectRatio: childAspectRatio,
              padding: EdgeInsets.zero,
              children: [
                _buildResponsiveQuickAccessCard(
                  context,
                  Icons.add_circle_outline,
                  'إضافة قسم',
                  Colors.blue[700]!,
                  screenWidth,
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AddClassPage())),
                ),
                _buildResponsiveQuickAccessCard(
                  context,
                  Icons.folder_special_outlined,
                  'إدارة الأقسام',
                  Colors.green[700]!,
                  screenWidth,
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ManageClassesPage())),
                ),
                _buildResponsiveQuickAccessCard(
                  context,
                  Icons.calendar_month_outlined,
                  'جدول جامع',
                  Colors.orange[700]!,
                  screenWidth,
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SelectionPage())),
                ),
                _buildResponsiveQuickAccessCard(
                  context,
                  Icons.bar_chart_rounded,
                  'الإحصائيات',
                  Colors.teal[700]!,
                  screenWidth,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StatisticsPage()),
                  ),
                ),
                _buildResponsiveQuickAccessCard(
                  context,
                  Icons.checklist_rounded,
                  'سجل الحضور',
                  Colors.indigo[700]!,
                  screenWidth,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AttendanceSystemPage()),
                  ),
                ),
                _buildResponsiveQuickAccessCard(
                  context,
                  Icons.payment_rounded,
                  'تفعيل الحساب',
                  Colors.purple[700]!,
                  screenWidth,
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => PaymentPage())),
                  showBadge: true,
                  badgeText: 'NOUVEAU',
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
  double screenWidth,
  VoidCallback onTap, {
  bool showBadge = false,
  String badgeText = 'Nouveau',
}) {
  // Détection du type d'appareil
  bool isPhone = screenWidth <= 600;
  bool isTablet = screenWidth > 600 && screenWidth <= 900;
  bool isDesktop = screenWidth > 900;

  return LayoutBuilder(
    builder: (context, constraints) {
      return Card(
        elevation: isDesktop ? 4 : (isTablet ? 3 : 2),
        shadowColor: color.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(isDesktop ? 20 : (isTablet ? 16 : 12)),
        ),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(isDesktop ? 20 : (isTablet ? 16 : 12)),
          onTap: onTap,
          onHover: isDesktop ? (hover) {} : null,
          child: Container(
            constraints: BoxConstraints(
              minHeight: isDesktop ? 160 : (isTablet ? 140 : 120),
            ),
            padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 16 : 12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icône avec animation
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.all(isDesktop ? 18 : (isTablet ? 14 : 12)),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: isDesktop
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        icon,
                        size: isDesktop ? 36 : (isTablet ? 32 : 28),
                        color: color,
                      ),
                    ),
                    if (showBadge)
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 8 : 6,
                            vertical: isDesktop ? 4 : 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isDesktop ? 10 : (isTablet ? 9 : 8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: isDesktop ? 16 : (isTablet ? 12 : 8)),
                // Titre avec gestion responsive
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: isDesktop ? 16 : (isTablet ? 14 : 12),
                    fontWeight: isDesktop ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: isDesktop ? 0.3 : 0,
                  ),
                  maxLines: isDesktop ? 2 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isDesktop) ...[
                  const SizedBox(height: 4),
                  // Ligne décorative pour desktop
                  Container(
                    width: 40,
                    height: 2,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
