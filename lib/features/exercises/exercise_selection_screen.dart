import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/jtech_theme.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/models.dart';
import 'exercise_details_screen.dart';
import 'exercise_gif_dialog.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  State<ExerciseSelectionScreen> createState() => _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  String _searchQuery = '';
  String _selectedBodyPart = 'Todos';
  String _selectedEquipment = 'Todos';
  bool _onlyFavorites = false;

  final Set<String> _selectedExerciseIds = {};

  final List<String> _bodyParts = [
    'Todos', 'Peito', 'Costas', 'Pernas (Coxas)', 'Panturrilhas',
    'Ombros', 'Braços (Superiores)', 'Antebraços', 'Abdômen / Cintura', 'Aeróbico / Cardio'
  ];

  final List<String> _equipments = [
    'Todos', 'Barra', 'Halteres', 'Peso Corporal', 'Polia (Cabo)',
    'Barra Guiada (Smith)', 'Máquina Alavancada', 'Kettlebell', 'Elástico / Extensor'
  ];

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<WorkoutRepository>(context);
    final allExercises = repo.exercicios;

    final filtered = allExercises.where((ex) {
      final matchesSearch = _searchQuery.isEmpty ||
          ex.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ex.grupoMuscular.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ex.equipamento.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesBodyPart = _selectedBodyPart == 'Todos' || ex.grupoMuscular == _selectedBodyPart;
      final matchesEquipment = _selectedEquipment == 'Todos' || ex.equipamento == _selectedEquipment;
      final matchesFav = !_onlyFavorites || ex.isFavorito;

      return matchesSearch && matchesBodyPart && matchesEquipment && matchesFav;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Exercícios'),
        actions: [
          IconButton(
            icon: Icon(
              _onlyFavorites ? Icons.star : Icons.star_border,
              color: _onlyFavorites ? Colors.amber : Colors.white,
            ),
            onPressed: () => setState(() => _onlyFavorites = !_onlyFavorites),
          ),
        ],
      ),
      body: Column(
        children: [
          // BARRA DE PESQUISA
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              style: const TextStyle(color: TitanNovaTheme.textWhite),
              decoration: InputDecoration(
                hintText: '🔍 Buscar por nome, grupo ou equipamento...',
                prefixIcon: const Icon(Icons.search, color: TitanNovaTheme.primaryBlue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: TitanNovaTheme.textGrey),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // CHIPS DE FILTRO POR PARTE DO CORPO
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _bodyParts.length,
              itemBuilder: (ctx, idx) {
                final bp = _bodyParts[idx];
                final isSelected = _selectedBodyPart == bp;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(bp),
                    selected: isSelected,
                    selectedColor: TitanNovaTheme.primaryBlue,
                    backgroundColor: TitanNovaTheme.cardDark,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : TitanNovaTheme.textGrey,
                      fontSize: 11,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedBodyPart = bp);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),

          // CHIPS DE FILTRO POR EQUIPAMENTO
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _equipments.length,
              itemBuilder: (ctx, idx) {
                final eq = _equipments[idx];
                final isSelected = _selectedEquipment == eq;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(eq),
                    selected: isSelected,
                    selectedColor: TitanNovaTheme.accentCyan,
                    backgroundColor: TitanNovaTheme.cardDark,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : TitanNovaTheme.textGrey,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedEquipment = eq);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // BANNER DISCRETO MODO OFFLINE / STATS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: TitanNovaTheme.cardDark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} exercícios disponíveis',
                  style: const TextStyle(color: TitanNovaTheme.textGrey, fontSize: 11),
                ),
                const Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: TitanNovaTheme.accentCyan, size: 14),
                    SizedBox(width: 4),
                    Text('Modo Offline Ativo', style: TextStyle(color: TitanNovaTheme.accentCyan, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          // LISTA DE EXERCÍCIOS COM CHECKBOX
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum exercício encontrado com estes filtros.',
                      style: TextStyle(color: TitanNovaTheme.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final ex = filtered[idx];
                      final isChecked = _selectedExerciseIds.contains(ex.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: CheckboxListTile(
                          activeColor: TitanNovaTheme.successGreen,
                          value: isChecked,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedExerciseIds.add(ex.id);
                              } else {
                                _selectedExerciseIds.remove(ex.id);
                              }
                            });
                          },
                          title: Text(
                            ex.nome,
                            style: const TextStyle(
                              color: TitanNovaTheme.textWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${ex.grupoMuscular} • Equipamento: ${ex.equipamento}',
                            style: const TextStyle(color: TitanNovaTheme.textGrey, fontSize: 11),
                          ),
                          secondary: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.zoom_in, color: TitanNovaTheme.accentCyan, size: 22),
                                tooltip: 'Expandir GIF',
                                onPressed: () {
                                  ExerciseGifDialog.show(context, exercicio: ex, modoSelecao: false);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.info_outline, color: TitanNovaTheme.textGrey, size: 20),
                                tooltip: 'Detalhes completos',
                                onPressed: () async {
                                  final res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ExerciseDetailsScreen(exercicio: ex, modoSelecao: true),
                                    ),
                                  );
                                  if (res == 'select') {
                                    setState(() => _selectedExerciseIds.add(ex.id));
                                  } else if (res == 'toggle_fav') {
                                    repo.toggleFavorito(ex.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // BOTÃO FIXO "ADICIONAR SELECIONADOS"
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: TitanNovaTheme.cardDark,
              border: Border(top: BorderSide(color: TitanNovaTheme.dividerColor)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _selectedExerciseIds.isEmpty
                    ? null
                    : () {
                        final selectedObjects = allExercises
                            .where((e) => _selectedExerciseIds.contains(e.id))
                            .toList();
                        Navigator.pop(context, selectedObjects);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TitanNovaTheme.successGreen,
                  disabledBackgroundColor: Colors.grey.shade800,
                ),
                icon: const Icon(Icons.check_circle),
                label: Text(
                  'ADICIONAR SELECIONADOS (${_selectedExerciseIds.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
