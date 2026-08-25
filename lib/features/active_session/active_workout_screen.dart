import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/jtech_theme.dart';
import '../../core/services/timer_audio_service.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/models.dart';
import 'workout_summary_screen.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final Treino treino;

  const ActiveWorkoutScreen({super.key, required this.treino});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final DateTime _inicioSessao = DateTime.now();
  late Timer _sessionTimer;
  int _segundosDecorridos = 0;

  int _exercicioIndexAtual = 0;

  // Controle do Cronômetro de Descanso
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  int _restTotalInitial = 60;
  bool _isResting = false;
  bool _isRestPaused = false;

  // Armazenamento das séries em andamento
  final Map<String, List<SerieRealizada>> _seriesRealizadasMap = {};

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
    _inicializarSeries();
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _segundosDecorridos++);
    });
  }

  void _inicializarSeries() {
    for (var ex in widget.treino.exercicios) {
      List<SerieRealizada> series = [];
      for (int i = 1; i <= ex.quantidadeSeries; i++) {
        series.add(
          SerieRealizada(
            id: const Uuid().v4(),
            sessaoId: '',
            exercicioId: ex.exercicioId,
            numeroSerie: i,
            carga: ex.cargaInicial,
            repeticoes: int.tryParse(ex.repeticoes.split('-').first) ?? 10,
            concluida: false,
          ),
        );
      }
      _seriesRealizadasMap[ex.exercicioId] = series;
    }
  }

  void _iniciarDescanso(int duracaoSegundos) {
    _restTimer?.cancel();
    setState(() {
      _restTotalInitial = duracaoSegundos;
      _restSecondsRemaining = duracaoSegundos;
      _isResting = true;
      _isRestPaused = false;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRestPaused) {
        if (_restSecondsRemaining > 1) {
          setState(() => _restSecondsRemaining--);
        } else {
          timer.cancel();
          setState(() {
            _restSecondsRemaining = 0;
            _isResting = false;
          });
          // Alerta sonoro / vibração / notificação
          TimerAudioService.instance.playRestCompleteAlert();
        }
      }
    });
  }

  void _ajustarTempoDescanso(int delta) {
    setState(() {
      _restSecondsRemaining = (_restSecondsRemaining + delta).clamp(0, 600);
    });
  }

  void _pularDescanso() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSecondsRemaining = 0;
    });
  }

  void _concluirSerie(String exercicioId, int index, bool val) {
    setState(() {
      final list = _seriesRealizadasMap[exercicioId]!;
      final old = list[index];
      list[index] = SerieRealizada(
        id: old.id,
        sessaoId: old.sessaoId,
        exercicioId: old.exercicioId,
        numeroSerie: old.numeroSerie,
        carga: old.carga,
        repeticoes: old.repeticoes,
        concluida: val,
      );
    });

    if (val) {
      // Se marcou como concluída, aciona o cronômetro automático de descanso
      final currentEx = widget.treino.exercicios[_exercicioIndexAtual];
      _iniciarDescanso(currentEx.descansoSegundos);
    }
  }

  void _finalizarTreino() {
    _sessionTimer.cancel();
    _restTimer?.cancel();

    final repo = Provider.of<WorkoutRepository>(context, listen: false);
    final sessao = SessaoTreino(
      id: const Uuid().v4(),
      usuarioId: repo.usuarioAtual?.id ?? 'guest',
      treinoId: widget.treino.id,
      nomeTreino: widget.treino.nome,
      inicio: _inicioSessao,
      fim: DateTime.now(),
      concluido: true,
    );

    List<SerieRealizada> todasSeries = [];
    _seriesRealizadasMap.values.forEach((l) => todasSeries.addAll(l));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryScreen(sessao: sessao, series: todasSeries),
      ),
    );
  }

  String _formatTempo(int segs) {
    final m = (segs ~/ 60).toString().padLeft(2, '0');
    final s = (segs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _sessionTimer.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentExItem = widget.treino.exercicios[_exercicioIndexAtual];
    final currentExInfo = currentExItem.exercicioInfo;
    final seriesDoExercicio = _seriesRealizadasMap[currentExItem.exercicioId] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.treino.nome),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: JTechTheme.accentCyan, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    _formatTempo(_segundosDecorridos),
                    style: const TextStyle(
                      color: JTechTheme.accentCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // CRONÔMETRO DE DESCANSO (SE ATIVO)
          if (_isResting) _buildRestTimerWidget(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAlignment.start,
                children: [
                  // CABEÇALHO DO EXERCÍCIO ATUAL
                  Card(
                    color: JTechTheme.surfaceDark,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Exercício ${_exercicioIndexAtual + 1} de ${widget.treino.exercicios.length}',
                                style: const TextStyle(color: JTechTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: JTechTheme.cardDark,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  currentExInfo?.grupoMuscular ?? 'Treino',
                                  style: const TextStyle(color: JTechTheme.textGrey, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentExInfo?.nome ?? 'Exercício Sem Nome',
                            style: const TextStyle(color: JTechTheme.textWhite, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Metas: ${currentExItem.quantidadeSeries} séries x ${currentExItem.repeticoes} reps • Descanso: ${currentExItem.descansoSegundos}s',
                            style: const TextStyle(color: JTechTheme.textGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TABELA DE REGISTRO DE SÉRIES
                  const Text(
                    'Registro de Séries & Cargas',
                    style: TextStyle(color: JTechTheme.textWhite, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: seriesDoExercicio.length,
                    itemBuilder: (ctx, idx) {
                      final s = seriesDoExercicio[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: s.concluida ? JTechTheme.successGreen.withOpacity(0.15) : JTechTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: s.concluida ? JTechTheme.successGreen : JTechTheme.dividerColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: s.concluida ? JTechTheme.successGreen : JTechTheme.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${s.numeroSerie}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Campo de Carga
                            Expanded(
                              child: TextFormField(
                                initialValue: '${s.carga}',
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: JTechTheme.textWhite, fontSize: 14),
                                decoration: const InputDecoration(
                                  labelText: 'Carga (kg)',
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  final num = double.tryParse(val) ?? 0.0;
                                  seriesDoExercicio[idx] = SerieRealizada(
                                    id: s.id,
                                    sessaoId: s.sessaoId,
                                    exercicioId: s.exercicioId,
                                    numeroSerie: s.numeroSerie,
                                    carga: num,
                                    repeticoes: s.repeticoes,
                                    concluida: s.concluida,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Campo de Repetições Realizadas
                            Expanded(
                              child: TextFormField(
                                initialValue: '${s.repeticoes}',
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: JTechTheme.textWhite, fontSize: 14),
                                decoration: const InputDecoration(
                                  labelText: 'Reps',
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  final num = int.tryParse(val) ?? 0;
                                  seriesDoExercicio[idx] = SerieRealizada(
                                    id: s.id,
                                    sessaoId: s.sessaoId,
                                    exercicioId: s.exercicioId,
                                    numeroSerie: s.numeroSerie,
                                    carga: s.carga,
                                    repeticoes: num,
                                    concluida: s.concluida,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Checkbox de Conclusão Verde
                            Checkbox(
                              value: s.concluida,
                              activeColor: JTechTheme.successGreen,
                              onChanged: (val) => _concluirSerie(currentExItem.exercicioId, idx, val ?? false),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // NAVEGAÇÃO ENTRE EXERCÍCIOS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _exercicioIndexAtual > 0
                            ? () => setState(() => _exercicioIndexAtual--)
                            : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Anterior'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _exercicioIndexAtual < widget.treino.exercicios.length - 1
                            ? () => setState(() => _exercicioIndexAtual++)
                            : _finalizarTreino,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _exercicioIndexAtual == widget.treino.exercicios.length - 1
                              ? JTechTheme.successGreen
                              : JTechTheme.primaryBlue,
                        ),
                        icon: Icon(_exercicioIndexAtual == widget.treino.exercicios.length - 1 ? Icons.check : Icons.arrow_forward),
                        label: Text(_exercicioIndexAtual == widget.treino.exercicios.length - 1 ? 'FINALIZAR' : 'Próximo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // BOTÃO INFERIOR FINALIZAR TREINO
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: JTechTheme.surfaceDark,
              border: Border(top: BorderSide(color: JTechTheme.dividerColor)),
            ),
            child: ElevatedButton(
              onPressed: _finalizarTreino,
              style: ElevatedButton.styleFrom(backgroundColor: JTechTheme.successGreen),
              child: const Text('FINALIZAR TREINO COMPLETO'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimerWidget() {
    final progress = (_restSecondsRemaining / _restTotalInitial).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0FF1A2332),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.hourglass_top_rounded, color: JTechTheme.accentCyan, size: 20),
                  SizedBox(width: 8),
                  Text('DESCANSO EM ANDAMENTO', style: TextStyle(color: JTechTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Text(
                _formatTempo(_restSecondsRemaining),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.black),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: JTechTheme.cardDark,
            color: JTechTheme.accentCyan,
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: JTechTheme.textWhite),
                onPressed: () => _ajustarTempoDescanso(-15),
                tooltip: '-15s',
              ),
              IconButton(
                icon: Icon(_isRestPaused ? Icons.play_arrow : Icons.pause, color: JTechTheme.accentCyan),
                onPressed: () => setState(() => _isRestPaused = !_isRestPaused),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: JTechTheme.textWhite),
                onPressed: () => _ajustarTempoDescanso(15),
                tooltip: '+15s',
              ),
              TextButton(
                onPressed: _pularDescanso,
                child: const Text('PULAR', style: TextStyle(color: JTechTheme.warningOrange, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
