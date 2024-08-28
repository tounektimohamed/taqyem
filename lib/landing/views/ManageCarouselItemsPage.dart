import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;

class ManageCarouselItemsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gérer les éléments du carrousel'),
      ),
      body: CarouselItemsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCarouselItemPage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
class CarouselItemsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('carouselItems').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var carouselDocs = snapshot.data!.docs;

        return ListView.separated(
          itemCount: carouselDocs.length,
          separatorBuilder: (context, index) => Divider(),
          itemBuilder: (context, index) {
            var carouselItem = carouselDocs[index].data() as Map<String, dynamic>;
            var url = carouselItem['url'];
            var type = carouselItem['type'] ?? 'url';

            Widget leading;
            if (type == 'image') {
              leading = kIsWeb
                ? Image.network(
                    url,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                      return Image.asset(
                        'assets/images/placeholder.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.network(
                    url,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                      return Image.asset(
                        'assets/images/placeholder.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      );
                    },
                  );
            } else {
              leading = Icon(Icons.link);
            }

            return Card(
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                leading: leading,
                title: Text(
                  type == 'image' ? 'Image' : 'Lien: ${url.substring(0, 50)}',
                  style: TextStyle(fontSize: 16),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: Text('Supprimer l\'élément'),
                        content: Text('Êtes-vous sûr de vouloir supprimer cet élément ?'),
                        actions: [
                          TextButton(
                            child: Text('Annuler'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: Text('Supprimer'),
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('carouselItems')
                                  .doc(carouselDocs[index].id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Élément supprimé'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
class AddCarouselItemPage extends StatefulWidget {
  @override
  _AddCarouselItemPageState createState() => _AddCarouselItemPageState();
}

class _AddCarouselItemPageState extends State<AddCarouselItemPage> {
  File? _image;
  String? _imageDataUrl;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController urlController = TextEditingController();

  Future<void> getImage() async {
    if (kIsWeb) {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();
      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final reader = html.FileReader();
          reader.readAsDataUrl(files[0]);
          reader.onLoadEnd.listen((e) {
            setState(() {
              _image = null; // Not used directly on web
              _imageDataUrl = reader.result as String; // Handle Data URL
            });
          });
        }
      });
    } else {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      setState(() {
        if (pickedFile != null) {
          _image = File(pickedFile.path);
          _imageDataUrl = null; // Not applicable for non-web platforms
        } else {
          print('No image selected.');
        }
      });
    }
  }

  Future<String> uploadImageToFirebase(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    firebase_storage.Reference ref =
        firebase_storage.FirebaseStorage.instance.ref().child('images/$fileName');
    firebase_storage.UploadTask uploadTask = ref.putFile(imageFile);
    firebase_storage.TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    String imageUrl = await taskSnapshot.ref.getDownloadURL();
    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter un élément au carrousel'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _image != null
                ? Image.file(
                    _image!,
                    height: 150,
                  )
                : _imageDataUrl != null
                    ? Image.network(
                        _imageDataUrl!,
                        height: 150,
                      )
                    : Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: Center(
                          child: Text(
                            'Aucune image sélectionnée.',
                            style: TextStyle(fontSize: 16.0),
                          ),
                        ),
                      ),
            ElevatedButton(
              onPressed: getImage,
              child: Text('Sélectionner une image'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'Lien',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_image != null) {
                  // For non-web platforms
                  String imageUrl = await uploadImageToFirebase(_image!);
                  FirebaseFirestore.instance.collection('carouselItems').add({
                    'url': imageUrl,
                    'type': 'image',
                  });
                } else if (_imageDataUrl != null) {
                  // For web platforms
                  FirebaseFirestore.instance.collection('carouselItems').add({
                    'url': _imageDataUrl!,
                    'type': 'image',
                  });
                } else {
                  var url = urlController.text;
                  if (url.isNotEmpty) {
                    FirebaseFirestore.instance.collection('carouselItems').add({
                      'url': url,
                      'type': 'url',
                    });
                  }
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Élément ajouté'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.pop(context);
              },
              child: Text('Ajouter l\'élément'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
