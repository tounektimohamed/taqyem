import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GeoJsonSelectionPage extends StatefulWidget {
  final void Function(String) onSelect; // Callback lors de la sélection d'un document GeoJSON

  const GeoJsonSelectionPage({Key? key, required this.onSelect}) : super(key: key);

  @override
  _GeoJsonSelectionPageState createState() => _GeoJsonSelectionPageState();
}

class _GeoJsonSelectionPageState extends State<GeoJsonSelectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sélectionner un plan GeoJSON'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('geojson_files').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucun plan GeoJSON disponible.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final docId = doc.id;
              final docName = doc.get('name') ?? docId; // Supposant que vous avez un champ name dans vos documents

              return ListTile(
                title: Text(docName),
                onTap: () {
                  widget.onSelect(docId);
                  Navigator.pop(context); // Fermer la page de sélection
                },
              );
            },
          );
        },
      ),
    );
  }
}
