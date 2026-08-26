class ExerciseTranslationService {
  static final Map<String, String> _bodyPartTranslations = {
    'chest': 'Peito',
    'back': 'Costas',
    'upper arms': 'Braços (Superiores)',
    'lower arms': 'Antebraços',
    'upper legs': 'Pernas (Coxas)',
    'lower legs': 'Panturrilhas',
    'shoulders': 'Ombros',
    'waist': 'Abdômen / Cintura',
    'cardio': 'Aeróbico / Cardio',
    'neck': 'Pescoço',
  };

  static final Map<String, String> _equipmentTranslations = {
    'barbell': 'Barra',
    'dumbbell': 'Halteres',
    'body weight': 'Peso Corporal',
    'cable': 'Polia (Cabo)',
    'leverage machine': 'Máquina Alavancada',
    'smith machine': 'Barra Guiada (Smith)',
    'kettlebell': 'Kettlebell',
    'band': 'Elástico / Extensor',
    'medicine ball': 'Bola Medicinal',
    'assisted': 'Assistido',
    'weighted': 'Com Carga Adicional',
    'stability ball': 'Bola Suíça',
    'ez barbell': 'Barra W (EZ)',
    'wheel roller': 'Rolo Abdominal',
    'bosu ball': 'Bosu',
    'roller': 'Rolo de Liberação',
    'rope': 'Corda',
  };

  static final Map<String, String> _targetMuscleTranslations = {
    'biceps': 'Bíceps',
    'triceps': 'Tríceps',
    'abs': 'Abdominais',
    'delts': 'Deltoides (Ombros)',
    'latissimus dorsi': 'Dorsais (Lats)',
    'pectorals': 'Peitoral',
    'quads': 'Quadríceps',
    'hamstrings': 'Posterior de Coxa',
    'glutes': 'Glúteos',
    'calves': 'Panturrilhas',
    'traps': 'Trapézio',
    'forearms': 'Antebraços',
    'lats': 'Dorsais',
    'cardiovascular system': 'Sistema Cardiovascular',
    'upper back': 'Parte Superior das Costas',
    'lower back': 'Lombar',
    'adductors': 'Adutores',
    'abductors': 'Abdutores',
    'spine': 'Coluna',
    'serratus anterior': 'Serrátil Anterior',
  };

  /// Traduz a parte do corpo (bodyPart)
  static String translateBodyPart(String text) {
    if (text.isEmpty) return 'Geral';
    final key = text.toLowerCase().trim();
    return _bodyPartTranslations[key] ?? _capitalize(text);
  }

  /// Traduz o equipamento
  static String translateEquipment(String text) {
    if (text.isEmpty) return 'Livre / Nenhum';
    final key = text.toLowerCase().trim();
    return _equipmentTranslations[key] ?? _capitalize(text);
  }

  /// Traduz o músculo alvo (target)
  static String translateTargetMuscle(String text) {
    if (text.isEmpty) return 'Geral';
    final key = text.toLowerCase().trim();
    return _targetMuscleTranslations[key] ?? _capitalize(text);
  }

  /// Traduz lista de músculos secundários
  static String translateSecondaryMuscles(List<dynamic> muscles) {
    if (muscles.isEmpty) return '';
    return muscles
        .map((m) => translateTargetMuscle(m.toString()))
        .join(', ');
  }

  /// Traduz o nome do exercício se houver mapeamento direto ou formata
  static String translateExerciseName(String originalName) {
    if (originalName.isEmpty) return 'Exercício';
    String name = originalName.toLowerCase();
    
    // Substituições comuns em títulos de exercícios
    name = name.replaceAll('barbell', 'com Barra');
    name = name.replaceAll('dumbbell', 'com Halteres');
    name = name.replaceAll('cable', 'na Polia');
    name = name.replaceAll('machine', 'na Máquina');
    name = name.replaceAll('smith', 'no Smith');
    name = name.replaceAll('bodyweight', 'Peso Corporal');
    name = name.replaceAll('seated', 'Sentado');
    name = name.replaceAll('standing', 'Em Pé');
    name = name.replaceAll('incline', 'Inclinado');
    name = name.replaceAll('decline', 'Declinado');

    return _capitalize(name);
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
