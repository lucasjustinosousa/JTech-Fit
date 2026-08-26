import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'exercise_translation_service.dart';

class ExerciseDbService {
  static const String _baseUrl = 'https://exercisedb.p.rapidapi.com';
  static const String _mirrorUrl = 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json';
  static const String _gifBaseUrl = 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/gifs/';

  final String? rapidApiKey;

  ExerciseDbService({this.rapidApiKey});

  /// Realiza a busca paginada completa da ExerciseDB V1 sem cortes pequenos fixos
  Future<List<Map<String, dynamic>>> fetchAllExercisesPaginated({
    Function(int current, int total)? onProgress,
  }) async {
    final List<Map<String, dynamic>> allResults = [];
    final Set<String> seenIds = {};

    int pageOffset = 0;
    const int pageLimit = 100;
    bool hasMorePages = true;

    int totalReceived = 0;
    int totalDuplicates = 0;
    int unavailableMedia = 0;

    // Se houver chave RapidAPI configurada, tenta buscar paginado via API oficial
    if (rapidApiKey != null && rapidApiKey!.isNotEmpty) {
      while (hasMorePages) {
        final url = '$_baseUrl/exercises?limit=$pageLimit&offset=$pageOffset';
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {
              'X-RapidAPI-Key': rapidApiKey!,
              'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
            },
          ).timeout(const Duration(seconds: 12));

          debugPrint('[ExerciseDb] Consultando URL: $url | Status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final parsedData = _parseResponseJson(response.body);
            debugPrint('[ExerciseDb] Recebidos: ${parsedData.length} exercícios na página (offset $pageOffset)');

            if (parsedData.isNotEmpty && pageOffset == 0) {
              debugPrint('[ExerciseDb] Primeiro Objeto JSON: ${jsonEncode(parsedData.first)}');
              debugPrint('[ExerciseDb] Campo GIF original: ${parsedData.first['gifUrl'] ?? parsedData.first['gif_url']}');
            }

            if (parsedData.isEmpty) {
              hasMorePages = false;
              break;
            }

            for (var rawItem in parsedData) {
              totalReceived++;
              final mapped = _mapExerciseApiData(rawItem);
              final String dbId = mapped['exercise_db_id'] ?? '';

              if (mapped['gif_url'] == null || (mapped['gif_url'] as String).isEmpty) {
                unavailableMedia++;
              }

              if (seenIds.contains(dbId)) {
                totalDuplicates++;
              } else {
                seenIds.add(dbId);
                allResults.add(mapped);
              }
            }

            pageOffset += pageLimit;
            if (onProgress != null) onProgress(allResults.length, 1500);
          } else {
            // Erros HTTP (401, 403, 404, 429, 500)
            debugPrint('[ExerciseDb] Erro HTTP ${response.statusCode}. Ativando fallback para o espelho público.');
            hasMorePages = false;
          }
        } catch (e) {
          debugPrint('[ExerciseDb] Exceção de rede na página offset $pageOffset: $e');
          hasMorePages = false;
        }
      }
    }

    // Se o retorno da API estiver vazio ou sem RapidAPI, ativa o fallback completo do espelho gratuito
    if (allResults.isEmpty) {
      final mirrorResults = await _fetchFromMirror();
      for (var mapped in mirrorResults) {
        totalReceived++;
        final String dbId = mapped['exercise_db_id'] ?? '';
        if (mapped['gif_url'] == null || (mapped['gif_url'] as String).isEmpty) {
          unavailableMedia++;
        }
        if (seenIds.contains(dbId)) {
          totalDuplicates++;
        } else {
          seenIds.add(dbId);
          allResults.add(mapped);
        }
      }
    }

    debugPrint('Sincronização finalizada: $totalReceived exercícios recebidos, ${allResults.length} salvos, $totalDuplicates duplicados e $unavailableMedia mídias indisponíveis.');

    return allResults;
  }

  /// Aceita respostas nos formatos: Lista direta [...], Objeto {"results": [...]}, Objeto {"exercises": [...]}
  List<Map<String, dynamic>> _parseResponseJson(String responseBody) {
    try {
      final dynamic decoded = jsonDecode(responseBody);
      if (decoded is List) {
        return decoded.map((e) => e as Map<String, dynamic>).toList();
      } else if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('results') && decoded['results'] is List) {
          return (decoded['results'] as List).map((e) => e as Map<String, dynamic>).toList();
        } else if (decoded.containsKey('exercises') && decoded['exercises'] is List) {
          return (decoded['exercises'] as List).map((e) => e as Map<String, dynamic>).toList();
        } else if (decoded.containsKey('data') && decoded['data'] is List) {
          return (decoded['data'] as List).map((e) => e as Map<String, dynamic>).toList();
        }
      }
    } catch (e) {
      debugPrint('[ExerciseDb] Erro ao decodificar JSON: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _fetchFromMirror() async {
    try {
      debugPrint('[ExerciseDb] Consultando espelho público: $_mirrorUrl');
      final response = await http.get(Uri.parse(_mirrorUrl)).timeout(const Duration(seconds: 12));
      debugPrint('[ExerciseDb] Espelho Status HTTP: ${response.statusCode}');

      if (response.statusCode == 200) {
        final parsedData = _parseResponseJson(response.body);
        debugPrint('[ExerciseDb] Espelho retornou ${parsedData.length} exercícios no total.');
        return parsedData.map((item) => _mapExerciseApiData(item)).toList();
      }
    } catch (e) {
      debugPrint('[ExerciseDb] Falha ao consultar espelho remoto: $e');
    }
    return [];
  }

  Map<String, dynamic> _mapExerciseApiData(Map<String, dynamic> item) {
    final String rawBodyPart = item['bodyPart'] ?? item['category'] ?? '';
    final String rawEquipment = item['equipment'] ?? '';
    final String rawTarget = item['target'] ?? item['primaryMuscles']?[0] ?? '';
    final List<dynamic> rawSecondary = item['secondaryMuscles'] ?? [];
    
    dynamic rawInstructions = item['instructions'] ?? item['steps'] ?? [];
    String instructionsText = '';
    if (rawInstructions is List) {
      instructionsText = rawInstructions.join('\n');
    } else {
      instructionsText = rawInstructions.toString();
    }

    final String originalName = item['name'] ?? item['title'] ?? 'Exercício';
    final String rawGif = item['gifUrl'] ?? item['gif_url'] ?? item['imageUrl'] ?? item['image'] ?? '';

    // Resolução de URL do GIF demonstrativo
    String finalGifUrl = '';
    if (rawGif.isNotEmpty) {
      if (rawGif.startsWith('http://') || rawGif.startsWith('https://')) {
        finalGifUrl = rawGif;
      } else {
        // Se retornar apenas o nome do arquivo ou ID do GIF
        final String cleanFileName = rawGif.startsWith('/') ? rawGif.substring(1) : rawGif;
        finalGifUrl = '$_gifBaseUrl$cleanFileName';
        if (!finalGifUrl.endsWith('.gif')) {
          finalGifUrl = '$finalGifUrl.gif';
        }
      }
    }

    final String dbId = item['id']?.toString() ?? originalName.replaceAll(' ', '_').toLowerCase();

    return {
      'exercise_db_id': dbId,
      'nome_original': originalName,
      'nome_traduzido': ExerciseTranslationService.translateExerciseName(originalName),
      'parte_corpo_original': rawBodyPart,
      'parte_corpo_traduzida': ExerciseTranslationService.translateBodyPart(rawBodyPart),
      'musculo_principal_original': rawTarget,
      'musculo_principal_traduzido': ExerciseTranslationService.translateTargetMuscle(rawTarget),
      'musculos_secundarios': ExerciseTranslationService.translateSecondaryMuscles(rawSecondary),
      'equipamento_original': rawEquipment,
      'equipamento_traduzido': ExerciseTranslationService.translateEquipment(rawEquipment),
      'instrucoes': instructionsText,
      'gif_url': finalGifUrl,
    };
  }
}
