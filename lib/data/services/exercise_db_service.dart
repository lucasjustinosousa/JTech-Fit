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
  /// e utiliza fallback da API oficial caso o arquivo local não esteja disponível.
  Future<List<Map<String, dynamic>>> fetchAllExercisesPaginated({
    Function(int current, int total)? onProgress,
  }) async {
    final List<Map<String, dynamic>> allResults = [];
    final Set<String> seenIds = {};

    try {
      debugPrint('[ExerciseDb V1] Carregando banco de dados local assets/exercises_db.json...');
      final String jsonString = await rootBundle.loadString('assets/exercises_db.json');
      final List<dynamic> data = jsonDecode(jsonString);

      if (data.isNotEmpty) {
        debugPrint('[ExerciseDb V1] Total carregado do arquivo local: ${data.length}');

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

          if (onProgress != null && processed % 100 == 0) {
            onProgress(processed, data.length);
            await Future.delayed(const Duration(milliseconds: 5));
          }
        }

        if (onProgress != null) {
          onProgress(data.length, data.length);
        }

        debugPrint('Integração ExerciseDB concluída via arquivo local: ${allResults.length} de ${data.length} exercícios.');
        return allResults;
      }
    } catch (e) {
      debugPrint('[ExerciseDb V1] Aviso ao carregar arquivo local: $e. Tentando fallback online...');
    }

    // Fallback para API Oficial usando paginação correta 'after'
    return await fetchFromApiDirectly(onProgress: onProgress);
  }

  /// Busca diretamente da API Oficial da ExerciseDB V1 usando paginação por 'after'
  Future<List<Map<String, dynamic>>> fetchFromApiDirectly({
    Function(int current, int total)? onProgress,
  }) async {
    final List<Map<String, dynamic>> allResults = [];
    final Set<String> seenIds = {};

    String? afterCursor;
    bool hasNextPage = true;
    int apiTotal = 1500;
    int totalGifsAvailable = 0;

    while (hasNextPage) {
      String url = '$_officialEndpoint?limit=25';
      if (afterCursor != null && afterCursor.isNotEmpty) {
        url = '$_officialEndpoint?limit=25&after=$afterCursor';
      }

      http.Response? response;
      int attempts = 0;

      while (attempts < 4 && response == null) {
        attempts++;
        try {
          debugPrint('[ExerciseDb V1] Consultando Endpoint (tentativa $attempts): $url');
          final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

          if (res.statusCode >= 200 && res.statusCode <= 299) {
            response = res;
          } else {
            debugPrint('[ExerciseDb V1] Status HTTP ${res.statusCode} na tentativa $attempts');
            if (attempts < 4) await Future.delayed(const Duration(milliseconds: 1500));
          }
        } catch (e) {
          debugPrint('[ExerciseDb V1] Falha de conexão ($url - tentativa $attempts): $e');
          if (attempts < 4) await Future.delayed(const Duration(milliseconds: 1500));
        }
      }

      if (response == null) {
        debugPrint('[ExerciseDb V1] Falha ao obter página após $attempts tentativas.');
        break;
      }

      try {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final bool isSuccess = jsonResponse['success'] == true;
        final Map<String, dynamic>? meta = jsonResponse['meta'];
        final List<dynamic>? data = jsonResponse['data'];

        if (meta != null) {
          apiTotal = meta['total'] ?? apiTotal;
          hasNextPage = meta['hasNextPage'] == true;
          afterCursor = meta['nextCursor']?.toString();
        } else {
          hasNextPage = false;
        }

        if (isSuccess && data != null && data.isNotEmpty) {
          for (var item in data) {
            final mapped = _mapOfficialExerciseData(item as Map<String, dynamic>);
            final String exId = mapped['exercise_db_id'] ?? '';

            if (mapped['gif_url'] != null && (mapped['gif_url'] as String).isNotEmpty) {
              totalGifsAvailable++;
            }

            if (!seenIds.contains(exId)) {
              seenIds.add(exId);
              allResults.add(mapped);
            }
          }

          if (onProgress != null) onProgress(allResults.length, apiTotal);
          await Future.delayed(const Duration(milliseconds: 100));
        } else {
          hasNextPage = false;
        }
      } catch (e) {
        debugPrint('[ExerciseDb V1] Erro de parsing JSON: $e');
        hasNextPage = false;
      }
    }

    debugPrint('Busca online ExerciseDB concluída: ${allResults.length} de $apiTotal exercícios.');
    return allResults;
  }

  Map<String, dynamic> _mapOfficialExerciseData(Map<String, dynamic> item) {
    final String exerciseId = item['exerciseId']?.toString() ?? item['id']?.toString() ?? '';
    final String originalName = item['name'] ?? 'Exercício';

    final List<dynamic> bodyParts = item['bodyParts'] is List ? item['bodyParts'] : (item['bodyPart'] != null ? [item['bodyPart']] : []);
    final List<dynamic> equipments = item['equipments'] is List ? item['equipments'] : (item['equipment'] != null ? [item['equipment']] : []);
    final List<dynamic> targetMuscles = item['targetMuscles'] is List ? item['targetMuscles'] : (item['target'] != null ? [item['target']] : []);
    final List<dynamic> secondaryMuscles = item['secondaryMuscles'] is List ? item['secondaryMuscles'] : [];
    final List<dynamic> instructions = item['instructions'] is List ? item['instructions'] : [];

    final String rawBodyPart = bodyParts.isNotEmpty ? (bodyParts.first?.toString() ?? '') : '';
    final String rawEquipment = equipments.isNotEmpty ? (equipments.first?.toString() ?? '') : '';
    final String rawTarget = targetMuscles.isNotEmpty ? (targetMuscles.first?.toString() ?? '') : '';

    String gifUrl = item['gifUrl']?.toString() ?? '';
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
