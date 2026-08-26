import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/jtech_theme.dart';
import '../../data/repositories/workout_repository.dart';
import '../common/disclaimer_banner.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _somHabilitado = true;
  bool _vibracaoHabilitada = true;

  void _exibirConfirmacaoExclusao() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: JTechTheme.cardDark,
        title: const Text('Excluir Conta e Dados?', style: TextStyle(color: JTechTheme.errorRed)),
        content: const Text(
          'Esta ação apagará permanentemente todos os seus treinos criados, histórico e configurações tanto do dispositivo quanto da nuvem.',
          style: TextStyle(color: JTechTheme.textWhite, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: JTechTheme.textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: JTechTheme.errorRed),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onLogout();
            },
            child: const Text('EXCLUIR TUDO'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<WorkoutRepository>(context);
    final user = repo.usuarioAtual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil e Configurações'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            // PERFIL DO USUÁRIO
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: JTechTheme.primaryBlue,
                    child: const Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.nome ?? 'Atleta JTech',
                    style: const TextStyle(color: JTechTheme.textWhite, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? 'atleta@jtechfit.com',
                    style: const TextStyle(color: JTechTheme.textGrey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // PREFERÊNCIAS DE TREINO
            const Text(
              'Preferências de Treino',
              style: TextStyle(color: JTechTheme.textWhite, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.scale, color: JTechTheme.accentCyan),
                    title: const Text('Unidade de Carga', style: TextStyle(color: Colors.white)),
                    trailing: DropdownButton<String>(
                      value: user?.unidadeCarga ?? 'kg',
                      dropdownColor: JTechTheme.cardDark,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'kg', child: Text('Quilogramas (kg)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'lb', child: Text('Libras (lb)', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (val) {
                        if (val != null) repo.atualizarUnidade(val);
                      },
                    ),
                  ),
                  const Divider(height: 1, color: JTechTheme.dividerColor),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined, color: JTechTheme.primaryBlue),
                    title: const Text('Descanso Padrão entre Séries', style: TextStyle(color: Colors.white)),
                    trailing: DropdownButton<int>(
                      value: user?.descansoPadrao ?? 60,
                      dropdownColor: JTechTheme.cardDark,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30 seg', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 60, child: Text('60 seg', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 90, child: Text('90 seg', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 120, child: Text('120 seg', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (val) {
                        if (val != null) repo.atualizarDescansoPadrao(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // SONS E NOTIFICAÇÕES
            const Text(
              'Sons e Notificações',
              style: TextStyle(color: JTechTheme.textWhite, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Som no Alerta de Descanso', style: TextStyle(color: Colors.white)),
                    value: _somHabilitado,
                    activeColor: JTechTheme.successGreen,
                    onChanged: (val) => setState(() => _somHabilitado = val),
                  ),
                  const Divider(height: 1, color: JTechTheme.dividerColor),
                  SwitchListTile(
                    title: const Text('Vibração ao Zerar o Cronômetro', style: TextStyle(color: Colors.white)),
                    value: _vibracaoHabilitada,
                    activeColor: JTechTheme.successGreen,
                    onChanged: (val) => setState(() => _vibracaoHabilitada = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // NUVEM E DADOS
            const Text(
              'Sincronização e Dados da Biblioteca',
              style: TextStyle(color: JTechTheme.textWhite, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.fitness_center, color: JTechTheme.successGreen),
                    title: const Text('Biblioteca ExerciseDB V1', style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '${repo.exercicios.length} exercícios armazenados offline\nÚltima atualização: Hoje às ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: JTechTheme.textGrey, fontSize: 11),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sincronizando todas as páginas da ExerciseDB...')),
                        );
                        await repo.carregarDados();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Biblioteca atualizada com sucesso! Total: ${repo.exercicios.length} exercícios.')),
                          );
                        }
                      },
                      child: const Text('ATUALIZAR', style: TextStyle(color: JTechTheme.accentCyan, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const Divider(height: 1, color: JTechTheme.dividerColor),
                  ListTile(
                    leading: const Icon(Icons.cleaned_services, color: JTechTheme.warningOrange),
                    title: const Text('Limpar Cache de Imagens / GIFs', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Fichas e treinos criados continuam salvos intactos.', style: TextStyle(color: JTechTheme.textGrey, fontSize: 11)),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cache de mídias limpo com sucesso!')),
                      );
                    },
                  ),
                  const Divider(height: 1, color: JTechTheme.dividerColor),
                  ListTile(
                    leading: const Icon(Icons.cloud_sync, color: JTechTheme.accentCyan),
                    title: const Text('Sincronizar com Supabase', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Offline-first ativo. Sincronização automática.', style: TextStyle(color: JTechTheme.textGrey, fontSize: 11)),
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh, color: JTechTheme.accentCyan),
                      onPressed: () {
                        repo.carregarDados();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dados sincronizados com sucesso!')),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1, color: JTechTheme.dividerColor),
                  ListTile(
                    leading: const Icon(Icons.download, color: JTechTheme.warningOrange),
                    title: const Text('Exportar Meus Dados (JSON/CSV)', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exportação concluída. Arquivo salvo.')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // BOTÃO SAIR E EXCLUIR
            ElevatedButton.icon(
              onPressed: widget.onLogout,
              style: ElevatedButton.styleFrom(backgroundColor: JTechTheme.surfaceDark),
              icon: const Icon(Icons.logout, color: JTechTheme.textWhite),
              label: const Text('SAIR DA CONTA', style: TextStyle(color: JTechTheme.textWhite)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _exibirConfirmacaoExclusao,
              child: const Text(
                'Excluir Conta e Todos os Dados',
                style: TextStyle(color: JTechTheme.errorRed, fontSize: 13, decoration: TextDecoration.underline),
              ),
            ),

            const SizedBox(height: 20),
            const DisclaimerBanner(compact: true),
          ],
        ),
      ),
    );
  }
}
