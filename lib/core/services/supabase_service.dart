import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/models.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._init();
  SupabaseClient? _client;
  bool _isInitialized = false;
  final _uuid = const Uuid();

  SupabaseService._init();

  bool get isInitialized => _isInitialized;
  SupabaseClient get client => _client!;

  Future<void> initialize({required String url, required String anonKey}) async {
    try {
      if (url.isNotEmpty && !url.contains('your-supabase')) {
        await Supabase.initialize(url: url, anonKey: anonKey);
        _client = Supabase.instance.client;
        _isInitialized = true;
        debugPrint('[Supabase] Inicializado com sucesso!');
      }
    } catch (e) {
      debugPrint('[Supabase] Offline ou erro de config: $e');
      _isInitialized = false;
    }
  }

  // Autenticação
  Future<User?> signUp(String email, String password) async {
    if (!_isInitialized) return null;
    final res = await _client!.auth.signUp(email: email, password: password);
    return res.user;
  }

  Future<User?> signIn(String email, String password) async {
    if (!_isInitialized) return null;
    final res = await _client!.auth.signInWithPassword(email: email, password: password);
    return res.user;
  }

  Future<void> signOut() async {
    if (!_isInitialized) return;
    await _client!.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    if (!_isInitialized) return;
    await _client!.auth.resetPasswordForEmail(email);
  }

  User? get currentUser => _isInitialized ? _client!.auth.currentUser : null;

  // ==========================================
  // SINCRONIZAÇÃO BIDIRECIONAL DE TREINOS
  // ==========================================

  /// Envia o treino para o Supabase (nuvem)
  Future<void> syncTreino(Treino treino) async {
    if (!_isInitialized) return;
    try {
      final exerciciosJsonList = treino.exercicios.map((e) {
        return {
          'id': e.id,
          'nome': e.exercicioInfo?.nome ?? e.exercicioId,
          'series': e.quantidadeSeries != null ? '${e.quantidadeSeries}' : '4',
          'reps': e.repeticoes ?? '10-12',
          'grupoMuscular': e.exercicioInfo?.grupoMuscular ?? 'Geral',
          'gifUrl': e.exercicioInfo?.gifUrl ?? '',
        };
      }).toList();

      final Map<String, dynamic> treinoPayload = {
        'id': treino.id,
        'nome': treino.nome,
        'descricao': treino.descricao,
        'dias_semana': treino.diasSemana,
        'cor_hex': treino.corHex,
        'exercicios': exerciciosJsonList,
        'criado_em': treino.criadoEm.toIso8601String(),
      };

      if (currentUser != null) {
        treinoPayload['usuario_id'] = currentUser!.id;
      }

      await _client!.from('treinos').upsert(treinoPayload);
      debugPrint('[Supabase] Treino "${treino.nome}" sincronizado na nuvem.');

      // Também salvar na tabela relacional exercicios_do_treino
      for (var ex in treino.exercicios) {
        try {
          await _client!.from('exercicios_do_treino').upsert({
            'id': ex.id,
            'treino_id': treino.id,
            'exercicio_id': ex.exercicioId,
            'ordem': ex.ordem,
            'quantidade_series': ex.quantidadeSeries ?? 4,
            'repeticoes': ex.repeticoes ?? '10-12',
            'carga_inicial': ex.cargaInicial ?? 0.0,
            'descanso_segundos': ex.descansoSegundos ?? 60,
          });
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[Supabase] Erro ao sincronizar treino online: $e');
    }
  }

  /// Busca todos os treinos da nuvem criados no Web ou Mobile
  Future<List<Treino>> fetchTreinosOnline() async {
    if (!_isInitialized) return [];
    try {
      final res = await _client!.from('treinos').select('*').order('criado_em', ascending: false);
      if (res is List && res.isNotEmpty) {
        List<Treino> treinos = [];
        for (var row in res) {
          List<ExercicioDoTreino> exerciciosList = [];

          // 1. Tentar ler do JSON embutido na coluna 'exercicios'
          if (row['exercicios'] != null) {
            try {
              dynamic rawEx = row['exercicios'];
              if (rawEx is String) rawEx = jsonDecode(rawEx);
              if (rawEx is List) {
                for (int i = 0; i < rawEx.length; i++) {
                  final item = rawEx[i];
                  final exNome = item['nome'] ?? item['name'] ?? 'Exercício';
                  final exGrupo = item['grupoMuscular'] ?? item['grupo_muscular'] ?? 'Geral';
                  final exGif = item['gifUrl'] ?? item['gif_url'] ?? '';
                  final seriesStr = item['series'] != null ? '${item['series']}' : '4';
                  final repsStr = item['reps'] != null ? '${item['reps']}' : '10-12';
                  final exId = item['id'] ?? 'ex_${row['id']}_$i';

                  exerciciosList.add(
                    ExercicioDoTreino(
                      id: exId,
                      treinoId: row['id'] ?? '',
                      exercicioId: exId,
                      ordem: i + 1,
                      quantidadeSeries: int.tryParse(seriesStr) ?? 4,
                      repeticoes: repsStr,
                      exercicioInfo: Exercicio(
                        id: exId,
                        nome: exNome,
                        grupoMuscular: exGrupo,
                        equipamento: 'Geral',
                        instrucoes: 'Execução controlada.',
                        gifUrl: exGif,
                      ),
                    ),
                  );
                }
              }
            } catch (e) {
              debugPrint('[Supabase] Erro ao processar JSON de exercícios: $e');
            }
          }

          treinos.add(Treino.fromMap(row, exercicios: exerciciosList));
        }
        debugPrint('[Supabase] ${treinos.length} treinos recuperados da nuvem.');
        return treinos;
      }
    } catch (e) {
      debugPrint('[Supabase] Erro ao buscar treinos online: $e');
    }
    return [];
  }

  /// Exclui um treino da nuvem
  Future<void> deleteTreinoOnline(String treinoId) async {
    if (!_isInitialized) return;
    try {
      await _client!.from('treinos').delete().eq('id', treinoId);
      debugPrint('[Supabase] Treino $treinoId excluído da nuvem.');
    } catch (e) {
      debugPrint('[Supabase] Erro ao excluir treino da nuvem: $e');
    }
  }

  // ==========================================
  // SINCRONIZAÇÃO DE HISTÓRICO / SESSÕES
  // ==========================================

  Future<void> syncSessao(SessaoTreino sessao, List<SerieRealizada> series) async {
    if (!_isInitialized) return;
    try {
      final Map<String, dynamic> sessaoPayload = {
        'id': sessao.id,
        'nome_treino': sessao.nomeTreino,
        'inicio': sessao.inicio.toIso8601String(),
        'fim': sessao.fim?.toIso8601String(),
        'concluido': sessao.concluido,
        'observacoes': sessao.observacoes,
      };

      if (currentUser != null) {
        sessaoPayload['usuario_id'] = currentUser!.id;
      }

      await _client!.from('sessoes_de_treino').upsert(sessaoPayload);
      for (var s in series) {
        try {
          await _client!.from('series_realizadas').upsert(s.toMap());
        } catch (_) {}
      }
      debugPrint('[Supabase] Sessão de treino sincronizada na nuvem.');
    } catch (e) {
      debugPrint('[Supabase] Erro ao sincronizar sessão online: $e');
    }
  }
}
