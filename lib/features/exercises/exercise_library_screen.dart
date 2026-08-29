import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/jtech_theme.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/models.dart';
import 'custom_exercise_dialog.dart';
import 'exercise_gif_dialog.dart';

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
                          leading: GestureDetector(
                            onTap: () => _mostrarGifExpandido(context, ex),
                            child: Stack(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: JTechTheme.accentCyan.withOpacity(0.4)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: ((ex.gifUrl != null && ex.gifUrl!.isNotEmpty) || (ex.imagemUrl != null && ex.imagemUrl!.isNotEmpty))
                                        ? Image.network(
                                            (ex.gifUrl != null && ex.gifUrl!.isNotEmpty) ? ex.gifUrl! : ex.imagemUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(
                                              _getGroupIcon(ex.grupoMuscular),
                                              color: JTechTheme.primaryBlue,
                                            ),
                                          )
                                        : Icon(
                                            _getGroupIcon(ex.grupoMuscular),
                                            color: JTechTheme.primaryBlue,
                                          ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: JTechTheme.accentCyan.withOpacity(0.6), width: 0.5),
                                    ),
                                    child: const Icon(Icons.zoom_in, color: JTechTheme.accentCyan, size: 10),
                                  ),
                                ),
                              ],
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      if (widget.modoSelecao) ...[
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _mostrarGifExpandido(context, ex),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: JTechTheme.accentCyan),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            icon: const Icon(Icons.zoom_in, color: JTechTheme.accentCyan, size: 18),
                                            label: const Text('EXPANDIR GIF', style: TextStyle(color: JTechTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: ElevatedButton.icon(
                                            onPressed: () => Navigator.pop(context, ex),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: JTechTheme.successGreen,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            icon: const Icon(Icons.add_circle_outline, size: 18),
                                            label: const Text('ADICIONAR AO TREINO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                        ),
                                      ] else ...[
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _mostrarGifExpandido(context, ex),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: JTechTheme.cardDark,
                                              side: const BorderSide(color: JTechTheme.accentCyan, width: 1.2),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            icon: const Icon(Icons.fullscreen_rounded, color: JTechTheme.accentCyan),
                                            label: const Text(
                                              'VER GIF EXPANDIDO (ZOOM 3D)',
                                              style: TextStyle(color: JTechTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3),
                                            ),
                                          ),
                                        ),
                                      ],
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
    final g = grupo.toLowerCase();
    if (g.contains('peito')) return Icons.fitness_center;
    if (g.contains('costa')) return Icons.accessibility_new;
    if (g.contains('perna') || g.contains('coxa') || g.contains('panturrilha')) return Icons.directions_run;
    if (g.contains('ombro') || g.contains('deltoide')) return Icons.sports_gymnastics;
    if (g.contains('bíceps') || g.contains('biceps')) return Icons.sports_kabaddi;
    if (g.contains('tríceps') || g.contains('triceps')) return Icons.flash_on;
    if (g.contains('abd') || g.contains('core')) return Icons.self_improvement;
    return Icons.fitness_center;
  }

  void _mostrarGifExpandido(BuildContext context, Exercicio ex) async {
    final resultado = await ExerciseGifDialog.show(
      context,
      exercicio: ex,
      modoSelecao: widget.modoSelecao,
    );

    if (resultado != null && widget.modoSelecao && mounted) {
      Navigator.pop(context, resultado);
    }
  }
}
