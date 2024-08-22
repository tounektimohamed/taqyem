import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';
import 'dart:typed_data'; // Pour utiliser les bytes

class KmlMapPage extends StatefulWidget {
  @override
  _KmlMapPageState createState() => _KmlMapPageState();
}

class _KmlMapPageState extends State<KmlMapPage> {
  GoogleMapController? _mapController;
  Set<Polygon> polygons = {};
  bool loadingData = false;
  MapType _currentMapType = MapType.normal;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _pickKmlFile() async {
    setState(() {
      loadingData = true;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['kml'],
    );

    if (result != null && result.files.single.bytes != null) {
      final kmlBytes = result.files.single.bytes!;
      final kmlDoc = loadKmlFromBytes(kmlBytes);
      final extractedPolygons = extractPolygonsFromKml(kmlDoc);

      setState(() {
        polygons = extractedPolygons;
        loadingData = false;
      });

      // Move camera to the first polygon for better visibility
      if (polygons.isNotEmpty) {
        final firstPolygon = polygons.first;
        final bounds = LatLngBounds(
          southwest: LatLng(
            firstPolygon.points.map((point) => point.latitude).reduce((a, b) => a < b ? a : b),
            firstPolygon.points.map((point) => point.longitude).reduce((a, b) => a < b ? a : b),
          ),
          northeast: LatLng(
            firstPolygon.points.map((point) => point.latitude).reduce((a, b) => a > b ? a : b),
            firstPolygon.points.map((point) => point.longitude).reduce((a, b) => a > b ? a : b),
          ),
        );

        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }
    } else {
      setState(() {
        loadingData = false;
      });
    }
  }

  XmlDocument loadKmlFromBytes(Uint8List kmlBytes) {
    final kmlString = String.fromCharCodes(kmlBytes);
    return XmlDocument.parse(kmlString);
  }

  Set<Polygon> extractPolygonsFromKml(XmlDocument kmlDoc) {
    final polygonSet = <Polygon>{};
    final placemarks = kmlDoc.findAllElements('Placemark');

    int polygonIdCounter = 1;

    for (final placemark in placemarks) {
      final coordinates = placemark.findAllElements('coordinates').expand((node) {
        return node.text.trim().split(' ').map((coordinate) {
          final parts = coordinate.split(',');
          if (parts.length >= 2) {
            final latitude = double.parse(parts[1]);
            final longitude = double.parse(parts[0]);
            return LatLng(latitude, longitude);
          }
          return LatLng(0, 0); // Valeur par défaut en cas d'erreur
        }).toList();
      }).toList();

      if (coordinates.isNotEmpty) {
        polygonSet.add(
          Polygon(
            polygonId: PolygonId('polygon_$polygonIdCounter'),
            points: coordinates,
            strokeWidth: 2,
            strokeColor: Colors.red, // Couleur du contour pour la visibilité
            fillColor: Colors.yellow.withOpacity(0.5), // Couleur de remplissage pour la visibilité
          ),
        );
        polygonIdCounter++;
      }
    }

    return polygonSet;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KML Map'),
        actions: [
          IconButton(
            icon: Icon(Icons.folder_open),
            onPressed: _pickKmlFile,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            polygons: polygons,
            mapType: _currentMapType,
            initialCameraPosition: CameraPosition(
              target: LatLng(32.9295, 10.4518), // Position initiale à Tataouine, Tunisie
              zoom: 12,
            ),
          ),
          if (loadingData)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
