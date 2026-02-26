import 'package:Taqyem/taqyem/payment/date_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CardDistributionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ثوابت النظام
  static const int DAILY_LIMIT_PER_CARD = 14;
  static const int TOTAL_CARDS = 3;
  static const int MAX_DAILY_SUBSCRIPTIONS = 42; // 14 × 3
  
  // أسماء البطاقات
  static const List<String> CARD_IDS = ['A', 'B', 'C'];
  
  // مفتاح التناوب (Rotation)
  String _lastUsedCardId = 'C'; // نبدأ بآخر بطاقة ليكون التالي A

  /// الحصول على إحصائيات اليوم الحالي
  Future<Map<String, dynamic>> getTodayStats() async {
    final today = DateUtils.formatDate(DateTime.now());
    final docRef = _firestore.collection('dailyStats').doc(today);
    
    final doc = await docRef.get();
    
    if (!doc.exists) {
      // إنشاء إحصائيات جديدة لليوم
      final initialStats = {
        'date': today,
        'cardA_count': 0,
        'cardB_count': 0,
        'cardC_count': 0,
        'totalToday': 0,
        'lastReset': FieldValue.serverTimestamp(),
      };
      await docRef.set(initialStats);
      return initialStats;
    }
    
    return doc.data() as Map<String, dynamic>;
  }

  /// تحديث إحصائيات البطاقة
  Future<void> updateCardStats(String cardId) async {
    final today = DateUtils.formatDate(DateTime.now());
    final docRef = _firestore.collection('dailyStats').doc(today);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      
      if (!doc.exists) {
        // إنشاء إحصائية جديدة
        final stats = {
          'date': today,
          'cardA_count': cardId == 'A' ? 1 : 0,
          'cardB_count': cardId == 'B' ? 1 : 0,
          'cardC_count': cardId == 'C' ? 1 : 0,
          'totalToday': 1,
          'lastReset': FieldValue.serverTimestamp(),
        };
        transaction.set(docRef, stats);
      } else {
        // تحديث الإحصائية الموجودة
        final data = doc.data() as Map<String, dynamic>;
        final field = 'card${cardId}_count';
        
        transaction.update(docRef, {
          field: (data[field] ?? 0) + 1,
          'totalToday': (data['totalToday'] ?? 0) + 1,
        });
      }
    });
    
    // تحديث آخر بطاقة مستخدمة للتناوب
    _lastUsedCardId = cardId;
  }

  /// اختيار البطاقة الأنسب (استراتيجية: الأقل استخداماً)
  Future<String?> selectBestCard() async {
    final stats = await getTodayStats();
    
    // حساب عدد المشتركين لكل بطاقة اليوم
    final cardCounts = {
      'A': stats['cardA_count'] ?? 0,
      'B': stats['cardB_count'] ?? 0,
      'C': stats['cardC_count'] ?? 0,
    };
    
    // التحقق من السقف اليومي الإجمالي
    final totalToday = stats['totalToday'] ?? 0;
    if (totalToday >= MAX_DAILY_SUBSCRIPTIONS) {
      print('⚠️ تم بلوغ الحد الأقصى اليومي ($MAX_DAILY_SUBSCRIPTIONS مشترك)');
      return null; // لا يمكن الاشتراك اليوم
    }
    
    // البحث عن البطاقات المتاحة
    final availableCards = cardCounts.entries
        .where((entry) => entry.value < DAILY_LIMIT_PER_CARD)
        .map((entry) => entry.key)
        .toList();
    
    if (availableCards.isEmpty) {
      print('⚠️ جميع البطاقات وصلت للحد الأقصى اليومي');
      return null;
    }
    
    // استراتيجية 1: البطاقة الأقل استخداماً
    String bestCard = availableCards.reduce((a, b) =>
        cardCounts[a]! < cardCounts[b]! ? a : b);
    
    print('✅ تم اختيار البطاقة $bestCard (${cardCounts[bestCard]}/${DAILY_LIMIT_PER_CARD})');
    return bestCard;
  }

  /// اختيار البطاقة بالتناوب الدائري (استراتيجية بديلة)
  Future<String?> selectCardByRotation() async {
    final stats = await getTodayStats();
    
    // التحقق من السقف اليومي الإجمالي
    final totalToday = stats['totalToday'] ?? 0;
    if (totalToday >= MAX_DAILY_SUBSCRIPTIONS) {
      return null;
    }
    
    // ترتيب البطاقات للتناوب
    final cardOrder = ['A', 'B', 'C'];
    int startIndex = (cardOrder.indexOf(_lastUsedCardId) + 1) % 3;
    
    // البحث عن أول بطاقة متاحة
    for (int i = 0; i < 3; i++) {
      final cardId = cardOrder[(startIndex + i) % 3];
      final count = stats['card${cardId}_count'] ?? 0;
      
      if (count < DAILY_LIMIT_PER_CARD) {
        return cardId;
      }
    }
    
    return null; // لا توجد بطاقات متاحة
  }

  /// التحقق من إمكانية الاشتراك اليوم
  Future<bool> canSubscribeToday() async {
    final stats = await getTodayStats();
    final totalToday = stats['totalToday'] ?? 0;
    return totalToday < MAX_DAILY_SUBSCRIPTIONS;
  }
