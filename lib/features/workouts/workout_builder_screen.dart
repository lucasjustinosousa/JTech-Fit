import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/titannova_theme.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/models.dart';
import '../common/gif_viewer_modal.dart';
import '../exercises/exercise_selection_screen.dart';

class WorkoutBuilderScreen extends StatefulWidget {
  final Treino? treinoExistente;

  const WorkoutBuilderScreen({super.key, this.treinoExistente});

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  final _nomeController = TextEditingController();
  final _descController = TextEditingController();
  final List<String> _diasSelecionados = [];
  List<ExercicioDoTreino> _exerciciosDoTreino = [];
  String _corHex = '#1E88E5';

  final List<String> _diasDaSemana = [
    'Segunda-feira', 'Terça-feira', 'Quarta-feira',
    'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.treinoExistente != null) {
      _nomeController.text = widget.treinoExistente!.nome;
      _descController.text = widget.treinoExistente!.descricao;
      _diasSelecionados.addAll(widget.treinoExistente!.diasSemana);
      _exerciciosDoTreino = List.from(widget.treinoExistente!.exercicios);
      _corHex = widget.treinoExistente!.corHex;
    }
  }

  void _adicionarExercicioDaBiblioteca() async {
    final dynamic resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ExerciseSelectionScreen(),
      ),
    );

    if (resultado != null && resultado is List<Exercicio>) {
      setState(() {
        for (var selecionado in resultado) {
          _exerciciosDoTreino.add(
            ExercicioDoTreino(
              id: const Uuid().v4(),
              treinoId: widget.treinoExistente?.id ?? '',
              exercicioId: selecionado.id,
              ordem: _exerciciosDoTreino.length + 1,
              exercicioInfo: selecionado,
            ),
          );
        }
      });
    }
  }

  void _salvarTreino() {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o nome do treino.')),
      );
      return;
    }

    final repo = Provider.of<WorkoutRepository>(context, listen: false);
    final treino = Treino(
      id: widget.treinoExistente?.id ?? const Uuid().v4(),
      usuarioId: repo.usuarioAtual?.id ?? 'guest',
      nome: _nomeController.text.trim(),
      descricao: _descController.text.trim(),
      diasSemana: _diasSelecionados,
      corHex: _corHex,
      criadoEm: widget.treinoExistente?.criadoEm ?? DateTime.now(),
      exercicios: _exerciciosDoTreino,
    );

    repo.salvarTreino(treino);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.treinoExistente == null ? 'Criar Novo Treino' : 'Editar Treino'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: TitanNovaTheme.successGreen, size: 28),
            onPressed: _salvarTreino,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            // Nome do Treino
            TextField(
              controller: _nomeController,
              style: const TextStyle(color: TitanNovaTheme.textWhite, fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Nome do Treino (ex: Treino A — Peito e Tríceps)',
                prefixIcon: Icon(Icons.edit, color: TitanNovaTheme.primaryBlue),
              ),
            ),
            const SizedBox(height: 12),

            // Foco / Objetivo do Treino (Chips de seleção rápida)
            const Text(
              'Foco / Objetivo do Treino (Opcional)',
              style: TextStyle(color: TitanNovaTheme.textWhite, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                '💪 Hipertrofia',
                '🔥 Emagrecimento',
                '🏋️‍♂️ Força Bruta',
                '⚡ Resistência',
                '🔰 Iniciante',
                '🏃 Cardio',
              ].map((foco) {
                final cleanName = foco.replaceFirst(RegExp(r'^[^\s]+\s*'), '');
                final isSelected = _descController.text == cleanName;
                return ChoiceChip(
                  label: Text(foco),
                  selected: isSelected,
                  selectedColor: TitanNovaTheme.primaryBlue,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : TitanNovaTheme.textGrey, fontSize: 12),
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _descController.text = cleanName;
                      } else {
                        if (_descController.text == cleanName) {
                          _descController.clear();
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Dias da Semana
            const Text(
              'Dias da Semana (Opcional)',
              style: TextStyle(color: TitanNovaTheme.textWhite, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: _diasDaSemana.map((dia) {
                final isSelected = _diasSelecionados.contains(dia);
                return FilterChip(
                  label: Text(dia),
                  selected: isSelected,
                  selectedColor: TitanNovaTheme.primaryBlue,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : TitanNovaTheme.textGrey, fontSize: 12),
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _diasSelecionados.add(dia);
                      } else {
                        _diasSelecionados.remove(dia);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // LISTA DE EXERCÍCIOS COM ARRASTAR E SOLTAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Exercícios do Treino',
                  style: TextStyle(color: TitanNovaTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _adicionarExercicioDaBiblioteca,
                  icon: const Icon(Icons.add, color: TitanNovaTheme.accentCyan),
                  label: const Text('Adicionar Exercício', style: TextStyle(color: TitanNovaTheme.accentCyan)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_exerciciosDoTreino.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: TitanNovaTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TitanNovaTheme.dividerColor),
                ),
                child: const Text(
                  'Nenhum exercício adicionado a este treino ainda.\nClique em "+ Adicionar Exercício" acima.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: TitanNovaTheme.textMuted, fontSize: 13),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exerciciosDoTreino.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _exerciciosDoTreino.removeAt(oldIndex);
                    _exerciciosDoTreino.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final exItem = _exerciciosDoTreino[index];
                  return Container(
                    key: ValueKey(exItem.id),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TitanNovaTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TitanNovaTheme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.drag_handle, color: TitanNovaTheme.textMuted),
                            const SizedBox(width: 8),
                            if (exItem.exercicioInfo?.gifUrl != null && exItem.exercicioInfo!.gifUrl!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () {
                                    if (exItem.exercicioInfo != null) {
                                      showGifViewerModal(context, exItem.exercicioInfo!);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: TitanNovaTheme.accentCyan.withOpacity(0.5)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: Image.network(
                                        exItem.exercicioInfo!.gifUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center, size: 16, color: TitanNovaTheme.primaryBlue),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (exItem.exercicioInfo != null) {
                                    showGifViewerModal(context, exItem.exercicioInfo!);
                                  }
                                },
                                child: Text(
                                  exItem.exercicioInfo?.nome ?? 'Exercício',
                                  style: const TextStyle(
                                    color: TitanNovaTheme.textWhite,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: TitanNovaTheme.errorRed, size: 20),
                              onPressed: () {
                                setState(() {
                                  _exerciciosDoTreino.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildParamInput(
                                label: 'Séries',
                                value: '${exItem.quantidadeSeries}',
                                onChanged: (val) {
                                  final num = int.tryParse(val) ?? 4;
                                  _exerciciosDoTreino[index] = ExercicioDoTreino(
                                    id: exItem.id,
                                    treinoId: exItem.treinoId,
                                    exercicioId: exItem.exercicioId,
                                    ordem: exItem.ordem,
                                    quantidadeSeries: num,
                                    repeticoes: exItem.repeticoes,
                                    cargaInicial: exItem.cargaInicial,
                                    descansoSegundos: exItem.descansoSegundos,
                                    exercicioInfo: exItem.exercicioInfo,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildParamInput(
                                label: 'Reps',
                                value: exItem.repeticoes,
                                onChanged: (val) {
                                  _exerciciosDoTreino[index] = ExercicioDoTreino(
                                    id: exItem.id,
                                    treinoId: exItem.treinoId,
                                    exercicioId: exItem.exercicioId,
                                    ordem: exItem.ordem,
                                    quantidadeSeries: exItem.quantidadeSeries,
                                    repeticoes: val,
                                    cargaInicial: exItem.cargaInicial,
                                    descansoSegundos: exItem.descansoSegundos,
                                    exercicioInfo: exItem.exercicioInfo,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildParamInput(
                                label: 'Descanso(s)',
                                value: '${exItem.descansoSegundos}',
                                onChanged: (val) {
                                  final sec = int.tryParse(val) ?? 60;
                                  _exerciciosDoTreino[index] = ExercicioDoTreino(
                                    id: exItem.id,
                                    treinoId: exItem.treinoId,
                                    exercicioId: exItem.exercicioId,
                                    ordem: exItem.ordem,
                                    quantidadeSeries: exItem.quantidadeSeries,
                                    repeticoes: exItem.repeticoes,
                                    cargaInicial: exItem.cargaInicial,
                                    descansoSegundos: sec,
                                    exercicioInfo: exItem.exercicioInfo,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _salvarTreino,
              child: const Text('SALVAR TREINO'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParamInput({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: value,
      keyboardType: TextInputType.text,
      style: const TextStyle(color: TitanNovaTheme.textWhite, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      onChanged: onChanged,
    );
  }
}
