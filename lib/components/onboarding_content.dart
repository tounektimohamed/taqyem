class UnbordingContent {
  String image;
  String title;
  String description;

  UnbordingContent({
    required this.image,
    required this.title,
    required this.description,
  });
}

List<UnbordingContent> contents = [
   UnbordingContent(
    title: 'انشاء تمارين علاج تتماشى مع احتياجات التلاميذ',
    image: 'lib/assets/icons/me/support_woman_16-9.gif',
    description: 'قدم تمارين علاجية مخصصة تساعد التلاميذ على تجاوز الصعوبات وفق مستوياتهم.'),
  UnbordingContent(
    title: 'انشاء ملف تقييم كامل باقل مجهود و اكثر دقة',
    image: 'lib/assets/icons/me/QZJI.gif',
    description: 'قم بإعداد تقارير شاملة عن أداء التلاميذ بسرعة ودقة عالية.'),
  UnbordingContent(
    title: 'تقييم تقدم التلاميذ',
    image: 'lib/assets/icons/me/progress.gif',
    description: 'تابع أداء وتطور كل تلميذ بسهولة على مر الوقت.'),
  UnbordingContent(
    title: 'إنشاء بطاقات تقييم مخصصة',
    image: 'lib/assets/icons/me/assessment.gif',
    description: 'اسمح للمعلمين بإنشاء تقييمات تتكيف مع احتياجات كل تلميذ.'),
  UnbordingContent(
    title: 'متابعة النتائج والتقدم',
    image: 'lib/assets/icons/me/results.gif',
    description: 'اعرض نتائج التقييمات وتابع تقدم التلاميذ في مختلف المواد.'),
 
];