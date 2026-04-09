import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  late HttpsCallable _sendNotificationCallable;
  late HttpsCallable _updateTokenCallable;

  Future<void> initialize() async {
    // Initialiser Firebase Functions
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      _sendNotificationCallable =
          functions.httpsCallable('sendNotificationToAll');
      _updateTokenCallable = functions.httpsCallable('updateFCMToken');
    } catch (e) {
      print('Firebase Functions initialization error: $e');
    }

    // Demander la permission de notification
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permission de notification accordée');
      await _getAndSaveToken();
    } else {
      print('Permission de notification refusée');
    }

    // Gérer les messages en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Gérer les messages quand l'app est ouverte depuis une notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Gérer les messages quand l'app est fermée
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleInitialMessage(initialMessage);
    }
  }

  Future<void> _getAndSaveToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
        await _saveTokenViaCloudFunction(token);
      }
    } catch (e) {
      print('Erreur lors de la récupération du token: $e');
    }
  }

  Future<void> _saveTokenViaCloudFunction(String token) async {
    try {
      if (_updateTokenCallable != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _updateTokenCallable.call({
            'token': token,
            'userId': user.uid,
          });
          print('Token sauvegardé via Cloud Function pour user ${user.uid}');
        }
      }
    } catch (e) {
      print('Erreur Cloud Function: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde du token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Message reçu en foreground: ${message.notification?.title}');

    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        data: message.data,
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('App ouverte depuis une notification');
    _handleNotificationTap(message.data);
  }

  void _handleInitialMessage(RemoteMessage message) {
    print('Message initial reçu');
    _handleNotificationTap(message.data);
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    print('Données de notification: $data');
  }

  void _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    print('Notification: $title - $body');
  }

  // Méthode pour envoyer une notification à tous les utilisateurs via Cloud Function
  static Future<void> sendNotificationToAllUsers({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final sendNotification = functions.httpsCallable('sendNotificationToAll');

      final result = await sendNotification.call({
        'title': title,
        'message': body,
        'imageUrl': imageUrl,
      });

      print('Résultat notification: ${result.data}');
    } catch (e) {
      print('Erreur Cloud Function: $e');
      await _sendNotificationViaFirestore(title, body);
    }
  }

  // Fallback: sauvegarder dans Firestore
  static Future<void> _sendNotificationViaFirestore(
      String title, String body) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('fcmToken', isNotEqualTo: null)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in usersSnapshot.docs) {
        final notifRef = doc.reference.collection('notifications').doc();
        batch.set(notifRef, {
          'title': title,
          'body': body,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      await batch.commit();
      print(
          'Notifications créées pour ${usersSnapshot.docs.length} utilisateurs');
    } catch (e) {
      print('Erreur: $e');
    }
  }

  // Méthode pour envoyer une notification à un utilisateur spécifique
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final sendNotification =
          functions.httpsCallable('sendNotificationToUser');

      await sendNotification.call({
        'userId': userId,
        'title': title,
        'message': body,
      });
    } catch (e) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }
  }

  // Méthode pour envoyer une notification à un groupe d'utilisateurs
  static Future<void> sendNotificationToGroup({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (var userId in userIds) {
        final notifRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc();

        batch.set(notifRef, {
          'title': title,
          'body': body,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      await batch.commit();
      print('Notifications envoyées à ${userIds.length} utilisateurs');
    } catch (e) {
      print('Erreur lors de l\'envoi des notifications de groupe: $e');
    }
  }
}
