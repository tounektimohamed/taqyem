import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FooterWidget extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        return Container(
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          color: Colors.blue,
          child: Column(
            children: [
              Text(
                'Ne manquez pas, restez informé',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              SizedBox(height: 20),
              isMobile
                  ? Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Entrez votre adresse e-mail',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            _subscribeToNewsletter(context);
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                          ),
                          child: Text('S\'ABONNER'),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 300,
                          child: TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Entrez votre adresse e-mail',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            _subscribeToNewsletter(context);
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                          ),
                          child: Text('S\'ABONNER'),
                        ),
                      ],
                    ),
              SizedBox(height: 20),
              Divider(color: Colors.white),
              SizedBox(height: 20),
              isMobile
                  ? Column(
                      children: [
                        FooterLink(text: 'À PROPOS DE NOUS'),
                        FooterLink(text: 'BLOG'),
                        FooterLink(text: 'CONDITIONS GÉNÉRALES'),
                        FooterLink(text: 'CONTACT'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FooterLink(text: 'À PROPOS DE NOUS'),
                        FooterLink(text: 'BLOG'),
                        FooterLink(text: 'CONDITIONS GÉNÉRALES'),
                        FooterLink(text: 'CONTACT'),
                      ],
                    ),
              SizedBox(height: 20),
              Text(
                '© ${DateTime.now().year} DREHATT. Tous droits réservés.',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  void _subscribeToNewsletter(BuildContext context) async {
    try {
      if (_emailController.text.isNotEmpty) {
        await FirebaseFirestore.instance.collection('subscribers').add({
          'email': _emailController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });

        _emailController.clear();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Abonnement réussi'),
            content: Text('Merci de vous être abonné à notre newsletter !'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Erreur'),
            content: Text('Veuillez entrer votre adresse e-mail.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de l\'abonnement à la newsletter : $e');
    }
  }
}

class FooterLink extends StatelessWidget {
  final String text;

  FooterLink({required this.text});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
