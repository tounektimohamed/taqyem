import 'dart:convert';
import 'dart:typed_data';
import 'package:DREHATT_app/screens2/jeojson/convertGeoJson.dart';
import 'package:DREHATT_app/screens2/jeojson/gerehtml.dart';
import 'package:DREHATT_app/screens2/jeojson/localhtml.dart';
import 'package:DREHATT_app/screens2/kml/KmlMapPage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class SigWeb extends StatefulWidget {
  const SigWeb({super.key, required this.title});

  final String title;

  @override
  State<SigWeb> createState() => _SigWebState();
}

class _SigWebState extends State<SigWeb> {
  bool loadingData = false;
  bool uploadingData = false;
  double uploadProgress = 0.0; // Add this line
  GoogleMapController? mapController;
  String _selectedGeoJsonDocumentId = '';
  Set<Polygon> polygons = {};
  MapType _currentMapType = MapType.normal;
  Set<Polyline> polylines = {};

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

  Future<void> uploadGeoJsonToStorage(
      String fileName, Uint8List fileBytes) async {
    try {
      final storageRef =
          FirebaseStorage.instance.ref().child('geojson_files/$fileName');
      await storageRef.putData(fileBytes);
      final downloadUrl = await storageRef.getDownloadURL();

      print('GeoJSON uploaded to Storage successfully: $downloadUrl');
    } catch (e) {
      print('Error uploading GeoJSON: $e');
    }
  }

  Future<void> loadGeoJsonFromStorage(String fileName) async {
    if (mapController == null) {
      print('Map controller is not initialized');
      return;
    }

    try {
      setState(() {
        loadingData = true;
      });

      final storageRef =
          FirebaseStorage.instance.ref().child('geojson_files/$fileName');
      final downloadUrl = await storageRef.getDownloadURL();
      final response = await http.get(Uri.parse(downloadUrl));
      final geoJsonData = response.body;

      final decodedGeoJson = json.decode(geoJsonData);
      final Set<Polygon> newPolygons = {};
      final Set<Polyline> newPolylines = {};

      int index = 0; // Initialize index for unique ID
      for (var feature in decodedGeoJson['features']) {
        if (feature['geometry']['type'] == 'MultiPolygon') {
          // Handle MultiPolygon
          final List<List<LatLng>> polygonList = [];
          for (var polygon in feature['geometry']['coordinates']) {
            final List<LatLng> ringPoints = [];
            for (var ring in polygon) {
              for (var coord in ring) {
                ringPoints.add(LatLng(coord[1], coord[0]));
              }
            }
            polygonList.add(ringPoints);
          }

          final polygonId = PolygonId('polygon_$index');
          index++;

          final String? fillHex = feature['properties']['fill'];
          final double fillOpacity =
              feature['properties']['fill-opacity']?.toDouble() ?? 0.5;
          final Color fillColor = fillHex != null
              ? Color(int.parse(fillHex.replaceFirst('#', '0xFF')))
              : Color.fromARGB(0, 236, 125, 125);

          newPolygons.add(
            Polygon(
              polygonId: polygonId,
              points: polygonList.expand((ring) => ring).toList(),
              strokeColor: feature['properties']['stroke'] != null
                  ? Color(int.parse(feature['properties']['stroke']
                      .replaceFirst('#', '0xFF')))
                  : Colors.black,
              strokeWidth:
                  feature['properties']['stroke-width']?.toDouble() ?? 2.0,
              fillColor: fillColor.withOpacity(fillOpacity),
              onTap: () {
                _showPolygonInfo(feature['properties']);
              },
            ),
          );
        } else if (feature['geometry']['type'] == 'LineString') {
          // Handle LineString
          final List<LatLng> linePoints = [];
          for (var coord in feature['geometry']['coordinates']) {
            if (coord is List && coord.length >= 2) {
              linePoints.add(LatLng(coord[1], coord[0]));
            }
          }

          final polylineId = PolylineId('polyline_$index');
          index++;

          newPolylines.add(
            Polyline(
              polylineId: polylineId,
              points: linePoints,
              color: Colors.red,
              width: 3,
            ),
          );
        } else if (feature['geometry']['type'] == 'MultiLineString') {
          // Handle MultiLineString
          for (var line in feature['geometry']['coordinates']) {
            final List<LatLng> linePoints = [];
            for (var coord in line) {
              if (coord is List && coord.length >= 2) {
                linePoints.add(LatLng(coord[1], coord[0]));
              }
            }

            final polylineId = PolylineId('polyline_$index');
            index++;

            newPolylines.add(
              Polyline(
                polylineId: polylineId,
                points: linePoints,
                color: Color.fromARGB(
                    255, 255, 179, 66), // Default color for MultiLineString
                width: 3,
              ),
            );
          }
        }
      }

      setState(() {
        polygons = newPolygons;
        polylines = newPolylines;
      });

      if (newPolygons.isNotEmpty || newPolylines.isNotEmpty) {
        final allPoints =
            newPolygons.expand((polygon) => polygon.points).toList();
        allPoints.addAll(newPolylines.expand((polyline) => polyline.points));
        final bounds = calculateBoundingBox(allPoints);
        mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }

      print('GeoJSON loaded and parsed successfully');
    } catch (e) {
      print('Error loading GeoJSON: $e');
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
      print('GeoJSON uploaded successfully');
    } catch (e) {
      print('Error uploading GeoJSON: $e');
    }
  }

