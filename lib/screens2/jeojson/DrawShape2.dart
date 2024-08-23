
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';
import 'dart:typed_data'; // Pour utiliser les bytes
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

enum DrawShape { polygon, circle, line }

enum MapLayer { normal, satellite, terrain, hybrid }

class CombinedMapPage extends StatefulWidget {
  @override
  _CombinedMapPageState createState() => _CombinedMapPageState();
}

class _CombinedMapPageState extends State<CombinedMapPage> {
  GoogleMapController? _mapController;
  Set<Polygon> polygons = {};
  Set<Polyline> polylines = {};
  Set<Circle> circles = {};
  bool loadingData = false;
  MapType _currentMapType = MapType.normal;
  List<LatLng> shapePoints = [];
  DrawShape selectedShape = DrawShape.polygon;
  MapLayer selectedLayer = MapLayer.normal;
  bool isDrawing = false;
  bool showSaveButton = false;
  String displayText = '';

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
            firstPolygon.points
                .map((point) => point.latitude)
                .reduce((a, b) => a < b ? a : b),
            firstPolygon.points
                .map((point) => point.longitude)
                .reduce((a, b) => a < b ? a : b),
          ),
          northeast: LatLng(
            firstPolygon.points
                .map((point) => point.latitude)
                .reduce((a, b) => a > b ? a : b),
            firstPolygon.points
                .map((point) => point.longitude)
                .reduce((a, b) => a > b ? a : b),
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
      final coordinates =
          placemark.findAllElements('coordinates').expand((node) {
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
            fillColor: Colors.yellow
                .withOpacity(0.5), // Couleur de remplissage pour la visibilité
          ),
        );
        polygonIdCounter++;
      }
    }

    return polygonSet;
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
  }
  
  void _showSaveDialog() async {
  final nameController = TextEditingController();
  final municipalityController = TextEditingController();
  final regionController = TextEditingController();
  final urbanModelController = TextEditingController();
  final areaController = TextEditingController();
  final urbanTypeController = TextEditingController();
  final lotTypeController = TextEditingController();
  final numOfLotsController = TextEditingController();

  // Calculer l'aire ou la distance en fonction de la forme
  double calculatedAreaOrDistance = _calculateShapeArea();
  areaController.text = calculatedAreaOrDistance.toStringAsFixed(2);

  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Save Shape'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Nom du demandeur de subdivision'),
              ),
              TextField(
                controller: municipalityController,
                decoration: InputDecoration(labelText: 'Municipalité'),
              ),
              TextField(
                controller: regionController,
                decoration: InputDecoration(labelText: 'Région'),
              ),
              TextField(
                controller: urbanModelController,
                decoration: InputDecoration(labelText: 'Modèle d\'aménagement urbain'),
              ),
              TextField(
                controller: areaController,
                decoration: InputDecoration(labelText: 'Superficie (m²)'),
                readOnly: true, // En lecture seule pour l'aire calculée
              ),
              TextField(
                controller: urbanTypeController,
                decoration: InputDecoration(labelText: 'Type urbain'),
              ),
              TextField(
                controller: lotTypeController,
                decoration: InputDecoration(labelText: 'Type de lotissement'),
              ),
              TextField(
                controller: numOfLotsController,
                decoration: InputDecoration(labelText: 'Nombre de lots'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop({
                'name': nameController.text,
                'municipality': municipalityController.text,
                'region': regionController.text,
                'urbanModel': urbanModelController.text,
                'area': areaController.text,
                'urbanType': urbanTypeController.text,
                'lotType': lotTypeController.text,
                'numOfLots': numOfLotsController.text,
              });
            },
            child: Text('Enregistrer'),
          ),
        ],
      );
    },
  );

  if (result != null) {
    final shapeName = result['name'] ?? 'Shape_${DateTime.now().millisecondsSinceEpoch}';
    final shapeMunicipality = result['municipality'] ?? '';
    final shapeRegion = result['region'] ?? '';
    final shapeUrbanModel = result['urbanModel'] ?? '';
    final shapeArea = double.tryParse(result['area'] ?? '0.0') ?? 0.0;
    final shapeUrbanType = result['urbanType'] ?? '';
    final shapeLotType = result['lotType'] ?? '';
    final shapeNumOfLots = int.tryParse(result['numOfLots'] ?? '0') ?? 0;

    await _saveShape(
      shapeName,
      shapeMunicipality,
      shapeRegion,
      shapeUrbanModel,
      shapeArea,
      shapeUrbanType,
      shapeLotType,
      shapeNumOfLots,
    );
  }
}

