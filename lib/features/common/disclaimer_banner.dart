import 'package:flutter/material.dart';
import '../../core/theme/jtech_theme.dart';

class DisclaimerBanner extends StatelessWidget {
  final bool compact;
  const DisclaimerBanner({super.key, this.compact = false});

  @override
  Widget build(BuildContext me) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: JTechTheme.warningOrange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: JTechTheme.warningOrange.withOpacity(0.4)),
        ),
        child: Row(
          children: const [
            Icon(Icons.shield_outlined, color: JTechTheme.warningOrange, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Este aplicativo não substitui orientação profissional. Interrompa se sentir dor.',
                style: TextStyle(color: JTechTheme.textGrey, fontSize: 11, fontWeight: FontWeight.w500),
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
        border: Border.all(color: JTechTheme.warningOrange, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: JTechTheme.warningOrange, size: 24),
              SizedBox(width: 10),
              Text(
                'Aviso de Saúde e Segurança',
                style: TextStyle(
                  color: JTechTheme.warningOrange,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '• O JTech Fit é uma ferramenta de acompanhamento e não substitui o trabalho de um profissional de Educação Física ou médico.\n'
            '• Interrompa imediatamente o exercício se sentir dor, tontura ou mal-estar.\n'
            '• Não tente executar exercícios com cargas excessivas sem orientação prévia.\n'
            '• Iniciantes e menores de idade devem treinar sob supervisão qualificada.',
            style: TextStyle(
              color: JTechTheme.textWhite,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
