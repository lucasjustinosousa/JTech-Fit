import 'package:flutter/material.dart';
import '../../core/theme/titannova_theme.dart';
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
                border: Border.all(color: TitanNovaTheme.dividerColor),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (ex.gifUrl != null && ex.gifUrl!.isNotEmpty && _isPlayingGif)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => ExerciseGifDialog.show(context, exercicio: ex, modoSelecao: widget.modoSelecao),
                        child: Image.network(
                          ex.gifUrl!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 240,
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
                                    color: TitanNovaTheme.accentCyan,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('Carregando animação GIF...', style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 12)),
                                ],
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fitness_center, color: TitanNovaTheme.primaryBlue, size: 64),
                                SizedBox(height: 8),
                                Text('Pré-visualização 3D demonstrativa', style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (ex.gifUrl != null && ex.gifUrl!.isNotEmpty) {
                          setState(() => _isPlayingGif = true);
                        }
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_circle_outline, color: TitanNovaTheme.accentCyan, size: 64),
                              SizedBox(height: 8),
                              Text('Toque para reproduzir animação', style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Chip indicador no canto inferior esquerdo
                  if (ex.gifUrl != null && ex.gifUrl!.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: TitanNovaTheme.accentCyan.withOpacity(0.4), width: 0.5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: TitanNovaTheme.accentCyan, size: 14),
                            SizedBox(width: 4),
                            Text('Toque para zoom / tela cheia', style: TextStyle(color: TitanNovaTheme.accentCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),

                  // Botão de tela cheia / zoom no canto superior direito
                  if (ex.gifUrl != null && ex.gifUrl!.isNotEmpty)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.fullscreen, color: TitanNovaTheme.accentCyan),
                          tooltip: 'Expandir GIF',
                          onPressed: () => _mostrarGifEmTelaCheia(context, ex),
                        ),
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
                          border: Border.all(color: TitanNovaTheme.accentCyan.withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: TitanNovaTheme.accentCyan, size: 14),
                            SizedBox(width: 4),
                            Text('AMPLIAR', style: TextStyle(color: TitanNovaTheme.accentCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Botão de Play/Pausa no canto inferior direito
                  if (ex.gifUrl != null && ex.gifUrl!.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: FloatingActionButton.small(
                        backgroundColor: TitanNovaTheme.primaryBlue,
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
              style: const TextStyle(color: TitanNovaTheme.textWhite, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (ex.nomeOriginal != null && ex.nomeOriginal!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                ex.nomeOriginal!,
                style: const TextStyle(color: TitanNovaTheme.textGrey, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag('🎯 Músculo: ${ex.grupoMuscular}', TitanNovaTheme.primaryBlue),
                _buildTag('🏋️ Equipamento: ${ex.equipamento}', TitanNovaTheme.accentCyan),
                if (ex.musculosAuxiliares.isNotEmpty)
                  _buildTag('💪 Auxiliares: ${ex.musculosAuxiliares}', TitanNovaTheme.successGreen),
              ],
            ),
            const SizedBox(height: 20),

            // INSTRUÇÕES PASSO A PASSO
            const Text(
              'Instruções de Execução',
              style: TextStyle(color: TitanNovaTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TitanNovaTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TitanNovaTheme.dividerColor),
              ),
              child: Text(
                ex.instrucoes.isNotEmpty ? ex.instrucoes : 'Executar o movimento com amplitude completa e controle de carga.',
                style: const TextStyle(color: TitanNovaTheme.textGrey, fontSize: 13, height: 1.4),
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
                  style: ElevatedButton.styleFrom(backgroundColor: TitanNovaTheme.successGreen),
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

  void _mostrarGifEmTelaCheia(BuildContext context, Exercicio ex) {
    if (ex.gifUrl == null || ex.gifUrl!.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ex.nome,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                  maxWidth: MediaQuery.of(context).size.width,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    panEnabled: true,
                    scaleEnabled: true,
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.network(
                      ex.gifUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(color: TitanNovaTheme.accentCyan),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_outlined, color: TitanNovaTheme.warningOrange, size: 48),
                              SizedBox(height: 8),
                              Text('Não foi possível carregar o GIF em tela cheia', style: TextStyle(color: TitanNovaTheme.textWhite, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: TitanNovaTheme.primaryBlue),
                  child: const Text('FECHAR TELA CHEIA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
