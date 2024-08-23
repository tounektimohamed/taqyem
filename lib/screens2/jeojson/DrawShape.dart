import 'package:DREHATT_app/screens2/jeojson/ShapeDetailsDialog.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

enum DrawShape { polygon, circle, line }

enum MapLayer { normal, satellite, terrain, hybrid }

class MapDrawingPage extends StatefulWidget {
  @override
  _MapDrawingPageState createState() => _MapDrawingPageState();
}

class _MapDrawingPageState extends State<MapDrawingPage> {
  GoogleMapController? mapController;
  List<LatLng> shapePoints = [];
  Set<Polygon> polygons = {};
  Set<Polyline> polylines = {};
  Set<Circle> circles = {};
  DrawShape selectedShape = DrawShape.polygon;
  MapLayer selectedLayer = MapLayer.normal;
  bool isDrawing = false;
  bool showSaveButton = false;
  String displayText = '';

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _startDrawing() {
    setState(() {
      isDrawing = true;
      shapePoints.clear();
      displayText = '';
      showSaveButton = false;
    });
  }

  void _stopDrawing() {
    setState(() {
      isDrawing = false;
      showSaveButton = true;
      _updateDisplayText();
    });
  }

  void _clearShapes() {
    setState(() {
      shapePoints.clear();
      polygons.clear();
      polylines.clear();
      circles.clear();
      displayText = '';
      isDrawing = false;
      showSaveButton = false;
    });
  }

  void _onTap(LatLng position) {
    if (isDrawing) {
      switch (selectedShape) {
        case DrawShape.polygon:
          _drawPolygon(position);
          break;
        case DrawShape.circle:
          _drawCircle(position);
          break;
        case DrawShape.line:
          _drawLine(position);
          break;
      }
    }
  }

  void _drawPolygon(LatLng position) {
    setState(() {
      shapePoints.add(position);
      polygons.clear();
      polygons.add(Polygon(
        polygonId: PolygonId('polygon'),
        points: shapePoints,
        strokeWidth: 2,
        fillColor: Colors.blue.withOpacity(0.3),
        strokeColor: Colors.blue,
      ));
      _updateDisplayText();
    });
  }

  void _drawCircle(LatLng position) {
    setState(() {
      if (shapePoints.isEmpty) {
        shapePoints.add(position);
      } else if (shapePoints.length == 1) {
        double radius = _calculateDistance(shapePoints[0], position);
        circles.clear();
        circles.add(Circle(
          circleId: CircleId('circle'),
          center: shapePoints[0],
          radius: radius,
          strokeWidth: 2,
          fillColor: Colors.blue.withOpacity(0.3),
          strokeColor: Colors.blue,
        ));
        shapePoints.clear();
        _stopDrawing();
      }
      _updateDisplayText();
    });
  }

  void _drawLine(LatLng position) {
    setState(() {
      if (shapePoints.isEmpty) {
        shapePoints.add(position);
      } else if (shapePoints.length == 1) {
        shapePoints.add(position);
        polylines.clear();
        polylines.add(Polyline(
          polylineId: PolylineId('line'),
          points: shapePoints,
          color: Colors.blue,
          width: 2,
        ));
        _stopDrawing();
      }
      _updateDisplayText();
    });
  }