  Future<void> _deleteGeoJsonFile(String fileName) async {
    try {
      final storageRef =
          FirebaseStorage.instance.ref().child('geojson_files/$fileName');
      await storageRef.delete();
      print('File deleted successfully');

      // Refresh the list of GeoJSON files after deletion
      _showGeoJsonSelectionDialog();
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  Future<void> _confirmAndDeleteGeoJsonFile(String fileName) async {
    // Show a confirmation dialog before deleting the file
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this file?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Proceed with deletion if confirmed
      try {
        final storageRef =
            FirebaseStorage.instance.ref().child('geojson_files/$fileName');
        await storageRef.delete();
        print('File deleted successfully');

        // Refresh the list of GeoJSON files after deletion
        _showGeoJsonSelectionDialog();
      } catch (e) {
        print('Error deleting file: $e');
      }
    }
  }

  Future<void> _showGeoJsonSelectionDialog() async {
    try {
      final storage = FirebaseStorage.instance;
      final listResult = await storage.ref('geojson_files').listAll();
      print(
          'Files in Storage: ${listResult.items.length}'); // Debug: print number of items

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select a GeoJSON File'),
            content: Container(
              width: double.maxFinite,
              child: ListView(
                children: listResult.items.map((fileRef) {
                  final fileName = fileRef.name;

                  return ListTile(
                    title: Text(fileName),
                    onTap: () {
                      Navigator.of(context).pop(); // Close the dialog
                      _selectGeoJson(fileName);
                    },
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        _confirmAndDeleteGeoJsonFile(fileName);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('Error listing GeoJSON files: $e'); // Show detailed error
      if (e is FirebaseException) {
        print('Error Code: ${e.code}');
        print('Error Message: ${e.message}');
      }
    }
  }

  Future<void> _selectGeoJson(String fileName) async {
    try {
      await loadGeoJsonFromStorage(fileName);
    } catch (e) {
      print('Error selecting GeoJSON file: $e');
    }
  }

  Future<void> _uploadGeoJsonFile() async {
    try {
      setState(() {
        uploadingData = true;
        uploadProgress = 0.0;
      });

      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['geojson']);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        final Uint8List fileBytes = file.bytes!;
        final String fileName = file.name;

        final storageRef =
            FirebaseStorage.instance.ref().child('geojson_files/$fileName');
        final uploadTask = storageRef.putData(fileBytes);

        uploadTask.snapshotEvents.listen((taskSnapshot) {
          setState(() {
            uploadProgress =
                (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
          });
        });

        await uploadTask.whenComplete(() async {
          final downloadUrl = await storageRef.getDownloadURL();
          print('File uploaded successfully: $downloadUrl');
          setState(() {
            uploadingData = false;
          });
        }).catchError((error) {
          print('Error uploading file: $error');
          setState(() {
            uploadingData = false;
          });
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      setState(() {
        uploadingData = false;
      });
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
          title: Text('Select Map Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Normal'),
                onTap: () {
                  _changeMapType(MapType.normal);
                  Navigator.of(context).pop(); // Ferme le dialogue
                },
              ),
              ListTile(
                title: Text('Satellite'),
                onTap: () {
                  _changeMapType(MapType.satellite);
                  Navigator.of(context).pop(); // Ferme le dialogue
                },
              ),
              ListTile(
                title: Text('Terrain'),
                onTap: () {
                  _changeMapType(MapType.terrain);
                  Navigator.of(context).pop(); // Ferme le dialogue
                },
              ),
              ListTile(
                title: Text('Hybrid'),
                onTap: () {
                  _changeMapType(MapType.hybrid);
                  Navigator.of(context).pop(); // Ferme le dialogue
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
        'Unknown Layer'; // Default text if 'Layer' is not available
    Color polygonColor = Colors.white; // Default color

    // Extract color if 'fill' property exists
    if (properties.containsKey('fill')) {
      String? fillHex = properties['fill'];
      if (fillHex != null) {
        polygonColor = Color(int.parse(fillHex.replaceFirst('#', '0xFF')));
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Polygon Info'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 50.0,
                  color: polygonColor,
                  child: Center(
                    child: Text(
                      layerName,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                ...properties.entries.map((entry) {
                  return Text('${entry.key}: ${entry.value}');
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des PAUS'),
        actions: [
           IconButton(
          icon: Icon(Icons.web),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HtmlListPage()),
            );
          },
          tooltip: 'Afficher HTML Local',
        ),
         
            IconButton(
          icon: Icon(Icons.web),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HtmlPagesList()),
            );
          },
          tooltip: 'Afficher HTML Local',
        ),
          IconButton(
            icon: const Icon(Icons.change_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GeoJsonConverterPage()),
              );
            },
            tooltip: 'convertisseur',
          ),
          IconButton(
            icon: Icon(Icons.map_sharp),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => KmlMapPage()),
              );
            },
            tooltip: 'kml reader',
          ),
          IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: _uploadGeoJsonFile,
            tooltip: 'telecharger geojson fils ',
          ),
          IconButton(
            icon: Icon(Icons.file_open),
            onPressed: _showGeoJsonSelectionDialog,
            tooltip: 'liste de paus',
          ),
          IconButton(
            icon: Icon(Icons.layers),
            onPressed: _showMapTypeSelectionDialog,
            tooltip: 'changer layer ',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            polygons: polygons,
            polylines: polylines, // Ajoutez cette ligne
            mapType: _currentMapType,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                  32.9295, 10.4518), // Position initiale à Tataouine, Tunisie
              zoom: 12,
            ),
          ),
          if (loadingData)
            Center(
              child: CircularProgressIndicator(),
            ),
          if (uploadingData) // Show the upload indicator with percentage
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: uploadProgress / 100),
                  SizedBox(height: 20),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    color: Colors.black
                        .withOpacity(0.7), // Background color with opacity
                    child: Text(
                      '${uploadProgress.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.white, // Text color
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
