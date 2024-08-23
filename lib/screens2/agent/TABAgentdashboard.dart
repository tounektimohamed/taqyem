import 'dart:async';

import 'package:DREHATT_app/screens2/agent/Agentdashbord.dart';
import 'package:DREHATT_app/screens2/login_signup/account_settings.dart';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:DREHATT_app/components/language_constants.dart';
import 'package:DREHATT_app/screens2/homepage2.dart';

class Agentdashboard extends StatefulWidget {
  const Agentdashboard({super.key});

  @override
  State<Agentdashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Agentdashboard> {
  final user = FirebaseAuth.instance.currentUser;

  //bottom nav bar
  int _selectedIndex = 0;

  //Floating Action Button
  bool isFABvisible = true;
  bool chatBot = true;

  //alarm list
  late List<AlarmSettings> alarms;

  static StreamSubscription? subscription;

  void loadAlarms() {
    setState(() {
      alarms = Alarm.getAlarms();
      alarms.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
    });
  }

//show alarm ring screen

  // // documnet IDs
  // List<String> docIDs = [];

  // //get docIDs
  // Future getDocIDs() async {
  //   await FirebaseFirestore.instance.collection('users').get().then(
  //         (snapshot) => snapshot.docs.forEach(
  //           (documnet) {
  //             print(documnet.reference);
  //             docIDs.add(documnet.reference.id);
  //           },
  //         ),
  //       );
  // }


  @override
  Widget build(BuildContext context) {
    //pages
    final List<Widget> pages = <Widget>[
      //main page
      const AgentDashboard(),
      //medication
     // const Mediaction(),
      //statistic
      //settings
      const SettingsPageUI(),
    ];

    //scaffold
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
      //floating action button
    
      //bottom navigation
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color.fromARGB(255, 242, 253, 255),
        destinations: [
          //home
          NavigationDestination(
            icon: const Icon(
              Icons.home_outlined,
            ),
            label: translation(context).home,
            selectedIcon: const Icon(
              Icons.home_rounded,
              color: Color.fromRGBO(7, 82, 96, 1),
            ),
          ),
          //medications
          // NavigationDestination(
          //   icon: const Icon(
          //     Icons.medication_outlined,
          //   ),
          //   label: translation(context).medications,
          //   selectedIcon: const Icon(
          //     Icons.medication,
          //     color: Color.fromRGBO(7, 82, 96, 1),
          //   ),
          // ),
          //history
          // NavigationDestination(
          //   icon: const Icon(
          //     Icons.analytics_outlined,
          //   ),
          //   label: translation(context).statistics,
          //   selectedIcon: const Icon(
          //     Icons.analytics_rounded,
          //     color: Color.fromRGBO(7, 82, 96, 1),
          //   ),
          // ),
          //settings
          NavigationDestination(
            icon: const Icon(
              Icons.settings,
            ),
            label: translation(context).settings,
            selectedIcon: const Icon(
              Icons.settings,
              color: Color.fromRGBO(7, 82, 96, 1),
            ),
          ),
        ],
        // unselectedLabelStyle: GoogleFonts.roboto(
        //   fontWeight: FontWeight.w400,
        // ),
        // selectedLabelStyle: GoogleFonts.roboto(
        //   fontWeight: FontWeight.w600,
        // ),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int) {
          switch (int) {
            case 0:
              isFABvisible = true;
              chatBot = true;
              break;
            case 1: //home
              //show FAB in medication page
              isFABvisible = true;
              chatBot = false;
              break;
            case 2:
              isFABvisible = false;
              chatBot = false;
              break;
            case 3:
              chatBot = false;
              isFABvisible = false;
              break;
          }

          setState(() {
            _selectedIndex = int;
          });
        },
      ),
    );
  }
}