Future<void> _saveShape(
  String shapeName,
  String shapeMunicipality,
  String shapeRegion,
  String shapeUrbanModel,
  double shapeArea,
  String shapeUrbanType,
  String shapeLotType,
  int shapeNumOfLots,
) async {
  if (polygons.isNotEmpty || circles.isNotEmpty || polylines.isNotEmpty) {
    // Obtenir la date et l'heure actuelles
    final currentDate = DateTime.now();

    final shapeData = {
      'name': shapeName,
      'municipality': shapeMunicipality,
      'region': shapeRegion,
      'urbanModel': shapeUrbanModel,
      'area': shapeArea,  // Ajout de l'aire ou de la distance calculée
      'urbanType': shapeUrbanType,
      'lotType': shapeLotType,
      'numOfLots': shapeNumOfLots,
      'registrationDate': currentDate,  // Ajout de la date d'enregistrement
      'coordinates': selectedShape == DrawShape.polygon
          ? polygons.first.points
              .map((point) => {
                    'latitude': point.latitude,
                    'longitude': point.longitude,
                  })
              .toList()
          : selectedShape == DrawShape.line
              ? polylines.first.points
                  .map((point) => {
                        'latitude': point.latitude,
                        'longitude': point.longitude,
                      })
                  .toList()
              : null,
      'center': selectedShape == DrawShape.circle
          ? {
              'latitude': circles.first.center.latitude,
              'longitude': circles.first.center.longitude,
            }
          : null,
      'radius': selectedShape == DrawShape.circle ? circles.first.radius : null,
    };

    await FirebaseFirestore.instance.collection('shapes').add(shapeData);
    _clearShapes();
  }
}



  Future<void> _fetchSavedShapes() async {
    setState(() {
      loadingData = true;
    });

    final querySnapshot =
        await FirebaseFirestore.instance.collection('shapes').get();
    final fetchedPolygons = <Polygon>{};
    final fetchedCircles = <Circle>{};
    final fetchedPolylines = <Polyline>{};

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final shapeType = data['type'] as String?;

      switch (shapeType) {
        case 'polygon':
          final coordinates = data['coordinates'] as List<dynamic>?;
          final points = coordinates
                  ?.map((point) {
                    final lat = point['latitude'] as double?;
                    final lng = point['longitude'] as double?;
                    return (lat != null && lng != null)
                        ? LatLng(lat, lng)
                        : null;
                  })
                  .whereType<LatLng>()
                  .toList() ??
              [];

          if (points.isNotEmpty) {
            fetchedPolygons.add(
              Polygon(
                polygonId: PolygonId(doc.id),
                points: points,
                strokeWidth: 2,
                strokeColor: Colors.green,
                fillColor: Colors.green.withOpacity(0.3),
              ),
            );
          }
          break;

        case 'circle':
          final centerData = data['center'] as Map<String, dynamic>?;
          final center = centerData != null
              ? LatLng(centerData['latitude'] as double,
                  centerData['longitude'] as double)
              : LatLng(0, 0);
          final radius = data['radius'] as double? ?? 0;

          fetchedCircles.add(
            Circle(
              circleId: CircleId(doc.id),
              center: center,
              radius: radius,
              strokeWidth: 2,
              fillColor: Colors.orange.withOpacity(0.3),
              strokeColor: Colors.orange,
            ),
          );
          break;

        case 'line':
          final coordinates = data['coordinates'] as List<dynamic>?;
          final points = coordinates
                  ?.map((point) {
                    final lat = point['latitude'] as double?;
                    final lng = point['longitude'] as double?;
                    return (lat != null && lng != null)
                        ? LatLng(lat, lng)
                        : null;
                  })
                  .whereType<LatLng>()
                  .toList() ??
              [];

          if (points.isNotEmpty) {
            fetchedPolylines.add(
              Polyline(
                polylineId: PolylineId(doc.id),
                points: points,
                color: Colors.purple,
                width: 2,
              ),
            );
          }
          break;

        default:
          break;
      }
    }

    setState(() {
      polygons = fetchedPolygons;
      circles = fetchedCircles;
      polylines = fetchedPolylines;
      loadingData = false;
    });
  }

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suivi des plans de lotissement'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchSavedShapes,
            tooltip: 'Fetch Saved Shapes',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              onTap: _onTap,
              mapType: _currentMapType,
              initialCameraPosition: CameraPosition(
                target:
                    LatLng(33.9167, 10.1667), // Initial position (Tataouine)
                zoom: 10,
              ),
              polygons: polygons,
              polylines: polylines,
              circles: circles,
            ),
          ),
          if (loadingData)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          if (displayText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(displayText),
            ),
          if (showSaveButton &&
              (selectedShape == DrawShape.circle || 
                  selectedShape == DrawShape.line || 
                  selectedShape == DrawShape.polygon))
            Container(
              color: Color.fromARGB(255, 83, 195, 199), // Background color to test visibility
              child: ElevatedButton(
                onPressed: _showSaveDialog,
                child: Text('Save Shape'),
                
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.file_upload),
                onPressed: _pickKmlFile,
                 tooltip: 'telecharger fichier kml ',
              ),
        
        
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: _clearShapes,
                 tooltip: 'clearShapes',
              ),
              DropdownButton<MapLayer>(
                value: selectedLayer,
                onChanged: (value) {
                  setState(() {
                    selectedLayer = value!;
                    _currentMapType = MapType.values[selectedLayer.index];
                  });
                },
                items: MapLayer.values.map((MapLayer layer) {
                  return DropdownMenuItem<MapLayer>(
                    value: layer,
                    child: Text(layer.toString().split('.').last),
                  );
                }).toList(),
              ),
              DropdownButton<DrawShape>(
                value: selectedShape,
                onChanged: (value) {
                  setState(() {
                    selectedShape = value!;
                    _clearShapes(); // Clear shapes when changing the drawing mode
                  });
                },
                items: DrawShape.values.map((DrawShape shape) {
                  return DropdownMenuItem<DrawShape>(
                    value: shape,
                    child: Text(shape.toString().split('.').last),
                  );
                }).toList(),
              ),
              ElevatedButton(
                onPressed: isDrawing ? _stopDrawing : _startDrawing,
                child: Text(isDrawing ? 'Stop Drawing' : 'Start Drawing'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}