import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FeedbackManagementPage extends StatefulWidget {
  const FeedbackManagementPage({Key? key}) : super(key: key);

  @override
  _FeedbackManagementPageState createState() => _FeedbackManagementPageState();
}

class _FeedbackManagementPageState extends State<FeedbackManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterStatus = 'الكل';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة التعليقات'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _filterStatus == 'الكل'
                  ? _firestore.collection('feedback').orderBy('createdAt', descending: true).snapshots()
                  : _firestore.collection('feedback').where('status', isEqualTo: _filterStatus).orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final feedbacks = snapshot.data!.docs;

                if (feedbacks.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد تعليقات متاحة',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: feedbacks.length,
                  itemBuilder: (context, index) {
                    final feedback = feedbacks[index].data() as Map<String, dynamic>;
                    return _buildFeedbackCard(feedback, feedbacks[index].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusFilterButton('الكل'),
          _buildStatusFilterButton('غير مقروء'),
          _buildStatusFilterButton('مقروء'),
          _buildStatusFilterButton('تمت المعالجة'),
        ],
      ),
    );
  }

  Widget _buildStatusFilterButton(String status) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _filterStatus == status ? Colors.blue : Colors.grey,
      ),
      onPressed: () {
        setState(() {
          _filterStatus = status;
        });
      },
      child: Text(status),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback, String feedbackId) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () => _showFeedbackDetails(feedback, feedbackId),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(feedback['status']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      feedback['status'] ?? 'غير معروف',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Text(
                    feedback['formattedDate'] ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                feedback['type'] ?? 'بدون نوع',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                feedback['text'] ?? 'لا يوجد نص',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (feedback['userName'] != null)
                Text(
                  'من: ${feedback['userName']}',
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'غير مقروء':
        return Colors.red;
      case 'مقروء':
        return Colors.blue;
      case 'تمت المعالجة':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showFeedbackDetails(Map<String, dynamic> feedback, String feedbackId) async {
    await _firestore.collection('feedback').doc(feedbackId).update({
      'status': 'مقروء',
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feedback['type'] ?? 'تفاصيل التعليق'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(feedback['text'] ?? 'لا يوجد نص'),
              const SizedBox(height: 16),
              Text('النوع: ${feedback['type']}'),
              Text('الحالة: ${feedback['status']}'),
              Text('التاريخ: ${feedback['formattedDate']}'),
              Text('المستخدم: ${feedback['userName']} (${feedback['userEmail']})'),
              // Vous pouvez ajouter l'affichage de la capture d'écran ici si vous l'avez stockée
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('feedback').doc(feedbackId).update({
                'status': 'تمت المعالجة',
              });
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('تمت المعالجة'),
          ),
        ],
      ),
    );
  }
}