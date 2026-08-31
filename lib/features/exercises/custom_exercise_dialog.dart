import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/jtech_theme.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/models.dart';

class CustomExerciseDialog extends StatefulWidget {
  const CustomExerciseDialog({super.key});

  @override
  State<CustomExerciseDialog> createState() => _CustomExerciseDialogState();
}

class _CustomExerciseDialogState extends State<CustomExerciseDialog> {
  final _nomeController = TextEditingController();
  final _instrucoesController = TextEditingController();
  final _cuidadosController = TextEditingController();
  final _mediaUrlController = TextEditingController();
  
  String _grupoMuscular = 'Peito';
  String _equipamento = 'Halteres';

  final List<String> _grupos = [
    'Peito', 'Costas', 'Pernas', 'Ombros', 'Bíceps',
    'Tríceps', 'Abdômen', 'Corpo inteiro', 'Mobilidade e aquecimento'
  ];

  final List<String> _equipamentos = [
    'Halteres', 'Barra', 'Máquina', 'Polia / Crossover',
    'Peso corporal', 'Kettlebell', 'Elástico / Band', 'Outro'
  ];

  void _salvarExercicioCustomizado() {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite o nome do exercício.')),
      );
      return;
    }

    final repo = Provider.of<WorkoutRepository>(context, listen: false);
    final media = _mediaUrlController.text.trim();
    final isGif = media.toLowerCase().contains('.gif') || media.toLowerCase().startsWith('http');

    final ex = Exercicio(
      id: 'custom_${const Uuid().v4()}',
      nome: _nomeController.text.trim(),
      grupoMuscular: _grupoMuscular,
      equipamento: _equipamento,
      instrucoes: _instrucoesController.text.trim(),
      cuidados: _cuidadosController.text.trim(),
      gifUrl: (isGif && media.isNotEmpty) ? media : null,
      videoUrl: media.isNotEmpty ? media : null,
      personalizado: true,
      usuarioId: repo.usuarioAtual?.id,
    );

    repo.salvarExercicioCustomizado(ex);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: JTechTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            const Text(
              'Criar Exercício Personalizado',
              style: TextStyle(color: JTechTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome do Exercício'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _grupoMuscular,
              dropdownColor: JTechTheme.cardDark,
              decoration: const InputDecoration(labelText: 'Grupo Muscular Principal'),
              items: _grupos.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (val) => setState(() => _grupoMuscular = val!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _equipamento,
              dropdownColor: JTechTheme.cardDark,
              decoration: const InputDecoration(labelText: 'Equipamento Necessário'),
              items: _equipamentos.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (val) => setState(() => _equipamento = val!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instrucoesController,
              decoration: const InputDecoration(labelText: 'Instruções de Execução'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cuidadosController,
              decoration: const InputDecoration(labelText: 'Cuidados / Dicas de postura'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mediaUrlController,
              decoration: const InputDecoration(labelText: 'Link para Foto ou Vídeo (opcional)'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR', style: TextStyle(color: JTechTheme.textGrey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _salvarExercicioCustomizado,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
                  child: const Text('SALVAR'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
