import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HousingApplicationListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Housing Applications Liste'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('applications').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Extract data from snapshot
          final List<DocumentSnapshot> documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              // Extract fields from each document
              final Map<String, dynamic> data = documents[index].data() as Map<String, dynamic>;
              final documentId = documents[index].id;

              // Extract selectedLocation as LatLng if available
              LatLng? selectedLocation;
              if (data['selectedLocation'] != null && data['selectedLocation'] is GeoPoint) {
                GeoPoint geoPoint = data['selectedLocation'] as GeoPoint;
                selectedLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
              }

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(data['name'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Address: ${data['address'] ?? ''}'),
                      Text('Phone: ${data['phone'] ?? ''}'),
                      Text('Email: ${data['email'] ?? ''}'),
                      if (data['selectedSector'] != null)
                        Text('Selected Sector: ${data['selectedSector'] ?? ''}'),
                      if (selectedLocation != null) ...[
                        SizedBox(
                          height: 200,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: selectedLocation,
                              zoom: 15,
                            ),
                            markers: {
                              Marker(
                                markerId: MarkerId('selectedLocation'),
                                position: selectedLocation,
                              ),
                            },
                            onMapCreated: (GoogleMapController controller) {},
                          ),
                        ),
                      ],
                      // Add more fields as needed
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      // Delete document from Firestore
                      FirebaseFirestore.instance.collection('applications').doc(documentId).delete().then((value) {
                        // Document successfully deleted
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Application deleted successfully')),
                        );
                      }).catchError((error) {
                        // Error deleting document
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete application')),
                        );
                      });
                    },
                  ),
                  onTap: () {
                    // Navigate to a detail page if needed
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
