// modern_drawer.dart
import 'package:Taqyem/taqyem/AddStudentPage.dart';
import 'package:Taqyem/taqyem/selectionPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Taqyem/taqyem/AddClassPage.dart';

import 'package:Taqyem/taqyem/pdf/ManagePDFPage.dart';

class ModernDrawer extends StatelessWidget {
  final User? currentUser;
  final String userName;
  final Stream<DocumentSnapshot> accountStatusStream;

  const ModernDrawer({
    Key? key,
    required this.currentUser,
    required this.userName,
    required this.accountStatusStream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 5,
              offset: const Offset(3, 0),
            ),
          ],
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(context),
            
            // Class Management Section
            _buildDrawerSectionHeader('Gestion des Classes'),
            _buildDrawerItem(
              context,
              Icons.school,
              'إضافة قسم جديد',
              () => _navigateTo(context, AddClassPage()),
            ),
            _buildDrawerItem(
              context,
              Icons.class_,
              'إدارة الأقسام',
              () => _navigateTo(context, ManageClassesPage()),
            ),

            // Tables Section
            _buildDrawerSectionHeader('Gestion des Tableaux'),
            _buildDrawerItem(
              context,
              Icons.table_chart,
              'إعداد جدول جامع',
              () => _navigateTo(context, SelectionPage()),
            ),

            // Documents Section
            _buildDrawerSectionHeader('Documents'),
            _buildDrawerItem(
              context,
              Icons.picture_as_pdf,
              'مشاركة وثائق تعلمية',
              () => _navigateTo(context, UploadPDFPage()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: currentUser?.photoURL != null
                ? NetworkImage(currentUser!.photoURL!)
                : null,
            backgroundColor: Colors.white,
            child: currentUser?.photoURL == null
                ? const Icon(Icons.person_outlined, color: Colors.black)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            userName,
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: accountStatusStream,
            builder: (context, snapshot) {
              bool isActive = false;
              if (snapshot.hasData && snapshot.data!.exists) {
                isActive = snapshot.data!['isActive'] ?? false;
              }

              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: isActive ? Colors.green[300] : Colors.red[300],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'Compte Premium' : 'Compte Standard',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: isActive ? Colors.green[200] : Colors.red[200],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 300), onTap);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          hoverColor: Colors.white.withOpacity(0.1),
          tileColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}