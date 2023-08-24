import 'package:flutter/material.dart';
import 'package:mymeds_app/screens/set_photo_screen.dart';

import 'package:maps_launcher/maps_launcher.dart';
import 'package:geolocator/geolocator.dart';

class More extends StatefulWidget {
  const More({super.key});

  @override
  State<More> createState() => _SettingsState();
}

class _SettingsState extends State<More> {
  Position? _currentPosition;

  // @override
  // void initState() {
  //   super.initState();
  //   _getCurrentLocation();
  // }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled, show a dialog to enable them.
        _showLocationServiceAlertDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // The user has denied access to location permissions.
          print('User denied permissions to access the device\'s location.');
          return;
        }
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  // Method to show the dialog to enable location services.
  void _showLocationServiceAlertDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enable Location Services'),
          content: Text('Please enable location services to use this app.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                bool serviceEnabled = await Geolocator.openLocationSettings();
                if (serviceEnabled) {
                  // Location services are now enabled, try getting the location again.
                  await _getCurrentLocation();
                }
              },
              child: Text('ENABLE'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //1st ROW

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 160,
                      height: 100,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SetPhotoScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                        ),
                        label: const Text(
                          'Add a photo of the prescription',
                        ),
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  width: 20,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 160,
                      height: 100,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _getCurrentLocation();
                          if (_currentPosition != null) {
                            MapsLauncher.launchQuery(
                                'nearby hospitals and pharmacies');
                          }
                        },
                        icon: const Icon(
                          Icons.location_on_outlined,
                        ),
                        label:
                            const Text('Find nearest pharmacies and hospitals'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(
              width: 40,
              height: 30,
            ),

            //2nd ROW

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 160,
                      height: 100,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => const SetPhotoScreen(),
                          //   ),
                          // );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color.fromARGB(255, 7, 83, 96),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                              content: Text(
                                'Coming soon...',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.calculate_outlined,
                        ),
                        label: const Text('Calculate your BMI'),
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  width: 20,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 160,
                      height: 100,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => const SetPhotoScreen(),
                          //   ),
                          // );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color.fromARGB(255, 7, 83, 96),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                              content: Text(
                                'Coming soon...',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.alarm_rounded,
                        ),
                        label: const Text('Alarm Settings'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(
              width: 40,
              height: 30,
            ),

            //3rd ROW

            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Column(
            //       mainAxisAlignment: MainAxisAlignment.start,
            //       children: [
            //         Container(
            //           width: 160,
            //           height: 100,
            //           child: ElevatedButton.icon(
            //             onPressed: () {
            //               Navigator.push(
            //                 context,
            //                 MaterialPageRoute(
            //                   builder: (context) => const SetPhotoScreen(),
            //                 ),
            //               );
            //             },
            //             icon: const Icon(
            //               Icons.account_box,
            //               color: Colors.black,
            //             ),
            //             label: const Text('Profile',
            //                 style: TextStyle(color: Colors.black)),
            //             style: ElevatedButton.styleFrom(
            //                 backgroundColor:
            //                     const Color.fromARGB(255, 254, 37, 37),
            //                 shape: RoundedRectangleBorder(
            //                   borderRadius: BorderRadius.circular(10),
            //                 )),
            //           ),
            //         ),
            //       ],
            //     ),
            //     const SizedBox(
            //       width: 20,
            //     ),
            //     Column(
            //       mainAxisAlignment: MainAxisAlignment.start,
            //       children: [
            //         Container(
            //           width: 160,
            //           height: 100,
            //           child: ElevatedButton.icon(
            //             onPressed: () {
            //               Navigator.push(
            //                 context,
            //                 MaterialPageRoute(
            //                   builder: (context) => const SetPhotoScreen(),
            //                 ),
            //               );
            //             },
            //             icon: const Icon(
            //               Icons.medical_information,
            //               color: Colors.black,
            //             ),
            //             label: const Text('Medicine',
            //                 style: TextStyle(color: Colors.black)),
            //             style: ElevatedButton.styleFrom(
            //               backgroundColor:
            //                   const Color.fromARGB(255, 68, 243, 255),
            //               shape: RoundedRectangleBorder(
            //                 borderRadius: BorderRadius.circular(10),
            //               ),
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ],
            // ),
            // const SizedBox(
            //   width: 40,
            //   height: 30,
            // ),

            // //4th ROW

            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Column(
            //       mainAxisAlignment: MainAxisAlignment.start,
            //       children: [
            //         Container(
            //           width: 160,
            //           height: 100,
            //           child: ElevatedButton.icon(
            //             onPressed: () {
            //               Navigator.push(
            //                 context,
            //                 MaterialPageRoute(
            //                   builder: (context) => const SetPhotoScreen(),
            //                 ),
            //               );
            //             },
            //             icon: const Icon(
            //               Icons.history,
            //               color: Colors.black,
            //             ),
            //             label: const Text('History',
            //                 style: TextStyle(color: Colors.black)),
            //             style: ElevatedButton.styleFrom(
            //                 backgroundColor:
            //                     const Color.fromARGB(255, 255, 136, 0),
            //                 shape: RoundedRectangleBorder(
            //                   borderRadius: BorderRadius.circular(10),
            //                 )),
            //           ),
            //         ),
            //       ],
            //     ),
            //     const SizedBox(
            //       width: 20,
            //     ),
            //     Column(
            //       mainAxisAlignment: MainAxisAlignment.start,
            //       children: [
            //         Container(
            //           width: 160,
            //           height: 100,
            //           child: ElevatedButton.icon(
            //             onPressed: () {
            //               Navigator.push(
            //                 context,
            //                 MaterialPageRoute(
            //                   builder: (context) => const SetPhotoScreen(),
            //                 ),
            //               );
            //             },
            //             icon: const Icon(
            //               Icons.food_bank,
            //               color: Colors.black,
            //             ),
            //             label: const Text('Foods',
            //                 style: TextStyle(color: Colors.black)),
            //             style: ElevatedButton.styleFrom(
            //               backgroundColor:
            //                   const Color.fromARGB(255, 152, 0, 246),
            //               shape: RoundedRectangleBorder(
            //                 borderRadius: BorderRadius.circular(10),
            //               ),
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}
