import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/titannova_theme.dart';
import '../../data/models/models.dart';
import '../../data/repositories/workout_repository.dart';

/// Modal / Pop-up avançado para visualização expandida do GIF na mesma tela
class ExerciseGifDialog extends StatefulWidget {
  final Exercicio exercicio;
  final bool modoSelecao;

  const ExerciseGifDialog({
    super.key,
    required this.exercicio,
    this.modoSelecao = false,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required Exercicio exercicio,
    bool modoSelecao = false,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar Visualização',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) {
        return ExerciseGifDialog(
          exercicio: exercicio,
          modoSelecao: modoSelecao,
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curvedValue = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curvedValue,
          alignment: Alignment.center,
          child: Opacity(
            opacity: anim1.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<ExerciseGifDialog> createState() => _ExerciseGifDialogState();
}

class _ExerciseGifDialogState extends State<ExerciseGifDialog> {
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;
  bool _showInstructions = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.05) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final nextScale = (_currentScale + 0.5).clamp(1.0, 4.0);
    _setZoom(nextScale);
  }

  void _zoomOut() {
    final nextScale = (_currentScale - 0.5).clamp(1.0, 4.0);
    _setZoom(nextScale);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() => _currentScale = 1.0);
  }

  void _setZoom(double targetScale) {
    _transformationController.value = Matrix4.identity()..scale(targetScale);
    setState(() => _currentScale = targetScale);
  }

  void _handleDoubleTap() {
    if (_currentScale > 1.2) {
      _resetZoom();
    } else {
      _setZoom(2.2);
    }
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

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<WorkoutRepository>(context);
    // Busca versão atualizada do exercício no repositório (para refletir favoritos)
    final exAtual = repo.exercicios.firstWhere(
      (e) => e.id == widget.exercicio.id,
      orElse: () => widget.exercicio,
    );

    final mediaUrl = (exAtual.gifUrl != null && exAtual.gifUrl!.isNotEmpty)
        ? exAtual.gifUrl!
        : ((exAtual.imagemUrl != null && exAtual.imagemUrl!.isNotEmpty)
            ? exAtual.imagemUrl!
            : (exAtual.videoUrl ?? ''));

    final size = MediaQuery.of(context).size;
    final dialogMaxHeight = size.height * 0.88;
    final dialogMaxWidth = size.width > 560 ? 540.0 : size.width * 0.94;
    final gifBoxHeight = (size.height * 0.42).clamp(280.0, 420.0);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: Container(
          width: dialogMaxWidth,
          constraints: BoxConstraints(maxHeight: dialogMaxHeight),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: TitanNovaTheme.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: TitanNovaTheme.accentCyan.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: TitanNovaTheme.accentCyan.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // CABEÇALHO DO POP-UP
                _buildHeader(context, exAtual, repo),

                // CORPO COM SCROLL (GIF EXPANDIDO + DETALHES)
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // VISUALIZADOR DE GIF COM ZOOM INTERATIVO
                        _buildInteractiveGifBox(mediaUrl, exAtual, gifBoxHeight),

                        const SizedBox(height: 10),

                        // BARRA DE CONTROLES DE ZOOM E DICA
                        _buildZoomControlsBar(),

                        const SizedBox(height: 12),

                        // BADGES DE INFORMAÇÕES TÉCNICAS
                        _buildTagsRow(exAtual),

                        const SizedBox(height: 12),

                        // GUIA DE EXECUÇÃO & CUIDADOS (EXPANSÍVEL)
                        _buildInstructionsAccordion(exAtual),
                      ],
                    ),
                  ),
                ),

                // RODAPÉ COM BOTÕES DE AÇÃO
                _buildFooter(context, exAtual),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Exercicio ex, WorkoutRepository repo) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: TitanNovaTheme.dividerColor)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TitanNovaTheme.primaryBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TitanNovaTheme.primaryBlue.withOpacity(0.4)),
            ),
            child: Icon(_getGroupIcon(ex.grupoMuscular), color: TitanNovaTheme.accentCyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.nome,
                  style: const TextStyle(
                    color: TitanNovaTheme.textWhite,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${ex.grupoMuscular} • ${ex.equipamento}',
                  style: const TextStyle(
                    color: TitanNovaTheme.textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Botão de Favoritar
          IconButton(
            icon: Icon(
              ex.isFavorito ? Icons.star_rounded : Icons.star_outline_rounded,
              color: ex.isFavorito ? Colors.amber : TitanNovaTheme.textMuted,
              size: 26,
            ),
            tooltip: ex.isFavorito ? 'Remover dos favoritos' : 'Favoritar exercício',
            onPressed: () => repo.toggleFavorito(ex.id),
          ),
          // Botão Fechar
          Container(
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: TitanNovaTheme.textWhite, size: 20),
              tooltip: 'Fechar',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveGifBox(String mediaUrl, Exercicio ex, double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF060709),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TitanNovaTheme.dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ÁREA COM PINCH-TO-ZOOM E PAN
            GestureDetector(
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.all(40),
                panEnabled: true,
                scaleEnabled: true,
                child: Center(
                  child: mediaUrl.isNotEmpty
                      ? Image.network(
                          mediaUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: height,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            final expectedBytes = loadingProgress.expectedTotalBytes;
                            final downloadedBytes = loadingProgress.cumulativeBytesLoaded;
                            final progress = expectedBytes != null ? downloadedBytes / expectedBytes : null;

                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      color: TitanNovaTheme.accentCyan,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Carregando animação 3D...',
                                    style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_getGroupIcon(ex.grupoMuscular), color: TitanNovaTheme.accentCyan, size: 64),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Demonstração em GIF indisponível',
                                    style: TextStyle(color: TitanNovaTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Siga as orientações escritas abaixo para executar corretamente.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_getGroupIcon(ex.grupoMuscular), color: TitanNovaTheme.accentCyan, size: 64),
                              const SizedBox(height: 12),
                              const Text(
                                'Demonstração indisponível',
                                style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),

            // BADGE SUPERIOR DIREITO "GIF 3D"
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TitanNovaTheme.accentCyan.withOpacity(0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: TitanNovaTheme.accentCyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'GIF LOOP',
                      style: TextStyle(
                        color: TitanNovaTheme.accentCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // AVISO DISCRETO DE ZOOM QUANDO APLICADO
            if (_currentScale > 1.1)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: TitanNovaTheme.primaryBlue.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Zoom: ${_currentScale.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControlsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TitanNovaTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TitanNovaTheme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.touch_app_rounded, color: TitanNovaTheme.accentCyan, size: 16),
              SizedBox(width: 6),
              Text(
                'Faça pinça ou duplo clique para ampliar',
                style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 11),
              ),
            ],
          ),
          Row(
            children: [
              _buildSmallIconButton(
                icon: Icons.remove_rounded,
                tooltip: 'Diminuir zoom',
                onTap: _zoomOut,
              ),
              const SizedBox(width: 4),
              _buildSmallIconButton(
                icon: Icons.add_rounded,
                tooltip: 'Aumentar zoom',
                onTap: _zoomIn,
              ),
              if (_currentScale > 1.1) ...[
                const SizedBox(width: 4),
                _buildSmallIconButton(
                  icon: Icons.restart_alt_rounded,
                  tooltip: 'Redefinir zoom (1.0x)',
                  color: TitanNovaTheme.accentCyan,
                  onTap: _resetZoom,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color color = TitanNovaTheme.textWhite,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildTagsRow(Exercicio ex) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildTag('🎯 ${ex.grupoMuscular}', TitanNovaTheme.primaryBlue),
        _buildTag('🏋️ ${ex.equipamento}', TitanNovaTheme.accentCyan),
        if (ex.musculosAuxiliares.isNotEmpty)
          _buildTag('💪 Auxiliares: ${ex.musculosAuxiliares}', TitanNovaTheme.successGreen),
      ],
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInstructionsAccordion(Exercicio ex) {
    return Container(
      decoration: BoxDecoration(
        color: TitanNovaTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TitanNovaTheme.dividerColor),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showInstructions = !_showInstructions),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: TitanNovaTheme.accentCyan, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Instruções e Cuidados',
                        style: TextStyle(
                          color: TitanNovaTheme.textWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _showInstructions ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: TitanNovaTheme.accentCyan,
                  ),
                ],
              ),
            ),
          ),
          if (_showInstructions)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: TitanNovaTheme.dividerColor, height: 12),
                  const Text(
                    'Instruções de Execução:',
                    style: TextStyle(color: TitanNovaTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ex.instrucoes.isNotEmpty
                        ? ex.instrucoes
                        : 'Realizar o movimento com amplitude completa, mantendo o abdômen contraído e postura alinhada.',
                    style: const TextStyle(color: TitanNovaTheme.textGrey, fontSize: 12, height: 1.35),
                  ),
                  if (ex.cuidados.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      '⚠️ Cuidados importantes:',
                      style: TextStyle(color: TitanNovaTheme.warningOrange, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ex.cuidados,
                      style: const TextStyle(color: TitanNovaTheme.textGrey, fontSize: 12, height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, Exercicio ex) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: TitanNovaTheme.surfaceDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(top: BorderSide(color: TitanNovaTheme.dividerColor)),
      ),
      child: Row(
        children: [
          if (widget.modoSelecao) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: TitanNovaTheme.dividerColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('CANCELAR', style: TextStyle(color: TitanNovaTheme.textGrey, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, ex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TitanNovaTheme.successGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('ADICIONAR AO TREINO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ] else ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TitanNovaTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text(
                  'FECHAR VISUALIZAÇÃO',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
