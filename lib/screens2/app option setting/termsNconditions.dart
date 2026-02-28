import 'package:flutter/material.dart';

class TermsAndConditions extends StatelessWidget {
  const TermsAndConditions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'سياسة الخصوصية',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF075260),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [

                Text(
                  'سياسة الخصوصية',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF075260),
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'نحن في تطبيق "تقييم – Taqyem" نولي أهمية قصوى لحماية بيانات المستخدمين وخصوصيتهم. توضح هذه السياسة كيفية جمع المعلومات واستخدامها وحمايتها عند استخدامك للتطبيق.',
                ),

                SizedBox(height: 24),

                Text(
                  'المعلومات التي نقوم بجمعها:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF075260),
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'قد نقوم بجمع بعض البيانات الأساسية مثل:',
                ),

                SizedBox(height: 8),

                Text('• الاسم وبيانات الحساب'),
                Text('• البريد الإلكتروني'),
                Text('• معلومات الأقسام والتلاميذ التي يُدخلها المستخدم'),
                Text('• بيانات الاستخدام لتحسين الأداء'),

                SizedBox(height: 24),

                Text(
                  'كيفية استخدام المعلومات:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF075260),
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'نستخدم البيانات من أجل:',
                ),

                SizedBox(height: 8),

                Text('• توفير خدمات التقييم والمتابعة'),
                Text('• تحسين تجربة المستخدم'),
                Text('• تطوير ميزات جديدة'),
                Text('• ضمان الأمان وحماية النظام'),

                SizedBox(height: 24),

                Text(
                  'حماية البيانات:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF075260),
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'نعتمد إجراءات تقنية وتنظيمية لحماية البيانات من الوصول غير المصرح به أو التعديل أو الإفشاء أو الإتلاف.',
                ),

                SizedBox(height: 24),

                Text(
                  'مشاركة المعلومات:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF075260),
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'لا نقوم ببيع أو تأجير البيانات لأي طرف ثالث. قد يتم مشاركة المعلومات فقط في حال وجود التزام قانوني أو بموافقة المستخدم.',
                ),

                SizedBox(height: 24),

                Text(
                  'حقوق المستخدم:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF075260),
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'يحق للمستخدم طلب الاطلاع على بياناته أو تعديلها أو حذفها في أي وقت من خلال إعدادات الحساب أو عبر التواصل مع فريق الدعم.',
                ),

                SizedBox(height: 24),

                Text(
                  'تحديثات السياسة:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF075260),
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'قد نقوم بتحديث سياسة الخصوصية من وقت لآخر. سيتم إشعار المستخدمين بأي تغييرات مهمة داخل التطبيق.',
                ),

                SizedBox(height: 24),

                Text(
                  'اتصل بنا:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'إذا كان لديك أي استفسار بخصوص سياسة الخصوصية، يمكنك التواصل معنا عبر صفحة الدعم داخل التطبيق.',
                ),

                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}