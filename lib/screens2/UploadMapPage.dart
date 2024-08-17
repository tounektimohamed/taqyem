import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class UploadMapPage extends StatefulWidget {
  @override
  _UploadMapPageState createState() => _UploadMapPageState();
}

class _UploadMapPageState extends State<UploadMapPage> {
  PlatformFile? _file;

  Future<void> _uploadFile() async {
    if (_file != null) {
      try {
        final storageRef = FirebaseStorage.instance.ref().child('geojson_files/${_file!.name}');
        final Uint8List fileBytes = _file!.bytes!;

        // Upload file to Firebase Storage
        await storageRef.putData(fileBytes);

        // Save metadata to Firestore
        await FirebaseFirestore.instance.collection('geojson_files').add({
          'name': _file!.name,
          'path': storageRef.fullPath,
          'uploadedAt': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File uploaded and metadata saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['geojson']);
    if (result != null) {
      setState(() {
        _file = result.files.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Map Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _selectFile,
              child: Text('Select GeoJSON File'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadFile,
              child: Text('Upload File'),
            ),
            if (_file != null) Text('Selected File: ${_file!.name}'),
          ],
        ),
      ),
    );
  }
}
