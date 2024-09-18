import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HtmlPagesList extends StatefulWidget {
  @override
  _HtmlPagesListState createState() => _HtmlPagesListState();
}

class _HtmlPagesListState extends State<HtmlPagesList> {
  List<String> htmlPages = [];

  // Fetch HTML pages from the Flask API
  Future<void> fetchHtmlPages() async {
    try {
      final response = await http.get(Uri.parse('https://geotiif.vercel.app/pages'));
      if (response.statusCode == 200) {
        setState(() {
          htmlPages = List<String>.from(json.decode(response.body));
        });
      } else {
        throw Exception('Failed to load HTML pages');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching pages: $e')));
    }
  }

  // Delete an HTML page
  Future<void> deleteHtmlPage(String title) async {
    try {
      final response = await http.delete(Uri.parse('https://geotiif.vercel.app/delete_html/$title'));
      if (response.statusCode == 200) {
        setState(() {
          htmlPages.remove(title);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Page supprimée avec succès")));
      } else {
        throw Exception('Failed to delete HTML page');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting page: $e')));
    }
  }

  // Update an HTML page
  Future<void> updateHtmlPage(String title, String newContent) async {
    try {
      final response = await http.put(
        Uri.parse('https://geotiif.vercel.app/update_html/$title'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': newContent}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Page mise à jour avec succès")));
        // Refresh the list of pages after update
        fetchHtmlPages();
      } else {
        throw Exception('Failed to update HTML page');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating page: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchHtmlPages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gere les liste des plans '),
      ),
      body: htmlPages.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: htmlPages.length,
              itemBuilder: (context, index) {
                final pageTitle = htmlPages[index];
                return ListTile(
                  title: Text(pageTitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () async {
                          // Fetch the existing content for the selected page
                          final content = await _fetchHtmlContent(pageTitle);
                          String newContent = await _showEditDialog(context, pageTitle, content);
                          if (newContent.isNotEmpty) {
                            await updateHtmlPage(pageTitle, newContent);
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => deleteHtmlPage(pageTitle),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<String> _fetchHtmlContent(String title) async {
    try {
      final response = await http.get(Uri.parse('https://geotiif.vercel.app/page/$title'));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to load HTML content');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching HTML content: $e')));
      return '';
    }
  }

  Future<String> _showEditDialog(BuildContext context, String title, String existingContent) async {
    TextEditingController controller = TextEditingController(text: existingContent);

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Page Content'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter new content'),
            maxLines: 10,
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(''); // Ensure that a non-null value is returned
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                Navigator.of(context).pop(controller.text); // Return the content from the TextField
              },
            ),
          ],
        );
      },
    ).then((value) => value ?? ''); // Ensure non-null return value
  }
}
