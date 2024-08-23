import 'package:DREHATT_app/screens2/login_signup/sign_in.dart';
import 'package:DREHATT_app/screens2/login_signup/sign_up.dart';
import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          color: Color.fromARGB(255, 138, 178, 211),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset('lib/assets/icons/me/cigle-meh.png',
                                height: 40),
                            SizedBox(width: 10),
                            Text('DREHATT',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 24)),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.menu, color: Colors.white),
                          onPressed: () {
                            // Ajouter un tiroir de navigation ou d'autres actions
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUp()),
                            );
                          },
                          child: Text('S\'INSCRIRE',
                              style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignIn()),
                            );
                          },
                          child: Text('CONNEXION'),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset('lib/assets/icons/me/cigle-meh.png',
                            height: 40),
                        SizedBox(width: 10),
                        Text('DREHATT',
                            style:
                                TextStyle(color: Colors.white, fontSize: 24)),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUp()),
                            );
                          },
                          child: Text('S\'INSCRIRE',
                              style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignIn()),
                            );
                          },
                          child: Text('CONNEXION'),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}
