import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Taqyem/screens2/users/Claim.dart'; // Assurez-vous que le chemin est correct

class ClaimsListPage extends StatelessWidget {
  Future<void> _deleteClaim(BuildContext context, String claimId) async {
    try {
      await FirebaseFirestore.instance.collection('claims').doc(claimId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Claim deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting claim: $e')),
      );
    }
  }

  void _openMap(BuildContext context, double latitude, double longitude) {
    final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    _launchURL(context, url);
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  Widget _buildImage(String imageUrl) {
    // Check if the URL is valid
    if (Uri.tryParse(imageUrl)?.isAbsolute ?? false) {
      return Image.network(
        imageUrl,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/images/placeholder.png'); // Default image asset
        },
      );
    } else {
      return Image.asset('assets/images/placeholder.png'); // Default image asset
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Claims List'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('claims').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              Claim claim = Claim.fromFirestore(snapshot.data!.docs[index]);

              return Card(
                elevation: 5,
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claim.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Content: ${claim.content}'),
                      SizedBox(height: 4),
                      Text('Phone: ${claim.phone}'),
                      SizedBox(height: 4),
                      Text('Email: ${claim.email}'),
                      SizedBox(height: 4),
                      if (claim.position != null)
                        Text(
                          'Location: ${claim.position!.latitude}, ${claim.position!.longitude}',
                        ),
                      SizedBox(height: 4),
                      Text('Date: ${claim.timestamp.toDate()}'),
                      SizedBox(height: 8),
                      _buildImage(claim.imageUrl),
                      ButtonBar(
                        alignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteClaim(context, claim.id),
                          ),
                          if (claim.position != null)
                            IconButton(
                              icon: Icon(Icons.map, color: const Color.fromRGBO(33, 150, 243, 1)),
                              onPressed: () => _openMap(context, claim.position!.latitude, claim.position!.longitude),
                            ),
                        ],
                      ),
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
