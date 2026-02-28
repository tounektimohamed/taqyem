import 'package:flutter/material.dart';

class HelpCenter extends StatelessWidget {
  const HelpCenter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'حول تطبيق تقييم – Taqyem',
            style: TextStyle(
              color: Color(0xFF075260),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [

                SizedBox(height: 10),

                Text(
                  'معلومات عامة:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF075260),
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'س1: ما هو تطبيق "تقييم – Taqyem"؟',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'تطبيق "تقييم – Taqyem" هو منظومة تربوية رقمية ذكية صُمِّمت خصيصًا لمساعدة الأستاذ على إدارة عمليات التقييم، المتابعة، التصنيف، والدعم العلاجي بطريقة منهجية دقيقة وسهلة الاستعمال، وفق التوجيهات البيداغوجية المعتمدة.',
                ),

                SizedBox(height: 16),

                Text(
                  'س2: ماذا يتيح لي التطبيق داخل القسم؟',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'يُمكّنك التطبيق من إنشاء الأقسام الدراسية، إضافة التلاميذ، تنظيم المواد حسب المستوى، ومتابعة الأداء الفردي والجماعي بطريقة منظمة وواضحة.',
                ),

                SizedBox(height: 24),

                Text(
                  'المميزات التربوية للنظام:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF075260),
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'س3: كيف يتم التقييم داخل التطبيق؟',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'يعتمد التطبيق على نظام تقييم قائم على المعايير والمؤشرات، حيث يمكن برمجة مؤشرات خاصة بكل مادة، وتقييم أداء التلاميذ بطريقة معيارية عادلة، مع عرض جدول جامع للنتائج قابل للاستخراج بصيغة PDF أو HTML.',
                ),

                SizedBox(height: 16),

                Text(
                  'س4: هل يقوم التطبيق بالتصنيف التربوي تلقائيًا؟',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'نعم، يقوم التطبيق تلقائيًا بتصنيف التلاميذ إلى مجموعة التميّز، مجموعة الدعم، ومجموعة العلاج اعتمادًا على نتائج التقييم ونِسَب التمكن.',
                ),

                SizedBox(height: 16),

                Text(
                  'س5: هل يوفر التطبيق خطط علاج تربوية؟',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'نعم، يساعد التطبيق على تحديد الصعوبات التعليمية لكل مجموعة، واقتراح حلول علاجية مناسبة، مع إمكانية إعداد تقارير فردية أو شاملة قابلة للطباعة.',
                ),

                SizedBox(height: 24),

                Text(
                  'الأمان والخصوصية:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF075260),
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'س6: هل بيانات التلاميذ آمنة؟',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'نعم، يتم تأمين البيانات وفق معايير الحماية المعتمدة، مع ضمان خصوصية المعلومات وعدم استخدامها خارج الإطار التربوي.',
                ),

                SizedBox(height: 16),

                Text(
                  'س7: هل يتم حفظ النتائج بطريقة آمنة؟',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'يتم حفظ جميع النتائج والتقارير بطريقة منظمة وآمنة، مع إمكانية الرجوع إليها في أي وقت.',
                ),

                SizedBox(height: 24),

                Text(
                  'الإحصائيات والمتابعة:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF075260),
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'س8: هل يوفر التطبيق إحصائيات تحليلية؟',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'نعم، يعرض التطبيق نسب التقدم، توزيع المستويات، وتحليل أداء كل تلميذ عبر تمثيل بصري واضح يساعد على اتخاذ قرارات تربوية سليمة.',
                ),

                SizedBox(height: 16),

                Text(
                  'س9: هل يدعم التطبيق نظام الحضور والغياب؟',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'نعم، يمكن تسجيل الحضور اليومي، احتساب نسب الغياب تلقائيًا، وتتبع الحالات الفردية بسهولة.',
                ),

                SizedBox(height: 24),

                Text(
                  'الدعم والتحديثات:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF075260),
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'س10: هل يتم تحديث التطبيق بانتظام؟',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'نعم، يتم إصدار تحديثات دورية لتحسين الأداء وإضافة ميزات جديدة تواكب المستجدات التربوية.',
                ),

                SizedBox(height: 30),

                Center(
                  child: Text(
                    '“تقييم – Taqyem”\nشريكك التربوي الذكي\nلتقييم أدق، متابعة أنجع، وتدخل علاجي أكثر فاعلية.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF075260),
                    ),
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}