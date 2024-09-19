import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui' as ui;

class HtmlListPage extends StatefulWidget {
  @override
  _HtmlListPageState createState() => _HtmlListPageState();
}

class _HtmlListPageState extends State<HtmlListPage> {
  String htmlContentUrl = '';
  List<String> documentTitles = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDocumentTitles(); // Récupère les titres des documents au démarrage
  }

  // Fonction pour récupérer les titres des documents depuis l'API
  Future<void> _fetchDocumentTitles() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse('https://geotiif.vercel.app/pages')); // URL correcte pour les titres
      if (response.statusCode == 200) {
        final List<dynamic> titles = json.decode(response.body);
        setState(() {
          documentTitles = titles.cast<String>(); // Convertit les titres en liste de chaînes
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load document titles');
      }
    } catch (e) {
      print('Error fetching document titles: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching document titles';
      });
    }
  }

  // Fonction pour récupérer le contenu HTML d'un document spécifique
Future<void> _fetchHtmlContent(String title) async {
  setState(() {
    isLoading = true;
  });
  try {
    final response = await http.get(Uri.parse('https://geotiif.vercel.app/page/$title')); // URL correcte pour le contenu
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body); // Décoder le JSON
      final String htmlContent = jsonResponse['content']; // Extraire le contenu HTML du champ 'content'
      
      setState(() {
        htmlContentUrl = Uri.dataFromString(htmlContent, mimeType: 'text/html').toString(); // Conversion du contenu en URL
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load HTML content');
    }
  } catch (e) {
    print('Error fetching HTML content: $e');
    setState(() {
      isLoading = false;
      errorMessage = 'Error fetching HTML content';
    });
  }
}


  @override
  Widget build(BuildContext context) {
    // Enregistrement du type de vue pour afficher le HTML
    if (htmlContentUrl.isNotEmpty) {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory('iframe', (int viewId) {
        var iframe = html.IFrameElement()
          ..width = '100%'
          ..height = '500'
          ..src = htmlContentUrl // Utilisation de src pour les URL
          ..style.border = 'none'; // Optionnel : retirer la bordure autour de l'iframe
        return iframe;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des plans'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isLoading)
              Center(
                child: CircularProgressIndicator(),
              )
            else if (errorMessage.isNotEmpty)
              Center(
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              )
            else ...[
              Expanded(
                child: ListView.builder(
                  itemCount: documentTitles.length,
                  itemBuilder: (context, index) {
                    final title = documentTitles[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4.0,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.0),
                        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () => _fetchHtmlContent(title), // Charge le contenu HTML lorsqu'un titre est sélectionné
                      ),
                    );
                  },
                ),
              ),
              if (htmlContentUrl.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 500,
                  child: HtmlElementView(viewType: 'iframe'), // Affiche le HTML dans un iframe
                ),
            ],
          ],
        ),
      ),
    );
  }
}
