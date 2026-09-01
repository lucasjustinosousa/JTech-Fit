import 'package:flutter/material.dart';
import '../../core/theme/titannova_theme.dart';

class DisclaimerBanner extends StatelessWidget {
  final bool compact;
  const DisclaimerBanner({super.key, this.compact = false});

  @override
  Widget build(BuildContext me) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: TitanNovaTheme.warningOrange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: TitanNovaTheme.warningOrange.withOpacity(0.4)),
        ),
        child: Row(
          children: const [
            Icon(Icons.shield_outlined, color: TitanNovaTheme.warningOrange, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Este aplicativo não substitui orientação profissional. Interrompa se sentir dor.',
                style: TextStyle(color: TitanNovaTheme.textGrey, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0FF231B0E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TitanNovaTheme.warningOrange, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: TitanNovaTheme.warningOrange, size: 24),
              SizedBox(width: 10),
              Text(
                'Aviso de Saúde e Segurança',
                style: TextStyle(
                  color: TitanNovaTheme.warningOrange,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '• O TitanNova Fit é uma ferramenta de acompanhamento e não substitui o trabalho de um profissional de Educação Física ou médico.\n'
            '• Interrompa imediatamente o exercício se sentir dor, tontura ou mal-estar.\n'
            '• Não tente executar exercícios com cargas excessivas sem orientação prévia.\n'
            '• Iniciantes e menores de idade devem treinar sob supervisão qualificada.',
            style: TextStyle(
              color: TitanNovaTheme.textWhite,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
