import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/models.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._init();
  SupabaseClient? _client;
  bool _isInitialized = false;

  SupabaseService._init();

  bool get isInitialized => _isInitialized;
  SupabaseClient get client => _client!;

  Future<void> initialize({required String url, required String anonKey}) async {
    try {
      if (url.isNotEmpty && !url.contains('your-supabase')) {
        await Supabase.initialize(url: url, anonKey: anonKey);
        _client = Supabase.instance.client;
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('Supabase offline ou erro de config: $e');
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

  // Sincronização de Dados com Supabase
  Future<void> syncTreino(Treino treino) async {
    if (!_isInitialized) return;
    try {
      await _client!.from('treinos').upsert(treino.toMap());
      for (var ex in treino.exercicios) {
        await _client!.from('exercicios_do_treino').upsert(ex.toMap());
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar treino online: $e');
    }
  }

  Future<void> syncSessao(SessaoTreino sessao, List<SerieRealizada> series) async {
    if (!_isInitialized) return;
    try {
      await _client!.from('sessoes_de_treino').upsert(sessao.toMap());
      for (var s in series) {
        await _client!.from('series_realizadas').upsert(s.toMap());
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar sessão online: $e');
    }
  }
}
