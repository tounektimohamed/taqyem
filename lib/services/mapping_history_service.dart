import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ocr_models.dart';

class MappingHistoryService {
  static Future<List<MappingHistory>> load(
    String uid,
    String classId,
    String matiereId,
  ) async {
    final docId = '$classId-$matiereId';
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('ocr_mapping_history')
        .doc(docId)
        .get();

    if (!doc.exists || doc.data() == null) {
      return [];
    }

    final data = doc.data()!;
    final mappings = data['mappings'] as List?;
    if (mappings == null) {
      return [];
    }

    return mappings.map((m) => MappingHistory.fromJson(m)).toList();
  }

  static List<BaremeMatch> applyHistory(
    List<BaremeMatch> matches,
    List<MappingHistory> history,
  ) {
    for (final match in matches) {
      final historyEntry = history.firstWhere(
        (h) => h.tableName == match.extracted.name,
        orElse: () => MappingHistory.empty(),
      );

      if (historyEntry.isNotEmpty && historyEntry.confidence >= 0.7) {
        match.appBareme = null;
        match.matchConfidence = historyEntry.confidence;
        match.isAutoMatched = true;
      }
    }
    return matches;
  }

  static Future<void> save(
    String uid,
    String classId,
    String matiereId,
    List<BaremeMatch> confirmedMatches,
  ) async {
    final docId = '$classId-$matiereId';
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('ocr_mapping_history')
        .doc(docId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      List<Map<String, dynamic>> existing = [];
      if (snap.exists && snap.data() != null) {
        final data = snap.data()!;
        final mappings = data['mappings'] as List?;
        if (mappings != null) {
          existing = List<Map<String, dynamic>>.from(mappings);
        }
      }

      for (final match in confirmedMatches) {
        if (match.appBareme == null) continue;

        final idx = existing.indexWhere(
          (m) => m['tableName'] == match.extracted.name,
        );

        if (idx >= 0) {
          existing[idx]['usedCount'] = (existing[idx]['usedCount'] ?? 0) + 1;
          existing[idx]['lastUsed'] = DateTime.now().toIso8601String();
          existing[idx]['appBaremeId'] = match.appBareme!.id;
          existing[idx]['appBaremeName'] = match.appBareme!.name;
        } else {
          existing.add({
            'tableName': match.extracted.name,
            'appBaremeId': match.appBareme!.id,
            'appBaremeName': match.appBareme!.name,
            'usedCount': 1,
            'lastUsed': DateTime.now().toIso8601String(),
          });
        }
      }

      tx.set(
        ref,
        {
          'mappings': existing,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  static Future<List<AppBareme>> loadAppBaremes(
    String uid,
    String classId,
    String matiereId,
  ) async {
    final docId = '$classId-$matiereId';
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('baremes')
        .doc(docId)
        .collection('items')
        .orderBy('order')
        .get();

    return snap.docs.map((doc) => AppBareme.fromFirestore(doc)).toList();
  }
}
