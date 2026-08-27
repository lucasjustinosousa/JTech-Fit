import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  /// Realiza a busca paginada por cursor da ExerciseDB V1 oficial (sem RapidAPI)
  Future<List<Map<String, dynamic>>> fetchAllExercisesPaginated({
    Function(int current, int total)? onProgress,
  }) async {
    final List<Map<String, dynamic>> allResults = [];
    final Set<String> seenIds = {};

    String? currentCursor;
    bool hasNextPage = true;
    int apiTotal = 1500;
    int totalReceived = 0;
    int totalGifsAvailable = 0;

    while (hasNextPage) {
      String url = '$_officialEndpoint?limit=50';
      if (currentCursor != null && currentCursor.isNotEmpty) {
        url = '$_officialEndpoint?limit=50&cursor=$currentCursor';
      }

      http.Response? response;
      int attempts = 0;

      while (attempts < 3 && response == null) {
        attempts++;
        try {
          debugPrint('[ExerciseDb V1] Consultando Endpoint (tentativa $attempts): $url');
          final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

          if (res.statusCode >= 200 && res.statusCode <= 299) {
            response = res;
          } else {
            debugPrint('[ExerciseDb V1] Status HTTP ${res.statusCode} na tentativa $attempts');
            if (attempts < 3) await Future.delayed(const Duration(milliseconds: 800));
          }
        } catch (e) {
          debugPrint('[ExerciseDb V1] Falha de conexão na requisição $url (tentativa $attempts): $e');
          if (attempts < 3) await Future.delayed(const Duration(milliseconds: 800));
        }
      }

      if (response == null) {
        debugPrint('[ExerciseDb V1] Não foi possível obter a página após 3 tentativas. Finalizando busca com os dados já carregados.');
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
          currentCursor = meta['nextCursor']?.toString();

          debugPrint('[ExerciseDb V1] Meta -> Total: $apiTotal | hasNextPage: $hasNextPage | nextCursor: $currentCursor');
        } else {
          hasNextPage = false;
        }

        if (isSuccess && data != null && data.isNotEmpty) {
          debugPrint('[ExerciseDb V1] Exercícios recebidos nesta página: ${data.length}');

          for (var item in data) {
            totalReceived++;
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
        } else {
          hasNextPage = false;
        }
      } catch (e) {
        debugPrint('[ExerciseDb V1] Erro de parsing JSON: $e');
        hasNextPage = false;
      }
    }

    debugPrint('Integração ExerciseDB concluída: ${allResults.length} de $apiTotal exercícios carregados e $totalGifsAvailable GIFs disponíveis.');

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
