
import 'package:flutter/material.dart';

class RatingPage extends StatefulWidget {
  final String subjectName;

  RatingPage({required this.subjectName});

  @override
  _RatingPageState createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  double _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Donner une note pour ${widget.subjectName}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Note pour ${widget.subjectName}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Slider(
              value: _rating,
              min: 0,
              max: 10,
              divisions: 10,
              label: _rating.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _rating = value;
                });
              },
            ),
            Text(
              _rating.toStringAsFixed(1),
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Vous pouvez sauvegarder la note dans Firestore ici si nécessaire.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Note de $_rating enregistrée pour ${widget.subjectName}')),
                );
                Navigator.pop(context);
              },
              child: Text('Enregistrer la note'),
            ),
          ],
        ),
      ),
    );
  }
}
