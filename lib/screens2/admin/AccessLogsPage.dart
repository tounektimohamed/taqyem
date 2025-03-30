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
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('access_logs')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, size: 50, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun journal d\'accès disponible',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              );
            }

            var logs = snapshot.data!.docs;

            // Regrouper les journaux par semaine
            var groupedLogs = _groupLogsByWeek(logs);

            return RefreshIndicator(
              onRefresh: () async {
                // Implémentez la logique de rafraîchissement si nécessaire
              },
              child: ListView.builder(
                itemCount: groupedLogs.keys.length,
                itemBuilder: (context, index) {
                  var week = groupedLogs.keys.elementAt(index);
                  var logsForWeek = groupedLogs[week]!;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.blue),
                      title: Text(
                        'Semaine du $week',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: logsForWeek.map((log) {
                        var data = log.data() as Map<String, dynamic>;
                        var userId = log.id;
                        var name = data['name'] ?? 'Utilisateur inconnu';
                        var email = data['email'] ?? 'Email non disponible';
                        var timestamp = data['timestamp'] as Timestamp;
                        var date = timestamp.toDate();
                        var formattedDate = DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date);
                        var formattedTime = DateFormat('HH:mm:ss').format(date);

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .get(),
                          builder: (context, userSnapshot) {
                            String displayName = name;
                            if (userSnapshot.hasData && userSnapshot.data!.exists) {
                              var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                              displayName = userData?['name'] ?? name;
                            }

                            return Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.grey.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    displayName.isNotEmpty 
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ),
                                title: Text(
                                  displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(email),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$formattedDate à $formattedTime',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Map<String, List<QueryDocumentSnapshot>> _groupLogsByWeek(List<QueryDocumentSnapshot> logs) {
    Map<String, List<QueryDocumentSnapshot>> groupedLogs = {};

    for (var log in logs) {
      var data = log.data() as Map<String, dynamic>;
      var timestamp = data['timestamp'] as Timestamp;
      var date = timestamp.toDate();
      
      // Utiliser le premier jour de la semaine comme clé
      var firstDayOfWeek = DateUtils.dateOnly(
        date.subtract(Duration(days: date.weekday - 1))
      );
      
      var weekKey = DateFormat('dd MMMM yyyy', 'fr_FR').format(firstDayOfWeek);

      if (!groupedLogs.containsKey(weekKey)) {
        groupedLogs[weekKey] = [];
      }
      groupedLogs[weekKey]!.add(log);
    }

    return groupedLogs;
  }
}