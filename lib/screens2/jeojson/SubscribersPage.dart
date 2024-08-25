import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class SubscribersPage extends StatefulWidget {
  const SubscribersPage({Key? key}) : super(key: key);

  @override
  _SubscribersPageState createState() => _SubscribersPageState();
}

class _SubscribersPageState extends State<SubscribersPage> {
  final List<String> _emails = [];

  void _copyEmailsToClipboard() {
    final emailString = _emails.join(', ');
    Clipboard.setData(ClipboardData(text: emailString));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emails copiés dans le presse-papier')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des abonnés'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _emails.isNotEmpty ? _copyEmailsToClipboard : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('subscribers').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var subscribers = snapshot.data!.docs;
                _emails.clear();
                for (var subscriber in subscribers) {
                  var data = subscriber.data() as Map<String, dynamic>;
                  var email = data['email'] ?? 'Pas d\'email';
                  _emails.add(email);
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Date d\'abonnement')),
                    ],
                    rows: subscribers.map((subscriber) {
                      var data = subscriber.data() as Map<String, dynamic>;
                      var email = data['email'] ?? 'Pas d\'email';
                      var timestamp = data['timestamp'] as Timestamp;
                      var date = timestamp.toDate();

                      return DataRow(cells: [
                        DataCell(Text(email)),
                        DataCell(Text(date.toLocal().toString())),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
