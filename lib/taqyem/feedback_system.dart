import 'package:flutter/material.dart';
import 'package:feedback/feedback.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class FeedbackSystem {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static void showFeedbackDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Utilisation d'un Builder pour le contexte RTL
        return Builder(
          builder: (context) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'شاركنا رأيك',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'كيف يمكننا تحسين تجربتك؟',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  _buildFeedbackButton(
                    context,
                    icon: Icons.thumb_up,
                    label: 'تعليق إيجابي',
                    onPressed: () => _showFeedbackInput(context, 'إيجابي'),
                  ),
                  const SizedBox(height: 12),
                  _buildFeedbackButton(
                    context,
                    icon: Icons.thumb_down,
                    label: 'الإبلاغ عن مشكلة',
                    onPressed: () => _showFeedbackInput(context, 'مشكلة'),
                  ),
                  const SizedBox(height: 12),
                  _buildFeedbackButton(
                    context,
                    icon: Icons.lightbulb,
                    label: 'اقتراح تحسين',
                    onPressed: () => _showFeedbackInput(context, 'اقتراح'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildFeedbackButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
static void _showFeedbackInput(BuildContext context, String feedbackType) {
  if (!context.mounted) return;  // Vérification avant toute opération
  
  Navigator.pop(context);
  
  try {
    BetterFeedback.of(context).show((feedback) async {
      await _saveFeedbackToFirestore(
        type: feedbackType,
        text: feedback.text,
        screenshot: feedback.screenshot,
        context: context,  // Passez le contexte ici
      );
    });
  } catch (e) {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
static Future<void> _saveFeedbackToFirestore({
  required String type,
  required String text,
  required Uint8List? screenshot,
  required BuildContext context,
}) async {
  try {
    // Vérifiez si le contexte est toujours valide
    if (context.mounted) {  // Utilisez context.mounted au lieu de mounted
      final user = _auth.currentUser;
      final now = DateTime.now();

      await _firestore.collection('feedback').add({
        'type': type,
        'text': text,
        'userId': user?.uid ?? 'anonymous',
        'userEmail': user?.email ?? 'anonymous',
        'userName': user?.displayName ?? 'مستخدم مجهول',
        'createdAt': now,
        'formattedDate': DateFormat('yyyy-MM-dd HH:mm', 'ar').format(now),
        'status': 'غير مقروء',
        'screenshot': screenshot != null,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('شكراً لك! تم استلام ملاحظتك بنجاح'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء إرسال الملاحظة'),
          backgroundColor: Colors.red,
        ),
      );
    }
    print('Error saving feedback: $e');
  }
}


  static Stream<int> getUnreadCount() {
    return _firestore
        .collection('feedback')
        .where('status', isEqualTo: 'غير مقروء')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  static Future<void> markAsRead(String feedbackId) async {
    await _firestore.collection('feedback').doc(feedbackId).update({
      'status': 'مقروء',
    });
  }
}