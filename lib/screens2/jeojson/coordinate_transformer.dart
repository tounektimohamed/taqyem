import 'package:proj4dart/proj4dart.dart';
import 'package:latlong2/latlong.dart'; // Assurez-vous d'utiliser latlong2 pour LatLng

final projSrc = Projection.get('EPSG:22332'); // Remplacez par le code EPSG approprié pour UTM
final projDst = Projection.get('EPSG:4326'); // WGS84

LatLng transformCoordinate(double easting, double northing) {
  final pointSrc = Point(x: easting, y: northing);
  final pointForward = projSrc!.transform(projDst!, pointSrc);

  // Assurez-vous que pointForward n'est pas nul
  if (pointForward == null) {
    throw Exception('La transformation des coordonnées a échoué');
  }

  return LatLng(pointForward.y, pointForward.x); // LatLng(lat, lng)
}
