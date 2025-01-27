import 'package:Taqyem/taqyem/tableau.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectedBaremesPage extends StatefulWidget {
  final String selectedClass;
  final String selectedMatiere;

  SelectedBaremesPage({required this.selectedClass, required this.selectedMatiere});

  @override
  _SelectedBaremesPageState createState() => _SelectedBaremesPageState();
}

class _SelectedBaremesPageState extends State<SelectedBaremesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barèmes et Sous-Barèmes Sélectionnés'),
        actions: [
          IconButton(
            icon: Icon(Icons.table_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DynamicTablePage(
                    selectedClass: widget.selectedClass,
                    selectedMatiere: widget.selectedMatiere,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('selections')
            .doc(widget.selectedClass)
            .collection(widget.selectedMatiere)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucun barème ou sous-barème sélectionné.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              var baremeId = doc['baremeId'];
              var isBareme = baremeId != null;

              if (isBareme) {
                // Si c'est un barème
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('classes')
                      .doc(widget.selectedClass)
                      .collection('matieres')
                      .doc(widget.selectedMatiere)
                      .collection('baremes')
                      .doc(baremeId)
                      .get(),
                  builder: (context, baremeSnapshot) {
                    if (baremeSnapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        title: Text('Chargement du barème...'),
                      );
                    }
                    if (!baremeSnapshot.hasData || !baremeSnapshot.data!.exists) {
                      return ListTile(
                        title: Text('Barème introuvable'),
                      );
                    }

                    var baremeData = baremeSnapshot.data!.data() as Map<String, dynamic>;
                    var baremeValue = baremeData['value'] ?? 'Valeur par défaut';

                    return Column(
                      children: [
                        ListTile(
                          title: Text('Barème: $baremeValue'),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('classes')
                              .doc(widget.selectedClass)
                              .collection('matieres')
                              .doc(widget.selectedMatiere)
                              .collection('baremes')
                              .doc(baremeId)
                              .collection('sousBaremes')
                              .snapshots(),
                          builder: (context, sousBaremesSnapshot) {
                            if (sousBaremesSnapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }
                            if (sousBaremesSnapshot.hasError) {
                              return Text('Erreur: ${sousBaremesSnapshot.error}');
                            }
                            if (!sousBaremesSnapshot.hasData || sousBaremesSnapshot.data!.docs.isEmpty) {
                              return SizedBox.shrink();
                            }

                            return Column(
                              children: sousBaremesSnapshot.data!.docs.map((sousBaremeDoc) {
                                var sousBaremeData = sousBaremeDoc.data() as Map<String, dynamic>;
                                var sousBaremeValue = sousBaremeData['value'] ?? 'Valeur par défaut';

                                return ListTile(
                                  title: Text('Sous-Barème: $sousBaremeValue'),
                                  subtitle: Text('Barème parent: $baremeValue'),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              } else {
                // Si c'est un sous-barème sans barème parent
                var sousBaremeId = doc.id;

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('classes')
                      .doc(widget.selectedClass)
                      .collection('matieres')
                      .doc(widget.selectedMatiere)
                      .collection('sousBaremes')
                      .doc(sousBaremeId)
                      .get(),
                  builder: (context, sousBaremeSnapshot) {
                    if (sousBaremeSnapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        title: Text('Chargement du sous-barème...'),
                      );
                    }
                    if (!sousBaremeSnapshot.hasData || !sousBaremeSnapshot.data!.exists) {
                      return ListTile(
                        title: Text('Sous-barème introuvable'),
                      );
                    }

                    var sousBaremeData = sousBaremeSnapshot.data!.data() as Map<String, dynamic>;
                    var sousBaremeValue = sousBaremeData['value'] ?? 'Valeur par défaut';

                    return ListTile(
                      title: Text('Sous-Barème: $sousBaremeValue'),
                      subtitle: Text('Aucun barème parent'),
                    );
                  },
                );
              }
            }).toList(),
          );
        },
      ),
    );
  }
}