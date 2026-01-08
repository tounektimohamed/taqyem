import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseCacheService {
  static final FirebaseCacheService _instance = FirebaseCacheService._internal();
  factory FirebaseCacheService() => _instance;
  FirebaseCacheService._internal();

  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheDuration = const Duration(minutes: 5);

  Future<dynamic> getData({
    required String collection,
    required String document,
    String? subCollection,
    String? subDocument,
    bool forceRefresh = false,
  }) async {
    String cacheKey = _generateCacheKey(
      collection, 
      document, 
      subCollection, 
      subDocument
    );

    // Vérifier si le cache est valide
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }

    // Charger depuis Firebase
    dynamic data;
    try {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection(collection)
          .doc(document);

      if (subCollection != null && subDocument != null) {
        data = await docRef
            .collection(subCollection)
            .doc(subDocument)
            .get()
            .then((snap) => snap.data());
      } else {
        data = await docRef.get().then((snap) => snap.data());
      }

      // Mettre en cache
      _cache[cacheKey] = data;
      _cacheTimestamps[cacheKey] = DateTime.now();
    } catch (e) {
      print('Erreur chargement Firestore: $e');
      return _cache[cacheKey]; // Retourner ancienne valeur si disponible
    }

    return data;
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

  void invalidateCache({String? key}) {
    if (key != null) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }
}
class AppDataRepository {
  static final AppDataRepository _instance = AppDataRepository._internal();
  factory AppDataRepository() => _instance;
  AppDataRepository._internal();

  // Cache pour les données fréquemment utilisées
  late Map<String, dynamic> _userDataCache;
  late Map<String, dynamic> _classDataCache;
  late Map<String, dynamic> _studentsCache;
  
  // Garder les références aux streams
  StreamSubscription? _userDataSubscription;
  StreamSubscription? _classDataSubscription;

  // Charger toutes les données essentielles une fois
  Future<void> initializeEssentialData(String userId, String classId) async {
    await Future.wait([
      _loadUserData(userId),
      _loadClassData(classId),
      _loadStudentsData(userId, classId),
    ]);
  }

  Future<void> _loadUserData(String userId) async {
    if (_userDataCache != null) return;
    
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .get();
    
    _userDataCache = doc.data() ?? {};
  }

  Future<void> _loadClassData(String classId) async {
    if (_classDataCache != null) return;
    
    final doc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .get();
    
    _classDataCache = doc.data() ?? {};
  }

  Future<void> _loadStudentsData(String userId, String classId) async {
    if (_studentsCache != null) return;
    
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('user_classes')
        .doc(classId)
        .collection('students')
        .get();
    
    _studentsCache = {
      'students': snapshot.docs,
      'lastUpdated': DateTime.now(),
    };
  }

  // Méthodes d'accès rapide
  dynamic getUserData() => _userDataCache;
  dynamic getClassData() => _classDataCache;
  dynamic getStudentsData() => _studentsCache?['students'];

  void dispose() {
    _userDataSubscription?.cancel();
    _classDataSubscription?.cancel();
  }
}