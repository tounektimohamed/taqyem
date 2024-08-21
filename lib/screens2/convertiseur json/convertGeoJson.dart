import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

Future<void> convertGeoJson(PlatformFile file, int epsgCode) async {
  final url = Uri.parse('https://convertisseur-json-utm-to-wgs.onrender.com/convert');

  try {
    final geoJsonContent = file.bytes != null ? utf8.decode(file.bytes!) : '';

    // Débogage : affiche les données envoyées
    print('Données envoyées : ${jsonEncode({
      'epsg_code': epsgCode,
      'geojson': jsonDecode(geoJsonContent),
    })}');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'epsg_code': epsgCode,
        'geojson': jsonDecode(geoJsonContent),
      }),
    );

    if (response.statusCode == 200) {
      final convertedGeoJson = jsonDecode(response.body);

      // Débogage : affiche les données reçues
      print('Données reçues : $convertedGeoJson');

      final jsonString = jsonEncode(convertedGeoJson);

      final blob = html.Blob([jsonString]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', '${file.name.split('.').first}_converted.geojson')
        ..click();

      html.Url.revokeObjectUrl(url);
    } else {
      throw Exception('Échec de la conversion GeoJSON: ${response.reasonPhrase}');
    }
  } catch (e) {
    throw Exception('Erreur lors de la conversion GeoJSON: $e');
  }
}


class GeoJsonConverterPage extends StatefulWidget {
  @override
  _GeoJsonConverterPageState createState() => _GeoJsonConverterPageState();
}

class _GeoJsonConverterPageState extends State<GeoJsonConverterPage> {
  PlatformFile? selectedFile;
  int? epsgCode;

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['geojson']);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFile = result.files.single;
        print('Fichier sélectionné : ${selectedFile!.name}');  // Débogage
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aucun fichier sélectionné.')));
    }
  }

  void _convertFile() async {
    if (selectedFile != null && epsgCode != null) {
      try {
        await convertGeoJson(selectedFile!, epsgCode!);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Conversion réussie!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de conversion: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veuillez sélectionner un fichier et entrer un code EPSG.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Convertisseur GeoJSON')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: Text('Sélectionner un fichier GeoJSON'),
            ),
            if (selectedFile != null) Text('Fichier sélectionné : ${selectedFile!.name}'),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Code EPSG'),
              onChanged: (value) {
                setState(() {
                  epsgCode = int.tryParse(value);
                });
              },
            ),
            ElevatedButton(
              onPressed: _convertFile,
              child: Text('Convertir et télécharger'),
            ),
          ],
        ),
      ),
    );
  }
}
