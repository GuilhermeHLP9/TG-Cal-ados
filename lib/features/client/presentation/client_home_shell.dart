import 'package:flutter/material.dart';

import 'orders_overview_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';

class ClientHomeShell extends StatefulWidget {
  const ClientHomeShell({super.key});

  @override
  State<ClientHomeShell> createState() => _ClientHomeShellState();
}

class _ClientHomeShellState extends State<ClientHomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = const [
      ClientChatScreen(),
      OrdersOverviewScreen(),
      ClientProfileScreen(),
      ClientSettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F4),
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        titleSpacing: 12,
        title: const _ClientHeader(),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: _ClientBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _ClientHeader extends StatelessWidget {
  const _ClientHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          child: Icon(Icons.person, color: AppColors.primary),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Pai (Fornecedor)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 2),
              Text(
                'Cliente',
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

class _ClientBottomNav extends StatelessWidget {
  const _ClientBottomNav({
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

class ClientChatScreen extends StatelessWidget {
  const ClientChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFFF0F3F4),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              children: const [
                _IncomingBubble(
                  title: 'Oi, tudo bem?',
                  subtitle: 'Progresso do Pedido',
                ),
                SizedBox(height: 14),
                _OutgoingBubble(
                  text: 'Oh tando coricnuado nuo\ncapitullo deia em diz?',
                ),
                SizedBox(height: 14),
                _IncomingBubble(
                  title: '60%',
                  subtitle: 'Progresso do Pedido',
                ),
                SizedBox(height: 14),
                _OutgoingBubble(
                  text: 'Empriesso, vaninuta\nnom teu somitado?',
                ),
                SizedBox(height: 14),
                _IncomingBubble(
                  title: '60%',
                  subtitle: 'Progresso do Pedido',
                ),
              ],
            ),
          ),
        ),
        const _ComposerBar(),
      ],
    );
  }
}

class _IncomingBubble extends StatelessWidget {
  const _IncomingBubble({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 190,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.chatIncomingAccent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutgoingBubble extends StatelessWidget {
  const _OutgoingBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 230),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.chatOutgoing,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCED7DE)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.upload_file_rounded, size: 20),
                  label: const Text('ENVIAR ARQUIVO'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderSection(
      title: 'Perfil',
      subtitle: 'Aba visual criada para seguir a navegacao da referencia.',
    );
  }
}

class ClientSettingsScreen extends StatelessWidget {
  const ClientSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderSection(
      title: 'Configuracoes',
      subtitle: 'Estilizacao pronta. As funcoes podem entrar depois.',
    );
  }
}

class _PlaceholderSection extends StatelessWidget {
  const _PlaceholderSection({
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
