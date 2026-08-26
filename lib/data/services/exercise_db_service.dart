import 'dart:convert';
import 'package:http/http.dart' as http;
import 'exercise_translation_service.dart';

class ExerciseDbService {
  static const String _baseUrl = 'https://exercisedb.p.rapidapi.com';
  // Endpoint espelho gratuito/fallback público para requisições diretas sem API Key
  static const String _mirrorUrl = 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json';

  final String? rapidApiKey;

  ExerciseDbService({this.rapidApiKey});

  /// Busca a lista completa de exercícios da ExerciseDB (via API ou fallback)
  Future<List<Map<String, dynamic>>> fetchExercises({int limit = 100, int offset = 0}) async {
    try {
      if (rapidApiKey != null && rapidApiKey!.isNotEmpty) {
        final response = await http.get(
          Uri.parse('$_baseUrl/exercises?limit=$limit&offset=$offset'),
          headers: {
            'X-RapidAPI-Key': rapidApiKey!,
            'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((item) => _mapExerciseApiData(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {
      // Falha graciosa de rede ou chave -> ativa o fallback espelho
    }

    // Fallback gracioso para a lista pública gratuita
    return _fetchFromMirror();
  }

  Future<List<Map<String, dynamic>>> _fetchFromMirror() async {
    try {
      final response = await http.get(Uri.parse(_mirrorUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => _mapExerciseApiData(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      print('[ExerciseDbService] Aviso ao buscar dados remotos: $e');
    }
    return [];
  }

  Map<String, dynamic> _mapExerciseApiData(Map<String, dynamic> item) {
    final String rawBodyPart = item['bodyPart'] ?? item['category'] ?? '';
    final String rawEquipment = item['equipment'] ?? '';
    final String rawTarget = item['target'] ?? item['primaryMuscles']?[0] ?? '';
    final List<dynamic> rawSecondary = item['secondaryMuscles'] ?? [];
    final List<dynamic> rawInstructions = item['instructions'] ?? [];
    final String originalName = item['name'] ?? '';

    return {
      'exercise_db_id': item['id']?.toString() ?? '',
      'nome_original': originalName,
      'nome_traduzido': ExerciseTranslationService.translateExerciseName(originalName),
      'parte_corpo_original': rawBodyPart,
      'parte_corpo_traduzida': ExerciseTranslationService.translateBodyPart(rawBodyPart),
      'musculo_principal_original': rawTarget,
      'musculo_principal_traduzido': ExerciseTranslationService.translateTargetMuscle(rawTarget),
      'musculos_secundarios': ExerciseTranslationService.translateSecondaryMuscles(rawSecondary),
      'equipamento_original': rawEquipment,
      'equipamento_traduzido': ExerciseTranslationService.translateEquipment(rawEquipment),
      'instrucoes': rawInstructions.join('\n'),
      'gif_url': item['gifUrl'] ?? item['gif_url'] ?? '',
    };
  }
}
