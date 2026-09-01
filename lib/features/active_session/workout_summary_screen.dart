import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/jtech_theme.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/models.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final SessaoTreino sessao;
  final List<SerieRealizada> series;

  const WorkoutSummaryScreen({
    super.key,
    required this.sessao,
    required this.series,
  });

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  final _obsController = TextEditingController();

  void _salvarERetornar() {
    final repo = Provider.of<WorkoutRepository>(context, listen: false);
    final sessaoFinal = SessaoTreino(
      id: widget.sessao.id,
      usuarioId: widget.sessao.usuarioId,
      treinoId: widget.sessao.treinoId,
      nomeTreino: widget.sessao.nomeTreino,
      inicio: widget.sessao.inicio,
      fim: widget.sessao.fim,
      observacoes: _obsController.text.trim(),
      concluido: true,
    );

    repo.finalizarSessao(sessaoFinal, widget.series);
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _compartilharResumo() {
    final duracaoMinutos = widget.sessao.fim != null
        ? widget.sessao.fim!.difference(widget.sessao.inicio).inMinutes
        : 0;

    final seriesConcluidas = widget.series.where((s) => s.concluida).length;
    double volumeTotal = 0;
    for (var s in widget.series.where((s) => s.concluida)) {
      volumeTotal += (s.carga * s.repeticoes);
    }

    final texto = '🏋️‍♂️ TREINO FINALIZADO COM SUCESSO!\n'
        'Aplicativo: TitanNova Fit\n'
        'Treino: ${widget.sessao.nomeTreino}\n'
        '⏱ Duração: $duracaoMinutos minutos\n'
        '✅ Séries Realizadas: $seriesConcluidas\n'
        '💪 Volume Total de Carga: ${volumeTotal.toStringAsFixed(0)} kg\n\n'
        'Treine pesado e acompanhe sua evolução no TitanNova Fit!';

    Share.share(texto);
  }

  @override
  Widget build(BuildContext context) {
    final duracaoMinutos = widget.sessao.fim != null
        ? widget.sessao.fim!.difference(widget.sessao.inicio).inMinutes
        : 0;

    final seriesConcluidas = widget.series.where((s) => s.concluida).length;
    double volumeTotal = 0;
    for (var s in widget.series.where((s) => s.concluida)) {
      volumeTotal += (s.carga * s.repeticoes);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumo do Treino'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAlignment.center,
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 72),
            const SizedBox(height: 12),
            const Text(
              'Parabéns! Treino Concluído!',
              style: TextStyle(color: TitanNovaTheme.textWhite, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.sessao.nomeTreino,
              style: const TextStyle(color: TitanNovaTheme.accentCyan, fontSize: 16),
            ),
            const SizedBox(height: 24),

            // CARDS DE METRICAS
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.timer,
                    label: 'Duração Total',
                    value: '$duracaoMinutos min',
                    color: TitanNovaTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.check_circle_outline,
                    label: 'Séries Concluídas',
                    value: '$seriesConcluidas',
                    color: TitanNovaTheme.successGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.fitness_center,
                    label: 'Volume de Carga',
                    value: '${volumeTotal.toStringAsFixed(0)} kg',
                    color: TitanNovaTheme.warningOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.workspace_premium,
                    label: 'Recorde Pessoal (PR)',
                    value: 'Novo PR! 🏆',
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // CAMPO DE OBSERVAÇÕES
            TextField(
              controller: _obsController,
              style: const TextStyle(color: TitanNovaTheme.textWhite),
              decoration: const InputDecoration(
                labelText: 'Observações sobre o treino de hoje',
                hintText: 'Como se sentiu? Algum desconforto ou evolução?',
                prefixIcon: Icon(Icons.notes, color: TitanNovaTheme.primaryBlue),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 28),

            // BOTÕES DE AÇÃO
            ElevatedButton.icon(
              onPressed: _salvarERetornar,
              style: ElevatedButton.styleFrom(backgroundColor: TitanNovaTheme.successGreen),
              icon: const Icon(Icons.save),
              label: const Text('SALVAR NO HISTÓRICO'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _compartilharResumo,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: TitanNovaTheme.accentCyan),
              ),
              icon: const Icon(Icons.share, color: TitanNovaTheme.accentCyan),
              label: const Text('COMPARTILHAR RESUMO', style: TextStyle(color: TitanNovaTheme.accentCyan, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TitanNovaTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TitanNovaTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: TitanNovaTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: TitanNovaTheme.textGrey, fontSize: 11)),
        ],
      ),
    );
  }
}
