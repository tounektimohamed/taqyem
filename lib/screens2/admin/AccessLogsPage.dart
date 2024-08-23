import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AccessLogsPage extends StatelessWidget {
  const AccessLogsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journaux d\'accès'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('access_logs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aucun journal d\'accès disponible.'));
          }

          var logs = snapshot.data!.docs;

          // Regrouper les journaux par semaine
          var groupedLogs = _groupLogsByWeek(logs);

          return ListView.builder(
            itemCount: groupedLogs.keys.length,
            itemBuilder: (context, index) {
              var week = groupedLogs.keys.elementAt(index);
              var logsForWeek = groupedLogs[week]!;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ExpansionTile(
                  title: Text('Semaine du $week'),
                  children: logsForWeek.map((log) {
                    var data = log.data() as Map<String, dynamic>;
                    var name = data['name'] ?? 'Pas de nom';
                    var email = data['email'] ?? 'Pas d\'email';
                    var timestamp = data['timestamp'] as Timestamp;
                    var date = timestamp.toDate();

                    return ListTile(
                      title: Text(name),
                      subtitle: Text('$email\n${DateFormat('yyyy-MM-dd HH:mm:ss').format(date)}'),
                      isThreeLine: true,
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Map<String, List<QueryDocumentSnapshot>> _groupLogsByWeek(List<QueryDocumentSnapshot> logs) {
    Map<String, List<QueryDocumentSnapshot>> groupedLogs = {};

    for (var log in logs) {
      var data = log.data() as Map<String, dynamic>;
      var timestamp = data['timestamp'] as Timestamp;
      var date = timestamp.toDate();
      var weekOfYear = DateFormat('yyyy-MM').format(date);

      if (!groupedLogs.containsKey(weekOfYear)) {
        groupedLogs[weekOfYear] = [];
      }
      groupedLogs[weekOfYear]!.add(log);
    }

    return groupedLogs;
  }
}
