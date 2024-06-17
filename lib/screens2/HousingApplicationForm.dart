import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
class HousingApplicationForm extends StatefulWidget {
  const HousingApplicationForm({super.key});

  @override
  State<HousingApplicationForm> createState() => _HousingApplicationFormState();
}

class _HousingApplicationFormState extends State<HousingApplicationForm> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  LatLng? _selectedLocation;
  File? _selectedFile;
  String? _selectedSector;
  final List<String> _sectors = [
    'Sector 1',
    'Sector 2',
    'Sector 3',
    'Sector 4',
    'Sector 5',
    'Sector 6'
  ];
  late GoogleMapController _mapController;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void submitApplication() {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    // Check if all required fields are filled
    if (name.isEmpty || address.isEmpty  || phone.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Prepare data to submit
    Map<String, dynamic> applicationData = {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'selectedLocation': _selectedLocation != null
          ? GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude)
          : null,
      'selectedSector': _selectedSector,
      // Add more fields as needed
    };

    // Add data to Firestore
    FirebaseFirestore.instance.collection('applications').add(applicationData)
        .then((value) {
          // Clear the form
          _nameController.clear();
          _addressController.clear();
          _phoneController.clear();
          _emailController.clear();
          _selectedLocation = null;
          _selectedFile = null;
          _selectedSector = null;

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Application submitted successfully!')),
          );
        })
        .catchError((error) {
          // Show error message if submission fails
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit application: $error')),
          );
        });
  }

Future<void> pickFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();
  if (result != null) {
    if (kIsWeb) {
      // On web platform, use `bytes` instead of `path`
      List<int> bytes = result.files.single.bytes!;
      // Process `bytes` as needed
    } else {
      // On mobile platforms (iOS and Android), use `path`
      File file = File(result.files.single.path!);
      setState(() {
        _selectedFile = file;
      });
    }
  }
}



  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Housing Application Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
           
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            const Text('Select Location:'),
            SizedBox(
              height: 300,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(37.7749, -122.4194),
                  zoom: 10,
                ),
                markers: _selectedLocation != null
                    ? {
                        Marker(
                          markerId: const MarkerId('selectedLocation'),
                          position: _selectedLocation!,
                        ),
                      }
                    : {},
                onTap: (LatLng coord) {
                  setState(() {
                    _selectedLocation = coord;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickFile,
              child: const Text('Upload Plan'),
            ),
            if (_selectedFile != null) Text('File selected: ${_selectedFile!.path}'),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Select Sector'),
              value: _selectedSector,
              items: _sectors.map((String sector) {
                return DropdownMenuItem<String>(
                  value: sector,
                  child: Text(sector),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSector = newValue;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitApplication,
              child: const Text('Submit Application'),
            ),
          ],
        ),
      ),
    );
  }
}
