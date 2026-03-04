import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:convert';
import 'dart:typed_data';

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
      stream: FirebaseFirestore.instance
          .collection('carouselItems')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // Gestion des erreurs
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 50),
                SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        // État de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Aucune donnée
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'Aucun élément dans le carrousel',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  'Appuyez sur le bouton + pour ajouter',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // Affichage de la liste
        var carouselDocs = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: carouselDocs.length,
          itemBuilder: (context, index) {
            var doc = carouselDocs[index];
            var carouselItem = doc.data() as Map<String, dynamic>;
            
            // Récupération des données avec valeurs par défaut
            String url = carouselItem['url'] ?? '';
            String type = carouselItem['type'] ?? 'url';
            Timestamp? createdAt = carouselItem['createdAt'];

            return Card(
              elevation: 3,
              margin: EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(12),
                leading: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: type == 'image' && url.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: url.startsWith('data:image')
                              ? Image.memory(
                                  base64Decode(url.split(',').last),
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Erreur Image.memory: $error');
                                    return _buildErrorIcon();
                                  },
                                )
                              : Image.network(
                                  url,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Erreur Image.network: $error');
                                    return _buildErrorIcon();
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / 
                                                loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        )
                      : Container(
                          color: Colors.blue[50],
                          child: Icon(
                            Icons.link,
                            color: Colors.blue[700],
                            size: 30,
                          ),
                        ),
                ),
                title: Text(
                  type == 'image' ? 'Image' : 'Lien externe',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      url.length > 50 ? '${url.substring(0, 50)}...' : url,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (createdAt != null)
                      Text(
                        'Ajouté le: ${_formatDate(createdAt.toDate())}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteDialog(context, doc.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorIcon() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey[400],
          size: 30,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  void _showDeleteDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Supprimer l\'élément'),
        content: Text('Êtes-vous sûr de vouloir supprimer cet élément ?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            child: Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Supprimer'),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('carouselItems')
                    .doc(docId)
                    .delete();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Élément supprimé'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class AddCarouselItemPage extends StatefulWidget {
  @override
  _AddCarouselItemPageState createState() => _AddCarouselItemPageState();
}

class _AddCarouselItemPageState extends State<AddCarouselItemPage> {
  Uint8List? _imageBytes;
  String? _imagePreviewUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final TextEditingController urlController = TextEditingController();

  Future<void> getImage() async {
    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        // Version Web
        const XTypeGroup typeGroup = XTypeGroup(
          label: 'Images',
          extensions: <String>['jpg', 'jpeg', 'png', 'gif', 'webp'],
          webWildCards: <String>['image/*'],
        );

        final XFile? pickedFile = await openFile(
          acceptedTypeGroups: <XTypeGroup>[typeGroup],
        );

        if (pickedFile != null) {
          final bytes = await pickedFile.readAsBytes();
          final previewUrl = 'data:${pickedFile.mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}';
          
          setState(() {
            _imageBytes = bytes;
            _imagePreviewUrl = previewUrl;
          });
        }
      } else {
        // Version Mobile
        final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          final bytes = await pickedFile.readAsBytes();
          final previewUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          
          setState(() {
            _imageBytes = bytes;
            _imagePreviewUrl = previewUrl;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter un élément'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Aperçu de l'image
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _imagePreviewUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _imagePreviewUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error, color: Colors.red, size: 50),
                                    Text('Erreur de chargement'),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 80, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text('Aucune image sélectionnée'),
                            ],
                          ),
                        ),
            ),
            SizedBox(height: 20),
            
            // Bouton sélection image
            ElevatedButton.icon(
              onPressed: _isLoading ? null : getImage,
              icon: Icon(Icons.image),
              label: Text('Sélectionner une image'),
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
            ),
            SizedBox(height: 20),
            
            // Champ lien
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'Ou entrez un lien',
                hintText: 'https://...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            SizedBox(height: 20),
            
            // Bouton ajout
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (_imageBytes != null) {
                  // Sauvegarde de l'image en base64 dans Firestore
                  String base64Image = 'data:image/jpeg;base64,${base64Encode(_imageBytes!)}';
                  
                  await FirebaseFirestore.instance.collection('carouselItems').add({
                    'url': base64Image,
                    'type': 'image',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Image ajoutée'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                } else if (urlController.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('carouselItems').add({
                    'url': urlController.text.trim(),
                    'type': 'url',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Lien ajouté'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚠️ Choisissez une image ou entrez un lien'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: Text(_isLoading ? 'Chargement...' : 'Ajouter'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}