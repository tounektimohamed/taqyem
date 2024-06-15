import 'package:DREHATT_app/screens2/add_news_screen.dart';
import 'package:flutter/material.dart';

class AgentHome extends StatelessWidget {
  const AgentHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agent Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, Agent!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddNewsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
