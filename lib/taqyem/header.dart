import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  final String profName;
  final String schoolName;
  final String className;
  final String matiereName;

  const PageHeader({
    required this.profName,
    required this.schoolName,
    required this.className,
    required this.matiereName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        children: [
          // Professeur, matière et classe à gauche (alignés verticalement)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الأستاذ: $profName',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                'المادة: $matiereName',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                'القسم: $className',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          Spacer(),
          // Logo et nom de l'école à droite
          Column(
            children: [
              Image.asset(
                'lib/assets/icons/me/ministere.png',
                height: 100,
              ),
              SizedBox(height: 8),
              Text(
                'مدرسة: $schoolName',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}