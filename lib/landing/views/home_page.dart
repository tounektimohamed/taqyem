import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'header_widget.dart'; // Import your header widget
import 'footer_widget.dart'; // Import your footer widget

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            HeaderWidget(), // Add your HeaderWidget here
            MainContent(),
            NewsSection(), // Assuming you want to add new functionality
            FooterWidget(), // Add your FooterWidget here
          ],
        ),
      ),
    );
  }
}

class MainContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionOne(),
        SectionTwo(),
      ],
    );
  }
}

class SectionOne extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        return Container(
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: isMobile
              ? Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A Perfect Landing Page To Showcase Your App',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: Icon(Icons.apple),
                              label: Text('App Store'),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: Icon(Icons.android),
                              label: Text('Google Play'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Image.asset(
                      'lib/assets/icons/me/mokup.png',
                      height: 300,
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A Perfect Landing Page To Showcase Your App',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout.',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: Icon(Icons.apple),
                                label: Text('App Store'),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: Icon(Icons.android),
                                label: Text('Google Play'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      'lib/assets/icons/me/mokup.png',
                      height: 300,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class SectionTwo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        return Container(
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            children: [
              Text(
                'Why Choose Us?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              isMobile
                  ? Column(
                      children: [
                        FeatureCard(
                          icon: Icons.security,
                          title: 'Secure Payment',
                          description:
                              'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                        ),
                        FeatureCard(
                          icon: Icons.payment,
                          title: 'Payment Gateway',
                          description:
                              'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                        ),
                        FeatureCard(
                          icon: Icons.integration_instructions,
                          title: 'Internal Integration',
                          description:
                              'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: FeatureCard(
                            icon: Icons.security,
                            title: 'Secure Payment',
                            description:
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                          ),
                        ),
                        Expanded(
                          child: FeatureCard(
                            icon: Icons.payment,
                            title: 'Payment Gateway',
                            description:
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                          ),
                        ),
                        Expanded(
                          child: FeatureCard(
                            icon: Icons.integration_instructions,
                            title: 'Internal Integration',
                            description:
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
                          ),
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

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  FeatureCard(
      {required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 50, color: Colors.blue),
            SizedBox(height: 10),
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(description, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// NewWidget is the new widget you want to add, integrate it accordingly

class NewsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                return const Center(child: CircularProgressIndicator());
              }

              var newsDocs = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: newsDocs.length,
                itemBuilder: (context, index) {
                  var news = newsDocs[index].data() as Map<String, dynamic>;
                  var title = news['title'] ?? 'No Title';
                  var content = news['content'] ?? 'No Content';
                  var timestamp = news['timestamp'] as Timestamp;
                  var date = timestamp.toDate();

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      leading: Image.asset(
                        'lib/assets/icons/me/news.gif', // Replace with your relative PNG file path
                        width: 130, // Desired image size
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                              color: const Color.fromARGB(255, 165, 159, 159),
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
    );
  }
}
