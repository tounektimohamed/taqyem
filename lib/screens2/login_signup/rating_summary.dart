import 'package:Taqyem/screens2/login_signup/rating_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RatingSummary extends StatefulWidget {
  const RatingSummary({Key? key}) : super(key: key);

  @override
  State<RatingSummary> createState() => _RatingSummaryState();
}

class _RatingSummaryState extends State<RatingSummary> {
  double _averageRating = 0;
  int _totalRatings = 0;
  Map<int, int> _ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

  @override
  void initState() {
    super.initState();
    _calculateAverages();
  }

  Future<void> _calculateAverages() async {
    try {
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .orderBy('createdAt', descending: true)
          .get();

      if (ratingsSnapshot.docs.isEmpty) return;

      double total = 0;
      Map<int, int> counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var doc in ratingsSnapshot.docs) {
        final rating = (doc.data()['rating'] ?? 0).toDouble();
        total += rating;
        
        // Compter par note
        int note = rating.toInt();
        if (note >= 1 && note <= 5) {
          counts[note] = (counts[note] ?? 0) + 1;
        }
      }

      setState(() {
        _totalRatings = ratingsSnapshot.docs.length;
        _averageRating = total / _totalRatings;
        _ratingCounts = counts;
      });
    } catch (e) {
      print('Erreur de calcul: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Évaluations',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 173, 1, 1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Résumé des notes
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.grey[100],
            child: Row(
              children: [
                // Note moyenne
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text(
                        _averageRating.toStringAsFixed(1),
                        style: GoogleFonts.roboto(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 173, 1, 1),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < _averageRating.round()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$_totalRatings évaluation${_totalRatings > 1 ? 's' : ''}',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Barres de progression par note
                Expanded(
                  flex: 2,
                  child: Column(
                    children: List.generate(5, (index) {
                      int note = 5 - index;
                      int count = _ratingCounts[note] ?? 0;
                      double percentage = _totalRatings > 0
                          ? (count / _totalRatings) * 100
                          : 0;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 30,
                              child: Text(
                                '$note★',
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.amber,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                ' ${percentage.toStringAsFixed(0)}%',
                                style: GoogleFonts.roboto(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des commentaires
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ratings')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final ratings = snapshot.data?.docs ?? [];

                if (ratings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Aucune évaluation pour le moment',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RatingPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 173, 1, 1),
                          ),
                          child: const Text('Donner mon avis'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: ratings.length,
                  itemBuilder: (context, index) {
                    final rating = ratings[index].data() as Map<String, dynamic>;
                    final date = (rating['createdAt'] as Timestamp?)?.toDate();
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Color.fromARGB(255, 173, 1, 1),
                                  child: Text(
                                    (rating['userName']?[0] ?? 'U').toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rating['userName'] ?? 'Utilisateur',
                                        style: GoogleFonts.roboto(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (date != null)
                                        Text(
                                          DateFormat('dd/MM/yyyy').format(date),
                                          style: GoogleFonts.roboto(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (i) {
                                    return Icon(
                                      i < (rating['rating'] ?? 0)
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            if (rating['comment'] != null && 
                                rating['comment'].toString().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  rating['comment'],
                                  style: GoogleFonts.roboto(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RatingPage(),
            ),
          );
        },
        backgroundColor: Color.fromARGB(255, 173, 1, 1),
        child: const Icon(Icons.add_comment),
      ),
    );
  }
}