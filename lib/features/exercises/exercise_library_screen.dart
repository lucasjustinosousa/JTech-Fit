import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/jtech_theme.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/models.dart';
import 'custom_exercise_dialog.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  final bool modoSelecao; // se chamado para selecionar em um treino

  const ExerciseLibraryScreen({super.key, this.modoSelecao = false});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String _buscaQuery = '';
  String _grupoFiltro = 'Todos';
  bool _apenasFavoritos = false;

  final List<String> _gruposNavegacao = [
    'Todos', 'Peito', 'Costas', 'Pernas', 'Ombros',
    'Bíceps', 'Tríceps', 'Abdômen', 'Corpo inteiro', 'Mobilidade e aquecimento'
  ];

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<WorkoutRepository>(context);
    final todosExercicios = repo.exercicios;

    final filtrados = todosExercicios.where((ex) {
      final bateNome = ex.nome.toLowerCase().contains(_buscaQuery.toLowerCase()) ||
          ex.grupoMuscular.toLowerCase().contains(_buscaQuery.toLowerCase()) ||
          ex.equipamento.toLowerCase().contains(_buscaQuery.toLowerCase());
      final bateGrupo = _grupoFiltro == 'Todos' || ex.grupoMuscular == _grupoFiltro;
      final bateFavorito = !_apenasFavoritos || ex.isFavorito;

      return bateNome && bateGrupo && bateFavorito;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modoSelecao ? 'Selecionar Exercício' : 'Biblioteca de Exercícios'),
        actions: [
          IconButton(
            icon: Icon(
              _apenasFavoritos ? Icons.star : Icons.star_border,
              color: _apenasFavoritos ? Colors.amber : JTechTheme.textWhite,
            ),
            onPressed: () {
              setState(() => _apenasFavoritos = !_apenasFavoritos);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: JTechTheme.accentCyan),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const CustomExerciseDialog(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // BARRA DE PESQUISA
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: const TextStyle(color: JTechTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'Buscar exercício por nome, equipamento...',
                prefixIcon: const Icon(Icons.search, color: JTechTheme.primaryBlue),
                suffixIcon: _buscaQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: JTechTheme.textGrey),
                        onPressed: () => setState(() => _buscaQuery = ''),
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _buscaQuery = val),
            ),
          ),

          // CHIPS DE GRUPOS MUSCULARES
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _gruposNavegacao.length,
              itemBuilder: (ctx, idx) {
                final grupo = _gruposNavegacao[idx];
                final isSelected = _grupoFiltro == grupo;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(grupo),
                    selected: isSelected,
                    selectedColor: JTechTheme.primaryBlue,
                    backgroundColor: JTechTheme.cardDark,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : JTechTheme.textGrey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _grupoFiltro = grupo);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // LISTA DE EXERCÍCIOS
          Expanded(
            child: filtrados.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum exercício encontrado para estes filtros.',
                      style: TextStyle(color: JTechTheme.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtrados.length,
                    itemBuilder: (context, index) {
                      final ex = filtrados[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          iconColor: JTechTheme.accentCyan,
                          collapsedIconColor: JTechTheme.textGrey,
                          leading: CircleAvatar(
                            backgroundColor: JTechTheme.primaryBlue.withOpacity(0.2),
                            child: Icon(
                              _getGroupIcon(ex.grupoMuscular),
                              color: JTechTheme.primaryBlue,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ex.nome,
                                  style: const TextStyle(
                                    color: JTechTheme.textWhite,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  ex.isFavorito ? Icons.star : Icons.star_border,
                                  color: ex.isFavorito ? Colors.amber : JTechTheme.textMuted,
                                  size: 22,
                                ),
                                onPressed: () => repo.toggleFavorito(ex.id),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${ex.grupoMuscular} • Equipamento: ${ex.equipamento}',
                            style: const TextStyle(color: JTechTheme.textGrey, fontSize: 12),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAlignment.start,
                                children: [
                                  if (ex.musculosAuxiliares.isNotEmpty) ...[
                                    Text('Músculos auxiliares: ${ex.musculosAuxiliares}',
                                        style: const TextStyle(color: JTechTheme.accentCyan, fontSize: 12)),
                                    const SizedBox(height: 8),
                                  ],
                                  const Text('Instruções:', style: TextStyle(color: JTechTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(ex.instrucoes, style: const TextStyle(color: JTechTheme.textGrey, fontSize: 13)),
                                  if (ex.cuidados.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    const Text('Cuidados na execução:', style: TextStyle(color: JTechTheme.warningOrange, fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(ex.cuidados, style: const TextStyle(color: JTechTheme.textGrey, fontSize: 13)),
                                  ],
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      if (widget.modoSelecao)
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => Navigator.pop(context, ex),
                                            style: ElevatedButton.styleFrom(backgroundColor: JTechTheme.successGreen),
                                            icon: const Icon(Icons.add_circle_outline),
                                            label: const Text('ADICIONAR AO TREINO'),
                                          ),
                                        )
                                      else
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              _mostrarDemonstrativoMidia(context, ex);
                                            },
                                            style: OutlinedButton.styleFrom(side: const BorderSide(color: JTechTheme.primaryBlue)),
                                            icon: const Icon(Icons.play_circle_fill, color: JTechTheme.primaryBlue),
                                            label: const Text('VÍDEO DEMONSTRATIVO', style: TextStyle(color: JTechTheme.primaryBlue)),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getGroupIcon(String grupo) {
    switch (grupo) {
      case 'Peito': return Icons.fitness_center;
      case 'Costas': return Icons.accessibility_new;
      case 'Pernas': return Icons.directions_run;
      case 'Ombros': return Icons.sports_gymnastics;
      case 'Bíceps': case 'Tríceps': return Icons.sports_kabaddi;
      default: return Icons.fitness_center;
    }
  }

  void _mostrarDemonstrativoMidia(BuildContext context, Exercicio ex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: JTechTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAlignment.start,
          children: [
            Text(ex.nome, style: const TextStyle(color: JTechTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: JTechTheme.dividerColor),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.play_circle_outline, color: JTechTheme.accentCyan, size: 64),
                  Positioned(
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Demonstração 3D / Vídeo Licenciado', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(ex.instrucoes, style: const TextStyle(color: JTechTheme.textGrey, fontSize: 13)),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('FECHAR'),
            ),
          ],
        ),
      ),
    );
  }
}
