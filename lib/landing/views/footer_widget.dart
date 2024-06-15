import 'package:flutter/material.dart';

class FooterWidget extends StatelessWidget {
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
                'Don\'t miss out, Stay updated',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              SizedBox(height: 20),
              isMobile
                  ? Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Enter your email address',
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
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          child: Text('SUBSCRIBE'),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 300,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Enter your email address',
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
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          child: Text('SUBSCRIBE'),
                        ),
                      ],
                    ),
              SizedBox(height: 20),
              Divider(color: Colors.white),
              SizedBox(height: 20),
              isMobile
                  ? Column(
                      children: [
                        FooterLink(text: 'ABOUT US'),
                        FooterLink(text: 'BLOG'),
                        FooterLink(text: 'ABOUT US'),
                        FooterLink(text: 'TERMS & CONDITIONS'),
                        FooterLink(text: 'CONTACT'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FooterLink(text: 'ABOUT US'),
                        FooterLink(text: 'BLOG'),
                        FooterLink(text: 'ABOUT US'),
                        FooterLink(text: 'TERMS & CONDITIONS'),
                        FooterLink(text: 'CONTACT'),
                      ],
                    ),
              SizedBox(height: 20),
              Text(
                '© 2022 DREHATT. All rights reserved.',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
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
