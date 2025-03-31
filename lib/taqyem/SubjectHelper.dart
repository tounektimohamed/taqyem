import 'package:flutter/material.dart';

class SubjectHelper {
  static Map<String, IconData> subjectIcons = {
    'التواصل الشفوي': Icons.mic,
    'قراءة': Icons.menu_book,
    'انتاج كتابي': Icons.edit,
    'قواعد لغة': Icons.g_translate,
    'رياضيات': Icons.calculate,
    'ايقاظ علمي': Icons.science,
    'تربية اسلامية': Icons.mosque,
    'تربية تكنولوجية': Icons.computer,
    'تربية موسيقية': Icons.music_note,
    'تربية تشكيلية': Icons.palette,
    'تربية بدنية': Icons.sports_soccer,
    'التاريخ': Icons.history,
    'الجغرافيا': Icons.public,
    'التربية المدنية': Icons.account_balance,
    'Expression orale et récitation': Icons.record_voice_over,
    'Lecture': Icons.chrome_reader_mode,
    'Production écrite': Icons.create,
    'écriture': Icons.drive_file_rename_outline,
    'dictée': Icons.spellcheck,
    'langue': Icons.language,
    'لغة انقليزية': Icons.translate,
  };

  static Color getSubjectColor(String subjectName) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
      Colors.pink,
    ];
    return colors[subjectName.hashCode % colors.length];
  }

  static IconData getIconForSubject(String subjectName) {
    return subjectIcons[subjectName] ?? Icons.book;
  }
}