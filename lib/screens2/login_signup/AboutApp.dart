import 'package:flutter/material.dart';

class AboutApp extends StatelessWidget {
  const AboutApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'حول التطبيق',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF075260),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [

              SizedBox(height: 10),

              Center(
                child: Icon(
                  Icons.school,
                  size: 80,
                  color: Color(0xFF075260),
                ),
              ),

              SizedBox(height: 20),

              Center(
                child: Text(
                  'تقييم – Taqyem',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF075260),
                  ),
                ),
              ),

              SizedBox(height: 8),

              Center(
                child: Text(
                  'النسخة 1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),

              SizedBox(height: 30),

              Text(
                'نبذة عن التطبيق:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF075260),
                ),
              ),

              SizedBox(height: 16),

              Text(
                'تطبيق "تقييم – Taqyem" هو منظومة تربوية رقمية ذكية تهدف إلى تمكين المعلمين من إدارة عمليات التقييم والمتابعة والتصنيف التربوي بطريقة منهجية دقيقة وسهلة الاستخدام.',
                style: TextStyle(fontSize: 16),
              ),

              SizedBox(height: 16),

              Text(
                'يساعد التطبيق على تحليل أداء التلاميذ، تحديد مواطن القوة والصعوبات، واقتراح تدخلات علاجية مناسبة وفق نتائج التقييم.',
                style: TextStyle(fontSize: 16),
              ),

              SizedBox(height: 24),

              Text(
                'رؤيتنا:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF075260),
                ),
              ),

              SizedBox(height: 16),

              Text(
                'تطوير بيئة تعليمية ذكية تعتمد على التحليل الدقيق للبيانات التربوية، وتدعم اتخاذ القرار التعليمي المبني على مؤشرات واضحة.',
                style: TextStyle(fontSize: 16),
              ),

              SizedBox(height: 24),

              Text(
                'أهداف التطبيق:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF075260),
                ),
              ),

              SizedBox(height: 16),

              Text('• تحسين جودة التقييم داخل القسم'),
              Text('• تسهيل المتابعة الفردية لكل تلميذ'),
              Text('• دعم التدخل العلاجي المبكر'),
              Text('• توفير تقارير دقيقة قابلة للطباعة'),

              SizedBox(height: 30),

              Center(
                child: Text(
                  '© 2026 Taqyem\nجميع الحقوق محفوظة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}