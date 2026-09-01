import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/titannova_theme.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/models.dart';
import 'workout_builder_screen.dart';

class WorkoutListScreen extends StatelessWidget {
  final Function(Treino treino) onStartWorkout;

  const WorkoutListScreen({super.key, required this.onStartWorkout});

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return TitanNovaTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<WorkoutRepository>(context);
    final treinos = repo.treinos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Divisões de Treino'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: TitanNovaTheme.accentCyan),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkoutBuilderScreen()),
              );
            },
          ),
        ],
      ),
      body: treinos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fitness_center_outlined, size: 64, color: TitanNovaTheme.textMuted),
                  const SizedBox(height: 16),
                  const Text('Nenhum treino criado ainda.', style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 16)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WorkoutBuilderScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Criar Novo Treino'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: treinos.length,
              itemBuilder: (context, index) {
                final treino = treinos[index];
                final cardColor = _parseColor(treino.corHex);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border(left: BorderSide(color: cardColor, width: 6)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                treino.nome,
                                style: const TextStyle(
                                  color: TitanNovaTheme.textWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: TitanNovaTheme.textGrey),
                              color: TitanNovaTheme.surfaceDark,
                              onSelected: (val) {
                                if (val == 'editar') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => WorkoutBuilderScreen(treinoExistente: treino)),
                                  );
                                } else if (val == 'duplicar') {
                                  repo.duplicarTreino(treino);
                                } else if (val == 'deletar') {
                                  repo.deletarTreino(treino.id);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'editar', child: Text('Editar Treino', style: TextStyle(color: Colors.white))),
                                const PopupMenuItem(value: 'duplicar', child: Text('Duplicar', style: TextStyle(color: Colors.white))),
                                const PopupMenuItem(value: 'deletar', child: Text('Excluir', style: TextStyle(color: TitanNovaTheme.errorRed))),
                              ],
                            ),
                          ],
                        ),
                        if (treino.descricao.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(treino.descricao, style: const TextStyle(color: TitanNovaTheme.textGrey, fontSize: 12)),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: treino.diasSemana.map((d) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              d,
                              style: TextStyle(color: cardColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          )).toList(),
                        ),
                        const Divider(height: 20, color: TitanNovaTheme.dividerColor),
                        
                        // Lista Expansível de Exercícios Montados no Treino
                        Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            title: Text(
                              '${treino.exercicios.length} exercícios montados',
                              style: const TextStyle(color: TitanNovaTheme.accentCyan, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            trailing: const Icon(Icons.keyboard_arrow_down, color: TitanNovaTheme.accentCyan),
                            children: [
                              const SizedBox(height: 6),
                              ...treino.exercicios.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final exItem = entry.value;
                                final nome = exItem.exercicioInfo?.nome ?? 'Exercício';
                                final grupo = exItem.exercicioInfo?.grupoMuscular ?? 'Geral';
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF090B10),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: TitanNovaTheme.dividerColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Text('${idx + 1}.', style: const TextStyle(color: TitanNovaTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(nome, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                            Text('$grupo • ${exItem.quantidadeSeries} séries x ${exItem.repeticoes} reps', style: const TextStyle(color: TitanNovaTheme.textGrey, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => onStartWorkout(treino),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TitanNovaTheme.successGreen,
                                minimumSize: const Size(130, 40),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.play_arrow, size: 20),
                              label: const Text('INICIAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: TitanNovaTheme.primaryBlue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WorkoutBuilderScreen()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('CRIAR NOVO TREINO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
