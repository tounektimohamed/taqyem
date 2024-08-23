import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Modèle de données pour les nouvelles
class News {
  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime timestamp;
 // final String name;

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.timestamp,
  //  required this.name,
  });
}

class GereListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News List'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('news').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<News> newsList = snapshot.data!.docs.map((document) {
            Timestamp timestamp = document['timestamp'] ?? Timestamp.now();
            return News(
              id: document.id,
              title: document['title'],
              content: document['content'],
              //name: document['name'] ?? '', // Potential issue causing the error
              author: document['author'],
              timestamp: timestamp.toDate(),
            );
          }).toList();

          return ListView.builder(
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              News news = newsList[index];
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(news.title),
                  subtitle: Text(
                      '${news.author} - ${_formatTimestamp(news.timestamp)}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      bool confirmDelete = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Confirm Delete'),
                          content: Text(
                              'Are you sure you want to delete this news?'),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                            ),
                            TextButton(
                              child: Text('Delete'),
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                            ),
                          ],
                        ),
                      );

                      if (confirmDelete == true) {
                        await FirebaseFirestore.instance
                            .collection('news')
                            .doc(news.id)
                            .delete();
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Méthode pour formater le timestamp en format lisible
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
