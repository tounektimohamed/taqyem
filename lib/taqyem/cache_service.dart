// lib/services/cache_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseCacheService {
  static final FirebaseCacheService _instance = FirebaseCacheService._internal();
  factory FirebaseCacheService() => _instance;
  
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheDuration = const Duration(minutes: 5);

  FirebaseCacheService._internal();

  Future<dynamic> getData({
    required String collection,
    required String document,
    String? subCollection,
    String? subDocument,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _generateCacheKey(collection, document, subCollection, subDocument);
    
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection(collection)
          .doc(document);

      dynamic data;
      if (subCollection != null && subDocument != null) {
        data = await docRef.collection(subCollection).doc(subDocument).get().then((snap) => snap.data());
      } else {
        data = await docRef.get().then((snap) => snap.data());
      }

      _cache[cacheKey] = data;
      _cacheTimestamps[cacheKey] = DateTime.now();
      return data;
    } catch (e) {
      return _cache[cacheKey];
    }
  }

  void invalidateCache({String? key}) {
    if (key != null) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }

  String _generateCacheKey(
    String collection, 
    String document, 
    String? subCollection, 
    String? subDocument
  ) {
    return '$collection/$document${subCollection != null ? '/$subCollection' : ''}${subDocument != null ? '/$subDocument' : ''}';
  }

  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }
}