// في كلاس CardDistributionService أضف:

  /// الحصول على معلومات البطاقة كاملة (مع QR و RIB)
  Future<Map<String, dynamic>?> getCardDetails(String cardId) async {
    try {
      final doc = await _firestore.collection('cards').doc(cardId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('خطأ في جلب معلومات البطاقة: $e');
      return null;
    }
  }

  /// تحديث معلومات البطاقة (للمسؤول)
  Future<bool> updateCardDetails(String cardId, {
    required String qrCodeUrl,
    required String ribNumber,
    String? bankName,
  }) async {
    try {
      await _firestore.collection('cards').doc(cardId).set({
        'id': cardId,
        'qrCodeUrl': qrCodeUrl,
        'ribNumber': ribNumber,
        'bankName': bankName ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'admin',
      }, SetOptions(merge: true));
      
      print('✅ تم تحديث معلومات البطاقة $cardId');
      return true;
    } catch (e) {
      print('❌ خطأ في تحديث البطاقة: $e');
      return false;
    }
  }

  /// جلب QR Code لبطاقة معينة
  Future<String?> getCardQRCode(String cardId) async {
    final details = await getCardDetails(cardId);
    return details?['qrCodeUrl'];
  }

  /// جلب RIB لبطاقة معينة
  Future<String?> getCardRIB(String cardId) async {
    final details = await getCardDetails(cardId);
    return details?['ribNumber'];
  }
  
  /// الحصول على إحصائيات البطاقات بشكل مفصل
  Future<Map<String, dynamic>> getDetailedStats() async {
    final stats = await getTodayStats();
    
    return {
      'cards': [
        {
          'id': 'A',
          'name': 'البطاقة الأولى',
          'count': stats['cardA_count'] ?? 0,
          'limit': DAILY_LIMIT_PER_CARD,
          'remaining': DAILY_LIMIT_PER_CARD - (stats['cardA_count'] ?? 0),
        },
        {
          'id': 'B',
          'name': 'البطاقة الثانية',
          'count': stats['cardB_count'] ?? 0,
          'limit': DAILY_LIMIT_PER_CARD,
          'remaining': DAILY_LIMIT_PER_CARD - (stats['cardB_count'] ?? 0),
        },
        {
          'id': 'C',
          'name': 'البطاقة الثالثة',
          'count': stats['cardC_count'] ?? 0,
          'limit': DAILY_LIMIT_PER_CARD,
          'remaining': DAILY_LIMIT_PER_CARD - (stats['cardC_count'] ?? 0),
        },
      ],
      'totalToday': stats['totalToday'] ?? 0,
      'maxDaily': MAX_DAILY_SUBSCRIPTIONS,
      'remainingTotal': MAX_DAILY_SUBSCRIPTIONS - (stats['totalToday'] ?? 0),
      'date': stats['date'],
    };
  }

  /// إعادة تعيين الإحصائيات (للاستخدام في Cloud Function)
  Future<void> resetDailyStats() async {
    final yesterday = DateUtils.formatDate(
      DateTime.now().subtract(Duration(days: 1))
    );
    final today = DateUtils.formatDate(DateTime.now());
    
    // أرشفة إحصائيات الأمس (اختياري)
    final yesterdayStats = await _firestore.collection('dailyStats').doc(yesterday).get();
    if (yesterdayStats.exists) {
      await _firestore.collection('dailyStats_archive').doc(yesterday).set(
        yesterdayStats.data() as Map<String, dynamic>
      );
    }
    
    // إنشاء إحصائيات اليوم الجديد
    await _firestore.collection('dailyStats').doc(today).set({
      'date': today,
      'cardA_count': 0,
      'cardB_count': 0,
      'cardC_count': 0,
      'totalToday': 0,
      'lastReset': FieldValue.serverTimestamp(),
    });
  }
}