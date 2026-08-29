import 'package:flutter/material.dart';
import '../../core/theme/jtech_theme.dart';
import '../../data/models/models.dart';
import 'exercise_gif_dialog.dart';

class ExerciseDetailsScreen extends StatefulWidget {
  final Exercicio exercicio;
  final bool modoSelecao;

  const ExerciseDetailsScreen({
    super.key,
    required this.exercicio,
    this.modoSelecao = false,
  });

  @override
  State<ExerciseDetailsScreen> createState() => _ExerciseDetailsScreenState();
}

class _ExerciseDetailsScreenState extends State<ExerciseDetailsScreen> {
  bool _isPlayingGif = true;

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercicio;

    return Scaffold(
      appBar: AppBar(
        title: Text(ex.nome),
        actions: [
          IconButton(
            icon: Icon(
              ex.isFavorito ? Icons.star : Icons.star_border,
              color: ex.isFavorito ? Colors.amber : Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context, 'toggle_fav');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            // REPRODUTOR DE GIF COM BOTÃO PLAY / PAUSE E EXPANDIR
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: JTechTheme.dividerColor),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (ex.gifUrl != null && ex.gifUrl!.isNotEmpty && _isPlayingGif)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GestureDetector(
                        onTap: () => ExerciseGifDialog.show(context, exercicio: ex, modoSelecao: widget.modoSelecao),
                        child: Image.network(
                          ex.gifUrl!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 240,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fitness_center, color: JTechTheme.primaryBlue, size: 64),
                                SizedBox(height: 8),
                                Text('Pré-visualização 3D demonstrativa', style: TextStyle(color: JTechTheme.textGrey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pause_circle_outline, color: JTechTheme.accentCyan, size: 64),
                          SizedBox(height: 8),
                          Text('Animação pausada', style: TextStyle(color: JTechTheme.textGrey, fontSize: 12)),
                        ],
                      ),
                    ),

                  // Botão de Expandir no canto superior direito
                  Positioned(
                    top: 10,
                    right: 10,
                    child: InkWell(
                      onTap: () => ExerciseGifDialog.show(context, exercicio: ex, modoSelecao: widget.modoSelecao),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: JTechTheme.accentCyan.withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: JTechTheme.accentCyan, size: 14),
                            SizedBox(width: 4),
                            Text('AMPLIAR', style: TextStyle(color: JTechTheme.accentCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Botão de Play/Pausa no canto inferior direito
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: FloatingActionButton.small(
                      backgroundColor: JTechTheme.primaryBlue,
                      onPressed: () {
                        setState(() => _isPlayingGif = !_isPlayingGif);
                      },
                      child: Icon(_isPlayingGif ? Icons.pause : Icons.play_arrow, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // INFORMATIVO TÉCNICO
            Text(
              ex.nome,
              style: const TextStyle(color: JTechTheme.textWhite, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (ex.nomeOriginal != null && ex.nomeOriginal!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                ex.nomeOriginal!,
                style: const TextStyle(color: JTechTheme.textGrey, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag('🎯 Músculo: ${ex.grupoMuscular}', JTechTheme.primaryBlue),
                _buildTag('🏋️ Equipamento: ${ex.equipamento}', JTechTheme.accentCyan),
                if (ex.musculosAuxiliares.isNotEmpty)
                  _buildTag('💪 Auxiliares: ${ex.musculosAuxiliares}', JTechTheme.successGreen),
              ],
            ),
            const SizedBox(height: 20),

            // INSTRUÇÕES PASSO A PASSO
            const Text(
              'Instruções de Execução',
              style: TextStyle(color: JTechTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: JTechTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: JTechTheme.dividerColor),
              ),
              child: Text(
                ex.instrucoes.isNotEmpty ? ex.instrucoes : 'Executar o movimento com amplitude completa e controle de carga.',
                style: const TextStyle(color: JTechTheme.textGrey, fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),

            // AVISO LEGAL E DE SEGURANÇA PROFISSIONAL
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '⚠️ Aviso de Segurança: A execução pode variar conforme o nível do usuário. Dor ou mal-estar são motivos para interromper. Iniciantes devem procurar orientação profissional qualificada. O aplicativo não substitui acompanhamento médico ou de profissional de educação física.',
                      style: TextStyle(color: Colors.amber, fontSize: 11, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // BOTÃO ADICIONAR
            if (widget.modoSelecao)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, 'select');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: JTechTheme.successGreen),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('ADICIONAR AO TREINO', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
