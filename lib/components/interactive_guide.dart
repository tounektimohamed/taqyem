import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class OnboardingHelper {
  static Future<void> resetOnboarding(String userId) async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .update({'hasSeenOnboarding': false});
  }

  static Future<bool> hasSeenOnboarding(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();
      return doc.data()?['hasSeenOnboarding'] ?? false;
    } catch (e) {
      return false;
    }
  }
}

class InteractiveGuide {
  static Future<void> startGuide(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return InteractiveGuideOverlay(userId: user.uid);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class InteractiveGuideOverlay extends StatefulWidget {
  final String userId;

  const InteractiveGuideOverlay({super.key, required this.userId});

  @override
  State<InteractiveGuideOverlay> createState() =>
      _InteractiveGuideOverlayState();
}

class _InteractiveGuideOverlayState extends State<InteractiveGuideOverlay> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  Map<String, String> _imageUrls = {};
  bool _isLoadingImages = true;

  final List<GuideStep> _steps = [
    GuideStep(
      id: 'welcome',
      title: 'مرحباً بك!',
      description: 'سنتعرف معاً على كيفية استخدام التطبيق خطوة بخطوة',
      icon: Icons.school,
      color: Colors.blue,
    ),
    GuideStep(
      id: 'create_class',
      title: 'إنشاء قسم',
      description: 'ابدأ بإنشاء قسم جديد لطلابك من القائمة الجانبية',
      icon: Icons.add_circle,
      color: Colors.green,
      actionHint: 'القائمة ← إضافة قسم جديد',
    ),
    GuideStep(
      id: 'save_class',
      title: 'حفظ القسم',
      description: 'أدخل اسم القسم ثم اضغط حفظ',
      icon: Icons.save,
      color: Colors.green,
      actionHint: 'أدخل الاسم واضغط حفظ',
    ),
    GuideStep(
      id: 'manage_classes',
      title: 'إدارة الأقسام',
      description: 'اذهب إلى إدارة الأقسام لاختيار القسم',
      icon: Icons.list,
      color: Colors.orange,
      actionHint: 'اضغط على إدارة الأقسام',
    ),
    GuideStep(
      id: 'select_class',
      title: 'اختيار القسم',
      description: 'اضغط على اسم القسم للدخول إليه',
      icon: Icons.touch_app,
      color: Colors.orange,
      actionHint: 'اضغط على بطاقة القسم',
    ),
    GuideStep(
      id: 'add_student',
      title: 'إضافة التلاميذ',
      description: 'اضغط على إضافة تلميذ لإضافة طلاب جدد',
      icon: Icons.person_add,
      color: Colors.purple,
      actionHint: 'اضغط على زر إضافة تلميذ',
    ),
    GuideStep(
      id: 'save_student',
      title: 'حفظ التلميذ',
      description: 'أدخل اسم التلميذ ورقمه ثم اضغط حفظ',
      icon: Icons.check,
      color: Colors.purple,
      actionHint: 'أدخل البيانات واضغط حفظ',
    ),
    GuideStep(
      id: 'manage_bareme',
      title: 'إنشاء المعايير',
      description: 'اضغط على إدارة المعايير لإنشاء سُلَّم التقييم',
      icon: Icons.assignment,
      color: Colors.teal,
      actionHint: 'اضغط على إدارة المعايير',
    ),
    GuideStep(
      id: 'add_bareme',
      title: 'إضافة معايير',
      description: 'أضف معايير مثل: الالتزام، التعاون، الإتقان',
      icon: Icons.add_task,
      color: Colors.teal,
      actionHint: 'أدخل اسم المعيار واضغط إضافة',
    ),
    GuideStep(
      id: 'evaluate',
      title: 'تقييم التلاميذ',
      description: 'اضغط على بطاقة تلميذ ثم اختر المعيار والقيمة',
      icon: Icons.rate_review,
      color: Colors.indigo,
      actionHint: 'اضغط على بطاقة التلميذ',
    ),
    GuideStep(
      id: 'select_value',
      title: 'تحديد القيمة',
      description: 'اختر المعيار واضغط على القيمة المناسبة',
      icon: Icons.star,
      color: Colors.indigo,
      actionHint: 'اختر القيمة واضغط حفظ',
    ),
    GuideStep(
      id: 'show_table',
      title: 'عرض الجدول',
      description: 'اضغط على جدول النتائج لعرض جميع التقييمات',
      icon: Icons.table_chart,
      color: Colors.deepOrange,
      actionHint: 'اضغط على جدول النتائج',
    ),
    GuideStep(
      id: 'export',
      title: 'تصدير',
      description: 'يمكنك تصدير الجدول أو طباعته',
      icon: Icons.print,
      color: Colors.deepOrange,
      actionHint: 'اضغط على زر التصدير',
    ),
    GuideStep(
      id: 'complete',
      title: 'تم!',
      description: 'أنت جاهز الآن لاستخدام التطبيق. استمتع!',
      icon: Icons.celebration,
      color: Colors.amber,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadImageUrls();
    });
  }

