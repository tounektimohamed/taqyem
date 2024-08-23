import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';

class CustomGeoJsonParser extends GeoJsonParser {
  CustomGeoJsonParser({
    required Color defaultMarkerColor,
    required Color defaultPolygonBorderColor,
    required Color defaultPolygonFillColor,
    required Color defaultCircleMarkerColor,
  }) : super(
          defaultMarkerColor: defaultMarkerColor,
          defaultPolygonBorderColor: defaultPolygonBorderColor,
          defaultPolygonFillColor: defaultPolygonFillColor,
          defaultCircleMarkerColor: defaultCircleMarkerColor,
        );

  final Map<String, Color> layerColorMap = {
    'EQUIP': Color(0xff0e38c0), // Dark Blue
    '1 UAa1': Color(0xffdb7979), // Light Red
    '1 E': Colors.red, // Red
    '1 UAa4': Color(0xff4caf50), // Green
    '1 UVa': Color(0xff2196f3), // Blue
    '1 NAa': Color(0xffff9800), // Orange
    '1 UVb': Color(0xff9c27b0), // Dark Purple
    '1 UBa': Color(0xffe91e63), // Pink
    '0 fonts': Color(0xff93C572), // Pistachio Green
  };

  Color parseColorFromString(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xff')));
    } catch (e) {
      print('Erreur de conversion de couleur: $colorString');
      return Colors.grey; // Couleur de secours
    }
  }

 @override
void parseGeoJsonAsString(String geoJsonString) {
  super.parseGeoJsonAsString(geoJsonString);

  polygons.clear();

  try {
    final Map<String, dynamic> geoJsonData = jsonDecode(geoJsonString);
    final List<dynamic> features = geoJsonData['features'];

    for (var feature in features) {
      final geometry = feature['geometry'];
      final properties = feature['properties'];
      final geometryType = geometry['type'];
      final layer = properties['Layer'] as String?;

      Color fillColor = Colors.green; // Couleur de remplissage par défaut
      Color borderColor = Colors.black; // Couleur de bordure par défaut
      double borderWidth = 2.0; // Largeur de bordure par défaut
      double fillOpacity = 0.5; // Opacité de remplissage par défaut

      if (layer != null && layerColorMap.containsKey(layer)) {
        fillColor = layerColorMap[layer]!;
        print('Couleur de remplissage basée sur le Layer: $fillColor');
      }

      if (properties.containsKey('fill')) {
        fillColor = parseColorFromString(properties['fill'] as String);
        print('Couleur de remplissage définie dans les propriétés: $fillColor');
      }

      if (properties.containsKey('stroke')) {
        borderColor = parseColorFromString(properties['stroke'] as String);
        print('Couleur de bordure définie dans les propriétés: $borderColor');
      }

      if (properties.containsKey('stroke-width')) {
        borderWidth = (properties['stroke-width'] as num).toDouble();
      }

      if (properties.containsKey('fill-opacity')) {
        fillOpacity = (properties['fill-opacity'] as num).toDouble();
      }

      if (geometryType == 'Polygon' || geometryType == 'MultiPolygon') {
        var coordinates = geometry['coordinates'];
        List<List<LatLng>> pointsList = [];

        if (geometryType == 'Polygon') {
          pointsList.add(
            (coordinates as List<dynamic>)[0]
                .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
                .toList(),
          );
        } else if (geometryType == 'MultiPolygon') {
          for (var polygon in coordinates) {
            for (var ring in (polygon as List<dynamic>)) {
              pointsList.add(
                ring.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList(),
              );
            }
          }
        }

        for (var points in pointsList) {
          polygons.add(
            Polygon(
              points: points,
              color: fillColor.withOpacity(fillOpacity),
              borderColor: borderColor,
              borderStrokeWidth: borderWidth,
            ),
          );
          print('Polygone ajouté avec couleur de remplissage: $fillColor et bordure: $borderColor');
        }
      }
    }
  } catch (e) {
    print('Erreur lors de l\'analyse du GeoJSON: $e');
  }
}

}
