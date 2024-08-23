import 'package:flutter/material.dart';

class TermsOfServices extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms of Services"),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/termsfoview.webp',
          ),
          const SizedBox(
            height: 20,
          ),
          const Text(
            "text here",
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          )
        ],
      )),
    );
  }
}
