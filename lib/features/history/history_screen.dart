import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/titannova_theme.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<WorkoutRepository>(context);
    final historico = repo.historico;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico e Evolução'),
      ),
      body: historico.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.bar_chart_outlined, size: 64, color: TitanNovaTheme.textMuted),
                  SizedBox(height: 16),
                  Text('Nenhum treino registrado ainda.', style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 16)),
                  SizedBox(height: 6),
                  Text('Complete seu primeiro treino para visualizar a evolução.', style: TextStyle(color: TitanNovaTheme.textMuted, fontSize: 12)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAlignment.start,
                children: [
                  // GRÁFICO SIMPLES DE EVOLUÇÃO DE TREINOS POR SEMANA
                  const Text(
                    'Evolução de Volume Semanal',
                    style: TextStyle(color: TitanNovaTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 180,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TitanNovaTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TitanNovaTheme.dividerColor),
                    ),
                    child: BarChart(
                      BarChartData(
                        backgroundColor: Colors.transparent,
                        barGroups: [
                          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 3, color: TitanNovaTheme.primaryBlue, width: 14)]),
                          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 4, color: TitanNovaTheme.primaryBlue, width: 14)]),
                          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 5, color: TitanNovaTheme.accentCyan, width: 14)]),
                          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 4, color: TitanNovaTheme.successGreen, width: 14)]),
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                switch (val.toInt()) {
                                  case 1: return const Text('Sem 1', style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 10));
                                  case 2: return const Text('Sem 2', style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 10));
                                  case 3: return const Text('Sem 3', style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 10));
                                  case 4: return const Text('Atual', style: TextStyle(color: TitanNovaTheme.successGreen, fontSize: 10, fontWeight: FontWeight.bold));
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // LISTA DE TREINOS ANTERIORES
                  const Text(
                    'Treinos Realizados',
                    style: TextStyle(color: TitanNovaTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: historico.length,
                    itemBuilder: (ctx, idx) {
                      final sessao = historico[idx];
                      final dataStr = DateFormat('dd/MM/yyyy • HH:mm').format(sessao.inicio);
                      final duracao = sessao.fim != null ? '${sessao.fim!.difference(sessao.inicio).inMinutes} min' : 'Em andamento';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: TitanNovaTheme.successGreen,
                            child: Icon(Icons.check, color: Colors.white),
                          ),
                          title: Text(
                            sessao.nomeTreino,
                            style: const TextStyle(color: TitanNovaTheme.textWhite, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '$dataStr • Duração: $duracao',
                            style: const TextStyle(color: TitanNovaTheme.textGrey, fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: TitanNovaTheme.textGrey),
                          onTap: () {
                            // Exibir detalhes das séries gravadas
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
