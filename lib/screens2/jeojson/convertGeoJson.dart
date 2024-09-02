import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
Future<void> removeZFromGeoJson(PlatformFile file) async {
  final url = Uri.parse('https://convertisseur-json-utm-to-wgs.onrender.com/remove_z');

  try {
    final geoJsonContent = file.bytes != null ? utf8.decode(file.bytes!) : '';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'geojson': jsonDecode(geoJsonContent)}),
    );

    if (response.statusCode == 200) {
      final processedGeoJson = jsonDecode(response.body);

      final jsonString = jsonEncode(processedGeoJson);

      final blob = html.Blob([jsonString]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', '${file.name.split('.').first}_noZ.geojson')
        ..click();

      html.Url.revokeObjectUrl(url);
    } else {
      throw Exception('Échec de la suppression de la composante Z: ${response.reasonPhrase}');
    }
  } catch (e) {
    throw Exception('Erreur lors de la suppression de la composante Z: $e');
  }
}

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
  bool _isLoading = false;

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
      setState(() {
        _isLoading = true;
      });

      try {
        await convertGeoJson(selectedFile!, epsgCode!);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conversion réussie!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de conversion: $e')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veuillez sélectionner un fichier et entrer un code EPSG.')));
    }
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Convertisseur GeoJSON a WGS')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _pickFile,
            child: const Text('Sélectionner un fichier GeoJSON WGS'),
          ),
          SizedBox(height: 16),
          if (selectedFile != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fichier sélectionné : ${selectedFile!.name}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Taille : ${selectedFile!.size ~/ 1024} KB', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Code EPSG',
              border: OutlineInputBorder(),
              suffixIcon: epsgCode != null
                  ? Icon(Icons.check, color: Colors.green)
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                epsgCode = int.tryParse(value);
              });
            },
          ),
          SizedBox(height: 16),
          Text('Veuillez patienter, la conversion peut prendre un certain temps'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _convertFile,
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : const Text('Convertir et télécharger'),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (selectedFile != null) {
                setState(() {
                  _isLoading = true;
                });

                try {
                  await removeZFromGeoJson(selectedFile!);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suppression de la composante Z réussie!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veuillez sélectionner un fichier.')));
              }
            },
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : const Text('Supprimer la composante Z et télécharger'),
          ),
        ],
      ),
    ),
  );
}
}
