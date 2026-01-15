class EducationalData {
  String? id;
  String classe;
  String matiere;
  String bareme;
  List<String> solutions;
  List<String> problemes;
  bool isMaster;

  EducationalData({
    this.id,
    required this.classe,
    required this.matiere,
    required this.bareme,
    required this.solutions,
    required this.problemes,
    this.isMaster = false,
  });

  factory EducationalData.fromJson(Map<String, dynamic> json, String id) {
    final solutions = json['solution'] is String
        ? [json['solution'] as String]
        : (json['solution'] as List?)?.cast<String>() ?? [];
    
    final problemes = json['probleme'] is String
        ? [json['probleme'] as String]
        : (json['probleme'] as List?)?.cast<String>() ?? [];

    final classe = json['classe']?.toString() ?? '';
    
    // Utilisez la nouvelle méthode pour toutes les années
    final isMaster = isMasterClassForAllYears(classe);

    return EducationalData(
      id: id,
      classe: classe,
      matiere: json['matiere']?.toString() ?? '',
      bareme: json['bareme']?.toString() ?? '',
      solutions: solutions,
      problemes: problemes,
      isMaster: isMaster,
    );
  }

  // MÉTHODE POUR TOUTES LES ANNÉES (de 1 à 6)
  static bool isMasterClassForAllYears(String classe) {
    if (classe.isEmpty) return false;
    
    final trimmedClasse = classe.trim();
    
    // Nettoyer les espaces multiples
    final cleanedClasse = trimmedClasse.replaceAll(RegExp(r'\s+'), ' ');
    
    // Vérifier si c'est une classe principale (ne se termine pas par une lettre/chiffre spécifique)
    
    // 1. D'abord, vérifier les patterns explicites pour les années 1 à 6
    final masterPatterns = [
      // Année 1
      'السنة الأولى ابتدائي',
      'السنة الأولى  ابتدائي',
      'السنة الاولى ابتدائي',
      
      // Année 2
      'السنة الثانية ابتدائي',
      'السنة الثانية  ابتدائي',
      'السنة الثانيةابتدائي',
      
      // Année 3
      'السنة الثالثة ابتدائي',
      'السنة الثالثة  ابتدائي',
      
      // Année 4
      'السنة الرابعة ابتدائي',
      'السنة الرابعة  ابتدائي',
      
      // Année 5
      'السنة الخامسة ابتدائي',
      'السنة الخامسة  ابتدائي',
      
      // Année 6
      'السنة السادسة ابتدائي',
      'السنة السادسة  ابتدائي',
      
      // Patterns génériques
      'السنة الأولى',
      'السنة الثانية',
      'السنة الثالثة',
      'السنة الرابعة',
      'السنة الخامسة',
      'السنة السادسة',
    ];
    
    for (final pattern in masterPatterns) {
      if (cleanedClasse == pattern) {
        return true;
      }
    }
    
    // 2. Vérifier par regex pour les classes principales
    final masterRegex = RegExp(r'^السنة\s+(?:الأولى|الثانية|الثالثة|الرابعة|الخامسة|السادسة)(?:\s+ابتدائي)?\s*$');
    
    if (masterRegex.hasMatch(cleanedClasse)) {
      return true;
    }
    
    // 3. Vérifier qu'elle ne se termine pas par un indicateur de sous-classe
    final lastPart = cleanedClasse.split(' ').last;
    
    final subClassIndicators = [
      'أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز', 'ح', 'ط', 'ي',
      'ا', 'ب', 'ج', 'د', 'ه', 'و', 'ز', 'ح', 'ط', 'ي',
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
      '1', '2', '3', '4', '5', '6', '7', '8', '9', '0',
      '.أ', '.ب', '.ج', '.د', '.هـ', '.و', '.ز',
      '.a', '.b', '.c', '.d', '.e', '.f', '.g',
      '.1', '.2', '.3', '.4', '.5', '.6'
    ];
    
    // Si le dernier élément n'est pas un indicateur de sous-classe ET
    // que la classe contient "السنة" suivie d'un numéro, c'est une master class
    if (!subClassIndicators.contains(lastPart) && 
        cleanedClasse.contains(RegExp(r'السنة\s+(?:الأولى|الثانية|الثالثة|الرابعة|الخامسة|السادسة)'))) {
      return true;
    }
    
    return false;
  }

  // Méthode pour obtenir l'année scolaire (1-6)
  int? get schoolYear {
    final regex = RegExp(r'السنة\s+(?:الأولى|الثانية|الثالثة|الرابعة|الخامسة|السادسة)');
    final match = regex.firstMatch(classe);
    
    if (match != null) {
      final yearText = match.group(0);
      if (yearText != null) {
        final yearMap = {
          'الأولى': 1,
          'الثانية': 2,
          'الثالثة': 3,
          'الرابعة': 4,
          'الخامسة': 5,
          'السادسة': 6,
        };
        
        for (final entry in yearMap.entries) {
          if (yearText.contains(entry.key)) {
            return entry.value;
          }
        }
      }
    }
    
    return null;
  }

  // Méthode pour obtenir le type de classe
  String get classType {
    if (classe.contains('ابتدائي')) return 'ابتدائي';
    if (classe.contains('إعدادي') || classe.contains('اعدادي')) return 'إعدادي';
    if (classe.contains('ثانوي')) return 'ثانوي';
    return 'غير محدد';
  }

  // Méthode pour obtenir toutes les sous-classes possibles (sections)
  List<String> get possibleSubclasses {
    if (!isMaster) return [classe];
    
    final masterClasse = this.masterClasse;
    final arabicLetters = ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز', 'ح', 'ط', 'ي'];
    
    return [
      masterClasse,
      ...arabicLetters.map((letter) => '$masterClasse $letter'),
      ...arabicLetters.map((letter) => '$masterClasse  $letter'),
      ...arabicLetters.map((letter) => '$masterClasse.$letter'),
    ];
  }

  // Méthode pour obtenir la classe principale (sans section)
  String get masterClasse {
    final regex = RegExp(r'^(.*?)(?:\s+[أ-يa-zA-Z0-9.]|\.[أ-يa-zA-Z0-9])?\s*$');
    final match = regex.firstMatch(classe.trim());
    return match?.group(1)?.trim() ?? classe;
  }

  // Ancienne méthode conservée pour compatibilité
  static bool isMasterClass(String classe) {
    return isMasterClassForAllYears(classe);
  }

  Map<String, dynamic> toJson() {
    return {
      'classe': classe,
      'matiere': matiere,
      'bareme': bareme,
      'solution': solutions,
      'probleme': problemes,
      'isMaster': isMaster,
      'schoolYear': schoolYear,
      'classType': classType,
      'masterClasse': masterClasse,
    };
  }
}