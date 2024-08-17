
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';

class SigWeb extends StatefulWidget {
  const SigWeb({super.key, required this.title});

  final String title;

  @override
  State<SigWeb> createState() => _SigWebState();
}

class _SigWebState extends State<SigWeb> {
  GeoJsonParser geoJsonParser = GeoJsonParser(
    defaultMarkerColor: const Color.fromARGB(255, 56, 47, 46),
    defaultPolygonBorderColor: Color.fromARGB(255, 212, 105, 43),
    defaultPolygonFillColor: const Color.fromARGB(255, 53, 49, 49).withOpacity(0.5),
    defaultCircleMarkerColor: const Color.fromARGB(255, 29, 28, 28).withOpacity(0.25),
  );

  bool loadingData = false;
  LatLngBounds? bounds;
  late MapController mapController;
  String _selectedTileLayer = 'OSM';
  String? _selectedGeoJsonDocumentId;

  bool myFilterFunction(Map<String, dynamic> properties) {
    return true;
  }

  void onTapMarkerFunction(Map<String, dynamic> map) {
    print('onTapMarkerFunction: $map');
  }

  LatLngBounds calculateBoundingBox(List<List<LatLng>> polygons) {
    double? minLat, maxLat, minLon, maxLon;

    for (var polygon in polygons) {
      for (var point in polygon) {
        if (minLat == null || point.latitude < minLat) minLat = point.latitude;
        if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
        if (minLon == null || point.longitude < minLon) minLon = point.longitude;
        if (maxLon == null || point.longitude > maxLon) maxLon = point.longitude;
      }
    }

    return LatLngBounds(
      LatLng(minLat ?? 0, minLon ?? 0),
      LatLng(maxLat ?? 0, maxLon ?? 0),
    );
  }

  Future<void> loadGeoJsonFromFirestore(String documentId) async {
    try {
      setState(() {
        loadingData = true;
      });

      final firestore = FirebaseFirestore.instance;
      final docSnapshot = await firestore.collection('geojson_files').doc(documentId).get();

      if (docSnapshot.exists) {
        final geoJsonData = docSnapshot.data()?['geojson'] as String?;
        if (geoJsonData != null) {
          geoJsonParser.parseGeoJsonAsString(geoJsonData);

          List<List<LatLng>> allPolygons = geoJsonParser.polygons
              .map((p) => p.points.map((e) => LatLng(e.latitude, e.longitude)).toList())
              .toList();

          LatLngBounds? newBounds;
          if (allPolygons.isNotEmpty) {
            newBounds = calculateBoundingBox(allPolygons);
          }

          if (newBounds != null) {
            setState(() {
              bounds = newBounds;
            });
            mapController.fitBounds(bounds!);
          }

          print('GeoJSON loaded and parsed successfully');
        } else {
          print('Field "geojson" does not exist in the document');
        }
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Error loading GeoJSON: $e');
    } finally {
      setState(() {
        loadingData = false;
      });
    }
  }

  Future<void> uploadGeoJsonToFirestore(String documentId, String geoJsonData) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('geojson_files').doc(documentId).set({
        'geojson': geoJsonData,
      });
      print('GeoJSON uploaded successfully');
    } catch (e) {
      print('Error uploading GeoJSON: $e');
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
          title: Text('Select a GeoJSON File'),
          content: Container(
            width: double.maxFinite,
            child: ListView(
              children: documents.map((doc) {
                final documentId = doc.id;
                final fileName = documentId; // Modify if you have a different field for names

                return ListTile(
                  title: Text(fileName),
                  onTap: () {
                    Navigator.of(context).pop();
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
      print('Error selecting GeoJSON file: $e');
    }
  }

  Future<void> _uploadGeoJsonFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['geojson']);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        final Uint8List fileBytes = file.bytes!;
        final geoJsonData = String.fromCharCodes(fileBytes);
        final fileName = file.name;

        await uploadGeoJsonToFirestore(fileName, geoJsonData);

        print('File uploaded successfully: $fileName');
      } else {
        print('No file selected');
      }
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    geoJsonParser.setDefaultMarkerTapCallback(onTapMarkerFunction);
    geoJsonParser.filterFunction = myFilterFunction;
    loadingData = true;
    _showGeoJsonSelectionDialog().then((_) {
      setState(() {
        loadingData = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Text('Suivie des PauS'), // Changer le titre ici
        actions: [
          IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: _uploadGeoJsonFile,
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: _showGeoJsonSelectionDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              center: LatLng(33.10, 10.25),
              zoom: 12,
              maxZoom: 100,
            ),
            children: [
              TileLayer(
                urlTemplate: _getTileUrl(_selectedTileLayer),
                userAgentPackageName: 'dev.fleaflet.flutter_map.example',
              ),
              if (!loadingData) PolygonLayer(polygons: geoJsonParser.polygons),
            ],
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: FloatingActionButton(
              onPressed: () {
                _showLayerSelectionMenu(context);
              },
              child: Icon(Icons.layers),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: () {
                    mapController.move(mapController.center, mapController.zoom + 1);
                  },
                  child: Icon(Icons.zoom_in),
                  heroTag: null,
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: () {
                    mapController.move(mapController.center, mapController.zoom - 1);
                  },
                  child: Icon(Icons.zoom_out),
                  heroTag: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTileUrl(String layer) {
    switch (layer) {
      case 'Satellite':
        return 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
      case 'Terrain':
        return 'https://tile.stamen.com/terrain/{z}/{x}/{y}.png';
      case 'OSM':
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  void _showLayerSelectionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Satellite'),
              onTap: () {
                setState(() {
                  _selectedTileLayer = 'Satellite';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Terrain'),
              onTap: () {
                setState(() {
                  _selectedTileLayer = 'Terrain';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('OSM'),
              onTap: () {
                setState(() {
                  _selectedTileLayer = 'OSM';
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}