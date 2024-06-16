import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClaimsListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List of Claims'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('claims').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var claims = snapshot.data!.docs;

          return ListView.builder(
            itemCount: claims.length,
            itemBuilder: (context, index) {
              var claim = claims[index].data() as Map<String, dynamic>;
              var title = claim['title'] ?? 'No Title';
              var content = claim['content'] ?? 'No Content';
              var phone = claim['phone'] ?? 'No Phone';
              var email = claim['email'] ?? 'No Email';
              var imageUrl = claim['imageUrl'] ?? '';
              var latitude = claim['position']['latitude'] ?? 0.0;
              var longitude = claim['position']['longitude'] ?? 0.0;

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  leading: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                      : Icon(Icons.image_not_supported, size: 50),
                  title: Text(title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(content),
                      SizedBox(height: 5),
                      Text('Phone: $phone'),
                      SizedBox(height: 5),
                      Text('Email: $email'),
                      SizedBox(height: 5),
                      Text('Location: $latitude, $longitude'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
