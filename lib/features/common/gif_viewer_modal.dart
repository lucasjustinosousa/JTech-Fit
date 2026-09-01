import 'package:flutter/material.dart';
import '../../core/theme/titannova_theme.dart';
import '../../data/models/models.dart';
import '../exercises/exercise_details_screen.dart';

/// Exibe um modal responsivo e interativo para visualização do GIF e instruções do exercício
void showGifViewerModal(
  BuildContext context,
  Exercicio exercicio, {
  bool modoSelecao = false,
  VoidCallback? onAdd,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => GifViewerModal(
      exercicio: exercicio,
      modoSelecao: modoSelecao,
      onAdd: onAdd,
    ),
  );
}

/// Exibe o diálogo em tela cheia com zoom interativo
void showGifFullscreenDialog(BuildContext context, Exercicio exercicio) {
  final mediaUrl = (exercicio.gifUrl != null && exercicio.gifUrl!.isNotEmpty)
      ? exercicio.gifUrl!
      : ((exercicio.imagemUrl != null && exercicio.imagemUrl!.isNotEmpty)
          ? exercicio.imagemUrl!
          : (exercicio.videoUrl ?? ''));

  if (mediaUrl.isEmpty) return;

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exercicio.nome,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65,
                maxWidth: MediaQuery.of(context).size.width,
              ),
              color: Colors.black,
              child: InteractiveViewer(
                panEnabled: true,
                scaleEnabled: true,
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.network(
                  mediaUrl,
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: TitanNovaTheme.primaryBlue),
                child: const Text('FECHAR TELA CHEIA'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class GifViewerModal extends StatefulWidget {
  final Exercicio exercicio;
  final bool modoSelecao;
  final VoidCallback? onAdd;

  const GifViewerModal({
    super.key,
    required this.exercicio,
    this.modoSelecao = false,
    this.onAdd,
  });

  @override
  State<GifViewerModal> createState() => _GifViewerModalState();
}

class _GifViewerModalState extends State<GifViewerModal> {
  bool _isPlaying = true;

  String get _mediaUrl {
    final ex = widget.exercicio;
    if (ex.gifUrl != null && ex.gifUrl!.isNotEmpty) {
      return ex.gifUrl!;
    }
    if (ex.imagemUrl != null && ex.imagemUrl!.isNotEmpty) {
      return ex.imagemUrl!;
    }
    return ex.videoUrl ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercicio;
    final hasMedia = _mediaUrl.isNotEmpty;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: TitanNovaTheme.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Barra de arrasto
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Cabeçalho com título e fechar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: TitanNovaTheme.primaryBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: TitanNovaTheme.primaryBlue.withOpacity(0.4)),
                            ),
                            child: Text(
                              ex.grupoMuscular.toUpperCase(),
                              style: const TextStyle(color: TitanNovaTheme.accentCyan, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: TitanNovaTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: TitanNovaTheme.dividerColor),
                            ),
                            child: Text(
                              ex.equipamento,
                              style: const TextStyle(color: TitanNovaTheme.textGrey, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ex.nome,
                        style: const TextStyle(
                          color: TitanNovaTheme.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: TitanNovaTheme.textGrey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TitanNovaTheme.dividerColor),

          // Conteúdo rolável seguro
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Player do GIF
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TitanNovaTheme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (hasMedia && _isPlaying)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => showGifFullscreenDialog(context, ex),
                              child: Image.network(
                                _mediaUrl,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: 250,
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
                                        const Text(
                                          'Carregando animação GIF...',
                                          style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.broken_image_outlined, color: TitanNovaTheme.warningOrange, size: 48),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Animação indisponível offline',
                                        style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _isPlaying = true),
                            child: Container(
                              color: Colors.black,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_circle_outline, color: TitanNovaTheme.accentCyan, size: 56),
                                    SizedBox(height: 8),
                                    Text('Toque para reproduzir animação', style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Controles sobre o GIF (Pausar e Tela Cheia)
                        if (hasMedia) ...[
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.fullscreen, color: TitanNovaTheme.accentCyan, size: 22),
                                tooltip: 'Ver em Tela Cheia / Zoom',
                                onPressed: () => showGifFullscreenDialog(context, ex),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 22),
                                tooltip: _isPlaying ? 'Pausar' : 'Reproduzir',
                                onPressed: () {
                                  setState(() => _isPlaying = !_isPlaying);
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: TitanNovaTheme.accentCyan.withOpacity(0.4), width: 0.5),
                              ),
                              child: const Text('GIF ANIMADO', style: TextStyle(color: TitanNovaTheme.accentCyan, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Músculos auxiliares se houver
                  if (ex.musculosAuxiliares.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.fitness_center, color: TitanNovaTheme.accentCyan, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Auxiliares: ${ex.musculosAuxiliares}',
                            style: const TextStyle(color: TitanNovaTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Instruções
                  const Text(
                    'Instruções de Execução:',
                    style: TextStyle(color: TitanNovaTheme.textWhite, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ex.instrucoes.isNotEmpty ? ex.instrucoes : 'Execute o movimento com controle de carga e amplitude correta.',
                    style: const TextStyle(color: TitanNovaTheme.textGrey, fontSize: 13, height: 1.4),
                  ),

                  if (ex.cuidados.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Cuidados:',
                      style: TextStyle(color: TitanNovaTheme.warningOrange, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ex.cuidados,
                      style: const TextStyle(color: TitanNovaTheme.textGrey, fontSize: 12, height: 1.3),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Botões de ação inferiores
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            decoration: BoxDecoration(
              color: TitanNovaTheme.surfaceDark,
              border: Border(top: BorderSide(color: TitanNovaTheme.dividerColor.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: TitanNovaTheme.dividerColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('FECHAR', style: TextStyle(color: TitanNovaTheme.textGrey)),
                  ),
                ),
                const SizedBox(width: 10),
                if (widget.modoSelecao && widget.onAdd != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onAdd!();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TitanNovaTheme.successGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('ADICIONAR'),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExerciseDetailsScreen(exercicio: ex, modoSelecao: widget.modoSelecao),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TitanNovaTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('DETALHES'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
