import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timeline_calendar/timeline/flutter_timeline_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymeds_app/components/medcard.dart';
import 'package:mymeds_app/screens/account_settings.dart';

class HomePage2 extends StatefulWidget {
  const HomePage2({super.key});

  @override
  State<HomePage2> createState() => _HomePage2State();
}

class _HomePage2State extends State<HomePage2> {
  final ValueNotifier<CalendarDateTime> _selectedDate =
      ValueNotifier<CalendarDateTime>(CalendarDateTime(
          year: DateTime.now().year,
          month: DateTime.now().month,
          day: DateTime.now().day));

  User? currentUser = FirebaseAuth.instance.currentUser;

  //document IDs
  List<String> docIds = [];

  //get docIDs
  Future getDocIDs() async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser!.email)
        .collection('Medications')
        .get()
        .then(
          (snapshot) => snapshot.docs.forEach(
            (document) {
              print(document.reference);
              docIds.add(document.reference.id);
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          //app logo and user icon
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            alignment: Alignment.topCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //logo and name
                Column(
                  children: [
                    //logo
                    const Image(
                      image: AssetImage('lib/assets/icon_small.png'),
                      height: 50,
                    ),
                    //app name
                    Text(
                      'MyMeds',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color.fromRGBO(7, 82, 96, 1),
                      ),
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
                              return SettingsPageUI();
                            },
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        child: const Icon(Icons.person_outlined),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.surface,
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
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                  child: TimelineCalendar(
                    calendarType: CalendarType.GREGORIAN,
                    calendarLanguage: "en",
                    calendarOptions: CalendarOptions(
                      viewType: ViewType.DAILY,
                      toggleViewType: true,
                      headerMonthElevation: 0,
                    ),
                    dayOptions: DayOptions(
                      compactMode: true,
                      dayFontSize: 15,
                      weekDaySelectedColor:
                          Theme.of(context).colorScheme.primary,
                      selectedBackgroundColor:
                          Theme.of(context).colorScheme.primary,
                      disableDaysBeforeNow: false,
                    ),
                    headerOptions: HeaderOptions(
                        weekDayStringType: WeekDayStringTypes.SHORT,
                        monthStringType: MonthStringTypes.FULL,
                        backgroundColor: Colors.transparent,
                        headerTextColor: Colors.black),
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
                    //title
                    Text(
                      // _currentDate.toString().substring(0, 10),
                      // '$_selectedDate',
                      _selectedDate.value.toString().substring(0, 10),
                      style: GoogleFonts.roboto(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    //reminder text
                    Text(
                      'You currently have no reminders',
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),

          //timeline widget
          Expanded(
            child: GlowingOverscrollIndicator(
              axisDirection: AxisDirection.down,
              color: const Color.fromARGB(255, 7, 83, 96),
              child: SingleChildScrollView(
                physics: ScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    children: [
                      FutureBuilder(
                        future: getDocIDs(),
                        builder: (context, snapshot) {
                          return ListView.builder(
                            itemCount: docIds.length,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return ValueListenableBuilder<CalendarDateTime>(
                                valueListenable: _selectedDate,
                                builder: (context, value, child) {
                                  return MedCard(
                                    documentID: docIds[index],
                                    index: index,
                                    size: docIds.length,
                                    selectedDate: value,
                                  );
                                },
                              );
                            },
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
