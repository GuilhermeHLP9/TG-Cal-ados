import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_heading.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = const [
      ('Pedidos novos', '12'),
      ('Em producao', '8'),
      ('Entrega hoje', '3'),
      ('Lucro previsto', 'R\$ 4.820'),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeading(
          title: 'Painel do proprietario',
          subtitle: 'Visao geral da operacao com foco em prazos, pedidos e retorno.',
        ),
        const SizedBox(height: 20),
        ...metrics.map(
          (metric) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.$2,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primaryDark,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(metric.$1),
                ],
              ),
            ),
          ),
        ),
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prioridades do dia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                'Confirmar pedidos novos, acompanhar atrasos e revisar materiais criticos para a producao.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
