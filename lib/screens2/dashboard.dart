import 'package:DREHATT_app/screens2/users/moreUser.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:DREHATT_app/screens2/homepage2.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final user = FirebaseAuth.instance.currentUser;

  // Bottom nav bar
  int _selectedIndex = 0;

  // Floating Action Button
  bool isFABvisible = true;
  bool chatBot = true;

  @override
  Widget build(BuildContext context) {
    // Pages
    final List<Widget> pages = <Widget>[
      const HomePage2(),
      const MoreUser(), // Assurez-vous que cette classe est définie et importée correctement
    ];

    // Scaffold
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(),
      ),
      body: SafeArea(
        child: Center(
          child: pages.elementAt(_selectedIndex),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color.fromARGB(255, 242, 253, 255),
        destinations: [
          // Home
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: 'Home', // Changez cela si vous avez une méthode de traduction
            selectedIcon: const Icon(
              Icons.home_rounded,
              color: Color.fromRGBO(7, 82, 96, 1),
            ),
          ),
          // MoreUser
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            label: 'More ', // Changez cela si vous avez une méthode de traduction
            selectedIcon: const Icon(
              Icons.person,
              color: Color.fromRGBO(7, 82, 96, 1),
            ),
          ),
        ],
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              isFABvisible = true;
              chatBot = true;
              break;
            case 1: // MoreUser
              isFABvisible = false;
              chatBot = false;
              break;
          }

          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
