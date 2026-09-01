import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../../core/database/local_database.dart';
import '../../core/services/supabase_service.dart';

class WorkoutRepository extends ChangeNotifier {
  final _uuid = const Uuid();
  Usuario? _usuarioAtual;
  List<Treino> _treinos = [];
  List<Exercicio> _exercicios = [];
  List<SessaoTreino> _historico = [];
  bool _isLoading = false;

  Usuario? get usuarioAtual => _usuarioAtual;
  List<Treino> get treinos => _treinos;
  List<Exercicio> get exercicios => _exercicios;
  List<SessaoTreino> get historico => _historico;
  bool get isLoading => _isLoading;

  WorkoutRepository() {
    _initDefaults();
  }

  Future<void> _initDefaults() async {
    _isLoading = true;
    notifyListeners();

    // Criar usuário convidado padrão se nenhum logado
    _usuarioAtual = Usuario(
      id: 'guest_user_1',
      nome: 'Atleta TitanNova',
      email: 'atleta@titannovafit.com',
      unidadeCarga: 'kg',
      descansoPadrao: 60,
      criadoEm: DateTime.now(),
    );

    await carregarDados();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> carregarDados() async {
    try {
      // 1. Carregar exercícios da biblioteca local
      _exercicios = await LocalDatabase.instance.getExercicios();

      // 2. Carregar treinos locais do SQLite
      _treinos = await LocalDatabase.instance.getTreinos(_usuarioAtual?.id ?? 'guest_user_1');
      _historico = await LocalDatabase.instance.getHistoricoSessoes();

      // 3. Se nenhum treino cadastrado ainda localmente, gerar treinos padrão de exemplo (A, B, C)
      if (_treinos.isEmpty && _exercicios.isNotEmpty) {
        await _seedDefaultTreinos();
        _treinos = await LocalDatabase.instance.getTreinos(_usuarioAtual?.id ?? 'guest_user_1');
      }

      // 4. Sincronização Bidirecional completa com a Nuvem (Supabase)
      if (SupabaseService.instance.isInitialized) {
        final treinosOnline = await SupabaseService.instance.fetchTreinosOnline();
        
        // A) Salvar no SQLite qualquer treino que esteja na nuvem e não no SQLite
        final localIds = _treinos.map((t) => t.id).toSet();
        for (var t in treinosOnline) {
          if (!localIds.contains(t.id)) {
            await LocalDatabase.instance.saveTreino(t);
          }
        }

        // B) Enviar para a nuvem qualquer treino do SQLite que ainda não esteja na nuvem
        final onlineIds = treinosOnline.map((t) => t.id).toSet();
        for (var t in _treinos) {
          if (!onlineIds.contains(t.id)) {
            await SupabaseService.instance.syncTreino(t);
          }
        }

        // Recarregar lista consolidada de treinos
        _treinos = await LocalDatabase.instance.getTreinos(_usuarioAtual?.id ?? 'guest_user_1');
      }
    } catch (e) {
      debugPrint('Erro ao carregar e sincronizar dados: $e');
    }
    notifyListeners();
  }

  Future<void> _seedDefaultTreinos() async {
    final peito = _exercicios.firstWhere((e) => e.grupoMuscular == 'Peito', orElse: () => _exercicios.first);
    final triceps = _exercicios.firstWhere((e) => e.grupoMuscular == 'Tríceps', orElse: () => _exercicios.first);
    final costas = _exercicios.firstWhere((e) => e.grupoMuscular == 'Costas', orElse: () => _exercicios.first);
    final biceps = _exercicios.firstWhere((e) => e.grupoMuscular == 'Bíceps', orElse: () => _exercicios.first);
    final pernas = _exercicios.firstWhere((e) => e.grupoMuscular == 'Pernas', orElse: () => _exercicios.first);

    final treinoA = Treino(
      id: 'treino_default_a',
      usuarioId: _usuarioAtual!.id,
      nome: 'Treino A — Peito & Tríceps',
      descricao: 'Hipertrofia',
      diasSemana: ['Segunda-feira', 'Quinta-feira'],
      corHex: '#1E88E5',
      criadoEm: DateTime.now(),
      exercicios: [
        ExercicioDoTreino(id: 'ex_a1', treinoId: 'treino_default_a', exercicioId: peito.id, ordem: 1, quantidadeSeries: 4, repeticoes: '10-12', cargaInicial: 30, descansoSegundos: 90, exercicioInfo: peito),
        ExercicioDoTreino(id: 'ex_a2', treinoId: 'treino_default_a', exercicioId: triceps.id, ordem: 2, quantidadeSeries: 3, repeticoes: '12-15', cargaInicial: 20, descansoSegundos: 60, exercicioInfo: triceps),
      ],
    );

    final treinoB = Treino(
      id: 'treino_default_b',
      usuarioId: _usuarioAtual!.id,
      nome: 'Treino B — Costas & Bíceps',
      descricao: 'Hipertrofia',
      diasSemana: ['Terça-feira', 'Sexta-feira'],
      corHex: '#00D2FF',
      criadoEm: DateTime.now(),
      exercicios: [
        ExercicioDoTreino(id: 'ex_b1', treinoId: 'treino_default_b', exercicioId: costas.id, ordem: 1, quantidadeSeries: 4, repeticoes: '10-12', cargaInicial: 40, descansoSegundos: 90, exercicioInfo: costas),
        ExercicioDoTreino(id: 'ex_b2', treinoId: 'treino_default_b', exercicioId: biceps.id, ordem: 2, quantidadeSeries: 3, repeticoes: '10-12', cargaInicial: 12, descansoSegundos: 60, exercicioInfo: biceps),
      ],
    );

    final ombros = _exercicios.firstWhere((e) => e.grupoMuscular == 'Ombros', orElse: () => _exercicios.first);
    final abdomen = _exercicios.firstWhere((e) => e.grupoMuscular == 'Abdômen', orElse: () => _exercicios.first);

    final treinoC = Treino(
      id: 'treino_default_c',
      usuarioId: _usuarioAtual!.id,
      nome: 'Treino C — Pernas & Panturrilhas',
      descricao: 'Força & Resistência',
      diasSemana: ['Quarta-feira', 'Sábado'],
      corHex: '#4CAF50',
      criadoEm: DateTime.now(),
      exercicios: [
        ExercicioDoTreino(id: 'ex_c1', treinoId: 'treino_default_c', exercicioId: pernas.id, ordem: 1, quantidadeSeries: 4, repeticoes: '8-10', cargaInicial: 60, descansoSegundos: 120, exercicioInfo: pernas),
      ],
    );

    final treinoD = Treino(
      id: 'treino_default_d',
      usuarioId: _usuarioAtual!.id,
      nome: 'Treino D — Ombros, Trapézio & Abdômen',
      descricao: 'Definição & Core',
      diasSemana: ['Sexta-feira'],
      corHex: '#FF9800',
      criadoEm: DateTime.now(),
      exercicios: [
        ExercicioDoTreino(id: 'ex_d1', treinoId: 'treino_default_d', exercicioId: ombros.id, ordem: 1, quantidadeSeries: 4, repeticoes: '10-12', cargaInicial: 16, descansoSegundos: 60, exercicioInfo: ombros),
        ExercicioDoTreino(id: 'ex_d2', treinoId: 'treino_default_d', exercicioId: abdomen.id, ordem: 2, quantidadeSeries: 3, repeticoes: '15-20', cargaInicial: 0, descansoSegundos: 45, exercicioInfo: abdomen),
      ],
    );

    await LocalDatabase.instance.saveTreino(treinoA);
    await LocalDatabase.instance.saveTreino(treinoB);
    await LocalDatabase.instance.saveTreino(treinoC);
    await LocalDatabase.instance.saveTreino(treinoD);

    if (SupabaseService.instance.isInitialized) {
      await SupabaseService.instance.syncTreino(treinoA);
      await SupabaseService.instance.syncTreino(treinoB);
      await SupabaseService.instance.syncTreino(treinoC);
      await SupabaseService.instance.syncTreino(treinoD);
    }
  }

  // Operações de Treinos
  Future<void> salvarTreino(Treino treino) async {
    await LocalDatabase.instance.saveTreino(treino);
    await SupabaseService.instance.syncTreino(treino);
    await carregarDados();
  }

  Future<void> duplicarTreino(Treino treino) async {
    final novoTreino = Treino(
      id: _uuid.v4(),
      usuarioId: treino.usuarioId,
      nome: '${treino.nome} (Cópia)',
      descricao: treino.descricao,
      diasSemana: treino.diasSemana,
      corHex: treino.corHex,
      criadoEm: DateTime.now(),
      exercicios: treino.exercicios.map((e) => ExercicioDoTreino(
        id: _uuid.v4(),
        treinoId: '',
        exercicioId: e.exercicioId,
        ordem: e.ordem,
        quantidadeSeries: e.quantidadeSeries,
        repeticoes: e.repeticoes,
        cargaInicial: e.cargaInicial,
        descansoSegundos: e.descansoSegundos,
        observacoes: e.observacoes,
        exercicioInfo: e.exercicioInfo,
      )).toList(),
    );

    await salvarTreino(novoTreino);
  }

  Future<void> deletarTreino(String treinoId) async {
    await LocalDatabase.instance.deleteTreino(treinoId);
    await SupabaseService.instance.deleteTreinoOnline(treinoId);
    await carregarDados();
  }

  // Operações de Exercícios
  Future<void> salvarExercicioCustomizado(Exercicio ex) async {
    await LocalDatabase.instance.saveExercicio(ex);
    await carregarDados();
  }

  Future<void> toggleFavorito(String exercicioId) async {
    final ex = _exercicios.firstWhere((e) => e.id == exercicioId);
    await LocalDatabase.instance.toggleFavorito(exercicioId, ex.isFavorito);
    await carregarDados();
  }

  // Finalização do Treino
  Future<void> finalizarSessao(SessaoTreino sessao, List<SerieRealizada> series) async {
    await LocalDatabase.instance.salvarSessaoRealizada(sessao, series);
    await SupabaseService.instance.syncSessao(sessao, series);
    await carregarDados();
  }

  // Configurações do Usuário
  void atualizarUnidade(String unidade) {
    if (_usuarioAtual != null) {
      _usuarioAtual = Usuario(
        id: _usuarioAtual!.id,
        nome: _usuarioAtual!.nome,
        email: _usuarioAtual!.email,
        fotoUrl: _usuarioAtual!.fotoUrl,
        unidadeCarga: unidade,
        descansoPadrao: _usuarioAtual!.descansoPadrao,
        criadoEm: _usuarioAtual!.criadoEm,
      );
      notifyListeners();
    }
  }

  void atualizarDescansoPadrao(int segundos) {
    if (_usuarioAtual != null) {
      _usuarioAtual = Usuario(
        id: _usuarioAtual!.id,
        nome: _usuarioAtual!.nome,
        email: _usuarioAtual!.email,
        fotoUrl: _usuarioAtual!.fotoUrl,
        unidadeCarga: _usuarioAtual!.unidadeCarga,
        descansoPadrao: segundos,
        criadoEm: _usuarioAtual!.criadoEm,
      );
      notifyListeners();
    }
  }
}