  Future<void> _loadImageUrls() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('guide_images')
          .doc('steps')
          .get();

      if (mounted) {
        if (doc.exists && doc.data() != null) {
          setState(() {
            _imageUrls = Map<String, String>.from(doc.data()!['images'] ?? {});
            _isLoadingImages = false;
          });
        } else {
          setState(() => _isLoadingImages = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingImages = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeGuide();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeGuide() async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.userId)
        .update({'hasSeenOnboarding': true});
    if (mounted) Navigator.of(context).pop();
  }

  void _skipToStep(int stepIndex) {
    setState(() => _currentStep = stepIndex);
    _pageController.animateToPage(
      stepIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400 || screenHeight < 550;
    final isLandscape = screenWidth > screenHeight;
    final step = _steps[_currentStep];
    final color = step.color;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Container(color: Colors.black54),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(color, isSmallScreen),
                Expanded(
                  child: Center(
                    child: Container(
                      margin: EdgeInsets.all(isSmallScreen ? 8 : 16),
                      constraints: BoxConstraints(
                        maxWidth: isSmallScreen ? screenWidth * 0.95 : 450,
                        maxHeight: screenHeight * 0.6,
                      ),
                      child: Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(isSmallScreen ? 16 : 24),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHeader(color, isSmallScreen),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: isSmallScreen ? 140 : 180,
                                ),
                                child: _isLoadingImages
                                    ? _buildLoadingIndicator(
                                        step, isSmallScreen)
                                    : _buildPageView(isSmallScreen),
                              ),
                              _buildIndicators(color, isSmallScreen),
                              _buildNavigation(color, isSmallScreen),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildQuickNav(color, isSmallScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(Color color, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 8 : 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: color.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome,
                    color: color, size: isSmallScreen ? 14 : 16),
                SizedBox(width: isSmallScreen ? 4 : 6),
                Text(
                  'دليل البدء',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 10 : 12,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _completeGuide,
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color color, bool isSmallScreen) {
    final step = _steps[_currentStep];

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(26), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isSmallScreen ? 16 : 24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(77),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              step.icon,
              color: Colors.white,
              size: isSmallScreen ? 24 : 32,
            ),
          ),
          SizedBox(width: isSmallScreen ? 10 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الخطوة ${_currentStep + 1} من ${_steps.length}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 1 : 2),
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildStepMenu(color, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildStepMenu(Color color, bool isSmallScreen) {
    return PopupMenuButton<int>(
      icon: Icon(Icons.menu,
          size: isSmallScreen ? 20 : 24, color: Colors.grey[600]),
      tooltip: 'انتقل إلى خطوة',
      onSelected: _skipToStep,
      itemBuilder: (context) => _steps.asMap().entries.map((entry) {
        final idx = entry.key;
        final s = entry.value;
        return PopupMenuItem<int>(
          value: idx,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: s.color.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(s.icon, size: 16, color: s.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _currentStep == idx
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (_currentStep == idx)
                Icon(Icons.check, size: 16, color: color),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPageView(bool isSmallScreen) {
    return PageView.builder(
      controller: _pageController,
      itemCount: _steps.length,
      onPageChanged: (index) {
        setState(() => _currentStep = index);
      },
      itemBuilder: (context, index) {
        final step = _steps[index];
        final hasImage = _imageUrls[step.id] != null || step.imagePath != null;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
          child: hasImage
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildStepImage(step, isSmallScreen),
                    ),
                    SizedBox(width: isSmallScreen ? 10 : 16),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.description,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 15,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.start,
                          ),
                          if (step.actionHint != null) ...[
                            SizedBox(height: isSmallScreen ? 10 : 16),
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
                              decoration: BoxDecoration(
                                color: Colors.amber.withAlpha(38),
                                borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 8 : 12),
                                border: Border.all(
                                    color: Colors.amber.withAlpha(77)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.touch_app,
                                      color: Colors.amber,
                                      size: isSmallScreen ? 16 : 20),
                                  SizedBox(width: isSmallScreen ? 6 : 10),
                                  Flexible(
                                    child: Text(
                                      step.actionHint!,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 11 : 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 15,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (step.actionHint != null) ...[
                      SizedBox(height: isSmallScreen ? 10 : 16),
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(38),
                          borderRadius:
                              BorderRadius.circular(isSmallScreen ? 8 : 12),
                          border: Border.all(color: Colors.amber.withAlpha(77)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app,
                                color: Colors.amber,
                                size: isSmallScreen ? 16 : 20),
                            SizedBox(width: isSmallScreen ? 6 : 10),
                            Flexible(
                              child: Text(
                                step.actionHint!,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildIndicators(Color color, bool isSmallScreen) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_steps.length, (index) {
          final isActive = _currentStep == index;
          return GestureDetector(
            onTap: () => _skipToStep(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? _steps[index].color : Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigation(Color color, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: _previousStep,
              icon: Icon(Icons.arrow_forward, size: isSmallScreen ? 16 : 18),
              label: Text('السابق',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            ),
          const Spacer(),
          TextButton(
            onPressed: _completeGuide,
            child: Text('تخطي',
                style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: isSmallScreen ? 12 : 14)),
          ),
          SizedBox(width: isSmallScreen ? 6 : 8),
          ElevatedButton.icon(
            onPressed: _nextStep,
            icon: Icon(
              _currentStep < _steps.length - 1 ? Icons.arrow_back : Icons.check,
              size: isSmallScreen ? 16 : 20,
            ),
            label: Text(
              _currentStep < _steps.length - 1 ? 'التالي' : 'إنهاء',
              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 24,
                vertical: isSmallScreen ? 8 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepImage(GuideStep step, bool isSmallScreen) {
    final double imageHeight = isSmallScreen ? 180 : 220;
    final String? imageData = _imageUrls[step.id] ?? step.imageUrl;

    print(
        'Step ${step.id}: imageData = ${imageData != null ? "exists (${imageData.length} chars)" : "null"}');

    if (imageData != null && imageData.isNotEmpty) {
      try {
        String base64String = imageData;
        if (imageData.contains(',')) {
          base64String = imageData.split(',').last;
        }

        final bytes = base64Decode(base64String);
        print('Step ${step.id}: decoded ${bytes.length} bytes');

        return Container(
          height: imageHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            border: Border.all(color: step.color.withAlpha(77)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                print('Step ${step.id}: Image.memory error: $error');
                return _buildImagePlaceholder(step, isSmallScreen, imageHeight);
              },
            ),
          ),
        );
      } catch (e) {
        print('Step ${step.id}: decoding error: $e');
        return _buildImagePlaceholder(step, isSmallScreen, imageHeight);
      }
    }

    if (step.imagePath != null) {
      return Container(
        height: imageHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          border: Border.all(color: step.color.withAlpha(77)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          child: Image.asset(
            step.imagePath!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Step ${step.id}: Image.asset error: $error');
              return _buildImagePlaceholder(step, isSmallScreen, imageHeight);
            },
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildImagePlaceholder(
      GuideStep step, bool isSmallScreen, double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: step.color.withAlpha(26),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              step.icon,
              size: isSmallScreen ? 40 : 50,
              color: step.color.withAlpha(128),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              'صورة توضيحية',
              style: TextStyle(
                color: step.color.withAlpha(179),
                fontSize: isSmallScreen ? 11 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(GuideStep step, bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 120 : 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: step.color.withAlpha(26),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: step.color,
              strokeWidth: 2,
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              'جاري تحميل الصور...',
              style: TextStyle(
                color: step.color.withAlpha(179),
                fontSize: isSmallScreen ? 11 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageLoading(GuideStep step, bool isSmallScreen, double height,
      ImageChunkEvent loadingProgress) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: step.color.withAlpha(26),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: step.color,
              strokeWidth: 2,
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              'جاري التحميل...',
              style: TextStyle(
                color: step.color,
                fontSize: isSmallScreen ? 11 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickNav(Color color, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 8 : 16),
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt,
                  size: isSmallScreen ? 14 : 16, color: Colors.grey[600]),
              SizedBox(width: isSmallScreen ? 4 : 6),
              Text(
                'الخطوات',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 10),
          SizedBox(
            height: isSmallScreen ? 32 : 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                final isActive = _currentStep == index;
                return GestureDetector(
                  onTap: () => _skipToStep(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(left: 6),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 4 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? step.color : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          step.icon,
                          size: isSmallScreen ? 12 : 14,
                          color: isActive ? Colors.white : Colors.grey[600],
                        ),
                        SizedBox(width: isSmallScreen ? 2 : 4),
                        Text(
                          step.title.length > 6
                              ? '${step.title.substring(0, 6)}...'
                              : step.title,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 9 : 11,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GuideStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? actionHint;
  final String? imagePath;
  final String? imageUrl;

  GuideStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.actionHint,
    this.imagePath,
    this.imageUrl,
  });
}
