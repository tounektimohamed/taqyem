const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

// Fonction pour envoyer une notification à tous les utilisateurs
exports.sendNotificationToAll = functions.https.onCall(async (data, context) => {
  const { title, message, imageUrl } = data;

  if (!title || !message) {
    throw new functions.https.HttpsError('invalid-argument', 'Titre et message requis');
  }

  try {
    // Récupérer tous les tokens FCM
    const usersSnapshot = await db.collection('users')
      .where('fcmToken', '!=', null)
      .get();

    const tokens = [];
    usersSnapshot.forEach(doc => {
      const token = doc.data().fcmToken;
      if (token) {
        tokens.push(token);
      }
    });

    if (tokens.length === 0) {
      return { success: true, message: 'Aucun token FCM trouvé', count: 0 };
    }

    // Envoyer la notification à tous les tokens
    const batchSize = 500;
    let successCount = 0;

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batch = tokens.slice(i, i + batchSize);
      
      // Construire le payload avec ou sans image
      const payload = {
        notification: {
          title: title,
          body: message,
          ...(imageUrl && { imageUrl: imageUrl }),
        },
        data: {
          type: 'admin_notification',
          click_action: 'OPEN_APP',
        },
        tokens: batch,
      };

      const response = await admin.messaging().sendEachForMulticast(payload);
      successCount += response.successCount;
    }

    // Sauvegarder la notification dans l'historique
    await db.collection('admin_notifications').add({
      title: title,
      message: message,
      imageUrl: imageUrl || null,
      target: 'all',
      recipientsCount: successCount,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { 
      success: true, 
      message: `Notification envoyée à ${successCount} utilisateurs`,
      count: successCount 
    };
  } catch (error) {
    console.error('Erreur:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Fonction pour mettre à jour le token FCM de l'utilisateur
exports.updateFCMToken = functions.https.onCall(async (data, context) => {
  const { token, userId } = data;

  if (!token) {
    throw new functions.https.HttpsError('invalid-argument', 'Token requis');
  }

  try {
    // Si userId est fourni directement, l'utiliser
    if (userId) {
      await db.collection('Users').doc(userId).set({
        fcmToken: token,
        tokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    } else {
      // Sinon chercher dans les documents pending_tokens
      const tokenDoc = await db.collection('pending_tokens').doc(token).get();
      
      if (tokenDoc.exists) {
        const uid = tokenDoc.data().userId;
        if (uid) {
          await db.collection('Users').doc(uid).set({
            fcmToken: token,
            tokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
          
          await db.collection('pending_tokens').doc(token).delete();
        }
      }
    }
    
    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Fonction pour envoyer une notification à un utilisateur spécifique
exports.sendNotificationToUser = functions.https.onCall(async (data, context) => {
  const { userId, title, message, imageUrl } = data;

  if (!userId || !title || !message) {
    throw new functions.https.HttpsError('invalid-argument', 'Paramètres manquants');
  }

  try {
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();
    const token = userData?.fcmToken;

    if (!token) {
      return { success: false, message: 'Token FCM non trouvé pour cet utilisateur' };
    }

    const payload = {
      notification: {
        title: title,
        body: message,
        ...(imageUrl && { imageUrl: imageUrl }),
      },
      data: {
        type: 'payment_request',
        userId: userId,
      },
      token: token,
    };

    await admin.messaging().send(payload);

    // Sauvegarder dans les notifications de l'utilisateur
    await db.collection('users').doc(userId).collection('notifications').add({
      title: title,
      body: message,
      imageUrl: imageUrl || null,
      type: 'payment_request',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
    });

    return { success: true, message: 'Notification envoyée' };
  } catch (error) {
    console.error('Erreur:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});