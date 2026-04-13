import 'package:cloud_firestore/cloud_firestore.dart';

class ExtractedBareme {
  final int position;
  final String name;
  final double confidence;
  final Map<String, double> scores;
  final double max;
  final bool hasSubThresholds;
  final List<String> rawCellValues;

  ExtractedBareme({
    required this.position,
    required this.name,
    required this.confidence,
    required this.scores,
    required this.max,
    this.hasSubThresholds = false,
    this.rawCellValues = const [],
  });

  factory ExtractedBareme.fromJson(Map<String, dynamic> json) {
    return ExtractedBareme(
      position: json['position'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      max: (json['max'] as num?)?.toDouble() ?? 0,
      hasSubThresholds: json['has_sub_thresholds'] as bool? ?? false,
      rawCellValues: (json['raw_cell_values'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      scores: {
        '---': (json['scores']?['---'] as num?)?.toDouble() ?? 0,
        '+--': (json['scores']?['+--'] as num?)?.toDouble() ?? 0,
        '++-': (json['scores']?['++-'] as num?)?.toDouble() ?? 0,
        '+++': (json['scores']?['+++'] as num?)?.toDouble() ?? 0,
      },
    );
  }

  Map<String, dynamic> toJson() => {
        'position': position,
        'name': name,
        'confidence': confidence,
        'max': max,
        'has_sub_thresholds': hasSubThresholds,
        'raw_cell_values': rawCellValues,
        'scores': scores,
      };

  ExtractedBareme copyWith({
    int? position,
    String? name,
    double? confidence,
    Map<String, double>? scores,
    double? max,
    bool? hasSubThresholds,
    List<String>? rawCellValues,
  }) {
    return ExtractedBareme(
      position: position ?? this.position,
      name: name ?? this.name,
      confidence: confidence ?? this.confidence,
      scores: scores ?? this.scores,
      max: max ?? this.max,
      hasSubThresholds: hasSubThresholds ?? this.hasSubThresholds,
      rawCellValues: rawCellValues ?? this.rawCellValues,
    );
  }
}

class OcrResult {
  final List<ExtractedBareme> baremes;
  final double totalMax;
  final double extractionConfidence;
  final List<String> warnings;

  OcrResult({
    required this.baremes,
    required this.totalMax,
    required this.extractionConfidence,
    this.warnings = const [],
  });

  factory OcrResult.fromJson(Map<String, dynamic> json) {
    return OcrResult(
      baremes: (json['baremes'] as List?)
              ?.map((e) => ExtractedBareme.fromJson(e))
              .toList() ??
          [],
      totalMax: (json['total_max'] as num?)?.toDouble() ?? 0,
      extractionConfidence:
          (json['extraction_confidence'] as num?)?.toDouble() ?? 0,
      warnings:
          (json['warnings'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class AppBareme {
  final String id;
  final String name;
  final int order;
  List<String>? currentCustomNotes;

  AppBareme({
    required this.id,
    required this.name,
    required this.order,
    this.currentCustomNotes,
  });

  factory AppBareme.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppBareme(
      id: doc.id,
      name: data['name'] as String? ?? '',
      order: data['order'] as int? ?? 0,
      currentCustomNotes:
          (data['customNotes'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}

class BaremeMatch {
  final ExtractedBareme extracted;
  AppBareme? appBareme;
  double matchConfidence;
  bool isAutoMatched;
  bool isConfirmedByUser;

  BaremeMatch({
    required this.extracted,
    this.appBareme,
    this.matchConfidence = 0.6,
    this.isAutoMatched = false,
    this.isConfirmedByUser = false,
  });

  BaremeMatch copyWith({
    ExtractedBareme? extracted,
    AppBareme? appBareme,
    double? matchConfidence,
    bool? isAutoMatched,
    bool? isConfirmedByUser,
  }) {
    return BaremeMatch(
      extracted: extracted ?? this.extracted,
      appBareme: appBareme ?? this.appBareme,
      matchConfidence: matchConfidence ?? this.matchConfidence,
      isAutoMatched: isAutoMatched ?? this.isAutoMatched,
      isConfirmedByUser: isConfirmedByUser ?? this.isConfirmedByUser,
    );
  }
}

class MappingHistory {
  final String tableName;
  final String appBaremeId;
  final String appBaremeName;
  int usedCount;
  DateTime lastUsed;

  MappingHistory({
    required this.tableName,
    required this.appBaremeId,
    required this.appBaremeName,
    this.usedCount = 0,
    DateTime? lastUsed,
  }) : lastUsed = lastUsed ?? DateTime.now();

  factory MappingHistory.fromJson(Map<String, dynamic> json) {
    return MappingHistory(
      tableName: json['tableName'] as String? ?? '',
      appBaremeId: json['appBaremeId'] as String? ?? '',
      appBaremeName: json['appBaremeName'] as String? ?? '',
      usedCount: json['usedCount'] as int? ?? 0,
      lastUsed: json['lastUsed'] != null
          ? DateTime.tryParse(json['lastUsed'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'tableName': tableName,
        'appBaremeId': appBaremeId,
        'appBaremeName': appBaremeName,
        'usedCount': usedCount,
        'lastUsed': lastUsed.toIso8601String(),
      };

  double get confidence => usedCount / (usedCount + 1);

  bool get isNotEmpty => tableName.isNotEmpty && appBaremeId.isNotEmpty;

  static MappingHistory empty() => MappingHistory(
        tableName: '',
        appBaremeId: '',
        appBaremeName: '',
      );
}
