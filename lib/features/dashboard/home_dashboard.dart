import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/jtech_theme.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/models.dart';
import '../common/disclaimer_banner.dart';

class HomeDashboard extends StatelessWidget {
  final Function(int tabIndex) onNavigateToTab;
  final Function(Treino treino) onStartWorkout;

  const HomeDashboard({
    super.key,
    required this.onNavigateToTab,
    required this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<WorkoutRepository>(context);
    final user = repo.usuarioAtual;
    final treinos = repo.treinos;
    final historico = repo.historico;

    // Calcular estatísticas da semana
    final agora = DateTime.now();
    final inicioSemana = agora.subtract(Duration(days: agora.weekday - 1));
    final treinosNaSemana = historico.where((h) => h.inicio.isAfter(inicioSemana)).length;

    final ultimoTreino = historico.isNotEmpty ? historico.first : null;
    final treinoRecomendado = treinos.isNotEmpty ? treinos.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.fitness_center, color: JTechTheme.primaryBlue, size: 24),
            SizedBox(width: 8),
            Text('JTECH FIT', style: TextStyle(fontWeight: FontWeight.black, letterSpacing: 1)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: JTechTheme.textWhite),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            // Saudação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: [
                    Text(
                      'Olá, ${user?.nome ?? 'Atleta'}! 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: JTechTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bora superar seus limites hoje?',
                      style: TextStyle(color: JTechTheme.textGrey, fontSize: 13),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: JTechTheme.primaryBlue,
                  child: const Icon(Icons.person, color: JTechTheme.textWhite),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // CARD PRINCIPAL: INICIAR TREINO DO DIA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0FF1E88E5), Color(0FF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: JTechTheme.primaryBlue.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'TREINO PROGRAMADO HOJE',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    treinoRecomendado?.nome ?? 'Selecione ou Crie um Treino',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${treinoRecomendado?.exercicios.length ?? 0} exercícios • ~45 minutos de duração',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (treinoRecomendado != null) {
                        onStartWorkout(treinoRecomendado);
                      } else {
                        onNavigateToTab(1); // Vai para abas de Treinos
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JTechTheme.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.play_arrow_rounded, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'INICIAR TREINO AGORA',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.black, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // CARDS DE ESTATÍSTICAS RÁPIDAS
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: JTechTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: JTechTheme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        const Icon(Icons.fitness_center_outlined, color: JTechTheme.accentCyan, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          '$treinosNaSemana treinos',
                          style: const TextStyle(color: JTechTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        const Text('Concluídos esta semana', style: TextStyle(color: JTechTheme.textGrey, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: JTechTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: JTechTheme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        const Icon(Icons.history_toggle_off_rounded, color: JTechTheme.successGreen, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          ultimoTreino != null ? DateFormat('dd/MM').format(ultimoTreino.inicio) : 'Nenhum',
                          style: const TextStyle(color: JTechTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ultimoTreino != null ? ultimoTreino.nomeTreino : 'Último treino efetuado',
                          style: const TextStyle(color: JTechTheme.textGrey, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ATALHOS RÁPIDOS
            const Text(
              'Acesso Rápido',
              style: TextStyle(color: JTechTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShortcutItem(
                  icon: Icons.list_alt_rounded,
                  label: 'Meus Treinos',
                  color: JTechTheme.primaryBlue,
                  onTap: () => onNavigateToTab(1),
                ),
                _buildShortcutItem(
                  icon: Icons.fitness_center_sharp,
                  label: 'Exercícios',
                  color: JTechTheme.accentCyan,
                  onTap: () => onNavigateToTab(2),
                ),
                _buildShortcutItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Histórico',
                  color: JTechTheme.warningOrange,
                  onTap: () => onNavigateToTab(3),
                ),
                _buildShortcutItem(
                  icon: Icons.person_outline,
                  label: 'Perfil',
                  color: Colors.purpleAccent,
                  onTap: () => onNavigateToTab(4),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const DisclaimerBanner(compact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: JTechTheme.textWhite, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
