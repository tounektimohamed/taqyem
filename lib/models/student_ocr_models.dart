class StudentEvaluationItem {
  final String baremeId;
  final String baremeName;
  final String? selectedLevel;
  final double selectedScore;
  final double circleConfidence;
  final String circleDescription;
  final bool fallbackUsed;
  String? userOverrideLevel;
  double? userOverrideScore;

  StudentEvaluationItem({
    required this.baremeId,
    required this.baremeName,
    this.selectedLevel,
    required this.selectedScore,
    required this.circleConfidence,
    this.circleDescription = '',
    this.fallbackUsed = false,
    this.userOverrideLevel,
    this.userOverrideScore,
  });

  String get effectiveLevel => userOverrideLevel ?? selectedLevel ?? '---';
  double get effectiveScore => userOverrideScore ?? selectedScore;
  bool get needsReview => circleConfidence < 0.7 || selectedLevel == null;

  factory StudentEvaluationItem.fromJson(Map<String, dynamic> json) {
    return StudentEvaluationItem(
      baremeId: json['baremeId'] as String? ?? '',
      baremeName: json['baremeName'] as String? ?? '',
      selectedLevel: json['selected_level'] as String?,
      selectedScore: (json['selected_score'] as num?)?.toDouble() ?? 0,
      circleConfidence: (json['circle_confidence'] as num?)?.toDouble() ?? 0.5,
      circleDescription: json['circle_description'] as String? ?? '',
      fallbackUsed: json['fallback_used'] as bool? ?? false,
    );
  }

  StudentEvaluationItem copyWith({
    String? baremeId,
    String? baremeName,
    String? selectedLevel,
    double? selectedScore,
    double? circleConfidence,
    String? circleDescription,
    bool? fallbackUsed,
    String? userOverrideLevel,
    double? userOverrideScore,
  }) {
    return StudentEvaluationItem(
      baremeId: baremeId ?? this.baremeId,
      baremeName: baremeName ?? this.baremeName,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      selectedScore: selectedScore ?? this.selectedScore,
      circleConfidence: circleConfidence ?? this.circleConfidence,
      circleDescription: circleDescription ?? this.circleDescription,
      fallbackUsed: fallbackUsed ?? this.fallbackUsed,
      userOverrideLevel: userOverrideLevel ?? this.userOverrideLevel,
      userOverrideScore: userOverrideScore ?? this.userOverrideScore,
    );
  }
}

class OcrStats {
  final int total;
  final int detected;
  final int lowConfidence;
  final int fallbackUsed;

  OcrStats({
    required this.total,
    required this.detected,
    required this.lowConfidence,
    required this.fallbackUsed,
  });

  factory OcrStats.fromJson(Map<String, dynamic> json) {
    return OcrStats(
      total: json['total'] as int? ?? 0,
      detected: json['detected'] as int? ?? 0,
      lowConfidence: json['low_confidence'] as int? ?? 0,
      fallbackUsed: json['fallback_used'] as int? ?? 0,
    );
  }
}

class StudentOcrResult {
  final List<StudentEvaluationItem> items;
  final double overallConfidence;
  final List<String> undetectedBaremes;
  final List<String> warnings;
  final OcrStats stats;

  StudentOcrResult({
    required this.items,
    required this.overallConfidence,
    this.undetectedBaremes = const [],
    this.warnings = const [],
    required this.stats,
  });

  factory StudentOcrResult.fromJson(Map<String, dynamic> json) {
    return StudentOcrResult(
      items: (json['student_evaluation'] as List?)
              ?.map((e) => StudentEvaluationItem.fromJson(e))
              .toList() ??
          [],
      overallConfidence:
          (json['overall_confidence'] as num?)?.toDouble() ?? 0.5,
      undetectedBaremes: (json['undetected_baremes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      warnings:
          (json['warnings'] as List?)?.map((e) => e.toString()).toList() ?? [],
      stats: OcrStats.fromJson(json['stats'] ?? {}),
    );
  }
}

class TableStructure {
  final List<TableBareme> baremes;

  TableStructure({required this.baremes});

  factory TableStructure.fromJson(Map<String, dynamic> json) {
    return TableStructure(
      baremes: (json['baremes'] as List?)
              ?.map((e) => TableBareme.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'baremes': baremes.map((b) => b.toJson()).toList(),
      };
}

class TableBareme {
  final String appBaremeId;
  final String appBaremeName;
  final String name;
  final Map<String, double> scores;

  TableBareme({
    required this.appBaremeId,
    required this.appBaremeName,
    required this.name,
    required this.scores,
  });

  factory TableBareme.fromJson(Map<String, dynamic> json) {
    return TableBareme(
      appBaremeId:
          json['appBaremeId'] as String? ?? json['id'] as String? ?? '',
      appBaremeName:
          json['appBaremeName'] as String? ?? json['name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      scores: json['scores'] != null
          ? Map<String, double>.from(
              (json['scores'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
              ),
            )
          : {},
    );
  }

  Map<String, dynamic> toJson() => {
        'appBaremeId': appBaremeId,
        'appBaremeName': appBaremeName,
        'name': name,
        'scores': scores,
      };
}
