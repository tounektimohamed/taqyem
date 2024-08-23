import 'dart:convert';
import 'dart:typed_data';
import 'package:DREHATT_app/screens2/jeojson/convertGeoJson.dart';
import 'package:DREHATT_app/screens2/kml/KmlMapPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:file_picker/file_picker.dart';

class SigWeb extends StatefulWidget {
  const SigWeb({super.key, required this.title});

  final String title;

  @override
  State<SigWeb> createState() => _SigWebState();
}

class _SigWebState extends State<SigWeb> {
  bool loadingData = false;
  GoogleMapController? mapController;
  String _selectedGeoJsonDocumentId = '';
  Set<Polygon> polygons = {};
  MapType _currentMapType = MapType.normal;

  final Map<String, Color> layerColorMap = {
    'EQUIP': Color(0xff0e38c0),
    '1 UAa1': Color(0xffdb7979),
    '1 E': Colors.red,
    '1 UAa4': Color(0xff4caf50),
    '1 UVa': Color(0xff2196f3),
    '1 NAa': Color(0xffff9800),
    '1 UVb': Color(0xff9c27b0),
    '1 UBa': Color(0xffe91e63),
    '0 fonts': Color(0xff93C572),
  };

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGeoJsonSelectionDialog();
    });
  }

  LatLngBounds calculateBoundingBox(List<LatLng> points) {
    double? minLat, maxLat, minLon, maxLon;

    for (var point in points) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLon == null || point.longitude < minLon) minLon = point.longitude;
      if (maxLon == null || point.longitude > maxLon) maxLon = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat ?? 0, minLon ?? 0),
      northeast: LatLng(maxLat ?? 0, maxLon ?? 0),
    );
  }

  Future<void> loadGeoJsonFromFirestore(String documentId) async {
    if (mapController == null) {
      print('Le contrôleur de la carte n\'est pas initialisé');
      return;
    }

    try {
      setState(() {
        loadingData = true;
      });

      final firestore = FirebaseFirestore.instance;
      final docSnapshot = await firestore.collection('geojson_files').doc(documentId).get();

      if (docSnapshot.exists) {
        final geoJsonData = docSnapshot.data()?['geojson'] as String?;
        if (geoJsonData != null) {
          final decodedGeoJson = json.decode(geoJsonData);
          final Set<Polygon> newPolygons = {};

          int index = 0; // Initialiser l'index pour un identifiant unique
          for (var feature in decodedGeoJson['features']) {
            if (feature['geometry']['type'] == 'MultiPolygon') {
              final List<LatLng> points = [];
              for (var polygon in feature['geometry']['coordinates']) {
                for (var ring in polygon) {
                  for (var coord in ring) {
                    points.add(LatLng(coord[1], coord[0]));
                  }
                }
              }

              // Générer un identifiant unique en utilisant l'index
              final polygonId = PolygonId('polygon_$index');
              index++; // Incrémenter l'index pour le prochain polygone

              // Extraire la couleur de remplissage si elle existe
              final String? fillHex = feature['properties']['fill'];
              final double fillOpacity = feature['properties']['fill-opacity'] ?? 0.5;
              final Color fillColor = fillHex != null
                  ? Color(int.parse(fillHex.replaceFirst('#', '0xFF')))
                  : Color.fromARGB(0, 236, 125, 125);

              newPolygons.add(
                Polygon(
                  polygonId: polygonId,
                  points: points,
                  strokeColor: feature['properties']['stroke'] != null
                      ? Color(int.parse(feature['properties']['stroke']
                          .replaceFirst('#', '0xFF')))
                      : Colors.black,
                  strokeWidth: feature['properties']['stroke-width']?.toDouble() ?? 2.0,
                  fillColor: fillColor.withOpacity(fillOpacity),
                  onTap: () {
                    _showPolygonInfo(feature['properties']);
                  },
                ),
              );
            }
          }

          setState(() {
            polygons = newPolygons;
          });

          if (newPolygons.isNotEmpty) {
            final bounds = calculateBoundingBox(
              newPolygons.expand((polygon) => polygon.points).toList(),
            );
            mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
          }

          print('GeoJSON chargé et analysé avec succès');
        } else {
          print('Le champ "geojson" n\'existe pas dans le document');
        }
      } else {
        print('Le document n\'existe pas');
      }
    } catch (e) {
      print('Erreur lors du chargement du GeoJSON : $e');
    } finally {
      setState(() {
        loadingData = false;
      });
    }
  }

  Future<void> uploadGeoJsonToFirestore(
      String documentId, String geoJsonData) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('geojson_files').doc(documentId).set({
        'geojson': geoJsonData,
      });
      print('GeoJSON téléchargé avec succès');
    } catch (e) {
      print('Erreur lors du téléchargement du GeoJSON : $e');
    }
  }

  Future<void> _showGeoJsonSelectionDialog() async {
    final firestore = FirebaseFirestore.instance;
    final querySnapshot = await firestore.collection('geojson_files').get();

    final documents = querySnapshot.docs;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sélectionner un fichier GeoJSON'),
          content: Container(
            width: double.maxFinite,
            child: ListView(
              children: documents.map((doc) {
                final documentId = doc.id;
                final fileName = documentId;

                return ListTile(
                  title: Text(fileName),
                  onTap: () {
                    Navigator.of(context).pop(); // Fermer la boîte de dialogue
                    _selectGeoJson(documentId);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectGeoJson(String documentId) async {
    try {
      await loadGeoJsonFromFirestore(documentId);
    } catch (e) {
      print('Erreur lors de la sélection du fichier GeoJSON : $e');
    }
  }

  Future<void> _uploadGeoJsonFile() async {
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['geojson']);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        final Uint8List fileBytes = file.bytes!;
        final geoJsonData = String.fromCharCodes(fileBytes);
        final fileName = file.name;

        await uploadGeoJsonToFirestore(fileName, geoJsonData);

        print('Fichier téléchargé avec succès : $fileName');
      } else {
        print('Aucun fichier sélectionné');
      }
    } catch (e) {
      print('Erreur lors du téléchargement du fichier : $e');
    }
  }

  void _changeMapType(MapType mapType) {
    setState(() {
      _currentMapType = mapType;
    });
  }

  void _showMapTypeSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sélectionner le type de carte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Normal'),
                onTap: () {
                  _changeMapType(MapType.normal);
                  Navigator.of(context).pop(); // Fermer la boîte de dialogue
                },
              ),
              ListTile(
                title: Text('Satellite'),
                onTap: () {
                  _changeMapType(MapType.satellite);
                  Navigator.of(context).pop(); // Fermer la boîte de dialogue
                },
              ),
              ListTile(
                title: Text('Terrain'),
                onTap: () {
                  _changeMapType(MapType.terrain);
                  Navigator.of(context).pop(); // Fermer la boîte de dialogue
                },
              ),
              ListTile(
                title: Text('Hybride'),
                onTap: () {
                  _changeMapType(MapType.hybrid);
                  Navigator.of(context).pop(); // Fermer la boîte de dialogue
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPolygonInfo(Map<String, dynamic> properties) {
    String layerName = properties['Layer'] ??
        'Couche inconnue'; // Valeur par défaut en cas d'absence
    String paperSpace = properties['PaperSpace'] ?? 'Espace papier inconnu';
    String subClasses = properties['SubClasses'] ?? 'Sous-classes inconnues';
    String linetype = properties['Linetype'] ?? 'Type de ligne inconnu';
    String entityHand = properties['EntityHand'] ?? 'Poignée d\'entité inconnue';
    String text = properties['Text'] ?? 'Texte inconnu';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Informations du polygone'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nom de la couche: $layerName'),
              Text('Espace papier: $paperSpace'),
              Text('Sous-classes: $subClasses'),
              Text('Type de ligne: $linetype'),
              Text('Poignée d\'entité: $entityHand'),
              Text('Texte: $text'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: _uploadGeoJsonFile,
          ),
          IconButton(
            icon: Icon(Icons.map),
            onPressed: _showMapTypeSelectionDialog,
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        mapType: _currentMapType,
        polygons: polygons,
        initialCameraPosition: CameraPosition(
          target: LatLng(33.8769, 10.21), // Coordonnées de Tataouine, Tunisie
          zoom: 10,
        ),
      ),
    );
  }
}
