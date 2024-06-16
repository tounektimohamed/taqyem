import 'package:DREHATT_app/screens2/Claim.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_timeline_calendar/timeline/flutter_timeline_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'account_settings.dart';

class HomePage2 extends StatefulWidget {
  const HomePage2({super.key});

  @override
  State<HomePage2> createState() => _HomePage2State();
}

class _HomePage2State extends State<HomePage2> {
  //date listener
  final ValueNotifier<CalendarDateTime> _selectedDate =
      ValueNotifier<CalendarDateTime>(
    CalendarDateTime(
        year: DateTime.now().year,
        month: DateTime.now().month,
        day: DateTime.now().day),
  );

  //current user
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Add any initialization code if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            //app logo and user icon
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              alignment: Alignment.topCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //logo and name
                  const Column(
                    children: [
                      //logo
                      Image(
                        image: AssetImage('lib/assets/icons/me/logo.png'),
                        height: 50,
                      ),
                    ],
                  ),

                  // user icon widget
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return const SettingsPageUI();
                              },
                            ),
                          );
                        },
                        child: (currentUser?.photoURL?.isEmpty ?? true)
                            ? CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.surface,
                                child: const Icon(Icons.person_outlined),
                              )
                            : CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                    NetworkImage(currentUser!.photoURL!),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // calendar, selected date and reminder text widget
            Column(
              children: [
                Container(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: TimelineCalendar(
                      calendarType: CalendarType.GREGORIAN,
                      calendarLanguage: "en",
                      calendarOptions: CalendarOptions(
                        viewType: ViewType.DAILY,
                        toggleViewType: true,
                        headerMonthElevation: 0,
                        headerMonthBackColor:
                            const Color.fromARGB(255, 241, 250, 251),
                      ),
                      dayOptions: DayOptions(
                        compactMode: true,
                        dayFontSize: 15,
                        weekDaySelectedColor:
                            Theme.of(context).colorScheme.primary,
                        selectedBackgroundColor:
                            Theme.of(context).colorScheme.primary,
                        disableDaysBeforeNow: false,
                        unselectedBackgroundColor: Colors.white,
                      ),
                      headerOptions: HeaderOptions(
                        weekDayStringType: WeekDayStringTypes.SHORT,
                        monthStringType: MonthStringTypes.FULL,
                        backgroundColor:
                            const Color.fromARGB(255, 241, 250, 251),
                        headerTextColor: Colors.black,
                      ),
                      onChangeDateTime: (date) {
                        setState(() {
                          _selectedDate.value = date;
                        });
                      },
                      onDateTimeReset: (p0) {
                        setState(() {
                          _selectedDate.value = CalendarDateTime(
                              year: DateTime.now().year,
                              month: DateTime.now().month,
                              day: DateTime.now().day);
                        });
                      },
                      dateTime: _selectedDate.value,
                    ),
                  ),
                ),

                //date text and reminder
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Display the selected date
                      Text(
                        _selectedDate.value.toString().substring(0, 10),
                        style: GoogleFonts.roboto(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      // Title for the news section
                      Text(
                        'News',
                        selectionColor: Colors.yellow,
                        style: GoogleFonts.roboto(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),
                      // StreamBuilder to fetch the latest news
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('news')
                            .orderBy('timestamp', descending: true)
                            .limit(5)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          var newsDocs = snapshot.data!.docs;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: newsDocs.length,
                            itemBuilder: (context, index) {
                              var news = newsDocs[index].data()
                                  as Map<String, dynamic>;
                              var title = news['title'] ?? 'No Title';
                              var content = news['content'] ?? 'No Content';
                              var timestamp = news['timestamp'] as Timestamp;
                              var date = timestamp.toDate();

                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: ListTile(
                                  leading: Image.asset(
                                    'lib/assets/icons/me/news.gif', // Remplacez par le chemin relatif de votre fichier PNG
                                    width: 130, // Taille souhaitée de l'image
                                    height: 100,
                                  ),
                                  title: Text(
                                    title,
                                    style: GoogleFonts.roboto(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        content,
                                        style: GoogleFonts.roboto(
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Published on: ${date.toLocal().toString().substring(0, 16)}',
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
           
          ],
        ),
      ),
    );
  }
}

class ClaimsListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Claims List'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('claims').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              Claim claim = Claim.fromFirestore(snapshot.data!.docs[index]);

              return ListTile(
                title: Text(claim.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Content: ${claim.content}'),
                    if (claim.position != null) // Check if position is not null
                      Text('Location: ${claim.position!.latitude}, ${claim.position!.longitude}'),
                    Text('Date: ${claim.timestamp.toDate().toString()}'),
                  ],
                ),
                // Add other UI elements as needed
              );
            },
          );
        },
      ),
    );
  }
}