  double _calculateDistance(LatLng start, LatLng end) {
    var p = 0.017453292519943295; // Pi / 180
    var c = cos;
    var a = 0.5 -
        c((end.latitude - start.latitude) * p) / 2 +
        c(start.latitude * p) *
            c(end.latitude * p) *
            (1 - c((end.longitude - start.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R * asin...
  }

  double _calculatePolygonArea(List<LatLng> points) {
    const double radiusOfEarth = 6371000; // in meters
    double area = 0;

    if (points.length < 3) return 0;

    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;

      double lat1 = points[i].latitude * pi / 180;
      double lon1 = points[i].longitude * pi / 180;
      double lat2 = points[j].latitude * pi / 180;
      double lon2 = points[j].longitude * pi / 180;

      area += (lon2 - lon1) * (2 + sin(lat1) + sin(lat2));
    }

    area = area * radiusOfEarth * radiusOfEarth / 2.0;
    return area.abs();
  }

  double _calculateShapeArea() {
    if (selectedShape == DrawShape.polygon && shapePoints.length > 2) {
      return _calculatePolygonArea(shapePoints);
    } else if (selectedShape == DrawShape.circle && circles.isNotEmpty) {
      double radius = circles.first.radius;
      return pi * radius * radius;
    }
    return 0;
  }

  void _updateDisplayText() {
    if (selectedShape == DrawShape.polygon && shapePoints.length > 2) {
      double area = _calculatePolygonArea(shapePoints);
      displayText = 'Aire: ${area.toStringAsFixed(2)} m²';
    } else if (selectedShape == DrawShape.circle && circles.isNotEmpty) {
      double radius = circles.first.radius;
      double area = pi * radius * radius;
      displayText = 'Aire: ${area.toStringAsFixed(2)} m²';
    } else if (selectedShape == DrawShape.line && shapePoints.length == 2) {
      double distance = _calculateDistance(shapePoints[0], shapePoints[1]);
      displayText = 'Distance: ${distance.toStringAsFixed(2)} m';
    }
    setState(() {});
  }

  void _changeMapLayer(MapLayer layer) {
    if (mapController != null) {
      setState(() {
        selectedLayer = layer;
      });
      mapController!.setMapStyle(_getMapStyle(layer));
    }
  }

  String _getMapStyle(MapLayer layer) {
    switch (layer) {
      case MapLayer.satellite:
        return '[]';
      case MapLayer.terrain:
        return '[{"featureType": "all","elementType": "geometry","stylers": [{"visibility": "simplified"}]}]';
      case MapLayer.hybrid:
        return '[]';
      case MapLayer.normal:
      default:
        return '[]';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Permis de batis'),
        actions: [
          IconButton(
            icon: Icon(Icons.undo),
            onPressed: shapePoints.isNotEmpty ? _undoLastPoint : null,
            tooltip: 'Annuler le dernier point',
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: polygons.isNotEmpty ||
                    polylines.isNotEmpty ||
                    circles.isNotEmpty
                ? _clearShapes
                : null,
            tooltip: 'Supprimer la forme',
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _confirmSave,
            tooltip: 'Save',
          ),
          IconButton(
            icon: Icon(Icons.calculate),
            onPressed: _updateDisplayText,
            tooltip: 'Update',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchSavedShapes,
            tooltip: 'Fetch Shapes',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                  33.1031, 10.4397), // Coordinates for Tataouine, Tunisia
              zoom: 9.0,
            ),
            polygons: polygons,
            polylines: polylines,
            circles: circles,
            onTap: _onTap,
            mapType: _getGoogleMapType(selectedLayer),
          ),
          if (displayText.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(10),
                color: Colors.black
                    .withOpacity(0.6), // Background color for better contrast
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white, // Better visibility on dark background
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.crop_square),
            label: 'Polygon',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.circle),
            label: 'Circle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Line',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Layer',
          ),
        ],
        currentIndex: DrawShape.values.indexOf(selectedShape),
        onTap: (index) {
          if (index < DrawShape.values.length) {
            setState(() {
              selectedShape = DrawShape.values[index];
              _startDrawing(); // Ensure drawing is started correctly
            });
          } else {
            _showLayerSelectionDialog();
          }
        },
        backgroundColor: Colors.white,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.blue,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [],
      ),
    );
  }

  MapType _getGoogleMapType(MapLayer layer) {
    switch (layer) {
      case MapLayer.satellite:
        return MapType.satellite;
      case MapLayer.terrain:
        return MapType.terrain;
      case MapLayer.hybrid:
        return MapType.hybrid;
      case MapLayer.normal:
      default:
        return MapType.normal;
    }
  }

  void _fetchSavedShapes() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('shapes').get();

      if (snapshot.docs.isEmpty) {
        _showMessage('Aucune forme enregistrée.');
        return;
      }

      List<Widget> shapeDetails = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String name = data['name'] ?? 'Inconnu';
        String shapeType = data['shapeType'] ?? 'Inconnu';
        List<dynamic> coordinates = data['coordinates'] ?? [];
        double surface = data['surface']?.toDouble() ?? 0;
        String municipality = data['municipality'] ?? 'Inconnue';
        String pau = data['pau'] ?? 'Inconnu';
        String urbanType = data['urbanType'] ?? 'Inconnu';
        String lotType = data['lotType'] ?? 'Inconnu';
        int numberOfLots = data['numberOfLots']?.toInt() ?? 0;

        shapeDetails.add(Card(
          elevation: 4.0,
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ListTile(
            leading: Icon(Icons.location_on, color: Colors.blue),
            title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Type: $shapeType\n'
              'Coordonnées: ${coordinates.toString()}\n'
              'Surface: ${surface.toStringAsFixed(2)} m²\n'
              'Municipalité: $municipality\n'
              'PAU: $pau\n'
              'Type Urbain: $urbanType\n'
              'Type de Lot: $lotType\n'
              'Nombre de Lots: $numberOfLots',
            ),
          ),
        ));
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Détails des Formes'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: shapeDetails,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Fermer'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _showMessage('Erreur lors de la récupération des formes: $e');
    }
  }

// Fonction utilitaire pour afficher des messages
  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Message'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _confirmSave() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Save'),
          content: Text('Are you sure you want to save this shape?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                Navigator.of(context).pop();
                _showSavePage();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSavePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => ShapeDetailsPage(
          shapeType: selectedShape.toString().split('.').last,
          area: _calculateShapeArea(),
        ),
      ),
    );
  }

  void _undoLastPoint() {
    setState(() {
      if (shapePoints.isNotEmpty) {
        shapePoints.removeLast();
        _updateShape();
        if (shapePoints.isEmpty) {
          _stopDrawing();
        }
      }
    });
  }

  void _updateShape() {
    switch (selectedShape) {
      case DrawShape.polygon:
        if (shapePoints.length > 2) {
          polygons.clear();
          polygons.add(Polygon(
            polygonId: PolygonId('polygon'),
            points: shapePoints,
            strokeWidth: 2,
            fillColor: Colors.blue.withOpacity(0.3),
            strokeColor: Colors.blue,
          ));
        } else {
          polygons.clear();
        }
        break;
      case DrawShape.circle:
        if (shapePoints.length == 1) {
          circles.clear();
          shapePoints.clear();
        }
        break;
      case DrawShape.line:
        if (shapePoints.length == 1) {
          polylines.clear();
          shapePoints.clear();
        }
        break;
    }
    _updateDisplayText();
  }

  void _showLayerSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Map Layer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: MapLayer.values.map((layer) {
              return ListTile(
                title: Text(layer.toString().split('.').last),
                onTap: () {
                  _changeMapLayer(layer);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
