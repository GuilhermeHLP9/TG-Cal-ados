import 'package:flutter/material.dart';

import 'owner_dashboard_screen.dart';
import 'owner_orders_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';

class OwnerHomeShell extends StatefulWidget {
  const OwnerHomeShell({super.key});

  @override
  State<OwnerHomeShell> createState() => _OwnerHomeShellState();
}

class _OwnerHomeShellState extends State<OwnerHomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = const [
      OwnerDashboardScreen(),
      OwnerOrdersScreen(),
      OwnerProfileScreen(),
      OwnerSettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F4),
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        titleSpacing: 12,
        title: const _OwnerHeader(),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: _OwnerBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _OwnerHeader extends StatelessWidget {
  const _OwnerHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          child: Icon(Icons.factory_outlined, color: AppColors.primary),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Painel do fornecedor',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 2),
              Text(
                'Gestao da fabrica',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white24,
          child: Icon(Icons.person_outline, color: Colors.white, size: 28),
        ),
      ],
    );
  }
}

class _OwnerBottomNav extends StatelessWidget {
  const _OwnerBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.chat_bubble, 'CHAT'),
      (Icons.assignment_outlined, 'PEDIDOS'),
      (Icons.person_outline, 'PERFIL'),
      (Icons.settings_outlined, 'CONFIGURACOES'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = index == currentIndex;

          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 4,
                    width: 58,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    item.$1,
                    color: selected ? AppColors.primary : Colors.black87,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OwnerPlaceholder(
      title: 'Perfil',
      subtitle: 'Aba visual criada para manter as quatro opcoes no rodape.',
    );
  }
}

class OwnerSettingsScreen extends StatelessWidget {
  const OwnerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OwnerPlaceholder(
      title: 'Configuracoes',
      subtitle: 'Estilizacao pronta para receber as funcoes depois.',
    );
  }
}

class _OwnerPlaceholder extends StatelessWidget {
  const _OwnerPlaceholder({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
