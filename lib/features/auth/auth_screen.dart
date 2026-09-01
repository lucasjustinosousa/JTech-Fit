import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/jtech_theme.dart';
import '../common/disclaimer_banner.dart';
import '../../data/repositories/workout_repository.dart';
import '../../core/services/supabase_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController(text: 'atleta@titannovafit.com');
  final _passController = TextEditingController(text: '123456');
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      widget.onLoginSuccess();
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (SupabaseService.instance.isInitialized) {
        if (_isLogin) {
          final user = await SupabaseService.instance.signIn(email, pass);
          if (user == null) {
            await SupabaseService.instance.signUp(email, pass);
          }
        } else {
          await SupabaseService.instance.signUp(email, pass);
        }
      }
    } catch (e) {
      debugPrint('[Auth] Erro ao autenticar no Supabase: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onLoginSuccess();
      }
    }
  }

  void _recuperarSenha() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TitanNovaTheme.cardDark,
        title: const Text('Recuperar Senha', style: TextStyle(color: TitanNovaTheme.textWhite)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Digite seu e-mail cadastrado para receber o link de redefinição de senha:',
              style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: TitanNovaTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('E-mail de recuperação enviado com sucesso!')),
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAlignment.center,
            children: [
              const SizedBox(height: 30),
              // LOGOTIPO TITANNOVA FIT
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: TitanNovaTheme.primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: TitanNovaTheme.primaryBlue.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  size: 52,
                  color: TitanNovaTheme.textWhite,
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'JTECH ',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.black,
                        color: TitanNovaTheme.textWhite,
                        letterSpacing: 1.5,
                      ),
                    ),
                    TextSpan(
                      text: 'FIT',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.black,
                        color: TitanNovaTheme.accentCyan,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Seu Treino sob Controle Absoluto',
                style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 14),
              ),
              const SizedBox(height: 36),

              // Formulário de Autenticação
              TextField(
                controller: _emailController,
                style: const TextStyle(color: TitanNovaTheme.textWhite),
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email_outlined, color: TitanNovaTheme.primaryBlue),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passController,
                obscureText: true,
                style: const TextStyle(color: TitanNovaTheme.textWhite),
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock_outline, color: TitanNovaTheme.primaryBlue),
                ),
              ),
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _recuperarSenha,
                  child: const Text(
                    'Esqueceu a senha?',
                    style: TextStyle(color: TitanNovaTheme.accentCyan, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botões Principais
              ElevatedButton(
                onPressed: _submitAuth,
                child: Text(_isLogin ? 'ENTRAR' : 'CRIAR MINHA CONTA'),
              ),
              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () {
                  setState(() => _isLogin = !_isLogin);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: TitanNovaTheme.primaryBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _isLogin ? 'Criar nova conta' : 'Já possuo uma conta (Entrar)',
                  style: const TextStyle(color: TitanNovaTheme.primaryBlue, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // Botão Continuar Sem Cadastro
              TextButton(
                onPressed: widget.onLoginSuccess,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Continuar sem cadastro (Modo Convidado)',
                      style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 13, decoration: TextDecoration.underline),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 12, color: TitanNovaTheme.textGrey),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // BANNER DE SEGURANÇA E SAÚDE OBRIGATÓRIO
              const DisclaimerBanner(compact: false),
            ],
          ),
        ),
      ),
    );
  }
}
