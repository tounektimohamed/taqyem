import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;

class SubdivisionMapPage extends StatefulWidget {
  const SubdivisionMapPage({Key? key}) : super(key: key);

  @override
  _SubdivisionMapPageState createState() => _SubdivisionMapPageState();
}

class _SubdivisionMapPageState extends State<SubdivisionMapPage> {
  late fm.MapController mapController;
  List<ll.LatLng> points = [];
  List<fm.Polygon> polygons = [];
  List<fm.Polyline> polylines = [];
  List<fm.CircleMarker> circles = [];
  List<fm.Marker> markers = [];
  double calculatedArea = 0.0;
  Color selectedColor = const Color.fromARGB(255, 194, 33, 243);
  String selectedShape = 'Polygon';
  bool isDrawing = false;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    mapController = fm.MapController();
  }

  void _addPoint(ll.LatLng point) {
    setState(() {
      isDrawing = true;
      points.add(point);

      if (selectedShape == 'Polygon') {
        polygons = [];
        if (points.length > 2) {
          polygons.add(fm.Polygon(
            points: List.from(points),
            color: selectedColor.withOpacity(0.5),
            borderStrokeWidth: 2.0,
            borderColor: selectedColor,
          ));
          calculatedArea = _calculatePolygonArea(points);
        }
      } else if (selectedShape == 'Circle') {
        if (points.length == 2) {
          final center = points[0];
          final radius = _calculateDistance(center, points[1]);
          circles = [];
          circles.add(fm.CircleMarker(
            point: center,
            color: selectedColor.withOpacity(0.5),
            borderColor: selectedColor,
            borderStrokeWidth: 2.0,
            radius: radius,
          ));
          calculatedArea = _calculateCircleArea(radius);
        }
      } else if (selectedShape == 'Line') {
        polylines = [];
        if (points.length > 1) {
          polylines.add(fm.Polyline(
            points: List.from(points),
            strokeWidth: 2.0,
            color: selectedColor,
          ));
        }
      } else if (selectedShape == 'Point') {
        markers = [];
        if (points.isNotEmpty) {
          markers.add(fm.Marker(
            point: points.last,
            child: Icon(Icons.location_on, color: selectedColor),
          ));
        }
      } else if (selectedShape == 'Square') {
        if (points.length == 2) {
          final squarePoints = _calculateSquarePoints(points[0], points[1]);
          polygons = [];
          polygons.add(fm.Polygon(
            points: squarePoints,
            color: selectedColor.withOpacity(0.5),
            borderStrokeWidth: 2.0,
            borderColor: selectedColor,
          ));
          calculatedArea = _calculatePolygonArea(squarePoints);
        }
      }
    });
  }

  void _completeShape() {
    setState(() {
      isDrawing = false;
      points.clear();
    });
  }

  List<ll.LatLng> _calculateSquarePoints(ll.LatLng p1, ll.LatLng p2) {
    double sideLength = _calculateDistance(p1, p2);
    double angle = atan2(p2.latitude - p1.latitude, p2.longitude - p1.longitude);

    return [
      p1,
      ll.LatLng(p1.latitude + sideLength * cos(angle), p1.longitude + sideLength * sin(angle)),
      ll.LatLng(p2.latitude + sideLength * cos(angle), p2.longitude + sideLength * sin(angle)),
      ll.LatLng(p2.latitude, p2.longitude),
      p1
    ];
  }

  double _calculatePolygonArea(List<ll.LatLng> polygonPoints) {
    if (polygonPoints.length < 3) return 0.0;

    double area = 0.0;
    int j = polygonPoints.length - 1;
    for (int i = 0; i < polygonPoints.length; i++) {
      area += (polygonPoints[j].longitude + polygonPoints[i].longitude) *
              (polygonPoints[j].latitude - polygonPoints[i].latitude);
      j = i;
    }
    return area.abs() / 2.0 * 111.32 * 111.32;
  }

  double _calculateCircleArea(double radius) {
    return pi * radius * radius * 111.32 * 111.32;
  }

  double _calculateDistance(ll.LatLng p1, ll.LatLng p2) {
    return sqrt(pow(p2.latitude - p1.latitude, 2) + pow(p2.longitude - p1.longitude, 2));
  }

  void _savePlan() {
    String firstName = _firstNameController.text;
    String lastName = _lastNameController.text;
    if ((polygons.isNotEmpty || polylines.isNotEmpty || circles.isNotEmpty || markers.isNotEmpty) &&
        firstName.isNotEmpty &&
        lastName.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plan saved for $firstName $lastName')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete the shape and fill in the client details.')),
      );
    }
  }

  void _selectColor() async {
    Color? color = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                setState(() {
                  selectedColor = color;
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Select'),
              onPressed: () {
                Navigator.of(context).pop(selectedColor);
              },
            ),
          ],
        );
      },
    );
    if (color != null) {
      setState(() {
        selectedColor = color;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subdivision Plan Tracking'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _savePlan,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: fm.FlutterMap(
              mapController: mapController,
              options: fm.MapOptions(
                center: ll.LatLng(33.10, 10.25),
                zoom: 12,
                interactiveFlags: isDrawing
                    ? fm.InteractiveFlag.none
                    : fm.InteractiveFlag.all,
                onTap: (tapPosition, point) {
                  _addPoint(point);
                },
              ),
              children: [
                fm.TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                fm.PolygonLayer(polygons: polygons),
                fm.PolylineLayer(polylines: polylines),
                fm.CircleLayer(circles: circles),
                fm.MarkerLayer(markers: markers),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _completeShape,
                    child: Text('Complete Shape'),
                  ),
                  SizedBox(height: 10),
                  Text('Area: ${calculatedArea.toStringAsFixed(2)} sq. meters'),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _selectColor,
                    child: Text('Select Color'),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: EdgeInsets.all(8),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    switch (selectedShape) {
                      case 'Polygon':
                        selectedShape = 'Square';
                        break;
                      case 'Square':
                        selectedShape = 'Circle';
                        break;
                      case 'Circle':
                        selectedShape = 'Line';
                        break;
                      case 'Line':
                        selectedShape = 'Point';
                        break;
                      case 'Point':
                        selectedShape = 'Polygon';
                        break;
                    }
                  });
                },
                child: Text('Switch to ${_getNextShape()}'),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: 10,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    mapController.move(mapController.center, mapController.zoom + 1);
                  },
                  child: Icon(Icons.zoom_in),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    mapController.move(mapController.center, mapController.zoom - 1);
                  },
                  child: Icon(Icons.zoom_out),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                TextField(
                  controller: _firstNameController,
                  decoration: InputDecoration(labelText: 'First Name'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _lastNameController,
                  decoration: InputDecoration(labelText: 'Last Name'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getNextShape() {
    switch (selectedShape) {
      case 'Polygon':
        return 'Square';
      case 'Square':
        return 'Circle';
      case 'Circle':
        return 'Line';
      case 'Line':
        return 'Point';
      case 'Point':
      default:
        return 'Polygon';
    }
  }
}
