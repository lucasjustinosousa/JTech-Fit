import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'exercise_translation_service.dart';

class ExerciseDbService {
  static const String _officialEndpoint = 'https://oss.exercisedb.dev/api/v1/exercises';
  static const String _mediaBaseUrl = 'https://static.exercisedb.dev/media/';

  /// Método de compatibilidade para buscar exercícios com limite opcional
  Future<List<Map<String, dynamic>>> fetchExercises({
    int limit = 1500,
    Function(int current, int total)? onProgress,
  }) async {
    final all = await fetchAllExercisesPaginated(onProgress: onProgress);
    if (limit > 0 && all.length > limit) {
      return all.sublist(0, limit);
    }
    return all;
  }

  /// Realiza a busca dos exercícios a partir do arquivo JSON local (assets/exercises_db.json)
  Future<List<Map<String, dynamic>>> fetchAllExercisesPaginated({
    Function(int current, int total)? onProgress,
  }) async {
    final List<Map<String, dynamic>> allResults = [];
    final Set<String> seenIds = {};

    try {
      debugPrint('[ExerciseDb V1] Carregando banco de dados local assets/exercises_db.json');
      final String jsonString = await rootBundle.loadString('assets/exercises_db.json');
      final List<dynamic> data = jsonDecode(jsonString);
      
      debugPrint('[ExerciseDb V1] Total carregado do arquivo: ${data.length}');
      
      int processed = 0;
      int totalGifsAvailable = 0;
      
      for (var item in data) {
        processed++;
        final mapped = _mapOfficialExerciseData(item as Map<String, dynamic>);
        final String exId = mapped['exercise_db_id'] ?? '';
        
        if (mapped['gif_url'] != null && (mapped['gif_url'] as String).isNotEmpty) {
          totalGifsAvailable++;
        }
        
        if (!seenIds.contains(exId)) {
          seenIds.add(exId);
          allResults.add(mapped);
        }
        
        // Simula progresso visual no app a cada 100 itens processados
        if (onProgress != null && processed % 100 == 0) {
          onProgress(processed, data.length);
          await Future.delayed(const Duration(milliseconds: 10)); 
        }
      }
      
      if (onProgress != null) {
        onProgress(data.length, data.length);
      }
      
      debugPrint('Integração ExerciseDB concluída: ${allResults.length} de ${data.length} exercícios carregados e $totalGifsAvailable GIFs disponíveis.');
      
    } catch (e) {
      debugPrint('[ExerciseDb V1] Erro ao carregar arquivo local: $e');
    }

    return allResults;
  }

  Map<String, dynamic> _mapOfficialExerciseData(Map<String, dynamic> item) {
    final String exerciseId = item['exerciseId']?.toString() ?? item['id']?.toString() ?? '';
    final String originalName = item['name'] ?? 'Exercício';

    final List<dynamic> bodyParts = item['bodyParts'] ?? [];
    final List<dynamic> equipments = item['equipments'] ?? [];
    final List<dynamic> targetMuscles = item['targetMuscles'] ?? [];
    final List<dynamic> secondaryMuscles = item['secondaryMuscles'] ?? [];
    final List<dynamic> instructions = item['instructions'] ?? [];

    final String rawBodyPart = bodyParts.isNotEmpty ? bodyParts.first.toString() : '';
    final String rawEquipment = equipments.isNotEmpty ? equipments.first.toString() : '';
    final String rawTarget = targetMuscles.isNotEmpty ? targetMuscles.first.toString() : '';

    String gifUrl = item['gifUrl'] ?? '';
    if (gifUrl.isEmpty && exerciseId.isNotEmpty) {
      gifUrl = '$_mediaBaseUrl$exerciseId.gif';
    }

    return {
      'exercise_db_id': exerciseId,
      'id': exerciseId,
      'nome_original': originalName,
      'nome_traduzido': ExerciseTranslationService.translateExerciseName(originalName),
      'nome': ExerciseTranslationService.translateExerciseName(originalName),
      'parte_corpo_original': rawBodyPart,
      'parte_corpo_traduzida': ExerciseTranslationService.translateBodyPart(rawBodyPart),
      'grupo_muscular': ExerciseTranslationService.translateBodyPart(rawBodyPart),
      'musculo_principal_original': rawTarget,
      'musculo_principal_traduzido': ExerciseTranslationService.translateTargetMuscle(rawTarget),
      'musculos_secundarios': ExerciseTranslationService.translateSecondaryMuscles(secondaryMuscles),
      'equipamento_original': rawEquipment,
      'equipamento_traduzido': ExerciseTranslationService.translateEquipment(rawEquipment),
      'equipamento': ExerciseTranslationService.translateEquipment(rawEquipment),
      'instrucoes': instructions.join('\n'),
      'gif_url': gifUrl,
    };
  }
}
