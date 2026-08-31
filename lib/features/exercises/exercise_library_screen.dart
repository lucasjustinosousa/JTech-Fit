import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/jtech_theme.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/models.dart';
import '../common/gif_viewer_modal.dart';
import 'exercise_details_screen.dart';
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
                          leading: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => showGifViewerModal(context, ex, modoSelecao: widget.modoSelecao),
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: JTechTheme.dividerColor),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(9),
                                      child: (ex.gifUrl != null && ex.gifUrl!.isNotEmpty)
                                          ? Image.network(
                                              ex.gifUrl!,
                                              width: 54,
                                              height: 54,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, progress) {
                                                if (progress == null) return child;
                                                return const Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(strokeWidth: 2, color: JTechTheme.accentCyan),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) => Center(
                                                child: Icon(
                                                  _getGroupIcon(ex.grupoMuscular),
                                                  color: JTechTheme.primaryBlue,
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Icon(
                                                _getGroupIcon(ex.grupoMuscular),
                                                color: JTechTheme.primaryBlue,
                                              ),
                                            ),
                                    ),
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.85),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: JTechTheme.accentCyan.withOpacity(0.6), width: 0.5),
                                        ),
                                        child: const Text('GIF ▶', style: TextStyle(color: JTechTheme.accentCyan, fontSize: 8, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                                  // GIF ANIMADO INCORPORADO DIRETO NO CARD EXPANDIDO
                                  if (ex.gifUrl != null && ex.gifUrl!.isNotEmpty) ...[
                                    Container(
                                      height: 220,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: JTechTheme.dividerColor),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(13),
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () => showGifFullscreenDialog(context, ex),
                                              child: Image.network(
                                                ex.gifUrl!,
                                                fit: BoxFit.contain,
                                                width: double.infinity,
                                                height: 220,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  final totalBytes = loadingProgress.expectedTotalBytes;
                                                  final loadedBytes = loadingProgress.cumulativeBytesLoaded;
                                                  final progress = totalBytes != null ? (loadedBytes / totalBytes) : null;
                                                  return Center(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        CircularProgressIndicator(
                                                          value: progress,
                                                          color: JTechTheme.accentCyan,
                                                        ),
                                                        const SizedBox(height: 10),
                                                        const Text('Carregando animação GIF...', style: TextStyle(color: JTechTheme.textGrey, fontSize: 12)),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (_, __, ___) => Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(_getGroupIcon(ex.grupoMuscular), color: JTechTheme.accentCyan, size: 48),
                                                      const SizedBox(height: 8),
                                                      const Text('Visualização disponível ao conectar', style: TextStyle(color: JTechTheme.textGrey, fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.65),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: IconButton(
                                                icon: const Icon(Icons.fullscreen, color: JTechTheme.accentCyan, size: 20),
                                                tooltip: 'Ver em tela cheia com zoom',
                                                onPressed: () => showGifFullscreenDialog(context, ex),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            left: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.75),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: JTechTheme.accentCyan.withOpacity(0.4), width: 0.5),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.zoom_in, color: JTechTheme.accentCyan, size: 12),
                                                  SizedBox(width: 4),
                                                  Text('Toque no GIF para zoom', style: TextStyle(color: JTechTheme.accentCyan, fontSize: 9, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],

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
                                      else ...[
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              showGifViewerModal(context, ex, modoSelecao: widget.modoSelecao);
                                            },
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: JTechTheme.accentCyan),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            icon: const Icon(Icons.fullscreen, color: JTechTheme.accentCyan, size: 20),
                                            label: const Text('AMPLIAR GIF', style: TextStyle(color: JTechTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ExerciseDetailsScreen(exercicio: ex, modoSelecao: widget.modoSelecao),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: JTechTheme.primaryBlue,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            icon: const Icon(Icons.info_outline, size: 18),
                                            label: const Text('DETALHES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
    if (g.contains('ombro')) return Icons.sports_gymnastics;
    if (g.contains('biceps') || g.contains('bíceps') || g.contains('triceps') || g.contains('tríceps')) return Icons.sports_kabaddi;
    return Icons.fitness_center;
  }

  void _mostrarDemonstrativoMidia(BuildContext context, Exercicio ex) {
    showGifViewerModal(context, ex, modoSelecao: widget.modoSelecao);
  }
}
