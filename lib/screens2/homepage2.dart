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
import 'login_signup/account_settings.dart';

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

class ClaimFormPage extends StatefulWidget {
  @override
  _ClaimFormPageState createState() => _ClaimFormPageState();
}

class _ClaimFormPageState extends State<ClaimFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  XFile? _image;
  String? _imageUrl;
  Position? _position;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
        if (kIsWeb) {
          _imageUrl = pickedFile.path;
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _position = position;
    });
  }

  Future<void> _submitClaim() async {
    if (_formKey.currentState!.validate() &&
        (_image != null || _imageUrl != null) &&
        _position != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        String imageUrl;
        if (!kIsWeb) {
          // Upload the image to Firebase Storage for non-web platforms
          String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
          UploadTask uploadTask = FirebaseStorage.instance
              .ref()
              .child('claims')
              .child(fileName)
              .putFile(File(_image!.path));

          TaskSnapshot taskSnapshot = await uploadTask;
          imageUrl = await taskSnapshot.ref.getDownloadURL();
        } else {
          imageUrl = _imageUrl!;
        }

        // Save the claim details to Firestore
        await FirebaseFirestore.instance.collection('claims').add({
          'userId': FirebaseAuth.instance.currentUser!.uid,
          'title': _titleController.text,
          'content': _contentController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
          'imageUrl': imageUrl,
          'position': GeoPoint(_position!.latitude, _position!.longitude),
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Claim submitted successfully')),
        );

        _formKey.currentState!.reset();
        setState(() {
          _image = null;
          _imageUrl = null;
          _position = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting claim: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Please fill all fields, add a photo, and select a location')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit a Claim'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter content';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              _image == null && _imageUrl == null
                  ? Text('No image selected.')
                  : kIsWeb
                      ? Image.network(_imageUrl!)
                      : Image.file(File(_image!.path)),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image),
                label: Text('Pick Image'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: Icon(Icons.location_on),
                label: Text('Get Current Location'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              _position == null
                  ? Text('No location selected.')
                  : Text(
                      'Location: ${_position!.latitude}, ${_position!.longitude}'),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitClaim,
                      child: Text('Submit Claim'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        textStyle: TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
